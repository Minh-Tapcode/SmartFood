namespace SmartFood.DTOs.Chat;

public class ChatActionDto
{
    public string Type { get; set; } = "add_to_cart";
    public string Label { get; set; } = "Thêm vào giỏ";
    public List<ChatActionProductDto> Products { get; set; } = new();
}

public class ChatActionProductDto
{
    public int ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public int Quantity { get; set; } = 1;
}
