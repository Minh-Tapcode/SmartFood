namespace SmartFood.DTOs.Recommendation;

public class PersonalizedProductDto
{
    public int ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public DateTime? ExpiryDate { get; set; }
    /// <summary>Ví dụ: hay_mua, yeu_thich, cung_danh_muc</summary>
    public string Reason { get; set; } = string.Empty;
}
