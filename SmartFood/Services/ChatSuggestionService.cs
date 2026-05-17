using System.Text.Json;
using SmartFood.DTOs.Chat;
using SmartFood.DTOs.Recommendation;

namespace SmartFood.Services;

public class ChatSuggestionService
{
    private readonly RecommendationService _recommendation;

    public ChatSuggestionService(RecommendationService recommendation)
    {
        _recommendation = recommendation;
    }

    public MealComboDto? TryResolveComboFromMessage(
        int userId,
        string userMessage,
        IReadOnlyList<(string Role, string Content)>? history = null,
        bool allowHistoryFallback = false)
    {
        if (MealComboBuilder.DetectStyleFromMessage(userMessage) != null)
            return null;

        if (ChatIntentHelper.Detect(userMessage, history) == ChatIntent.MealRecommendation
            && !ContainsAny(MealComboBuilder.NormalizeForMatch(userMessage), "combo"))
            return null;

        var catalog = _recommendation.GetInStockCatalog(100);
        var preferredIds = _recommendation.GetPersonalizedForUser(userId).Select(p => p.ProductId).ToHashSet();

        var combo = MealComboBuilder.TryBuildFromMentionedProducts(userMessage, catalog, preferredIds);
        if (combo != null) return combo;

        if (!allowHistoryFallback || history == null) return null;

        var normalized = MealComboBuilder.NormalizeForMatch(userMessage);
        if (!IsAddToCartIntent(normalized) && !ContainsAny(normalized, "combo"))
            return null;

        foreach (var (role, content) in history.Reverse())
        {
            if (!string.Equals(role, "user", StringComparison.OrdinalIgnoreCase)) continue;
            combo = MealComboBuilder.TryBuildFromMentionedProducts(content ?? "", catalog, preferredIds);
            if (combo != null) return combo;
        }

        return null;
    }

    public StructuredMealReply? TryBuildProductSearchReply(
        int userId,
        string userMessage,
        IReadOnlyList<(string Role, string Content)>? history = null)
    {
        if (!ProductReplyBuilder.IsProductOrDrinkQuery(userMessage))
        {
            var norm = MealComboBuilder.NormalizeForMatch(userMessage);
            if (!ProductReplyBuilder.IsAlternativeAsk(norm)) return null;
        }

        var catalog = _recommendation.GetInStockCatalog(100);
        if (catalog.Count == 0) return null;

        var normalized = MealComboBuilder.NormalizeForMatch(userMessage);
        var isAltAsk = ProductReplyBuilder.IsAlternativeAsk(normalized);
        var concept = ProductReplyBuilder.DetectSearchConcept(userMessage, history) ?? "general";

        List<CatalogProductDto> products;
        if (isAltAsk)
        {
            products = ProductReplyBuilder.FilterByConcept(catalog, concept);
        }
        else
        {
            products = ProductReplyBuilder.MatchByMessage(catalog, userMessage);
            if (products.Count == 0 && concept == "drink")
                products = ProductReplyBuilder.FilterByConcept(catalog, "drink");
        }

        if (products.Count == 0)
        {
            return new StructuredMealReply(
                "Xin lỗi bạn nhé 🙏 Shop hiện chưa có loại bạn hỏi. Bạn xem thêm danh mục trên app nhé.",
                []);
        }

        string reply;
        List<ChatActionDto> actions;

        if (products.Count == 1)
        {
            reply = ProductReplyBuilder.FormatSingleProductReply(products[0]);
            actions = new List<ChatActionDto> { BuildSingleProductAction(products[0]) };
        }
        else
        {
            var label = concept == "drink" ? "nước/uống" : "sản phẩm";
            reply = ProductReplyBuilder.FormatProductListReply(products, isAltAsk, label);
            actions = isAltAsk && products.Count == 1
                ? new List<ChatActionDto> { BuildSingleProductAction(products[0]) }
                : products.Select(BuildSingleProductAction).Take(3).ToList();
        }

        return new StructuredMealReply(reply, actions);
    }

    private static ChatActionDto BuildSingleProductAction(CatalogProductDto p) => new()
    {
        Type = "add_to_cart",
        Label = $"Thêm {p.Name} ({p.Price:N0}đ)",
        Products = new List<ChatActionProductDto>
        {
            new() { ProductId = p.Id, Name = p.Name, Quantity = 1 }
        }
    };

    public StructuredMealReply? TryBuildIngredientComboReply(
        int userId,
        string userMessage,
        IReadOnlyList<(string Role, string Content)>? history = null)
    {
        if (MealComboBuilder.DetectStyleFromMessage(userMessage) != null)
            return null;

        var combo = TryResolveComboFromMessage(userId, userMessage, history, allowHistoryFallback: true);
        if (combo == null) return null;

        var normalized = MealComboBuilder.NormalizeForMatch(userMessage);
        var isCartAsk = IsAddToCartIntent(normalized);
        var isCookingAsk = ContainsAny(normalized,
            "nau mon", "mon gi", "che bien", "lam mon", "nau gi", "an gi");

        if (isCartAsk && !isCookingAsk && !MentionsIngredientsInMessage(userMessage, combo))
        {
            return new StructuredMealReply(
                MealComboBuilder.FormatAddToCartHintMessage(combo),
                new List<ChatActionDto> { BuildComboAction(combo) });
        }

        if (!isCookingAsk && !ContainsAny(normalized, "combo") && !MentionsIngredientsInMessage(userMessage, combo))
            return null;

        return new StructuredMealReply(
            MealComboBuilder.FormatIngredientComboMessage(combo, includeCookingTip: isCookingAsk || ContainsAny(normalized, "combo")),
            new List<ChatActionDto> { BuildComboAction(combo) });
    }

