
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Password { get; set; } = null!;
        public string? Phone { get; set; }
        [Column("role")]
        public string Role { get; set; } = "buyer";
        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // Navigation
        public Cart? Cart { get; set; }
        public ICollection<Order>? Orders { get; set; }
        public ICollection<Favorite>? Favorites { get; set; }
    }
}