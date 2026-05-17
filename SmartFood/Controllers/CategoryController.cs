using Microsoft.AspNetCore.Mvc;
using SmartFood.DTOs.Category;
using SmartFood.Services;

namespace SmartFood.Controllers
{
        [Route("api/[controller]")]
        [ApiController]
        public class CategoryController : ControllerBase
        {
            private readonly CategoryService _service;

            public CategoryController(CategoryService service)
            {
                _service = service;
            }

            // ===== GET ALL =====
            [HttpGet]
            public async Task<IActionResult> GetAll()
            {
                return Ok(await _service.GetAll());
            }

            // ===== GET BY ID =====
            [HttpGet("{id}")]
            public async Task<IActionResult> Get(int id)
            {
                var data = await _service.GetById(id);
                if (data == null) return NotFound();
                return Ok(data);
            }

            // ===== CREATE =====
            [HttpPost]
            public async Task<IActionResult> Create([FromForm] CreateCategoryDto dto)
            {
                return Ok(await _service.Create(dto));
            }

            // ===== UPDATE =====
            [HttpPut("{id}")]
            public async Task<IActionResult> Update(int id,[FromForm] UpdateCategoryDto dto)
            {
                var result = await _service.Update(id, dto);
                if (!result) return NotFound();
                return Ok("Updated");
            }

            // ===== DELETE =====
            [HttpDelete("{id}")]
            public async Task<IActionResult> Delete(int id)
            {
                var result = await _service.Delete(id);
                if (!result) return NotFound();
                return Ok("Deleted");
            }

            // ===== SEARCH =====
            [HttpGet("search")]
            public async Task<IActionResult> Search(string keyword)
            {
                return Ok(await _service.Search(keyword));
            }
        }
}
