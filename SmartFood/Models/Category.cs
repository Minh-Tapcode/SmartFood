using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    public class Category
    {
        public int Id { get; set; }
        [Column("name")]
        public string Name { get; set; } = null!;
        public string? Icon { get; set; } // Lưu đường dẫn ảnh

        public ICollection<Product>? Products { get; set; }
    }
}
