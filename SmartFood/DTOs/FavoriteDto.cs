namespace SmartFood.DTOs
{
    public class FavoriteDto
    {
        public int UserId { get; set; }
        public int ProductId { get; set; }

        public string? ProductName { get; set; }
        public decimal Price { get; set; }
        public string? Image { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}