namespace SmartFood.DTOs.Order
{
    public class OrderListItemDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public decimal TotalPrice { get; set; }
        public string Status { get; set; } = "";
        public string? Address { get; set; }
        public DateTime CreatedAt { get; set; }
        public string ReceiverName { get; set; } = "";
        public string ReceiverPhone { get; set; } = "";
        public string? Note { get; set; }

        public string? PaymentMethod { get; set; }
        public string PaymentStatus { get; set; } = "unpaid";

        public decimal ShippingFee { get; set; }
        public decimal DiscountAmount { get; set; }
        public int? PromotionId { get; set; }
        public string? PromotionTitle { get; set; }
    }
}
