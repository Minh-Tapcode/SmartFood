using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.Models;
using System.Collections.Generic;
using System.Linq;

public class ProductRepository
{
    private readonly SmartFoodContext _context;

    public ProductRepository(SmartFoodContext context)
    {
        _context = context;
    }

    // Lấy tất cả sản phẩm
    public List<Product> GetAll()
    {
        return _context.Products
            .Include(p => p.Category) 
            .ToList(); 
    }

    // Lấy sản phẩm theo id
    public Product GetById(int id)
    {
        return _context.Products
            .Include(p => p.Category)
            .FirstOrDefault(p => p.Id == id);
    }

    // Thêm sản phẩm
    public void Add(Product product)
    {
        _context.Products.Add(product);
    }

    // Xóa sản phẩm
    public void Delete(Product product)
    {
        _context.Products.Remove(product);
    }

    // Lưu thay đổi
    public void Save()
    {
        _context.SaveChanges();
    }
}