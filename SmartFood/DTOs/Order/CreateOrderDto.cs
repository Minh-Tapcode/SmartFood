namespace SmartFood.DTOs.Order
{
    public class CreateOrderDto
    {
        public string Address { get; set; }
        public string ReceiverName { get; set; }
        public string ReceiverPhone { get; set; }
        public string Note { get; set; }
        public string PaymentMethod { get; set; }
        public decimal ShippingFee { get; set; } = 15000m;
        public decimal DiscountAmount { get; set; } = 0m;
        public decimal? FinalAmount { get; set; }

        public int? PromotionId { get; set; }

        public List<int>? CartItemIds { get; set; }
    }
}