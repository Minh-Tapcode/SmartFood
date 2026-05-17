using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class Order
    {
        public int Id { get; set; }
        [Column("user_id")]
        public int UserId { get; set; }
        [Column("total_price")]
        public decimal TotalPrice { get; set; }
        public string Status { get; set; } = "pending";
        public string? Address { get; set; }
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        [Column("receiver_name")]
        public string ReceiverName { get; set; }
        [Column("receiver_phone")]

        public string ReceiverPhone { get; set; }
        [Column("note")]

        public string Note { get; set; }

        [Column("shipping_fee")]
        public decimal ShippingFee { get; set; }

        [Column("discount_amount")]
        public decimal DiscountAmount { get; set; }

        [Column("promotion_id")]
        public int? PromotionId { get; set; }

        [Column("promotion_title")]
        public string? PromotionTitle { get; set; }

        // Navigation
        public User? User { get; set; }
        public ICollection<OrderItem>? OrderItems { get; set; }
        public ICollection<Payment>? Payments { get; set; }
    }
}
