using System.ComponentModel.DataAnnotations;

namespace SmartFood.DTOs.Category
{
    public class UpdateCategoryDto
    {
        [Required]
        public string Name { get; set; }

        public IFormFile? IconFile { get; set; }
    }
}