namespace SmartFood.DTOs.Promotion
{
    public class UpsertPromotionDto
    {
        public string Title { get; set; } = "";
        public double DiscountPercent { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
