using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class Ratings
    {
        public int Id { get; set; }
        [Column("user_id")]
        public int UserId { get; set; }
        [Column("product_id")]
        public int ProductId { get; set; }
        [Column("order_id")]
        public int? OrderId { get; set; }
        [Column("so_sao")]
        public int SoSao { get; set; }
        [Column("noi_dung")]
        public string? NoiDung { get; set; }
        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [NotMapped]
        public string UserName { get; set; } = "";
    }
}
