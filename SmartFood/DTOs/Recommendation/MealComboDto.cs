namespace SmartFood.DTOs.Recommendation;

public class MealComboDto
{
    public string StyleKey { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string TierLabel { get; set; } = string.Empty;
    public string Blurb { get; set; } = string.Empty;
    public List<MealComboItemDto> Items { get; set; } = new();
    public decimal EstimatedTotal { get; set; }
    public bool UsesCustomerHistory { get; set; }
    public int HistoryMatchCount { get; set; }
}

public class MealComboItemDto
{
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Unit { get; set; } = "sp";
    public string Role { get; set; } = string.Empty;
}
