namespace SmartFood.Services;

public enum ChatIntent
{
    General,
    ProductSearch,
    MealRecommendation,
    OrderStatus,
    Promotion
}

public static class ChatIntentHelper
{
    private static readonly string[] MealKeywords =
    {
        "gợi ý", "goi y", "gợi ý món", "mon gi", "món gì", "ăn gì", "an gi", "combo",
        "healthy", "nấu nhanh", "nau nhanh", "cơm gia đình", "com gia dinh", "ăn vặt", "an vat",
        "bữa tối", "bua toi", "bữa trưa", "hôm nay ăn", "hom nay an", "mua gì", "nên mua gì"
    };

    private static readonly string[] ProductSearchKeywords =
    {
        "có ", "con ", "ban co", "bán ", "mua ", "giá ", "gia ", "còn hàng", "con hang", "tồn", "hsd", "hạn dùng",
        "nuoc", "nước", "khác không", "khac khong", "loại nào", "loai nao", "còn gì", "con gi",
        "tìm ", "tim ", "kiếm ", "kiem ", "bao nhiêu", "bao nhieu", "còn bán", "con ban"
    };

    private static readonly string[] OrderKeywords =
    {
        "đơn hàng", "don hang", "đơn #", "don #", "trạng thái đơn", "giao hàng", "giao hang", "ship", "mua lại", "mua lai"
    };

    private static readonly string[] PromotionKeywords =
    {
        "voucher", "giảm giá", "giam gia", "khuyến mãi", "khuyen mai", "promotion", "ưu đãi"
    };

    private static readonly string[] MealStyleKeywords =
    {
        "healthy", "ăn healthy", "an healthy", "ít dầu", "it dau", "eat clean",
        "tiết kiệm", "tiet kiem", "protein", "đạm", "dam ", "nhẹ bụng", "nhe bung",
        "nấu nhanh", "nau nhanh", "nhanh", "cơm gia đình", "com gia dinh", "gia đình",
        "ăn vặt", "an vat", "ăn nhẹ", "an nhe", "tráng miệng", "trang mieng", "snack"
    };

    public static ChatIntent Detect(string userMessage, IReadOnlyList<(string Role, string Content)>? history = null)
    {
        var text = Normalize(userMessage);
        if (string.IsNullOrWhiteSpace(text)) return ChatIntent.General;

        if (ContainsAny(text, PromotionKeywords)) return ChatIntent.Promotion;
        if (ContainsAny(text, OrderKeywords)) return ChatIntent.OrderStatus;
        if (ContainsAny(text, MealKeywords) || ContainsAny(text, MealStyleKeywords))
            return ChatIntent.MealRecommendation;
        if (ContainsAny(text, ProductSearchKeywords)) return ChatIntent.ProductSearch;

        if (history != null)
        {
            var botAskedStyle = history.Any(h =>
                h.Role == "assistant" &&
                ContainsAny(Normalize(h.Content ?? ""), "healthy", "nấu nhanh", "cơm gia đình", "ăn vặt", "bạn muốn ăn"));
            if (botAskedStyle && ContainsAny(text, MealStyleKeywords))
                return ChatIntent.MealRecommendation;
        }

        return ChatIntent.General;
    }

    public static bool HasChosenMealStyle(string userMessage) =>
        ContainsAny(Normalize(userMessage), MealStyleKeywords);

    public static bool BotAskedMealStyle(IReadOnlyList<(string Role, string Content)>? history)
    {
        if (history == null) return false;
        return history.Any(h =>
            h.Role == "assistant" &&
            ContainsAny(Normalize(h.Content), "healthy", "nấu nhanh", "cơm gia đình", "ăn vặt"));
    }

    private static string Normalize(string s) => s.Trim().ToLowerInvariant();

    private static bool ContainsAny(string text, params string[] keywords) =>
        keywords.Any(k => text.Contains(k, StringComparison.Ordinal));
}
