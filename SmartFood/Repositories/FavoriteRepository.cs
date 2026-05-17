using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.Models;

public class FavoriteRepository
{
    private readonly SmartFoodContext _context;

    public FavoriteRepository(SmartFoodContext context)
    {
        _context = context;
    }

    public void Add(Favorite fav)
    {
        _context.Favorites.Add(fav);
    }

    public void Delete(Favorite fav)
    {
        _context.Favorites.Remove(fav);
    }

    public Favorite? Get(int userId, int productId)
    {
        return _context.Favorites
            .FirstOrDefault(x => x.UserId == userId && x.ProductId == productId);
    }
    public DbSet<Favorite> Favorites => _context.Favorites;

    public List<Favorite> GetByUser(int userId)
    {
        return _context.Favorites
            .Where(x => x.UserId == userId)
            .ToList();
    }

    public void Save()
    {
        _context.SaveChanges();
    }
}