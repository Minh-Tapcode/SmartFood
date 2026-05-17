using SmartFood.DTOs.Chat;
using SmartFood.Models;
using SmartFood.Repositories;

namespace SmartFood.Services
{
    public class ChatService
    {
        /// <summary>
        /// Sau khoảng này không có tin nhân viên, trợ lý AI trả lời lại (dù chat đã gán agent).
        /// </summary>
        private static readonly TimeSpan AgentInactiveBeforeBotResumes = TimeSpan.FromMinutes(30);

        private readonly ChatRepository _repo;
        private readonly IAiChatService _aiChat;
        private readonly ChatSuggestionService _suggestions;
        private readonly Microsoft.Extensions.Options.IOptions<Options.GroqOptions> _groqOptions;

        public ChatService(
            ChatRepository repo,
            IAiChatService aiChat,
            ChatSuggestionService suggestions,
            Microsoft.Extensions.Options.IOptions<Options.GroqOptions> groqOptions)
        {
            _repo = repo;
            _aiChat = aiChat;
            _suggestions = suggestions;
            _groqOptions = groqOptions;
        }

        public ChatListItemDto CreateOrGetOpenChat(int currentUserId, CreateChatDto dto)
        {
            var customerUserId = dto.CustomerUserId ?? currentUserId;
            var existing = _repo.GetOpenChatByCustomer(customerUserId);
            if (existing != null)
            {
                return MapChat(existing);
            }

            var chat = new Chat
            {
                CustomerUserId = customerUserId,
                AgentUserId = dto.AgentUserId,
                Status = "open",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _repo.AddChat(chat);
            return MapChat(chat);
        }

        public List<ChatListItemDto> GetMyChats(int userId)
        {
            var chats = _repo.GetByUser(userId);
            return BuildChatList(chats);
        }

        public List<ChatListItemDto> GetAllChats()
        {
            var chats = _repo.GetAll();
            return BuildChatList(chats);
        }

        private List<ChatListItemDto> BuildChatList(List<Chat> chats)
        {
            var result = new List<ChatListItemDto>();

            foreach (var chat in chats)
            {
                var dto = MapChat(chat);
                var latest = _repo.GetLatestMessage(chat.Id);
                var latestCustomer = _repo.GetLatestCustomerMessage(chat.Id);
                dto.LastMessage = latest?.Content;
                dto.LastMessageAt = latest?.SentAt;
                dto.LastSenderType = latest?.SenderType;
                dto.LastCustomerMessageAt = latestCustomer?.SentAt;
                result.Add(dto);
            }

            return result;
        }

        public List<MessageDto> GetMessages(long chatId, int take = 100)
        {
            var messages = _repo.GetMessages(chatId, take);
            return messages.Select(MapMessage).ToList();
        }

        public async Task<(MessageDto userMessage, MessageDto? botMessage)> SendMessageAsync(
            long chatId,
            int senderUserId,
            string content,
            CancellationToken cancellationToken = default)
        {
            var chat = _repo.GetById(chatId) ?? throw new Exception("Chat not found");

            if (string.IsNullOrWhiteSpace(content))
            {
                throw new Exception("Message content is required");
            }

            var senderType = ResolveSenderType(chat, senderUserId);
            if (senderType == null)
            {
                throw new Exception("You are not a participant of this chat");
            }

            var trimmed = content.Trim();

            var message = new Message
            {
                ChatId = chatId,
                SenderType = senderType,
                SenderUserId = senderUserId,
                Content = trimmed,
                SentAt = DateTime.Now
            };
            _repo.AddMessage(message);

            chat.UpdatedAt = DateTime.Now;
            _repo.UpdateChat(chat);

            MessageDto? botDto = null;
            if (senderType == "customer" && ShouldBotReply(chat))
            {
                botDto = await TryGenerateBotReplyAsync(chat, trimmed, cancellationToken);
            }

            return (MapMessage(message), botDto);
        }

        private bool ShouldBotReply(Chat chat)
        {
            if (chat.AgentUserId == null) return true;

            var lastAgent = _repo.GetLatestAgentMessage(chat.Id);
            if (lastAgent == null) return true;

            return DateTime.Now - lastAgent.SentAt >= AgentInactiveBeforeBotResumes;
        }

        private async Task<MessageDto?> TryGenerateBotReplyAsync(
            Chat chat,
            string userMessage,
            CancellationToken cancellationToken)
        {
            try
            {
                List<ChatActionDto> actions;
                string reply;
                var history = BuildAiHistory(chat.Id, excludeLatestCustomerMessage: userMessage);

                var structuredMeal = _suggestions.TryBuildStructuredMealReply(chat.CustomerUserId, userMessage)
                    ?? _suggestions.TryBuildVagueMealChoiceReply(userMessage);
                if (structuredMeal != null)
                {
                    reply = structuredMeal.Reply;
                    actions = structuredMeal.Actions;
                }
                else
                {
                    var productSearch = MealComboBuilder.DetectStyleFromMessage(userMessage) == null
                        ? _suggestions.TryBuildProductSearchReply(chat.CustomerUserId, userMessage, history)
                        : null;
                    if (productSearch != null)
                    {
                        reply = productSearch.Reply;
                        actions = productSearch.Actions;
                    }
                    else
                    {
                        var ingredientCombo = _suggestions.TryBuildIngredientComboReply(
                            chat.CustomerUserId, userMessage, history);
                        if (ingredientCombo != null)
                        {
                            reply = ingredientCombo.Reply;
                            actions = ingredientCombo.Actions;
                        }
                        else
                        {
                            reply = await _aiChat.GetSupportReplyAsync(
                                chat.CustomerUserId,
                                userMessage,
                                history,
                                cancellationToken);
                            actions = _suggestions.BuildActions(chat.CustomerUserId, userMessage, history: history);
                        }
                    }
                }

                var actionsJson = actions.Count > 0
                    ? ChatSuggestionService.SerializeActions(actions)
                    : null;

                var botMessage = new Message
                {
                    ChatId = chat.Id,
                    SenderType = "bot",
                    SenderUserId = null,
                    Content = reply,
                    SuggestedActionsJson = actionsJson,
                    SentAt = DateTime.Now
                };
                _repo.AddMessage(botMessage);

                chat.UpdatedAt = DateTime.Now;
                _repo.UpdateChat(chat);

                return MapMessage(botMessage);
            }
            catch (Exception ex)
            {
                var fallback = _groqOptions.Value.ApiKey.StartsWith("YOUR_", StringComparison.OrdinalIgnoreCase)
                    ? "Trợ lý AI chưa được cấu hình API key. Vui lòng liên hệ nhân viên."
                    : $"Trợ lý AI tạm lỗi: {ex.Message}. Vui lòng thử lại hoặc chờ nhân viên.";

                var botMessage = new Message
                {
                    ChatId = chat.Id,
                    SenderType = "bot",
                    SenderUserId = null,
                    Content = fallback.Length > 500 ? fallback[..500] : fallback,
                    SentAt = DateTime.Now
                };
                _repo.AddMessage(botMessage);
                chat.UpdatedAt = DateTime.Now;
                _repo.UpdateChat(chat);
                return MapMessage(botMessage);
            }
        }

        private List<(string Role, string Content)> BuildAiHistory(
            long chatId,
            string? excludeLatestCustomerMessage = null)
        {
            var take = Math.Clamp(_groqOptions.Value.HistoryMessageCount, 2, 30);
            var messages = _repo.GetMessages(chatId, take);
            if (!string.IsNullOrEmpty(excludeLatestCustomerMessage) && messages.Count > 0)
            {
                var last = messages[^1];
                if (last.SenderType == "customer" &&
                    string.Equals(last.Content, excludeLatestCustomerMessage, StringComparison.Ordinal))
                {
                    messages = messages.Take(messages.Count - 1).ToList();
                }
            }

            var result = new List<(string Role, string Content)>();

            foreach (var m in messages)
            {
                var role = m.SenderType switch
                {
                    "customer" => "user",
                    "bot" => "assistant",
                    "agent" => "assistant",
                    _ => "user"
                };
                var content = m.SenderType == "agent"
                    ? $"[Nhân viên]: {m.Content}"
                    : m.Content;
                result.Add((role, content));
            }

            return result;
        }

        private string? ResolveSenderType(Chat chat, int senderUserId)
        {
            if (chat.CustomerUserId == senderUserId) return "customer";
            if (chat.AgentUserId == senderUserId) return "agent";
            if (chat.AgentUserId == null)
            {
                chat.AgentUserId = senderUserId;
                chat.UpdatedAt = DateTime.Now;
                _repo.UpdateChat(chat);
                return "agent";
            }
            return null;
        }

        private static ChatListItemDto MapChat(Chat chat)
        {
            return new ChatListItemDto
            {
                Id = chat.Id,
                CustomerUserId = chat.CustomerUserId,
                CustomerName = chat.CustomerUser?.Name ?? $"Khach {chat.CustomerUserId}",
                AgentUserId = chat.AgentUserId,
                Status = chat.Status,
                CreatedAt = chat.CreatedAt,
                UpdatedAt = chat.UpdatedAt
            };
        }

        private static MessageDto MapMessage(Message message)
        {
            return new MessageDto
            {
                Id = message.Id,
                ChatId = message.ChatId,
                SenderType = message.SenderType,
                SenderUserId = message.SenderUserId,
                Content = message.Content,
                SentAt = message.SentAt,
                Actions = ChatSuggestionService.DeserializeActions(message.SuggestedActionsJson)
            };
        }

        public int AddSuggestedProductsToCart(int userId, AddChatToCartDto dto, CartService cartService)
        {
            var pairs = dto.Products
                .Where(p => p.ProductId > 0 && p.Quantity > 0)
                .Select(p => (p.ProductId, p.Quantity));
            return cartService.AddMultipleToCart(userId, pairs);
        }
    }
}