    public StructuredMealReply? TryBuildVagueMealChoiceReply(string userMessage)
    {
        if (!MealComboBuilder.IsVagueMealAsk(userMessage)) return null;
        return new StructuredMealReply(MealComboBuilder.FormatVagueMealChoiceMessage(), []);
    }

    public StructuredMealReply? TryBuildStructuredMealReply(int userId, string userMessage)
    {
        var mealStyle = MealComboBuilder.DetectStyleFromMessage(userMessage);
        if (mealStyle == null && MealComboBuilder.DetectHealthyVariant(userMessage) != null)
            mealStyle = "healthy";
        if (mealStyle == null) return null;

        if (mealStyle == "healthy" && MealComboBuilder.DetectHealthyVariant(userMessage) == null)
        {
            return new StructuredMealReply(
                MealComboBuilder.FormatHealthySubChoiceMessage(),
                []);
        }

        var catalog = _recommendation.GetInStockCatalog(100);
        var preferredIds = _recommendation.GetPersonalizedForUser(userId).Select(p => p.ProductId).ToHashSet();
        var variant = mealStyle == "healthy" ? MealComboBuilder.DetectHealthyVariant(userMessage) : null;

        var combos = MealComboBuilder.BuildCombos(catalog, preferredIds, mealStyle, maxCombos: 3, healthyVariant: variant);
        if (combos.Count == 0) return null;

        var opening = GetPersonalizedOpeningLine(userId, mealStyle);
        var reply = MealComboBuilder.FormatMultiComboMessage(combos, opening, mealStyle);
        var actions = combos.Select(BuildComboAction).ToList();

        return new StructuredMealReply(reply, actions);
    }

    public List<ChatActionDto> BuildActions(
        int userId,
        string userMessage,
        MealComboDto? lockedCombo = null,
        IReadOnlyList<(string Role, string Content)>? history = null)
    {
        // LLM fallback: không đoán combo từ tin/history — tránh nút giỏ lệch với nội dung bot
        if (lockedCombo != null)
            return new List<ChatActionDto> { BuildComboAction(lockedCombo) };

        if (MealComboBuilder.DetectStyleFromMessage(userMessage) != null)
            return new List<ChatActionDto>();

        if (ChatIntentHelper.Detect(userMessage, history) == ChatIntent.MealRecommendation)
            return new List<ChatActionDto>();

        var crossSell = _recommendation.GetCrossSellProducts(userId, 3);
        if (crossSell.Count == 0) return new List<ChatActionDto>();

        return new List<ChatActionDto>
        {
            new()
            {
                Type = "add_to_cart",
                Label = "Thêm gợi ý mua kèm vào giỏ",
                Products = crossSell.Select(p => new ChatActionProductDto
                {
                    ProductId = p.ProductId,
                    Name = p.Name,
                    Quantity = 1
                }).ToList()
            }
        };
    }

    private static bool IsAddToCartIntent(string normalizedMessage) =>
        ContainsAny(normalizedMessage,
            "them vao gio", "cho vao gio", "mua combo", "dat combo",
            "them gio", "add cart", "them vao gio hang");

    private static bool MentionsIngredientsInMessage(string userMessage, MealComboDto combo) =>
        combo.Items.Any(i => MealComboBuilder.MessageMentionsProduct(userMessage, i.ProductName));

    private static ChatActionDto BuildComboAction(MealComboDto combo)
    {
        var tier = string.IsNullOrWhiteSpace(combo.TierLabel) ? "Combo" : combo.TierLabel;
        return new()
        {
            Type = "add_to_cart",
            Label = $"Thêm {tier} (~{combo.EstimatedTotal:N0}đ)",
            Products = combo.Items
                .Where(i => i.ProductId > 0)
                .Select(i => new ChatActionProductDto
                {
                    ProductId = i.ProductId,
                    Name = i.ProductName,
                    Quantity = 1
                })
                .ToList()
        };
    }

    public string? GetPersonalizedOpeningLine(int userId, string mealStyle)
    {
        var category = _recommendation.GetTopPurchasedCategoryName(userId);
        var styleLabel = mealStyle switch
        {
            "healthy" => "healthy",
            "nau_nhanh" => "nấu nhanh",
            "com_gia_dinh" => "cơm gia đình",
            "an_vat" => "ăn nhẹ",
            _ => "phù hợp"
        };

        if (!string.IsNullOrEmpty(category))
            return $"Dựa trên thói quen mua {category.ToLower()} của bạn, vài combo {styleLabel}:";

        var hasHistory = _recommendation.GetPersonalizedForUser(userId).Count > 0;
        if (hasHistory)
            return $"Dựa trên các món bạn thường mua, vài combo {styleLabel}:";

        return $"Một vài combo {styleLabel} hôm nay:";
    }

    private static bool IsGenericHealthyOnly(string message)
    {
        var t = message.ToLowerInvariant().Trim();
        return ContainsAny(t, "healthy", "ăn healthy", "an healthy", "ít dầu", "it dau")
               && !ContainsAny(t, "tiết kiệm", "protein", "đạm", "nhẹ bụng", "rau");
    }

    private static bool ContainsAny(string text, params string[] parts) =>
        parts.Any(p => text.Contains(p, StringComparison.Ordinal));

    public static string? SerializeActions(List<ChatActionDto> actions) =>
        actions.Count == 0 ? null : JsonSerializer.Serialize(actions);

    public static List<ChatActionDto>? DeserializeActions(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return null;
        try
        {
            return JsonSerializer.Deserialize<List<ChatActionDto>>(json,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        }
        catch
        {
            return null;
        }
    }
}

public record StructuredMealReply(string Reply, List<ChatActionDto> Actions);
