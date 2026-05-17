using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class CartItem
    {
        public int Id { get; set; }
        [Column("cart_id")]
        public int CartId { get; set; }
        [Column("product_id")]
        public int ProductId { get; set; }
        public int Quantity { get; set; }

        // Navigation
        public Cart? Cart { get; set; }
        public Product? Product { get; set; }
    }
}
