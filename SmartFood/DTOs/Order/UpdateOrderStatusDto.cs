using System.ComponentModel.DataAnnotations;

namespace SmartFood.DTOs.Order
{
    public class UpdateOrderStatusDto
    {
        [Required]
        public string Status { get; set; } = "";
    }
}
