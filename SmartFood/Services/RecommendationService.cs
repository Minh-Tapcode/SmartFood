using System.Text;
using Microsoft.EntityFrameworkCore;
using SmartFood.Data;
using SmartFood.DTOs.Recommendation;
using SmartFood.Models;

namespace SmartFood.Services;

public class RecommendationService
{
    private const int MaxPersonalized = 8;
    private const int MaxFrequentPurchases = 5;
    private const int MaxFavorites = 5;
    private const int MaxSameCategory = 4;

    private readonly SmartFoodContext _context;

    public RecommendationService(SmartFoodContext context)
    {
        _context = context;
    }

    public List<PersonalizedProductDto> GetPersonalizedForUser(int userId)
    {
        var result = new List<PersonalizedProductDto>();
        var addedIds = new HashSet<int>();

        void TryAdd(Product? product, string reason)
        {
            if (product == null || product.Stock <= 0 || addedIds.Contains(product.Id)) return;
            if (result.Count >= MaxPersonalized) return;

            addedIds.Add(product.Id);
            result.Add(new PersonalizedProductDto
            {
                ProductId = product.Id,
                Name = product.Name,
                Price = product.Price,
                Stock = product.Stock,
                ExpiryDate = product.ExpiryDate,
                Reason = reason
            });
        }

        var frequentProductIds = _context.OrderItem
            .AsNoTracking()
            .Where(oi => _context.Orders.Any(o => o.Id == oi.OrderId && o.UserId == userId))
            .GroupBy(oi => oi.ProductId)
            .Select(g => new { ProductId = g.Key, TotalQty = g.Sum(x => x.Quantity) })
            .OrderByDescending(x => x.TotalQty)
            .Take(MaxFrequentPurchases)
            .ToList();

        var frequentProducts = new List<Product>();
        foreach (var item in frequentProductIds)
        {
            var product = _context.Products.AsNoTracking().FirstOrDefault(p => p.Id == item.ProductId);
            if (product != null)
            {
                frequentProducts.Add(product);
                TryAdd(product, "hay_mua");
            }
        }

        var favoriteProductIds = _context.Favorites
            .AsNoTracking()
            .Where(f => f.UserId == userId)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => f.ProductId)
            .Take(MaxFavorites)
            .ToList();

        foreach (var productId in favoriteProductIds)
        {
            var product = _context.Products.AsNoTracking().FirstOrDefault(p => p.Id == productId);
            TryAdd(product, "yeu_thich");
        }

        var categoryIds = frequentProducts
            .Where(p => p.CategoryId.HasValue)
            .Select(p => p.CategoryId!.Value)
            .Distinct()
            .ToList();

        if (categoryIds.Count > 0 && result.Count < MaxPersonalized)
        {
            var sameCategory = _context.Products
                .AsNoTracking()
                .Where(p =>
                    p.Stock > 0 &&
                    p.CategoryId != null &&
                    categoryIds.Contains(p.CategoryId.Value) &&
                    !addedIds.Contains(p.Id))
                .OrderByDescending(p => p.Stock)
                .Take(MaxSameCategory)
                .ToList();

            foreach (var product in sameCategory)
            {
                TryAdd(product, "cung_danh_muc");
            }
        }

