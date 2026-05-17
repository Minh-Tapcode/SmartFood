using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    [Table("Messages")]
    public class Message
    {
        [Key]
        public long Id { get; set; }

        public long ChatId { get; set; }

        [MaxLength(20)]
        public string SenderType { get; set; } = "customer";

        public int? SenderUserId { get; set; }

        public string Content { get; set; } = string.Empty;

        /// <summary>JSON danh sách ChatActionDto — nút thêm giỏ từ gợi ý AI.</summary>
        public string? SuggestedActionsJson { get; set; }

        public DateTime SentAt { get; set; } = DateTime.Now;

        public Chat? Chat { get; set; }

        public User? SenderUser { get; set; }
    }
}
