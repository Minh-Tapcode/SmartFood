namespace SmartFood.DTOs
{
    public class RatingDto
    {
        public int UserId { get; set; }

        public int ProductId { get; set; }

        public int? OrderId { get; set; }

        public int SoSao { get; set; }

        public string? NoiDung { get; set; }
    }
}
