using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class Product
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public int Stock { get; set; } = 0;
        [Column("category_id")]
        public int? CategoryId { get; set; }
        [Column("expiry_date")]
        public DateTime? ExpiryDate { get; set; }
        public string? Origin { get; set; }
        public string Unit { get; set; }
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // Navigation
        [Column("image_url")]
        public string? ImageUrl { get; set; }
        public Category? Category { get; set; }
        public ICollection<OrderItem>? OrderItems { get; set; }
        public ICollection<Favorite>? Favorites { get; set; }
    }
}
