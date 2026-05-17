using SmartFood.DTOs.Order;
using SmartFood.Models;
using SmartFood.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartFood.Services
{
    public class OrderService
    {
        private readonly OrderRepository _orderRepo;
        private readonly PaymentRepository _paymentRepo;
        private readonly IPaymentService _paymentService;
        private readonly PromotionRepository _promotionRepo;

        public OrderService(
            OrderRepository orderRepo,
            PaymentRepository paymentRepo,
            IPaymentService paymentService,
            PromotionRepository promotionRepo)
        {
            _orderRepo = orderRepo;
            _paymentRepo = paymentRepo;
            _paymentService = paymentService;
            _promotionRepo = promotionRepo;
        }

        public async Task<object> CreateOrder(int userId, SmartFood.DTOs.Order.CreateOrderDto dto)
        {
            var cart = _orderRepo.GetCartByUser(userId);
            if (cart == null)
                throw new Exception("Cart empty");
            var cartItems = _orderRepo.GetCartItems(cart.Id);

            var selectedIds = (dto.CartItemIds ?? new List<int>())
                .Where(x => x > 0)
                .Distinct()
                .ToList();
            if (selectedIds.Any())
            {
                cartItems = cartItems
                    .Where(x => selectedIds.Contains(x.Id))
                    .ToList();
            }

            if (!cartItems.Any())
                throw new Exception("Cart empty");

            decimal subtotal = 0;
            var orderItems = new List<OrderItem>();

            foreach (var item in cartItems)
            {
                var product = _orderRepo.GetProduct(item.ProductId);
                if (product == null)
                    throw new Exception($"Product {item.ProductId} not found");
                if (product.Stock < item.Quantity)
                    throw new Exception($"Product {product.Name} is out of stock");

                subtotal += product.Price * item.Quantity;

                orderItems.Add(new OrderItem
                {
                    ProductId = product.Id,
                    Quantity = item.Quantity,
                    Price = product.Price
                });
            }

            var shippingFee = dto.ShippingFee < 0 ? 0 : dto.ShippingFee;
            decimal discountAmount;
            int? promotionIdSaved = null;
            string? promotionTitleSaved = null;

            if (dto.PromotionId.HasValue && dto.PromotionId.Value > 0)
            {
                var promo = _promotionRepo.GetById(dto.PromotionId.Value);
                var now = DateTime.Now;
                if (promo == null || promo.StartDate > now || promo.EndDate < now)
                    throw new Exception("Phiếu giảm giá không hợp lệ hoặc đã hết hạn.");
                if (_orderRepo.UserHasUsedPromotion(userId, dto.PromotionId.Value))
                    throw new Exception("Mỗi tài khoản chỉ được dùng mã giảm giá này một lần.");
                discountAmount = Math.Round(subtotal * (promo.DiscountPercent / 100m), 0, MidpointRounding.AwayFromZero);
                promotionIdSaved = promo.Id;
                promotionTitleSaved = promo.Title;
            }
            else
            {
                discountAmount = dto.DiscountAmount < 0 ? 0 : dto.DiscountAmount;
                if (discountAmount > subtotal)
                    discountAmount = subtotal;
            }

            var computedFinal = subtotal + shippingFee - discountAmount;
            if (computedFinal < 0) computedFinal = 0;

            var finalAmount = (dto.PromotionId.HasValue && dto.PromotionId.Value > 0)
                ? computedFinal
                : (dto.FinalAmount.HasValue && dto.FinalAmount.Value > 0 ? dto.FinalAmount.Value : computedFinal);

            var order = new Order
            {
                UserId = userId,
                TotalPrice = finalAmount,
                Address = dto.Address,
                ReceiverName = dto.ReceiverName,
                ReceiverPhone = dto.ReceiverPhone,
                Note = dto.Note,
                Status = "pending",
                ShippingFee = shippingFee,
                DiscountAmount = discountAmount,
                PromotionId = promotionIdSaved,
                PromotionTitle = promotionTitleSaved
            };

            _orderRepo.CreateOrder(order);
            orderItems.ForEach(x => x.OrderId = order.Id);
            _orderRepo.AddOrderItems(orderItems);
            _orderRepo.DeductProductStocks(orderItems);
            if (selectedIds.Any())
            {
                _orderRepo.RemoveCartItemsByIds(cart.Id, selectedIds);
            }
            else
            {
                _orderRepo.ClearCart(cart.Id);
            }

            return dto.PaymentMethod switch
            {
                "COD" => await _paymentService.PayOnDelivery(order.Id),
                "VNPAY" => await _paymentService.PayWithVNPay(order.Id),
                _ => throw new Exception("Invalid payment method")
            };
        }

        public List<OrderListItemDto> GetOrdersByUser(int userId)
        {
            var orders = _orderRepo.GetOrdersByUser(userId);
            return MapListItems(orders);
        }

        public UserPurchaseInsightsDto GetUserPurchaseInsights(int userId)
        {
            var orders = _orderRepo.GetOrdersByUser(userId);
            var topRows = _orderRepo.GetTopPurchasedProductsForUser(userId, 8);

            return new UserPurchaseInsightsDto
            {
                TotalOrders = orders.Count,
                TotalSpent = orders.Sum(o => o.TotalPrice),
                LastOrderAt = orders.FirstOrDefault()?.CreatedAt,
                TopProducts = topRows.Select(r => new TopProductInsightDto
                {
                    Name = r.Name,
                    Quantity = r.Quantity
                }).ToList(),
                Orders = MapListItems(orders)
            };
        }

        public List<OrderListItemDto> GetAllOrders()
        {
            var orders = _orderRepo.GetAllOrders();
            return MapListItems(orders);
        }

        public OrderDetailClientDto? GetOrderDetail(int orderId)
        {
            var o = _orderRepo.GetOrder(orderId);
            if (o == null) return null;

            var items = _orderRepo.GetOrderItems(orderId);
            var products = _orderRepo.GetProductsByIds(items.Select(i => i.ProductId));
            return new OrderDetailClientDto
            {
                Order = MapListItem(o),
                OrderDetails = items.Select(i =>
                {
                    products.TryGetValue(i.ProductId, out var product);
                    return new OrderLineDto
                    {
                        OrderId = o.Id,
                        ProductId = i.ProductId,
                        ProductName = product?.Name ?? "",
                        ImageUrl = product?.ImageUrl,
                        Price = i.Price,
                        Quantity = i.Quantity
                    };
                }).ToList()
            };
        }

        public bool UpdateOrderStatus(int orderId, string status)
        {
            var order = _orderRepo.GetOrder(orderId);
            if (order == null) return false;

            var normalized = (status ?? "").Trim().ToLower();
            var allowed = new HashSet<string>
            {
                "pending", "picking", "processing", "shipping", "completed", "cancelled", "returned"
            };
            if (!allowed.Contains(normalized)) return false;

            var previous = (order.Status ?? "pending").Trim().ToLower();
            if (previous == normalized)
                return true;

            if (ShouldRestoreStockAfterStatusChange(previous, normalized))
            {
                var lineItems = _orderRepo.GetOrderItems(orderId);
                if (lineItems.Count > 0)
                    _orderRepo.RestoreProductStocks(lineItems);
            }

            order.Status = normalized;
            _orderRepo.UpdateOrder(order);
            return true;
        }

        /// <summary>
        /// User chỉ được hủy khi đơn còn <c>pending</c> (chờ xác nhận). Hoàn kho qua <see cref="UpdateOrderStatus"/>.
        /// </summary>
        public (bool ok, string message) TryCancelOrderByUser(int orderId, int userId)
        {
            if (userId <= 0)
                return (false, "Thiếu thông tin người dùng.");

            var order = _orderRepo.GetOrder(orderId);
            if (order == null)
                return (false, "Không tìm thấy đơn hàng.");
            if (order.UserId != userId)
                return (false, "Bạn không thể hủy đơn này.");

            var previous = (order.Status ?? "pending").Trim().ToLower();
            if (previous != "pending")
                return (false, "Chỉ hủy được khi đơn đang chờ xác nhận.");

            var ok = UpdateOrderStatus(orderId, "cancelled");
            return ok ? (true, "") : (false, "Không cập nhật được trạng thái đơn.");
        }

        /// <summary>
        /// Đơn đã trừ kho lúc tạo; chỉ cộng lại khi chuyển sang cancelled/returned lần đầu (tránh cộng đôi).
        /// </summary>
        private static bool ShouldRestoreStockAfterStatusChange(string previous, string next)
        {
            if (next != "cancelled" && next != "returned")
                return false;
            if (previous == "cancelled" || previous == "returned")
                return false;
            return true;
        }

        public object GetRevenueSummary(DateTime? startDate, DateTime? endDate)
        {
            var query = _orderRepo.GetAllOrders().AsQueryable();
            if (startDate.HasValue) query = query.Where(x => x.CreatedAt >= startDate.Value.Date);
            if (endDate.HasValue) query = query.Where(x => x.CreatedAt < endDate.Value.Date.AddDays(1));

            var orders = query.ToList();
            return new
            {
                totalOrders = orders.Count,
                totalRevenue = orders.Sum(x => x.TotalPrice),
                totalUsers = orders.Select(x => x.UserId).Distinct().Count()
            };
        }

        public IEnumerable<object> GetRevenueByDay(int days = 7)
        {
            var from = DateTime.Today.AddDays(-(days - 1));
            var orders = _orderRepo.GetAllOrders().Where(x => x.CreatedAt.Date >= from).ToList();

            return Enumerable.Range(0, days).Select(i =>
            {
                var date = from.AddDays(i).Date;
                var inDay = orders.Where(x => x.CreatedAt.Date == date);
                return new
                {
                    date = date.ToString("yyyy-MM-dd"),
                    orderCount = inDay.Count(),
                    revenue = inDay.Sum(x => x.TotalPrice)
                };
            });
        }

        /// <summary>
        /// One row per calendar day between start and end (inclusive). Span is capped at 366 days.
        /// </summary>
        public IEnumerable<object> GetRevenueByDayRange(DateTime startDate, DateTime endDate)
        {
            var start = startDate.Date;
            var end = endDate.Date;
            if (end < start)
            {
                (start, end) = (end, start);
            }

            var dayCount = (int)(end - start).TotalDays + 1;
            if (dayCount > 366)
            {
                start = end.AddDays(-365);
                dayCount = 366;
            }

            var orders = _orderRepo.GetAllOrders()
                .Where(x => x.CreatedAt.Date >= start && x.CreatedAt.Date <= end)
                .ToList();

            return Enumerable.Range(0, dayCount).Select(i =>
            {
                var date = start.AddDays(i).Date;
                var inDay = orders.Where(x => x.CreatedAt.Date == date);
                return new
                {
                    date = date.ToString("yyyy-MM-dd"),
                    orderCount = inDay.Count(),
                    revenue = inDay.Sum(x => x.TotalPrice)
                };
            });
        }

        public IEnumerable<object> GetRevenueByMonth(int year)
        {
            var orders = _orderRepo.GetAllOrders().Where(x => x.CreatedAt.Year == year).ToList();
            return Enumerable.Range(1, 12).Select(month =>
            {
                var inMonth = orders.Where(x => x.CreatedAt.Month == month);
                return new
                {
                    month,
                    orderCount = inMonth.Count(),
                    revenue = inMonth.Sum(x => x.TotalPrice)
                };
            });
        }

        public IEnumerable<object> GetRevenueByYear()
        {
            var orders = _orderRepo.GetAllOrders().ToList();
            if (!orders.Any())
            {
                var y = DateTime.Now.Year;
                return new[] { new { year = y, orderCount = 0, revenue = 0m } };
            }

            var minY = orders.Min(x => x.CreatedAt.Year);
            var maxY = Math.Max(orders.Max(x => x.CreatedAt.Year), DateTime.Now.Year);

            return Enumerable.Range(minY, maxY - minY + 1).Select(year =>
            {
                var inYear = orders.Where(x => x.CreatedAt.Year == year);
                return new
                {
                    year,
                    orderCount = inYear.Count(),
                    revenue = inYear.Sum(x => x.TotalPrice)
                };
            });
        }

        private List<OrderListItemDto> MapListItems(List<Order> orders)
        {
            var payments = _paymentRepo.GetLatestPaymentsByOrderIds(orders.Select(o => o.Id));
            return orders.Select(o => MapListItem(o, payments.GetValueOrDefault(o.Id))).ToList();
        }

        private OrderListItemDto MapListItem(Order o, Payment? payment = null)
        {
            payment ??= _paymentRepo.GetPaymentByOrderId(o.Id);
            return new OrderListItemDto
            {
                Id = o.Id,
                UserId = o.UserId,
                TotalPrice = o.TotalPrice,
                Status = o.Status ?? "pending",
                Address = o.Address,
                CreatedAt = o.CreatedAt,
                ReceiverName = o.ReceiverName ?? "",
                ReceiverPhone = o.ReceiverPhone ?? "",
                Note = o.Note,
                PaymentMethod = payment?.Method,
                PaymentStatus = MapPaymentDisplayStatus(payment),
                ShippingFee = o.ShippingFee,
                DiscountAmount = o.DiscountAmount,
                PromotionId = o.PromotionId,
                PromotionTitle = o.PromotionTitle
            };
        }

        private static string MapPaymentDisplayStatus(Payment? payment)
        {
            if (payment == null) return "unpaid";
            var s = (payment.Status ?? "").Trim().ToLowerInvariant();
            return s switch
            {
                "paid" => "paid",
                "success" => "paid",
                "pending" => "pending",
                "failed" => "failed",
                _ => "unpaid"
            };
        }
    }
}