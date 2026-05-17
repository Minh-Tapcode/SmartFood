using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using SmartFood.DTOs.Chat;
using SmartFood.Hubs;
using SmartFood.Services;
using System.Security.Claims;

namespace SmartFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ChatController : ControllerBase
    {
        private readonly ChatService _chatService;
        private readonly CartService _cartService;
        private readonly IHubContext<ChatHub> _hubContext;

        public ChatController(ChatService chatService, CartService cartService, IHubContext<ChatHub> hubContext)
        {
            _chatService = chatService;
            _cartService = cartService;
            _hubContext = hubContext;
        }

        [HttpPost("threads")]
        public IActionResult CreateOrGetThread([FromBody] CreateChatDto dto)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
            var chat = _chatService.CreateOrGetOpenChat(userId, dto);
            return Ok(chat);
        }

        [HttpGet("threads")]
        public IActionResult GetMyThreads()
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
            var chats = _chatService.GetMyChats(userId);
            return Ok(chats);
        }

        [HttpGet("threads/all")]
        public IActionResult GetAllThreads()
        {
            var chats = _chatService.GetAllChats();
            return Ok(chats);
        }

        [HttpGet("threads/{chatId:long}/messages")]
        public IActionResult GetMessages(long chatId, [FromQuery] int take = 100)
        {
            if (take <= 0) take = 100;
            if (take > 200) take = 200;

            var messages = _chatService.GetMessages(chatId, take);
            return Ok(messages);
        }

        [HttpPost("threads/{chatId:long}/messages")]
        public async Task<IActionResult> SendMessage(long chatId, [FromBody] SendMessageDto dto)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
            var result = await _chatService.SendMessageAsync(chatId, userId, dto.Content, HttpContext.RequestAborted);

            var groupName = ChatHub.GetGroupName(chatId);
            await _hubContext.Clients.Group(groupName).SendAsync("chat:new-message", result.userMessage);

            if (result.botMessage != null)
            {
                await _hubContext.Clients.Group(groupName).SendAsync("chat:new-message", result.botMessage);
            }

            return Ok(new
            {
                sent = result.userMessage,
                bot = result.botMessage,
                actions = result.botMessage?.Actions
            });
        }

        [HttpPost("add-to-cart")]
        public IActionResult AddSuggestedToCart([FromBody] AddChatToCartDto dto)
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
            if (dto.Products == null || dto.Products.Count == 0)
                return BadRequest(new { message = "Không có sản phẩm để thêm" });

            try
            {
                var count = _chatService.AddSuggestedProductsToCart(userId, dto, _cartService);
                return Ok(new { message = $"Đã thêm {count} sản phẩm vào giỏ", count });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