        return result;
    }

    public static string FormatReason(string reason) => reason switch
    {
        "hay_mua" => "bạn hay mua",
        "yeu_thich" => "trong danh sách yêu thích",
        "cung_danh_muc" => "cùng danh mục bạn hay mua",
        _ => reason
    };

    public List<CatalogProductDto> GetInStockCatalog(int take = 40)
    {
        return _context.Products
            .AsNoTracking()
            .Include(p => p.Category)
            .Where(p => p.Stock > 0)
            .OrderByDescending(p => p.Stock)
            .Take(take)
            .Select(p => new CatalogProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                Unit = string.IsNullOrWhiteSpace(p.Unit) ? "sp" : p.Unit,
                CategoryName = p.Category != null ? p.Category.Name : "Khác",
                MealTags = InferMealTags(p.Name, p.Category != null ? p.Category.Name : null)
            })
            .ToList();
    }

    public string BuildMealCatalogSection(int userId)
    {
        var sb = new StringBuilder();
        var catalog = GetInStockCatalog(60);
        var personalized = GetPersonalizedForUser(userId);

        sb.AppendLine("=== CATALOG (chỉ được gợi ý SP có tên ở đây; KHÔNG đọc tồn/HSD cho khách) ===");
        if (catalog.Count == 0)
        {
            sb.AppendLine("(Chưa có sản phẩm)");
            return sb.ToString();
        }

        foreach (var group in catalog.GroupBy(c => c.CategoryName).OrderBy(g => g.Key))
        {
            sb.AppendLine($"[{group.Key}]");
            foreach (var p in group)
            {
                var tags = p.MealTags.Length > 0 ? string.Join(", ", p.MealTags) : "general";
                sb.AppendLine($"  - {p.Name} | {p.Price:N0}đ/{p.Unit} | phong_cach: {tags}");
            }
        }

        if (personalized.Count > 0)
        {
            sb.AppendLine();
            sb.AppendLine("=== ƯU TIÊN CHO KHÁCH NÀY (đã mua / thích) ===");
            foreach (var p in personalized)
            {
                sb.AppendLine($"  - {p.Name} | {p.Price:N0}đ ({FormatReason(p.Reason)})");
            }
        }

        return sb.ToString();
    }

    public string BuildPersonalizationInsights(int userId)
    {
        var sb = new StringBuilder();
        var personalized = GetPersonalizedForUser(userId);
        var catalog = GetInStockCatalog(60);
        var preferredIds = personalized.Select(p => p.ProductId).ToHashSet();

        sb.AppendLine("=== GỢI Ý CÁ NHÂN (dùng 1–2 câu mở đầu tự nhiên, không liệt kê máy móc) ===");

        if (personalized.Count > 0)
        {
            var top = personalized.Take(3).Select(p => p.Name).ToList();
            sb.AppendLine($"Khách hay mua/thích: {string.Join(", ", top)}.");
            sb.AppendLine("Ví dụ cách nói: \"Vì bạn hay mua {0}, mình gợi ý...\" (thay {0} bằng tên SP thật).");
        }
        else
        {
            sb.AppendLine("Khách mới — chưa có lịch sử mua/thích.");
        }

        var now = DateTime.Now;
        var promos = _context.Promotions.AsNoTracking()
            .Where(p => p.StartDate <= now && p.EndDate >= now)
            .Take(2)
            .ToList();
        if (promos.Count > 0)
        {
            foreach (var pr in promos)
                sb.AppendLine($"Khuyến mãi đang chạy: {pr.Title} (giảm {pr.DiscountPercent}%) — nhắc nhẹ nếu phù hợp combo.");
        }

        var nearExpiry = _context.Products.AsNoTracking()
            .Where(p => p.Stock > 0 && p.ExpiryDate != null && p.ExpiryDate <= now.AddDays(7))
            .OrderBy(p => p.ExpiryDate)
            .Take(2)
            .Select(p => p.Name)
            .ToList();
        if (nearExpiry.Count > 0)
            sb.AppendLine($"SP tươi nên dùng sớm (nội bộ): {string.Join(", ", nearExpiry)} — chỉ nhắc nếu khách hỏi gợi ý/tiết kiệm, không nói \"HSD\".");

        return sb.ToString();
    }

    public string? GetTopPurchasedCategoryName(int userId)
    {
        var topProductId = _context.OrderItem
            .AsNoTracking()
            .Where(oi => _context.Orders.Any(o => o.Id == oi.OrderId && o.UserId == userId))
            .GroupBy(oi => oi.ProductId)
            .OrderByDescending(g => g.Sum(x => x.Quantity))
            .Select(g => g.Key)
            .FirstOrDefault();

        if (topProductId == 0) return null;

        var cat = _context.Products.AsNoTracking()
            .Include(p => p.Category)
            .Where(p => p.Id == topProductId)
            .Select(p => p.Category != null ? p.Category.Name : null)
            .FirstOrDefault();

        return cat;
    }

    /// <summary>Sản phẩm thường được mua cùng đơn với SP khách hay mua (cross-sell).</summary>
    public List<PersonalizedProductDto> GetCrossSellProducts(int userId, int take = 3)
    {
        var topPurchasedIds = _context.OrderItem
            .AsNoTracking()
            .Where(oi => _context.Orders.Any(o => o.Id == oi.OrderId && o.UserId == userId))
            .GroupBy(oi => oi.ProductId)
            .OrderByDescending(g => g.Sum(x => x.Quantity))
            .Take(3)
            .Select(g => g.Key)
            .ToList();

        if (topPurchasedIds.Count == 0)
        {
            return GetInStockCatalog(20)
                .OrderBy(_ => Guid.NewGuid())
                .Take(take)
                .Select(p => new PersonalizedProductDto
                {
                    ProductId = p.Id,
                    Name = p.Name,
                    Price = p.Price,
                    Stock = 1,
                    Reason = "goi_y_kem"
                })
                .ToList();
        }

        var orderIds = _context.OrderItem
            .AsNoTracking()
            .Where(oi => topPurchasedIds.Contains(oi.ProductId))
            .Select(oi => oi.OrderId)
            .Distinct()
            .ToList();

        var coProductIds = _context.OrderItem
            .AsNoTracking()
            .Where(oi => orderIds.Contains(oi.OrderId) && !topPurchasedIds.Contains(oi.ProductId))
            .GroupBy(oi => oi.ProductId)
            .OrderByDescending(g => g.Sum(x => x.Quantity))
            .Take(take * 2)
            .Select(g => g.Key)
            .ToList();

        var result = new List<PersonalizedProductDto>();
        foreach (var pid in coProductIds)
        {
            var p = _context.Products.AsNoTracking().FirstOrDefault(x => x.Id == pid && x.Stock > 0);
            if (p == null) continue;
            result.Add(new PersonalizedProductDto
            {
                ProductId = p.Id,
                Name = p.Name,
                Price = p.Price,
                Stock = p.Stock,
                ExpiryDate = p.ExpiryDate,
                Reason = "mua_kem"
            });
            if (result.Count >= take) break;
        }

        return result;
    }

    public string BuildCrossSellPromptSection(int userId)
    {
        var items = GetCrossSellProducts(userId, 4);
        if (items.Count == 0) return "(Không có gợi ý mua kèm)";

        var sb = new StringBuilder();
        sb.AppendLine("=== MUA KÈM (cross-sell — thường khách mua cùng đơn) ===");
        foreach (var p in items)
            sb.AppendLine($"  - {p.Name} | {p.Price:N0}đ");
        return sb.ToString();
    }

    public string BuildCombosSection(int userId, string? mealStyle, int maxCombos = 2)
    {
        var catalog = GetInStockCatalog(60);
        var preferredIds = GetPersonalizedForUser(userId).Select(p => p.ProductId).ToHashSet();
        var combos = MealComboBuilder.BuildCombos(catalog, preferredIds, mealStyle, maxCombos);
        return MealComboBuilder.FormatCombosForPrompt(combos);
    }

    private static string[] InferMealTags(string productName, string? categoryName)
    {
        var text = $"{productName} {categoryName}".ToLowerInvariant();
        var tags = new List<string>();

        if (ContainsAny(text, "salad", "xà lách", "xa lach", "ức gà", "uc ga", "cá hồi", "ca hoi", "eat clean", "organic"))
            tags.Add("healthy");
        if (ContainsAny(text, "mì", "mi ", "xúc xích", "xuc xich", "đồ hộp", "instant", "nhanh"))
            tags.Add("nau_nhanh");
        if (ContainsAny(text, "thịt", "thit", "trứng", "trung", "gạo", "gao"))
            tags.Add("com_gia_dinh");
        if (ContainsAny(text, "bánh", "banh", "snack", "sữa", "sua", "nước", "nuoc", "trái", "trai", "chuối", "chuoi"))
            tags.Add("an_vat");

        if (tags.Count == 0) tags.Add("general");
        return tags.Distinct().ToArray();
    }

    private static bool ContainsAny(string text, params string[] parts) =>
        parts.Any(p => text.Contains(p, StringComparison.Ordinal));
}
