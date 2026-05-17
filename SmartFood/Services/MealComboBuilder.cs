using System.Globalization;
using System.Text;
using SmartFood.DTOs.Recommendation;

namespace SmartFood.Services;

public static class MealComboBuilder
{
    private const decimal TierBudgetMax = 120_000m;
    private const decimal TierStandardMax = 220_000m;

    private static readonly (string Style, string Title, string Blurb, string[][] Slots)[] Templates =
    {
        ("healthy", "Salad rau + ức gà", "Nhiều rau, protein gọn nhẹ", new[]
        {
            new[] { "xà lách", "xa lach", "salad" },
            new[] { "ức gà", "uc ga", "thịt gà", "thit ga" }
        }),
        ("healthy", "Cá hồi + rau củ", "Omega-3, bữa tối cao cấp", new[]
        {
            new[] { "cá hồi", "ca hoi" },
            new[] { "cà rốt", "ca rot", "cà chua", "ca chua", "dưa leo", "dua leo" }
        }),
        ("nau_nhanh", "Mì trứng xúc xích", "Xong trong 15 phút", new[]
        {
            new[] { "mì", "mi ly", "mì gói", "mi goi" },
            new[] { "trứng", "trung" },
            new[] { "xúc xích", "xuc xich" }
        }),
        ("nau_nhanh", "Cơm chiên trứng", "No nhanh, đơn giản", new[]
        {
            new[] { "gạo", "gao" },
            new[] { "trứng", "trung" }
        }),
        ("com_gia_dinh", "Thịt bò xào bắp cải", "Đủ chất cho bữa chính", new[]
        {
            new[] { "thịt bò", "thit bo" },
            new[] { "bắp cải", "bap cai" }
        }),
        ("com_gia_dinh", "Canh cà rốt + thịt", "Ấm bụng, dễ nấu", new[]
        {
            new[] { "cà rốt", "ca rot" },
            new[] { "thịt heo", "thit heo", "thịt bò", "thit bo" }
        }),
        ("an_vat", "Trái cây mix", "Ăn nhẹ, giải khát", new[]
        {
            new[] { "chuối", "chuoi" },
            new[] { "cam", "táo", "tao", "xoài", "xoai" }
        }),
        ("an_vat", "Sữa + chuối", "Bổ sung năng lượng nhẹ", new[]
        {
            new[] { "sữa", "sua" },
            new[] { "chuối", "chuoi" }
        })
    };

    public static List<MealComboDto> BuildCombos(
        List<CatalogProductDto> catalog,
        HashSet<int> preferredProductIds,
        string? styleFilter = null,
        int maxCombos = 3,
        HealthyVariant? healthyVariant = null)
    {
        var candidates = new List<MealComboDto>();

        var anchor = BuildPreferredAnchorCombo(catalog, preferredProductIds, styleFilter);
        if (anchor != null) candidates.Add(anchor);

        foreach (var template in Templates)
        {
            if (styleFilter != null && !string.Equals(template.Style, styleFilter, StringComparison.OrdinalIgnoreCase))
                continue;

            var combo = TryBuildTemplate(catalog, preferredProductIds, template);
            if (combo != null) candidates.Add(combo);
        }

        candidates = candidates
            .GroupBy(c => string.Join("|", c.Items.Select(i => i.ProductId).OrderBy(x => x)))
            .Select(g => g.First())
            .ToList();

        candidates = ApplyHealthyVariantFilter(candidates, healthyVariant);

        candidates = candidates
            .OrderByDescending(c => c.HistoryMatchCount)
            .ThenBy(c => c.EstimatedTotal)
            .ToList();

        AssignDistinctTiers(candidates);

        return candidates.Take(maxCombos).ToList();
    }

