using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.DTOs.Rating;
using SmartFood.Models;

namespace SmartFood.Repositories
{
    public class RatingRepository
    {
        private readonly SmartFoodContext _context;

        public RatingRepository(SmartFoodContext context)
        {
            _context = context;
        }

        // ===== GET ALL BY PRODUCT =====
        public async Task<List<Ratings>> GetByProduct(int productId)
        {
            return await (
                from r in _context.Ratings
                join u in _context.Users on r.UserId equals u.Id
                where r.ProductId == productId
                orderby r.CreatedAt descending
                select new Ratings
                {
                    Id = r.Id,
                    UserId = r.UserId,
                    ProductId = r.ProductId,
                    OrderId = r.OrderId,
                    SoSao = r.SoSao,
                    NoiDung = r.NoiDung,
                    CreatedAt = r.CreatedAt,
                    UserName = u.Name
                }
            ).ToListAsync();
        }

        public async Task<List<Ratings>> GetByProductAndStars(int productId, int stars)
        {
            return await (
                from r in _context.Ratings
                join u in _context.Users on r.UserId equals u.Id
                where r.ProductId == productId && r.SoSao == stars
                orderby r.CreatedAt descending
                select new Ratings
                {
                    Id = r.Id,
                    UserId = r.UserId,
                    ProductId = r.ProductId,
                    OrderId = r.OrderId,
                    SoSao = r.SoSao,
                    NoiDung = r.NoiDung,
                    CreatedAt = r.CreatedAt,
                    UserName = u.Name
                }
            ).ToListAsync();
        }

        // ===== GET USER RATING =====
        public async Task<Ratings?> GetUserRating(int userId, int productId, int? orderId = null)
        {
            var query = _context.Ratings
                .Where(r => r.UserId == userId && r.ProductId == productId);
            if (orderId.HasValue && orderId.Value > 0)
            {
                query = query.Where(r => r.OrderId == orderId.Value);
            }
            return await query
                .OrderByDescending(r => r.CreatedAt)
                .FirstOrDefaultAsync();
        }

        // ===== CREATE =====
        public async Task<Ratings> Create(Ratings rating)
        {
            _context.Ratings.Add(rating);
            await _context.SaveChangesAsync();
            return rating;
        }

        // ===== UPDATE =====
        public async Task<bool> Update(Ratings rating)
        {
            _context.Ratings.Update(rating);
            await _context.SaveChangesAsync();
            return true;
        }

        // ===== DELETE =====
        public async Task<bool> Delete(Ratings rating)
        {
            _context.Ratings.Remove(rating);
            await _context.SaveChangesAsync();
            return true;
        }

        // ===== STATS =====
        public async Task<object> GetStats(int productId)
        {
            var ratings = await _context.Ratings
                .Where(r => r.ProductId == productId)
                .ToListAsync();

            var total = ratings.Count;

            var avg = total == 0 ? 0 : ratings.Average(r => r.SoSao);

            return new
            {
                total,
                average = avg,
                fiveStar = ratings.Count(r => r.SoSao == 5),
                fourStar = ratings.Count(r => r.SoSao == 4),
                threeStar = ratings.Count(r => r.SoSao == 3),
                twoStar = ratings.Count(r => r.SoSao == 2),
                oneStar = ratings.Count(r => r.SoSao == 1),
            };
        }

        public async Task<List<UserReviewItemDto>> GetUserReviewItems(int userId)
        {
            var completedStatuses = new[] { "completed", "delivered" };

            var rows = await (
                from o in _context.Orders
                join oi in _context.OrderItem on o.Id equals oi.OrderId
                join p in _context.Products on oi.ProductId equals p.Id
                join r in _context.Ratings.Where(x => x.UserId == userId)
                    on new { ProductId = p.Id, OrderId = o.Id }
                    equals new { ProductId = r.ProductId, OrderId = r.OrderId ?? 0 } into ratingGroup
                from r in ratingGroup.DefaultIfEmpty()
                where o.UserId == userId && completedStatuses.Contains((o.Status ?? "").ToLower())
                select new UserReviewItemDto
                {
                    OrderId = o.Id,
                    ProductId = p.Id,
                    ProductName = p.Name,
                    ProductImage = p.ImageUrl,
                    IsReviewed = r != null,
                    SoSao = r != null ? r.SoSao : null,
                    NoiDung = r != null ? r.NoiDung : null,
                    RatedAt = r != null ? r.CreatedAt : null
                }
            ).ToListAsync();

            return rows
                .OrderByDescending(x => x.IsReviewed)
                .ThenByDescending(x => x.RatedAt ?? DateTime.MinValue)
                .ToList();
        }

        public async Task<bool> HasUserRatedOrder(int userId, int orderId)
        {
            if (orderId <= 0) return false;
            return await _context.Ratings.AnyAsync(r =>
                r.UserId == userId && r.OrderId == orderId);
        }
    }
}