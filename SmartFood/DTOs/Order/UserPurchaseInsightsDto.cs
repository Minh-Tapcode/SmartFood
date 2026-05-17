namespace SmartFood.DTOs.Order;

public class UserPurchaseInsightsDto
{
    public int TotalOrders { get; set; }
    public decimal TotalSpent { get; set; }
    public DateTime? LastOrderAt { get; set; }
    public List<TopProductInsightDto> TopProducts { get; set; } = new();
    public List<OrderListItemDto> Orders { get; set; } = new();
}

public class TopProductInsightDto
{
    public string Name { get; set; } = string.Empty;
    public int Quantity { get; set; }
}
