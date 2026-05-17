namespace SmartFood.DTOs.Rating
{
    public class UserReviewItemDto
    {
        public int OrderId { get; set; }
        public int ProductId { get; set; }
        public string ProductName { get; set; } = "";
        public string? ProductImage { get; set; }
        public bool IsReviewed { get; set; }
        public int? SoSao { get; set; }
        public string? NoiDung { get; set; }
        public DateTime? RatedAt { get; set; }
    }
}
