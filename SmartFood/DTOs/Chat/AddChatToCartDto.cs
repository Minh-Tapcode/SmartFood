namespace SmartFood.DTOs.Chat;

public class AddChatToCartDto
{
    public List<ChatActionProductDto> Products { get; set; } = new();
}
