using Microsoft.AspNetCore.Mvc;
using SmartFood.Services;

namespace SmartFood.Controllers
{
    [ApiController]
    [Route("api/ratings")]
    public class RatingController : ControllerBase
    {
        private readonly RatingService _service;

        public RatingController(RatingService service)
        {
            _service = service;
        }

        // ===== GET LIST =====
        [HttpGet("{productId}")]
        public async Task<IActionResult> GetRatings(int productId, [FromQuery] int? stars)
        {
            var data = stars.HasValue
                ? await _service.GetByProductAndStars(productId, stars.Value)
                : await _service.GetByProduct(productId);
            return Ok(data);
        }

        // ===== GET STATS =====
        [HttpGet("stats/{productId}")]
        public async Task<IActionResult> GetStats(int productId)
        {
            var data = await _service.GetStats(productId);
            return Ok(data);
        }

        // ===== ADD / UPDATE =====
        [HttpPost]
        public async Task<IActionResult> AddOrUpdate(
            int userId,
            int productId,
            int soSao,
            string? noiDung,
            int? orderId)
        {
            var result = await _service.AddOrUpdate(userId, productId, soSao, noiDung, orderId);
            return Ok(result);
        }

        // ===== DELETE =====
        [HttpDelete]
        public async Task<IActionResult> Delete(int userId, int productId, int? orderId)
        {
            var result = await _service.Delete(userId, productId, orderId);
            return Ok(result);
        }

        [HttpGet("user/{userId}/summary")]
        public async Task<IActionResult> GetUserSummary(int userId)
        {
            var result = await _service.GetUserReviewSummary(userId);
            return Ok(result);
        }

        [HttpGet("check-order")]
        public async Task<IActionResult> CheckOrderReviewed(int userId, int orderId)
        {
            var reviewed = await _service.HasRatedOrder(userId, orderId);
            return Ok(new { reviewed });
        }
    }
}