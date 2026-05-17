using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class Favorite
    {
        [Column("user_id")]
        public int UserId { get; set; }

        [Column("product_id")]
        public int ProductId { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // Navigation
        public User? User { get; set; }
        public Product? Product { get; set; }
    }
}
