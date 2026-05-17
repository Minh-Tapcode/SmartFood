using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SmartFood.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        public Task JoinChat(long chatId)
        {
            return Groups.AddToGroupAsync(Context.ConnectionId, GetGroupName(chatId));
        }

        public Task LeaveChat(long chatId)
        {
            return Groups.RemoveFromGroupAsync(Context.ConnectionId, GetGroupName(chatId));
        }

        public static string GetGroupName(long chatId) => $"chat-{chatId}";
    }
}