    private static MealComboDto? BuildPreferredAnchorCombo(
        List<CatalogProductDto> catalog,
        HashSet<int> preferredIds,
        string? styleFilter)
    {
        var preferred = catalog.Where(p => preferredIds.Contains(p.Id)).ToList();
        if (preferred.Count < 2) return null;

        if (styleFilter != null)
        {
            var styled = preferred.Where(p => p.MealTags.Contains(styleFilter)).ToList();
            if (styled.Count >= 2) preferred = styled;
        }

        var items = preferred.Take(3).Select(p => ToItem(p)).ToList();
        var total = items.Sum(i => i.Price);

        return new MealComboDto
        {
            StyleKey = styleFilter ?? "general",
            Title = "Combo quen thuộc của bạn",
            Blurb = BlurbForStyle(styleFilter, total, fromHistory: true),
            Items = items,
            EstimatedTotal = total,
            UsesCustomerHistory = true,
            HistoryMatchCount = items.Count
        };
    }

    private static MealComboDto? TryBuildTemplate(
        List<CatalogProductDto> catalog,
        HashSet<int> preferredIds,
        (string Style, string Title, string Blurb, string[][] Slots) template)
    {
        var items = new List<MealComboItemDto>();
        var usedIds = new HashSet<int>();

        foreach (var slot in template.Slots)
        {
            var match = FindProduct(catalog, slot, preferredIds, usedIds);
            if (match == null) return null;
            usedIds.Add(match.Id);
            items.Add(ToItem(match));
        }

        var historyMatches = items.Count(i => preferredIds.Contains(i.ProductId));
        if (preferredIds.Count >= 2 && historyMatches == 0)
            return null;

        var total = items.Sum(i => i.Price);

        return new MealComboDto
        {
            StyleKey = template.Style,
            Title = template.Title,
            Blurb = template.Blurb,
            Items = items,
            EstimatedTotal = total,
            UsesCustomerHistory = historyMatches > 0,
            HistoryMatchCount = historyMatches
        };
    }

    private static void AssignDistinctTiers(List<MealComboDto> combos)
    {
        var usedTiers = new HashSet<string>();
        foreach (var c in combos)
        {
            c.TierLabel = PickTier(c.EstimatedTotal, usedTiers);
            usedTiers.Add(c.TierLabel);
        }
    }

    private static string PickTier(decimal total, HashSet<string> used)
    {
        var tier = total switch
        {
            <= TierBudgetMax => "Tiết kiệm",
            <= TierStandardMax => "Phổ thông",
            _ => "Cao cấp"
        };
        if (!used.Contains(tier)) return tier;
        if (!used.Contains("Tiết kiệm") && total <= TierStandardMax) return "Tiết kiệm";
        if (!used.Contains("Phổ thông")) return "Phổ thông";
        return "Cao cấp";
    }

    private static List<MealComboDto> ApplyHealthyVariantFilter(
        List<MealComboDto> combos,
        HealthyVariant? variant)
    {
        if (variant == null) return combos;

        return variant switch
        {
            HealthyVariant.Budget => combos.Where(c => c.EstimatedTotal <= TierBudgetMax).ToList(),
            HealthyVariant.Protein => combos.Where(c =>
                c.Title.Contains("gà", StringComparison.OrdinalIgnoreCase) ||
                c.Title.Contains("cá", StringComparison.OrdinalIgnoreCase) ||
                c.Items.Any(i => i.ProductName.Contains("gà", StringComparison.OrdinalIgnoreCase) ||
                                 i.ProductName.Contains("cá", StringComparison.OrdinalIgnoreCase))).ToList(),
            HealthyVariant.Light => combos.Where(c =>
                c.HistoryMatchCount >= 1 ||
                c.Title.Contains("rau", StringComparison.OrdinalIgnoreCase) ||
                c.Title.Contains("salad", StringComparison.OrdinalIgnoreCase)).ToList(),
            _ => combos
        };
    }

    public static HealthyVariant? DetectHealthyVariant(string message)
    {
        var t = message.ToLowerInvariant();
        if (ContainsAny(t, "tiết kiệm", "tiet kiem", "rẻ", "re ", "dưới 120", "budget"))
            return HealthyVariant.Budget;
        if (ContainsAny(t, "protein", "đạm", "dam ", "tăng cơ", "ức gà", "uc ga"))
            return HealthyVariant.Protein;
        if (ContainsAny(t, "ít dầu", "it dau", "nhẹ bụng", "rau xanh", "eat clean"))
            return HealthyVariant.Light;
        return null;
    }

