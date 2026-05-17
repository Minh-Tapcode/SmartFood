using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartFood.Models
{
    [Table("Chats")]
    public class Chat
    {
        [Key]
        public long Id { get; set; }

        public int CustomerUserId { get; set; }

        public int? AgentUserId { get; set; }

        [MaxLength(20)]
        public string Status { get; set; } = "open";

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        public User? CustomerUser { get; set; }

        public User? AgentUser { get; set; }

        public ICollection<Message>? Messages { get; set; }
    }
}
