using System.ComponentModel.DataAnnotations;

namespace SmartFood.DTOs.Category
{
    public class CreateCategoryDto
    {
        [Required]
        public string Name { get; set; }
        public IFormFile? IconFile { get; set; }
    }
}