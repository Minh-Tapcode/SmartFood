namespace SmartFood.DTOs.Chat
{
    public class MessageDto
    {
        public long Id { get; set; }
        public long ChatId { get; set; }
        public string SenderType { get; set; } = string.Empty;
        public int? SenderUserId { get; set; }
        public string Content { get; set; } = string.Empty;
        public DateTime SentAt { get; set; }
        public List<ChatActionDto>? Actions { get; set; }
    }
}
