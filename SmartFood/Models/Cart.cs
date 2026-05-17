using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class Cart
    {
        public int Id { get; set; }
        [Column("user_id")]
        public int UserId { get; set; }

        // Navigation
        public User? User { get; set; }
        public ICollection<CartItem>? CartItems { get; set; }
    }
}
