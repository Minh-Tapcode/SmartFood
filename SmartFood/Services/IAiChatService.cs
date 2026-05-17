namespace SmartFood.Services;

public interface IAiChatService
{
    Task<string> GetSupportReplyAsync(
        int customerUserId,
        string userMessage,
        IReadOnlyList<(string Role, string Content)> conversationHistory,
        CancellationToken cancellationToken = default);
}
