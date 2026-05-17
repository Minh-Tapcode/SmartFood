using Microsoft.AspNetCore.Mvc;
using SmartFood.DTOs.Promotion;
using SmartFood.Models;
using SmartFood.Repositories;

namespace SmartFood.Controllers
{
    [ApiController]
    [Route("api/promotions")]
    public class PromotionsController : ControllerBase
    {
        private readonly PromotionRepository _repo;
        private readonly OrderRepository _orderRepo;

        public PromotionsController(PromotionRepository repo, OrderRepository orderRepo)
        {
            _repo = repo;
            _orderRepo = orderRepo;
        }

        [HttpGet]
        public IActionResult GetActive()
        {
            var list = _repo.GetActive();
            return Ok(list.Select(p => new
            {
                id = p.Id,
                title = p.Title,
                discountPercent = p.DiscountPercent,
                startDate = p.StartDate,
                endDate = p.EndDate
            }));
        }

        /// <summary>Danh sách promotionId user đã dùng (theo đơn hàng trên server).</summary>
        [HttpGet("used")]
        public IActionResult GetUsedByUser([FromQuery] int userId)
        {
            if (userId <= 0)
                return BadRequest(new { message = "userId is required" });

            var ids = _orderRepo.GetUsedPromotionIdsForUser(userId);
            return Ok(new { promotionIds = ids });
        }

        [HttpGet("all")]
        public IActionResult GetAll()
        {
            var list = _repo.GetAll();
            return Ok(list.Select(ToResponse));
        }

        [HttpPost]
        public IActionResult Create([FromBody] UpsertPromotionDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Title))
                return BadRequest(new { message = "Title is required" });
            if (dto.DiscountPercent <= 0 || dto.DiscountPercent > 100)
                return BadRequest(new { message = "DiscountPercent phải trong khoảng 0-100" });
            if (dto.EndDate < dto.StartDate)
                return BadRequest(new { message = "EndDate phải lớn hơn StartDate" });
            var discountPercent = (int)Math.Round(dto.DiscountPercent, MidpointRounding.AwayFromZero);

            var created = _repo.Create(new Promotion
            {
                Title = dto.Title.Trim(),
                DiscountPercent = discountPercent,
                StartDate = dto.StartDate,
                EndDate = dto.EndDate
            });
            return Ok(ToResponse(created));
        }

        [HttpPut("{id:int}")]
        public IActionResult Update(int id, [FromBody] UpsertPromotionDto dto)
        {
            var existing = _repo.GetById(id);
            if (existing == null) return NotFound();

            if (string.IsNullOrWhiteSpace(dto.Title))
                return BadRequest(new { message = "Title is required" });
            if (dto.DiscountPercent <= 0 || dto.DiscountPercent > 100)
                return BadRequest(new { message = "DiscountPercent phải trong khoảng 0-100" });
            if (dto.EndDate < dto.StartDate)
                return BadRequest(new { message = "EndDate phải lớn hơn StartDate" });
            var discountPercent = (int)Math.Round(dto.DiscountPercent, MidpointRounding.AwayFromZero);

            existing.Title = dto.Title.Trim();
            existing.DiscountPercent = discountPercent;
            existing.StartDate = dto.StartDate;
            existing.EndDate = dto.EndDate;
            _repo.Update(existing);
            return Ok(ToResponse(existing));
        }

        [HttpDelete("{id:int}")]
        public IActionResult Delete(int id)
        {
            var existing = _repo.GetById(id);
            if (existing == null) return NotFound();
            _repo.Delete(existing);
            return Ok(new { success = true, id });
        }

        private static object ToResponse(Promotion p) => new
        {
            id = p.Id,
            title = p.Title,
            discountPercent = p.DiscountPercent,
            startDate = p.StartDate,
            endDate = p.EndDate,
            isActive = p.StartDate <= DateTime.Now && p.EndDate >= DateTime.Now
        };
    }
}
