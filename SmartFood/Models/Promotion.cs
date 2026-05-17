using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    [Table("Promotions")]
    public class Promotion
    {
        public int Id { get; set; }

        public string Title { get; set; } = null!;

        [Column("discount_percent")]
        public int DiscountPercent { get; set; }

        [Column("start_date")]
        public DateTime StartDate { get; set; }

        [Column("end_date")]
        public DateTime EndDate { get; set; }
    }
}
