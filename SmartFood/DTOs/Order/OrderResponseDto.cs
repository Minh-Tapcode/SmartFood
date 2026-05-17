namespace SmartFood.DTOs.Order
{
    public class OrderResponseDto
    {
        public int OrderId { get; set; }
        public decimal TotalPrice { get; set; }
        public string Status { get; set; }       // pending, paid, failed...
        public string PaymentMethod { get; set; } // COD / VNPAY
        public string? PaymentUrl { get; set; }   // chỉ VNPay mới có
    }
}