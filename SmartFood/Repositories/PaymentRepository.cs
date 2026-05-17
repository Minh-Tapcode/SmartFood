using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.Models;
using System.Linq;

namespace SmartFood.Repositories
{
    public class PaymentRepository
    {
        private readonly SmartFoodContext _context;

        public PaymentRepository(SmartFoodContext context)
        {
            _context = context;
        }

        public void Create(Payment payment)
        {
            _context.Payments.Add(payment);
            _context.SaveChanges();
        }

        public Payment GetPaymentByOrderId(int orderId) =>
            _context.Payments
                .Where(x => x.OrderId == orderId)
                .OrderByDescending(x => x.Id)
                .FirstOrDefault();

        public Dictionary<int, Payment> GetLatestPaymentsByOrderIds(IEnumerable<int> orderIds)
        {
            var ids = orderIds.Distinct().ToList();
            if (ids.Count == 0) return new Dictionary<int, Payment>();

            return _context.Payments
                .AsNoTracking()
                .Where(p => ids.Contains(p.OrderId))
                .AsEnumerable()
                .GroupBy(p => p.OrderId)
                .ToDictionary(
                    g => g.Key,
                    g => g.OrderByDescending(p => p.Id).First());
        }

        public void Update(Payment payment)
        {
            _context.Payments.Update(payment);
            _context.SaveChanges();
        }
    }
}