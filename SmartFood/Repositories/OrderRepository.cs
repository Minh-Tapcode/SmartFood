using SmartFood.Data;
using SmartFood.Models;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;

namespace SmartFood.Repositories
{
    public class OrderRepository
    {
        private readonly SmartFoodContext _context;

        public OrderRepository(SmartFoodContext context)
        {
            _context = context;
        }

        public Cart GetCartByUser(int userId) => _context.Cart.FirstOrDefault(x => x.UserId == userId);

        public List<CartItem> GetCartItems(int cartId) => _context.CartItems.Where(x => x.CartId == cartId).ToList();

        public Product GetProduct(int productId) => _context.Products.Find(productId);

        public Dictionary<int, Product> GetProductsByIds(IEnumerable<int> productIds)
        {
            var ids = productIds.Distinct().ToList();
            if (ids.Count == 0) return new Dictionary<int, Product>();

            return _context.Products
                .AsNoTracking()
                .Where(p => ids.Contains(p.Id))
                .ToDictionary(p => p.Id);
        }

        public List<TopProductInsightRow> GetTopPurchasedProductsForUser(int userId, int take = 8)
        {
            return (from oi in _context.OrderItem.AsNoTracking()
                    join o in _context.Orders.AsNoTracking() on oi.OrderId equals o.Id
                    join p in _context.Products.AsNoTracking() on oi.ProductId equals p.Id
                    where o.UserId == userId
                    group oi by new { p.Id, p.Name } into g
                    orderby g.Sum(x => x.Quantity) descending
                    select new TopProductInsightRow
                    {
                        Name = g.Key.Name,
                        Quantity = g.Sum(x => x.Quantity)
                    })
                .Take(take)
                .ToList();
        }

        public void DeductProductStocks(IEnumerable<OrderItem> items)
        {
            foreach (var item in items)
            {
                var product = _context.Products.Find(item.ProductId);
                if (product == null)
                    throw new Exception($"Product {item.ProductId} not found");
                if (product.Stock < item.Quantity)
                    throw new Exception($"Product {product.Name} out of stock");

                product.Stock -= item.Quantity;
            }

            _context.SaveChanges();
        }

        /// <summary>Hoàn tồn kho khi đơn hủy / hoàn trả (đối xứng với DeductProductStocks).</summary>
        public void RestoreProductStocks(IEnumerable<OrderItem> items)
        {
            foreach (var item in items)
            {
                var product = _context.Products.Find(item.ProductId);
                if (product == null)
                    continue;
                product.Stock += item.Quantity;
            }

            _context.SaveChanges();
        }

        public void CreateOrder(Order order)
        {
            _context.Orders.Add(order);
            _context.SaveChanges();
        }

        public void AddOrderItems(List<OrderItem> items)
        {
            _context.OrderItem.AddRange(items);
            _context.SaveChanges();
        }

        public void ClearCart(int cartId)
        {
            var items = _context.CartItems.Where(x => x.CartId == cartId);
            _context.CartItems.RemoveRange(items);
            _context.SaveChanges();
        }

        public void RemoveCartItemsByIds(int cartId, IEnumerable<int> cartItemIds)
        {
            var ids = (cartItemIds ?? Enumerable.Empty<int>()).Distinct().ToList();
            if (!ids.Any()) return;

            var items = _context.CartItems
                .Where(x => x.CartId == cartId && ids.Contains(x.Id))
                .ToList();

            if (!items.Any()) return;

            _context.CartItems.RemoveRange(items);
            _context.SaveChanges();
        }

        public Order GetOrder(int orderId) => _context.Orders.Find(orderId);

        public void UpdateOrder(Order order)
        {
            _context.Orders.Update(order);
            _context.SaveChanges();
        }

        public List<Order> GetOrdersByUser(int userId) =>
            _context.Orders
                .AsNoTracking()
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.CreatedAt)
                .ToList();

        public List<Order> GetAllOrders() =>
            _context.Orders
                .AsNoTracking()
                .OrderByDescending(o => o.CreatedAt)
                .ToList();

        public List<OrderItem> GetOrderItems(int orderId) =>
            _context.OrderItem
                .AsNoTracking()
                .Where(i => i.OrderId == orderId)
                .ToList();

        /// <summary>User đã từng đặt đơn áp dụng promotion này (mỗi user tối đa 1 lần / mã).</summary>
        public bool UserHasUsedPromotion(int userId, int promotionId) =>
            _context.Orders
                .AsNoTracking()
                .Any(o => o.UserId == userId && o.PromotionId == promotionId);

        public List<int> GetUsedPromotionIdsForUser(int userId) =>
            _context.Orders
                .AsNoTracking()
                .Where(o => o.UserId == userId && o.PromotionId != null && o.PromotionId > 0)
                .Select(o => o.PromotionId!.Value)
                .Distinct()
                .ToList();
    }

    public class TopProductInsightRow
    {
        public string Name { get; set; } = string.Empty;
        public int Quantity { get; set; }
    }
}