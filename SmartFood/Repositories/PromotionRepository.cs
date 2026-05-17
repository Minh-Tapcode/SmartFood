using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.Models;

namespace SmartFood.Repositories
{
    public class PromotionRepository
    {
        private readonly SmartFoodContext _context;

        public PromotionRepository(SmartFoodContext context)
        {
            _context = context;
        }

        /// <summary>Chương trình đang trong khoảng thời gian hiệu lực.</summary>
        public List<Promotion> GetActive(DateTime? at = null)
        {
            var now = at ?? DateTime.Now;
            return _context.Promotions
                .AsNoTracking()
                .Where(p => p.StartDate <= now && p.EndDate >= now)
                .OrderBy(p => p.Title)
                .ToList();
        }

        public List<Promotion> GetAll()
        {
            return _context.Promotions
                .AsNoTracking()
                .OrderByDescending(p => p.StartDate)
                .ToList();
        }

        public Promotion? GetById(int id) =>
            _context.Promotions.FirstOrDefault(p => p.Id == id);

        public Promotion Create(Promotion promotion)
        {
            _context.Promotions.Add(promotion);
            _context.SaveChanges();
            return promotion;
        }

        public bool Update(Promotion promotion)
        {
            _context.Promotions.Update(promotion);
            _context.SaveChanges();
            return true;
        }

        public bool Delete(Promotion promotion)
        {
            _context.Promotions.Remove(promotion);
            _context.SaveChanges();
            return true;
        }
    }
}
