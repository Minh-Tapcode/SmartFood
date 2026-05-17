using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    [Table("OrderItems")]
    public class OrderItem
    {
        public int Id { get; set; }
        [Column("order_id")]
        public int OrderId { get; set; }
        [Column("product_id")]
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public decimal Price { get; set; }

        // Navigation
        public Order? Order { get; set; }
        public Product? Product { get; set; }
    }
}
