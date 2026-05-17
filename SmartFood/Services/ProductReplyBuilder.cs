using System.Text;
using SmartFood.DTOs.Recommendation;

namespace SmartFood.Services;

/// <summary>
/// Trả lời tìm/mua SP chỉ từ catalog thật — tránh LLM bịa tên hoặc cách dùng sai.
/// </summary>
public static class ProductReplyBuilder
{
    private static readonly string[] DrinkKeywords = { "nuoc", "nước", "drink", "uong", "uống", "sinh to", "sinh tố", "tra ", "trà " };
    private static readonly string[] AlternativeAskKeywords =
    {
        "khac khong", "khác không", "con gi", "còn gì", "loai nao", "loại nào",
        "ngoai ra", "nào khác", "nao khac", "co gi khac", "có gì khác", "them loai"
    };

    public static bool IsProductOrDrinkQuery(string userMessage)
    {
        var t = MealComboBuilder.NormalizeForMatch(userMessage);
        if (string.IsNullOrWhiteSpace(t)) return false;

        if (IsAlternativeAsk(t)) return true;
        if (ContainsAny(t, DrinkKeywords)) return true;
        if (ContainsAny(t, "mua ", "ban ", "bán ", "co ", "có ", "gia ", "giá ", "con hang", "còn hàng",
                "tim ", "tìm ", "kiem ", "kiếm ", "bao nhieu", "bao nhiêu", "con ban", "còn bán"))
            return true;

        return false;
    }

    public static bool IsAlternativeAsk(string normalizedMessage) =>
        AlternativeAskKeywords.Any(k => normalizedMessage.Contains(k, StringComparison.Ordinal));

    public static string? DetectSearchConcept(string userMessage, IReadOnlyList<(string Role, string Content)>? history)
    {
        var texts = new List<string> { userMessage };
        if (history != null)
        {
            foreach (var (role, content) in history.TakeLast(6).Reverse())
            {
                if (!string.IsNullOrWhiteSpace(content))
                    texts.Add(content);
            }
        }

        foreach (var text in texts)
        {
            var t = MealComboBuilder.NormalizeForMatch(text);
            if (ContainsAny(t, DrinkKeywords)) return "drink";
        }

        var msgNorm = MealComboBuilder.NormalizeForMatch(userMessage);
        if (ContainsAny(msgNorm, "mua ", "ban ", "co ", "gia ")) return "general";
        return null;
    }

    public static List<CatalogProductDto> FilterByConcept(List<CatalogProductDto> catalog, string concept)
    {
        return concept switch
        {
            "drink" => catalog
                .Where(IsDrinkProduct)
                .OrderBy(p => p.Name)
                .ToList(),
            _ => catalog.OrderBy(p => p.Name).ToList()
        };
    }

    public static List<CatalogProductDto> MatchByMessage(List<CatalogProductDto> catalog, string userMessage)
    {
        return catalog
            .Where(p => MealComboBuilder.MessageMentionsProduct(userMessage, p.Name))
            .OrderBy(p => p.Name)
            .ToList();
    }

    public static string GetUsageHint(CatalogProductDto product)
    {
        var text = MealComboBuilder.NormalizeForMatch($"{product.Name} {product.CategoryName}");

        if (ContainsAny(text, "nuoc cam", "nước cam"))
            return "Uống trực tiếp, giải khát";
        if (ContainsAny(text, "nuoc ", "nước ", "tra ", "trà ", "cafe", "cà phê"))
            return "Uống trực tiếp";
        if (ContainsAny(text, "sua ", "sữa "))
            return "Uống hoặc pha sinh tố";
        if (ContainsAny(text, "trai cay", "trái cây", "chuoi", "chuối", "tao ", "táo ", "cam ", "xoai", "xoài"))
            return "Ăn trực tiếp hoặc làm sinh tố";
        if (ContainsAny(text, "rau ", "cai ", "cải ", "xa lach", "xà lách", "rau muong", "rau muống"))
            return "Rửa sạch, luộc/xào/nấu canh";
        if (ContainsAny(text, "thit ", "thịt ", "ga ", "gà ", "bo ", "bò ", "heo", "lợn"))
            return "Chế biến nấu ăn (xào, kho, nướng...)";
        if (ContainsAny(text, "ca hoi", "cá hồi", "ca ", "cá "))
            return "Nấu ăn (hấp, kho, nướng...)";
        if (ContainsAny(text, "mi ", "mì ", "gao", "gạo"))
            return "Nấu ăn";

        return "Dùng theo nhu cầu";
    }

    public static string FormatProductLine(CatalogProductDto p) =>
        $"{GetEmoji(p)} {p.Name} – {p.Price:N0}đ/{p.Unit}";

    public static string FormatSingleProductReply(CatalogProductDto p, bool askToBuy = true)
    {
        var sb = new StringBuilder();
        sb.AppendLine(FormatProductLine(p));
        sb.AppendLine($"Cách dùng: {GetUsageHint(p)}");
        if (askToBuy)
            sb.Append("Bạn có muốn thêm vào giỏ không? 🛒");
        return sb.ToString().Trim();
    }

    public static string FormatProductListReply(
        IReadOnlyList<CatalogProductDto> products,
        bool isAlternativeAsk,
        string? conceptLabel = null)
    {
        var sb = new StringBuilder();

        if (products.Count == 0)
        {
            sb.Append("Xin lỗi bạn nhé 🙏 Shop hiện chưa có loại bạn hỏi. Bạn xem thêm danh mục trên app nhé.");
            return sb.ToString().Trim();
        }

        if (isAlternativeAsk && products.Count == 1)
        {
            sb.AppendLine("Xin lỗi bạn nhé 🙏 Hiện shop chỉ còn loại này thôi:");
            sb.AppendLine();
            sb.AppendLine(FormatProductLine(products[0]));
            sb.AppendLine($"Cách dùng: {GetUsageHint(products[0])}");
            sb.Append("Bạn có muốn thêm vào giỏ không? 🛒");
            return sb.ToString().Trim();
        }

        var label = conceptLabel ?? "sản phẩm";
        if (isAlternativeAsk)
            sb.AppendLine($"Shop đang có các loại {label} sau:");
        else
            sb.AppendLine($"Shop đang có {products.Count} loại {label}:");
        sb.AppendLine();

        foreach (var p in products)
        {
            sb.AppendLine(FormatProductLine(p));
            sb.AppendLine($"  Cách dùng: {GetUsageHint(p)}");
        }

        sb.AppendLine();
        sb.Append("Bạn muốn chọn loại nào? Có thể bấm nút thêm giỏ bên dưới nếu có 🛒");
        return sb.ToString().Trim();
    }

    private static bool IsDrinkProduct(CatalogProductDto p)
    {
        var text = MealComboBuilder.NormalizeForMatch($"{p.Name} {p.CategoryName}");
        return ContainsAny(text, "nuoc", "nước", "drink", "tra ", "trà ", "cafe", "cà phê", "sinh to");
    }

    private static string GetEmoji(CatalogProductDto p)
    {
        var t = MealComboBuilder.NormalizeForMatch(p.Name);
        if (t.Contains("cam")) return "🍊";
        if (t.Contains("nuoc") || t.Contains("nước")) return "🥤";
        if (t.Contains("sua")) return "🥛";
        if (t.Contains("tra")) return "🍵";
        return "🛒";
    }

    private static bool ContainsAny(string text, params string[] parts) =>
        parts.Any(p => text.Contains(p, StringComparison.Ordinal));
}