    public static string? DetectStyleFromMessage(string message)
    {
        var t = message.Trim().ToLowerInvariant();
        if (ContainsAny(t, "healthy", "ăn healthy", "an healthy"))
            return "healthy";
        if (ContainsAny(t, "ít dầu", "it dau", "eat clean")) return "healthy";
        if (ContainsAny(t, "nấu nhanh", "nau nhanh", "dưới 20")) return "nau_nhanh";
        if (ContainsAny(t, "cơm gia đình", "com gia dinh", "bữa chính", "bua chinh")) return "com_gia_dinh";
        if (ContainsAny(t, "ăn vặt", "an vat", "ăn nhẹ", "an nhe", "tráng miệng", "trang mieng", "snack")) return "an_vat";
        return null;
    }

    public static string FormatMultiComboMessage(
        List<MealComboDto> combos,
        string? openingLine,
        string styleKey)
    {
        var sb = new StringBuilder();
        if (!string.IsNullOrWhiteSpace(openingLine))
            sb.AppendLine(openingLine);

        if (combos.Count == 0)
        {
            sb.AppendLine();
            sb.Append("Hiện shop chưa đủ nguyên liệu combo — bạn xem danh mục sản phẩm trên app nhé 🛒");
            return sb.ToString().Trim();
        }

        var styleEmoji = styleKey switch
        {
            "healthy" => "🥗",
            "nau_nhanh" => "⚡",
            "com_gia_dinh" => "🍱",
            "an_vat" => "🍎",
            _ => "🍽️"
        };

        sb.AppendLine();
        for (var i = 0; i < combos.Count; i++)
        {
            var c = combos[i];
            sb.AppendLine($"{styleEmoji} {c.TierLabel} · {c.Title}");
            if (!string.IsNullOrWhiteSpace(c.Blurb))
                sb.AppendLine(c.Blurb);
            foreach (var item in c.Items)
                sb.AppendLine($"  • {item.ProductName} – {item.Price:N0}đ");
            sb.AppendLine($"  Ước tính: ~{c.EstimatedTotal:N0}đ");
            if (i < combos.Count - 1) sb.AppendLine();
        }

        sb.AppendLine();
        sb.Append("Chọn nút bên dưới để thêm combo vào giỏ nhé 🛒");
        return sb.ToString().Trim();
    }

    public static string FormatVagueMealChoiceMessage()
    {
        return """
            Bạn thích kiểu nào? Mình sẽ gợi ý món phù hợp 🍽️

            🥗 Ăn healthy
            Ít dầu mỡ, nhiều rau xanh

            ⚡ Nấu nhanh
            Có món dưới 20 phút

            🍱 Cơm gia đình
            Đủ dinh dưỡng cho bữa chính

            🍎 Ăn nhẹ / tráng miệng
            Trái cây, sữa, đồ ăn vặt

            Chọn 1 kiểu ăn nhé (Healthy / Nấu nhanh / Cơm gia đình / Ăn nhẹ) 👇
            """.Trim();
    }

    public static bool IsVagueMealAsk(string message)
    {
        var t = NormalizeForMatch(message);
        if (!ContainsAny(t, "goi y", "goi mon", "an gi", "mon gi", "mua gi", "nen mua"))
            return false;
        return DetectStyleFromMessage(message) == null
               && DetectHealthyVariant(message) == null;
    }

    public static string FormatHealthySubChoiceMessage()
    {
        return """
            Bạn muốn healthy theo hướng nào?

            💰 Tiết kiệm — dưới ~120k
            💪 Nhiều đạm — ức gà, cá
            🥗 Nhẹ bụng — rau, trái cây quen thuộc

            Trả lời 1 trong 3 ý trên (vd: "tiết kiệm") nhé 👇
            """.Trim();
    }

    public static string FormatCombosForPrompt(List<MealComboDto> combos)
    {
        if (combos.Count == 0) return "(Chưa có combo)";

        var sb = new StringBuilder();
        foreach (var c in combos)
        {
            sb.AppendLine($"• [{c.TierLabel}] {c.Title} (~{c.EstimatedTotal:N0}đ)");
            foreach (var item in c.Items)
                sb.AppendLine($"  - id={item.ProductId} {item.ProductName}");
        }
        return sb.ToString().TrimEnd();
    }

