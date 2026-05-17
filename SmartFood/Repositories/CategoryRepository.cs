using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.Models;
using System;

namespace SmartFood.Repositories
{
    public class CategoryRepository
    {
        private readonly SmartFoodContext _context;

        public CategoryRepository(SmartFoodContext context)
        {
            _context = context;
        }

        public async Task<List<Category>> GetAll()
        {
            return await _context.Categories.ToListAsync();
        }

        public async Task<Category?> GetById(int id)
        {
            return await _context.Categories.FindAsync(id);
        }

        public async Task<Category> Create(Category category)
        {
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            return category;
        }

        public async Task<bool> Update(Category category)
        {
            _context.Categories.Update(category);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> Delete(Category category)
        {
            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<List<Category>> Search(string keyword)
        {
            keyword = keyword.ToLower();

            return await _context.Categories
                .Where(c => c.Name.ToLower().Contains(keyword))
                .ToListAsync();
        }
    }
}