using SmartFood.Repositories;
using SmartFood.DTOs.Category;
using SmartFood.Models;
using Microsoft.AspNetCore.Hosting;

namespace SmartFood.Services
{
    public class CategoryService
    {
        private readonly CategoryRepository _repo;
        private readonly IWebHostEnvironment _env;

        public CategoryService(CategoryRepository repo, IWebHostEnvironment env)
        {
            _repo = repo;
            _env = env;
        }

        // ===== MAP =====
        private CategoryResponseDto Map(Category c)
        {
            return new CategoryResponseDto
            {
                Id = c.Id,
                Name = c.Name,
                Icon = c.Icon!=null // 🔥 thêm
                     ? $"https://localhost:7145{c.Icon}"
                       : null

            };
        }

        // ===== CRUD =====

        public async Task<List<CategoryResponseDto>> GetAll()
        {
            var list = await _repo.GetAll();
            return list.Select(Map).ToList();
        }

        public async Task<CategoryResponseDto?> GetById(int id)
        {
            var c = await _repo.GetById(id);
            return c == null ? null : Map(c);
        }

        public async Task<CategoryResponseDto> Create(CreateCategoryDto dto)
        {
            string? iconPath = null;

            if (dto.IconFile != null)
            {
                var fileName = Guid.NewGuid() + Path.GetExtension(dto.IconFile.FileName);

                // 🔥 lưu vào wwwroot/icon
                var folder = Path.Combine(_env.WebRootPath, "icon");

                if (!Directory.Exists(folder))
                    Directory.CreateDirectory(folder);

                var filePath = Path.Combine(folder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.IconFile.CopyToAsync(stream);
                }

                iconPath = "/icon/" + fileName;
            }

            var category = new Category
            {
                Name = dto.Name,
                Icon = iconPath // 🔥 thêm
            };

            var result = await _repo.Create(category);
            return Map(result);
        }

        public async Task<bool> Update(int id, UpdateCategoryDto dto)
        {
            var category = await _repo.GetById(id);
            if (category == null) return false;

            category.Name = dto.Name;

            if (dto.IconFile != null)
            {
                var fileName = Guid.NewGuid() + Path.GetExtension(dto.IconFile.FileName);

                var folder = Path.Combine(_env.WebRootPath, "icon");

                if (!Directory.Exists(folder))
                    Directory.CreateDirectory(folder);

                var filePath = Path.Combine(folder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.IconFile.CopyToAsync(stream);
                }

                category.Icon = "/icon/" + fileName; // 🔥 update icon
            }

            return await _repo.Update(category);
        }

        public async Task<bool> Delete(int id)
        {
            var category = await _repo.GetById(id);
            if (category == null) return false;

            return await _repo.Delete(category);
        }

        // ===== SEARCH =====

        public async Task<List<CategoryResponseDto>> Search(string keyword)
        {
            var list = await _repo.Search(keyword);
            return list.Select(Map).ToList();
        }
    }
}