    private static MealComboItemDto ToItem(CatalogProductDto p) => new()
    {
        ProductId = p.Id,
        ProductName = p.Name,
        Price = p.Price,
        Unit = p.Unit
    };

    private static string BlurbForStyle(string? style, decimal total, bool fromHistory)
    {
        if (fromHistory) return "Gồm món bạn hay đặt, dễ làm quen";

        return style switch
        {
            "healthy" => total <= TierBudgetMax ? "Ít dầu, nhẹ bụng" : "Cân bằng dinh dưỡng",
            "nau_nhanh" => "Nhanh, đỡ đói",
            "com_gia_dinh" => "Đủ bữa cho cả nhà",
            "an_vat" => "Ăn nhẹ, dễ ăn",
            _ => "Phù hợp hôm nay"
        };
    }

    private static CatalogProductDto? FindProduct(
        List<CatalogProductDto> catalog,
        string[] keywords,
        HashSet<int> preferredIds,
        HashSet<int> usedIds)
    {
        return catalog
            .Where(p => !usedIds.Contains(p.Id))
            .Where(p => keywords.Any(k => p.Name.Contains(k, StringComparison.OrdinalIgnoreCase)))
            .OrderByDescending(p => preferredIds.Contains(p.Id) ? 100 : 0)
            .ThenByDescending(p => keywords.Count(k => p.Name.Contains(k, StringComparison.OrdinalIgnoreCase)))
            .ThenBy(p => p.Price)
            .FirstOrDefault();
    }

    private static bool ContainsAny(string text, params string[] parts) =>
        parts.Any(p => text.Contains(p, StringComparison.Ordinal));

    /// <summary>
    /// Ghép combo từ SP khách nhắc tên trong tin (vd: cà chua + rau muống + cà rốt).
    /// </summary>
    public static MealComboDto? TryBuildFromMentionedProducts(
        string userMessage,
        List<CatalogProductDto> catalog,
        HashSet<int> preferredProductIds)
    {
        if (string.IsNullOrWhiteSpace(userMessage) || catalog.Count == 0) return null;

        var matched = new List<CatalogProductDto>();
        var usedIds = new HashSet<int>();

        foreach (var product in catalog.OrderByDescending(p => p.Name.Length))
        {
            if (!MessageMentionsProduct(userMessage, product.Name)) continue;
            if (!usedIds.Add(product.Id)) continue;
            matched.Add(product);
        }

        if (matched.Count < 2) return null;

        var items = matched
            .OrderByDescending(p => preferredProductIds.Contains(p.Id))
            .ThenBy(p => p.Name)
            .Take(5)
            .Select(ToItem)
            .ToList();

        var total = items.Sum(i => i.Price);
        var title = string.Join(" + ", items.Select(i => i.ProductName));

        return new MealComboDto
        {
            StyleKey = "custom",
            Title = title,
            Blurb = GetCookingTip(items),
            Items = items,
            EstimatedTotal = total,
            TierLabel = "Combo",
            UsesCustomerHistory = items.Any(i => preferredProductIds.Contains(i.ProductId)),
            HistoryMatchCount = items.Count(i => preferredProductIds.Contains(i.ProductId))
        };
    }

    public static string FormatIngredientComboMessage(MealComboDto combo, bool includeCookingTip = true)
    {
        var sb = new StringBuilder();
        if (includeCookingTip && !string.IsNullOrWhiteSpace(combo.Blurb))
        {
            sb.AppendLine(combo.Blurb);
            sb.AppendLine();
        }

        sb.AppendLine($"Combo {combo.Title}:");
        foreach (var item in combo.Items)
            sb.AppendLine($"  • {item.ProductName} – {item.Price:N0}đ");
        sb.AppendLine($"Ước tính: ~{combo.EstimatedTotal:N0}đ");
        sb.AppendLine();
        sb.Append("Bấm nút bên dưới để thêm combo vào giỏ nhé 🛒");
        return sb.ToString().Trim();
    }

