using Microsoft.EntityFrameworkCore;
using SmartFood.DTOs;
using SmartFood.Models;

public class FavoriteService
{
    private readonly FavoriteRepository _repo;

    public FavoriteService(FavoriteRepository repo)
    {
        _repo = repo;
    }

    // ===== TOGGLE =====
    public string Toggle(int userId, int productId)
    {
        var existing = _repo.Get(userId, productId);

        if (existing != null)
        {
            _repo.Delete(existing);
            _repo.Save();
            return "Unliked";
        }

        var fav = new Favorite
        {
            UserId = userId,
            ProductId = productId
        };

        _repo.Add(fav);
        _repo.Save();

        return "Liked";
    }

    // ===== GET FAVORITES (CHUẨN - CÓ IMAGE) =====
    public async Task<List<FavoriteDto>> GetByUser(int userId)
    {
        return await _repo.Favorites
            .Where(f => f.UserId == userId)
            .Include(f => f.Product)
            .Select(f => new FavoriteDto
            {
                UserId = f.UserId,
                ProductId = f.ProductId,
                ProductName = f.Product!.Name,
                Price = f.Product.Price,
                CreatedAt = f.CreatedAt
            })
            .ToListAsync();
    }

    // ===== CHECK =====
    public bool IsFavorite(int userId, int productId)
    {
        return _repo.Get(userId, productId) != null;
    }
}