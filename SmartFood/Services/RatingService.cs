using SmartFood.Models;
using SmartFood.Repositories;

namespace SmartFood.Services
{
    public class RatingService
    {
        private readonly RatingRepository _repo;

        public RatingService(RatingRepository repo)
        {
            _repo = repo;
        }

        // ===== GET ALL =====
        public async Task<List<Ratings>> GetByProduct(int productId)
        {
            return await _repo.GetByProduct(productId);
        }

        public async Task<List<Ratings>> GetByProductAndStars(int productId, int stars)
        {
            if (stars < 1 || stars > 5) return new List<Ratings>();
            return await _repo.GetByProductAndStars(productId, stars);
        }

        // ===== GET STATS =====
        public async Task<object> GetStats(int productId)
        {
            return await _repo.GetStats(productId);
        }

        // ===== ADD OR UPDATE =====
        public async Task<object> AddOrUpdate(int userId, int productId, int soSao, string? noiDung, int? orderId = null)
        {
            if (soSao < 1 || soSao > 5)
            {
                return new
                {
                    success = false,
                    message = "Số sao phải từ 1 đến 5"
                };
            }
            var existing = await _repo.GetUserRating(userId, productId, orderId);

            if (existing != null)
            {
                existing.SoSao = soSao;
                existing.NoiDung = noiDung;

                await _repo.Update(existing);

                return new
                {
                    success = true,
                    message = "Cập nhật đánh giá thành công",
                    data = existing
                };
            }
            else
            {
                var rating = new Ratings
                {
                    UserId = userId,
                    ProductId = productId,
                    OrderId = (orderId.HasValue && orderId.Value > 0) ? orderId.Value : null,
                    SoSao = soSao,
                    NoiDung = noiDung,
                    CreatedAt = DateTime.Now
                };

                await _repo.Create(rating);

                return new
                {
                    success = true,
                    message = "Thêm đánh giá thành công",
                    data = rating
                };
            }
        }

        // ===== DELETE =====
        public async Task<bool> Delete(int userId, int productId, int? orderId = null)
        {
            var rating = await _repo.GetUserRating(userId, productId, orderId);

            if (rating == null) return false;

            return await _repo.Delete(rating);
        }

        public async Task<object> GetUserReviewSummary(int userId)
        {
            var items = await _repo.GetUserReviewItems(userId);
            var reviewed = items.Count(x => x.IsReviewed);
            var unreviewed = items.Count - reviewed;
            return new
            {
                reviewed,
                unreviewed,
                total = items.Count,
                items
            };
        }

        public async Task<bool> HasRatedOrder(int userId, int orderId)
        {
            return await _repo.HasUserRatedOrder(userId, orderId);
        }
    }
}