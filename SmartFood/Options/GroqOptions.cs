namespace SmartFood.Options;

public class GroqOptions
{
    public const string SectionName = "Groq";

    public string ApiKey { get; set; } = string.Empty;
    public string Model { get; set; } = "llama-3.1-8b-instant";
    public int MaxTokens { get; set; } = 700;
    public int HistoryMessageCount { get; set; } = 12;
}
