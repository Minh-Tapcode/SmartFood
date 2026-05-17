using Microsoft.AspNetCore.Mvc;
using SmartFood.DTOs.Order;
using SmartFood.Services;

namespace SmartFood.Controllers
{
    [ApiController]
    [Route("api/orders")]
    public class OrderController : ControllerBase
    {
        private readonly OrderService _orderService;

        public OrderController(OrderService orderService)
        {
            _orderService = orderService;
        }

        /// <summary>Danh sách đơn: ?userId= (user) hoặc tất cả (admin / không truyền).</summary>
        [HttpGet]
        public IActionResult List([FromQuery] int? userId)
        {
            if (userId.HasValue)
                return Ok(_orderService.GetOrdersByUser(userId.Value));
            return Ok(_orderService.GetAllOrders());
        }

        [HttpGet("{id:int}")]
        public IActionResult GetById(int id)
        {
            var detail = _orderService.GetOrderDetail(id);
            if (detail == null) return NotFound();
            return Ok(detail);
        }

        /// <summary>Thống kê mua hàng của user (admin) — một request thay vì N+1 chi tiết đơn.</summary>
        [HttpGet("user/{userId:int}/insights")]
        public IActionResult GetUserPurchaseInsights(int userId)
        {
            if (userId <= 0)
                return BadRequest(new { message = "Invalid userId" });
            return Ok(_orderService.GetUserPurchaseInsights(userId));
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromQuery] int userId, [FromBody] SmartFood.DTOs.Order.CreateOrderDto dto)
        {
            if (userId <= 0)
                return BadRequest(new { message = "Invalid userId" });

            try
            {
                var result = await _orderService.CreateOrder(userId, dto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id:int}/status")]
        public IActionResult UpdateStatus(int id, [FromBody] UpdateOrderStatusDto dto)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Status))
                return BadRequest(new { message = "Status is required" });

            var ok = _orderService.UpdateOrderStatus(id, dto.Status);
            if (!ok) return BadRequest(new { message = "Invalid order or status" });
            return Ok(new { message = "Updated", id, status = dto.Status.ToLower() });
        }

        /// <summary>User hủy đơn chỉ khi đơn đang chờ xác nhận (pending); hoàn tồn kho.</summary>
        [HttpPut("{id:int}/cancel")]
        public IActionResult CancelByUser(int id, [FromQuery] int userId)
        {
            if (userId <= 0)
                return BadRequest(new { message = "Invalid userId" });

            var (ok, message) = _orderService.TryCancelOrderByUser(id, userId);
            if (!ok)
                return BadRequest(new { message });
            return Ok(new { message = "Đã hủy đơn hàng", id, status = "cancelled" });
        }

        [HttpGet("statistics/summary")]
        public IActionResult RevenueSummary([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            return Ok(_orderService.GetRevenueSummary(startDate, endDate));
        }

        [HttpGet("statistics/by-day")]
        public IActionResult RevenueByDay(
            [FromQuery] int days = 7,
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            if (startDate.HasValue && endDate.HasValue)
            {
                return Ok(_orderService.GetRevenueByDayRange(startDate.Value, endDate.Value));
            }

            if (days <= 0) days = 7;
            if (days > 60) days = 60;
            return Ok(_orderService.GetRevenueByDay(days));
        }

        [HttpGet("statistics/by-month")]
        public IActionResult RevenueByMonth([FromQuery] int year)
        {
            if (year <= 0) year = DateTime.Now.Year;
            return Ok(_orderService.GetRevenueByMonth(year));
        }

        [HttpGet("statistics/by-year")]
        public IActionResult RevenueByYear()
        {
            return Ok(_orderService.GetRevenueByYear());
        }
    }
}