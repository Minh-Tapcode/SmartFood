using SmartFood.Models;

namespace SmartFood.DTOs
{
    namespace SmartFood.DTOs
    {
        public class ProductDto
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string? Description { get; set; }
            public decimal Price { get; set; }
            public int Stock { get; set; }

            public string? CategoryName { get; set; }
            public DateTime CreatedAt { get; set; }
            public DateTime? ExpiryDate { get; set; }
            public string Origin { get; set; }
            public string Unit { get; set; }

            public string? ImageUrl { get; set; }

        }
    }
    public class ProductCreateDto
    {
        public string Name { get; set; }
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public int CategoryId { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public string Origin { get; set; }
        public string Unit { get; set; }

        public IFormFile? ImageFile { get; set; }
    }
    public class ProductUpdateDto
    {
        public string Name { get; set; }
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public int Stock { get; set; }
        public int CategoryId { get; set; }
        public DateTime? ExpiryDate { get; set; }
        public string Origin { get; set; }
        public string Unit { get; set; }
        public IFormFile? ImageFile { get; set; }

    }

    public class ProductImageUpdateDto
    {
        public IFormFile ImageFile { get; set; }
    }

}
