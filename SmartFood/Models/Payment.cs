using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class Payment
    {
        public int Id { get; set; }
        [Column("order_id")]
        public int OrderId { get; set; }
        public string? Method { get; set; } 
        public decimal Amount { get; set; }
        public string? Status { get; set; } 
        [Column("transaction_id")]
        public string? TransactionId { get; set; }
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // Navigation
        public Order? Order { get; set; }
    }
}