    public static string FormatAddToCartHintMessage(MealComboDto combo)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"Combo {combo.Title} (~{combo.EstimatedTotal:N0}đ):");
        foreach (var item in combo.Items)
            sb.AppendLine($"  • {item.ProductName} – {item.Price:N0}đ");
        sb.AppendLine();
        sb.Append("Bấm nút bên dưới để thêm vào giỏ. Thanh toán COD hoặc VNPay khi đặt hàng nhé 🛒");
        return sb.ToString().Trim();
    }

    private static string GetCookingTip(List<MealComboItemDto> items)
    {
        var names = items.Select(i => NormalizeForMatch(i.ProductName)).ToList();
        var hasTomato = names.Any(n => n.Contains("ca chua"));
        var hasSpinach = names.Any(n => n.Contains("rau muong") || n.Contains("rau lang"));
        var hasCarrot = names.Any(n => n.Contains("ca rot"));
        var hasChicken = names.Any(n => n.Contains("ga") || n.Contains("uc ga"));
        var hasFish = names.Any(n =>
            n.Contains("ca hoi") ||
            (n.Contains("ca ") && !n.Contains("ca chua") && !n.Contains("ca rot")));

        if (hasTomato && hasSpinach && hasCarrot)
            return "Với combo này bạn có thể nấu canh chua nhẹ, xào rau hoặc salad trộn — nhanh và dễ ăn 🍲";
        if (hasTomato && hasChicken)
            return "Gợi ý: gà xào cà chua hoặc canh gà chua — bữa no, đủ đạm 🍗";
        if (hasCarrot && hasChicken)
            return "Gợi ý: cà rốt hầm với gà hoặc xào thơm — ấm bụng, dễ nấu 🥕";
        if (hasFish && hasCarrot)
            return "Gợi ý: cá hấp/kho kèm cà rốt — bữa tối gọn nhẹ 🐟";

        return "Có thể chế biến xào, nấu canh hoặc salad tùy khẩu vị — món nhà đơn giản mà ngon 🍽️";
    }

    public static bool MessageMentionsProduct(string message, string productName)
    {
        var msgTokens = TokenizeMessage(message);
        if (msgTokens.Count == 0) return false;

        var name = NormalizeForMatch(productName);
        if (string.IsNullOrWhiteSpace(name)) return false;

        // Tên đủ trong tin (chuỗi liền, vd "nuoc cam")
        var nameSpaced = $" {name} ";
        var msgSpaced = $" {string.Join(' ', msgTokens)} ";
        if (msgSpaced.Contains(nameSpaced, StringComparison.Ordinal)) return true;

        var nameTokens = name.Split(' ', StringSplitOptions.RemoveEmptyEntries)
            .Where(t => t.Length >= 2)
            .ToList();
        if (nameTokens.Count == 0) return false;

        // Mọi từ trong tên SP phải là TỪ RIÊNG trong tin — tránh "ga"/"ca" khớp trong "healthy"
        if (nameTokens.All(t => msgTokens.Contains(t))) return true;

        // Một từ đặc trưng (>= 4 ký tự) trùng khít
        if (nameTokens.Count == 1 && nameTokens[0].Length >= 4 && msgTokens.Contains(nameTokens[0]))
            return true;

        return false;
    }

    public static HashSet<string> TokenizeMessage(string message)
    {
        var normalized = NormalizeForMatch(message);
        if (string.IsNullOrWhiteSpace(normalized)) return new HashSet<string>();

        return normalized
            .Split(new[] { ' ', ',', '.', '!', '?', ';', ':', '(', ')', '+', '-', '/' },
                StringSplitOptions.RemoveEmptyEntries)
            .Where(t => t.Length >= 2)
            .ToHashSet(StringComparer.Ordinal);
    }

    public static string NormalizeForMatch(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return string.Empty;

        var normalized = text.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder(normalized.Length);
        foreach (var c in normalized)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        }

        return sb.ToString()
            .ToLowerInvariant()
            .Replace('đ', 'd')
            .Replace('Đ', 'd');
    }
}

public enum HealthyVariant
{
    Budget,
    Protein,
    Light
}
