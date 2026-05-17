namespace SmartFood.DTOs
{
    public class RatingStatsDto
    {
        public int Total { get; set; }

        public double Average { get; set; }

        public int FiveStar { get; set; }

        public int FourStar { get; set; }

        public int ThreeStar { get; set; }

        public int TwoStar { get; set; }

        public int OneStar { get; set; }
    }
}
