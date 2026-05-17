using SmartFood.Data;
using SmartFood.DTOs;
using SmartFood.DTOs.SmartFood.DTOs;
using SmartFood.Models;
using Microsoft.AspNetCore.Hosting;

public class ProductService
{
    private readonly ProductRepository _repo;
    private readonly IWebHostEnvironment _env;

    public ProductService(ProductRepository repo, IWebHostEnvironment env)
    {
        _repo = repo;
        _env = env;
    }

    // ===== MAP =====
    private ProductDto Map(Product p)
    {
        return new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            Description = p.Description,
            Price = p.Price,
            Stock = p.Stock,
            CategoryName = p.Category?.Name,
            CreatedAt = p.CreatedAt,
            ExpiryDate = p.ExpiryDate,
            Origin = p.Origin,
            Unit = p.Unit,
            ImageUrl = p.ImageUrl
        };
    }

    // ===== CRUD =====

    public List<ProductDto> GetAll()
    {
        return _repo.GetAll().Select(Map).ToList();
    }

    public ProductDto GetById(int id)
    {
        var p = _repo.GetById(id);
        return p == null ? null : Map(p);
    }

    public ProductDto Create(ProductCreateDto dto)
    {
        var product = new Product
        {
            Name = dto.Name,
            Description = dto.Description,
            Price = dto.Price,
            Stock = dto.Stock,
            CategoryId = dto.CategoryId,
            ExpiryDate = dto.ExpiryDate,
            Origin = dto.Origin,
            Unit = dto.Unit,
            CreatedAt = DateTime.Now,
            ImageUrl = null // ảnh sẽ gán bên dưới nếu có
        };

        // Lưu sản phẩm trước
        _repo.Add(product);
        _repo.Save();

        // Lưu ảnh nếu có
        if (dto.ImageFile != null)
        {
            var file = dto.ImageFile;
            var fileName = Guid.NewGuid() + Path.GetExtension(file.FileName);
            var imagesFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "images");
            if (!Directory.Exists(imagesFolder))
            {
                Directory.CreateDirectory(imagesFolder);
            }
            var path = Path.Combine(imagesFolder, fileName);

            using (var stream = new FileStream(path, FileMode.Create))
            {
                file.CopyTo(stream);
            }

            product.ImageUrl = "/images/" + fileName;
            _repo.Save();
        }

        return Map(product);
    }

    public bool Update(int id, ProductUpdateDto dto)
    {
        var p = _repo.GetById(id);
        if (p == null) return false;

        p.Name = dto.Name;
        p.Description = dto.Description;
        p.Price = dto.Price;
        p.Stock = dto.Stock;
        p.CategoryId = dto.CategoryId;
        p.ExpiryDate = dto.ExpiryDate;
        p.Origin = dto.Origin;
        p.Unit = dto.Unit;

        // Nếu cập nhật ảnh mới
        if (dto.ImageFile != null)
        {
            var file = dto.ImageFile;
            var fileName = Guid.NewGuid() + Path.GetExtension(file.FileName);
            var imagesFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "images");
            if (!Directory.Exists(imagesFolder))
            {
                Directory.CreateDirectory(imagesFolder);
            }
            var path = Path.Combine(imagesFolder, fileName);

            using (var stream = new FileStream(path, FileMode.Create))
            {
                file.CopyTo(stream);
            }

            p.ImageUrl = "/images/" + fileName;
        }

        _repo.Save();
        return true;
    }

    public ProductDto? UpdateImage(int id, IFormFile imageFile)
    {
        var p = _repo.GetById(id);
        if (p == null) return null;

        var fileName = Guid.NewGuid() + Path.GetExtension(imageFile.FileName);
        var imagesFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "images");
        if (!Directory.Exists(imagesFolder))
        {
            Directory.CreateDirectory(imagesFolder);
        }
        var path = Path.Combine(imagesFolder, fileName);

        using (var stream = new FileStream(path, FileMode.Create))
        {
            imageFile.CopyTo(stream);
        }

        p.ImageUrl = "/images/" + fileName;
        _repo.Save();
        return Map(p);
    }

    public bool Delete(int id)
    {
        var p = _repo.GetById(id);
        if (p == null) return false;

        _repo.Delete(p);
        _repo.Save();
        return true;
    }

    // ===== CATEGORY =====

    public List<ProductDto> GetByCategory(int categoryId)
    {
        return _repo.GetAll()
            .Where(p => p.CategoryId == categoryId)
            .Select(Map)
            .ToList();
    }

    // ===== SEARCH =====

    public List<ProductDto> Search(string keyword)
    {
        keyword = keyword.ToLower();

        return _repo.GetAll()
            .Where(p => p.Name.ToLower().Contains(keyword))
            .Select(Map)
            .ToList();
    }

    // ===== FILTER =====

    public List<ProductDto> Filter(decimal? min, decimal? max)
    {
        var query = _repo.GetAll().AsQueryable();

        if (min.HasValue)
            query = query.Where(p => p.Price >= min);

        if (max.HasValue)
            query = query.Where(p => p.Price <= max);

        return query.Select(Map).ToList();
    }
}