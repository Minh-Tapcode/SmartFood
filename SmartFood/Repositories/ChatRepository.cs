using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.Models;

namespace SmartFood.Repositories
{
    public class ChatRepository
    {
        private readonly SmartFoodContext _context;

        public ChatRepository(SmartFoodContext context)
        {
            _context = context;
        }

        public Chat? GetById(long chatId)
        {
            return _context.Chats.FirstOrDefault(x => x.Id == chatId);
        }

        public List<Chat> GetByUser(int userId)
        {
            return _context.Chats
                .AsNoTracking()
                .Include(x => x.CustomerUser)
                .Where(x => x.CustomerUserId == userId || x.AgentUserId == userId)
                .OrderByDescending(x => x.UpdatedAt)
                .ToList();
        }

        public List<Chat> GetAll()
        {
            return _context.Chats
                .AsNoTracking()
                .Include(x => x.CustomerUser)
                .OrderByDescending(x => x.UpdatedAt)
                .ToList();
        }

        public Chat? GetOpenChatByCustomer(int customerUserId)
        {
            return _context.Chats
                .FirstOrDefault(x => x.CustomerUserId == customerUserId && x.Status == "open");
        }

        public void AddChat(Chat chat)
        {
            _context.Chats.Add(chat);
            _context.SaveChanges();
        }

        public void UpdateChat(Chat chat)
        {
            _context.Chats.Update(chat);
            _context.SaveChanges();
        }

        public List<Message> GetMessages(long chatId, int take = 100)
        {
            return _context.Messages
                .AsNoTracking()
                .Where(x => x.ChatId == chatId)
                .OrderByDescending(x => x.SentAt)
                .Take(take)
                .OrderBy(x => x.SentAt)
                .ToList();
        }

        public void AddMessage(Message message)
        {
            _context.Messages.Add(message);
            _context.SaveChanges();
        }

        public Message? GetLatestMessage(long chatId)
        {
            return _context.Messages
                .AsNoTracking()
                .Where(x => x.ChatId == chatId)
                .OrderByDescending(x => x.SentAt)
                .FirstOrDefault();
        }

        public Message? GetLatestCustomerMessage(long chatId)
        {
            return _context.Messages
                .AsNoTracking()
                .Where(x => x.ChatId == chatId && x.SenderType == "customer")
                .OrderByDescending(x => x.SentAt)
                .FirstOrDefault();
        }

        public Message? GetLatestAgentMessage(long chatId)
        {
            return _context.Messages
                .AsNoTracking()
                .Where(x => x.ChatId == chatId && x.SenderType == "agent")
                .OrderByDescending(x => x.SentAt)
                .FirstOrDefault();
        }
    }
}
