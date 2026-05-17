namespace SmartFood.DTOs.Chat
{
    public class ChatListItemDto
    {
        public long Id { get; set; }
        public int CustomerUserId { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public int? AgentUserId { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string? LastMessage { get; set; }
        public DateTime? LastMessageAt { get; set; }
        public string? LastSenderType { get; set; }
        public DateTime? LastCustomerMessageAt { get; set; }
    }
}
