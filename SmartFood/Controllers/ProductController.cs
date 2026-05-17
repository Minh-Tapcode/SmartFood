using Microsoft.AspNetCore.Mvc;
using SmartFood.DTOs;

[Route("api/[controller]")]
[ApiController]
public class ProductController : ControllerBase
{
    private readonly ProductService _service;

    public ProductController(ProductService service)
    {
        _service = service;
    }

    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(_service.GetAll());
    }

    [HttpGet("{id}")]
    public IActionResult Get(int id)
    {
        var p = _service.GetById(id);
        if (p == null) return NotFound();
        return Ok(p);
    }

    [HttpPost]
    public IActionResult Create([FromForm] ProductCreateDto dto)
    {
        var validationError = ValidateProductPayload(dto.Name, dto.Price, dto.Stock, dto.CategoryId);
        if (validationError != null) return BadRequest(validationError);
        validationError = ValidateExpiryDate(dto.ExpiryDate, DateTime.Today);
        if (validationError != null) return BadRequest(validationError);
        return Ok(_service.Create(dto));
    }

    [HttpPut("{id}")]
    public IActionResult Update(int id, [FromForm] ProductUpdateDto dto)
    {
        var validationError = ValidateProductPayload(dto.Name, dto.Price, dto.Stock, dto.CategoryId);
        if (validationError != null) return BadRequest(validationError);
        var existing = _service.GetById(id);
        if (existing == null) return NotFound();
        validationError = ValidateExpiryDate(dto.ExpiryDate, existing.CreatedAt.Date);
        if (validationError != null) return BadRequest(validationError);
        var result = _service.Update(id, dto);
        if (!result) return NotFound();
        return Ok("Updated");
    }

    [HttpPut("{id}/image")]
    public IActionResult UpdateImage(int id, [FromForm] ProductImageUpdateDto dto)
    {
        if (dto.ImageFile == null || dto.ImageFile.Length == 0)
        {
            return BadRequest("ImageFile is required.");
        }

        var updated = _service.UpdateImage(id, dto.ImageFile);
        if (updated == null) return NotFound();
        return Ok(updated);
    }

    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        var result = _service.Delete(id);
        if (!result) return NotFound();
        return Ok("Deleted");
    }

    [HttpGet("category/{categoryId}")]
    public IActionResult GetByCategory(int categoryId)
    {
        return Ok(_service.GetByCategory(categoryId));
    }

    [HttpGet("search")]
    public IActionResult Search(string keyword)
    {
        return Ok(_service.Search(keyword));
    }

    [HttpGet("filter")]
    public IActionResult Filter(decimal? min, decimal? max)
    {
        return Ok(_service.Filter(min, max));
    }

    private string? ValidateProductPayload(string? name, decimal price, int stock, int categoryId)
    {
        if (string.IsNullOrWhiteSpace(name)) return "Name is required.";
        if (price <= 0) return "Price must be greater than 0.";
        if (stock < 0) return "Stock cannot be negative.";
        if (categoryId <= 0) return "CategoryId is invalid.";
        return null;
    }

    private string? ValidateExpiryDate(DateTime? expiryDate, DateTime createdAtReference)
    {
        if (!expiryDate.HasValue)
            return "ExpiryDate is required.";
        if (expiryDate.Value.Date < createdAtReference.Date)
            return "Hạn sử dụng không được trước ngày tạo sản phẩm.";
        return null;
    }
}