using System.Net.Http.Headers;

using System.Text;

using System.Text.Json;

using Microsoft.Extensions.Options;

using SmartFood.Options;

using SmartFood.Repositories;



namespace SmartFood.Services;



public class GroqChatService : IAiChatService

{

    private const string ChatCompletionsUrl = "https://api.groq.com/openai/v1/chat/completions";



    private readonly HttpClient _httpClient;

    private readonly GroqOptions _options;

    private readonly OrderRepository _orderRepo;

    private readonly RecommendationService _recommendationService;



    public GroqChatService(

        HttpClient httpClient,

        IOptions<GroqOptions> options,

        ProductRepository productRepo,

        OrderRepository orderRepo,

        RecommendationService recommendationService)

    {

        _httpClient = httpClient;

        _options = options.Value;

        _orderRepo = orderRepo;

        _recommendationService = recommendationService;

    }



    public async Task<string> GetSupportReplyAsync(

        int customerUserId,

        string userMessage,

        IReadOnlyList<(string Role, string Content)> conversationHistory,

        CancellationToken cancellationToken = default)

    {

        if (string.IsNullOrWhiteSpace(_options.ApiKey) ||

            _options.ApiKey.StartsWith("YOUR_", StringComparison.OrdinalIgnoreCase))

        {

            return "Trợ lý AI chưa được cấu hình. Vui lòng liên hệ nhân viên hỗ trợ.";

        }



        var intent = ChatIntentHelper.Detect(userMessage, conversationHistory);

        var systemPrompt = BuildSystemPrompt(customerUserId, intent, userMessage, conversationHistory);

        var messages = new List<object>

        {

            new { role = "system", content = systemPrompt }

        };



        foreach (var (role, content) in conversationHistory)

        {

            if (string.IsNullOrWhiteSpace(content)) continue;

            messages.Add(new { role, content });

        }



        messages.Add(new { role = "user", content = userMessage.Trim() });



        var payload = new

        {

            model = _options.Model,

            messages,

            max_tokens = _options.MaxTokens,

            temperature = intent switch
            {
                ChatIntent.MealRecommendation => 0.55,
                ChatIntent.ProductSearch => 0.2,
                _ => 0.35
            }

        };



        using var request = new HttpRequestMessage(HttpMethod.Post, ChatCompletionsUrl);

        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);

        request.Content = new StringContent(

            JsonSerializer.Serialize(payload),

            Encoding.UTF8,

            "application/json");



        using var response = await _httpClient.SendAsync(request, cancellationToken);

        var body = await response.Content.ReadAsStringAsync(cancellationToken);



        if (!response.IsSuccessStatusCode)

        {

            throw new Exception($"Groq error ({(int)response.StatusCode}): {body}");

        }



        using var doc = JsonDocument.Parse(body);

        var reply = doc.RootElement

            .GetProperty("choices")[0]

            .GetProperty("message")

            .GetProperty("content")

            .GetString();



        return string.IsNullOrWhiteSpace(reply)

            ? "Xin lỗi, tôi chưa trả lời được. Bạn có thể thử hỏi lại hoặc chờ nhân viên hỗ trợ."

            : reply.Trim();

    }



    private string BuildSystemPrompt(

        int customerUserId,

        ChatIntent intent,

        string userMessage,

        IReadOnlyList<(string Role, string Content)> history)

    {

        var sb = new StringBuilder();

        sb.AppendLine(

            """

            Bạn là trợ lý mua sắm thực phẩm SmartFood — thân thiện, tư vấn như người bán hàng am hiểu ẩm thực.

            Trả lời tiếng Việt. Dùng emoji nhẹ (1–2/đoạn) khi gợi ý món.

            

            QUY TẮC BẮT BUỘC:

            - KHÔNG hiển thị "tồn", "HSD", "stock" cho khách trừ khi họ hỏi "còn hàng không" / "hạn dùng".

            - Format sản phẩm cho khách: "🍊 Tên – 12.000đ/kg" + một dòng cách dùng ngắn (đúng loại SP).

            - Chỉ nhắc sản phẩm CÓ TÊN trong CATALOG bên dưới. TUYỆT ĐỐI không bịa tên/giá (vd: không tự thêm "nước sương", "nước mận" nếu không có trong catalog).
            - Nước uống/đồ uống: cách dùng là "uống trực tiếp" — KHÔNG viết "nấu ăn" cho nước cam, nước đóng chai...
            - Khách hỏi "có loại khác không" mà catalog chỉ có 1 SP → xin lỗi: "Hiện shop chỉ còn ... thôi".
            - KHÔNG tự viết dòng "Bạn hay mua..." / "Vì bạn hay mua..." — hệ thống đã xử lý riêng.
            - Nếu có block COMBO GỢI Ý SẴN: chỉ được mô tả đúng combo đó, không đổi tên món/SP.

            - Ngắn gọn: ưu tiên 3–6 câu; gợi ý món có thể dài hơn một chút nếu là combo.

            - Khi gợi ý combo có giá từ CATALOG: nhắc khách bấm nút "Thêm combo" bên dưới tin nhắn (nếu có).
            - Không bịa combo/giá — chỉ mô tả SP có trong CATALOG hoặc block COMBO GỢI Ý SẴN.

            """);



        sb.AppendLine();

        sb.AppendLine($"INTENT_PHÁT_HIỆN: {intent}");

        AppendIntentInstructions(sb, intent, userMessage, history);

        sb.AppendLine();
        sb.Append(_recommendationService.BuildPersonalizationInsights(customerUserId));

        var mealStyle = MealComboBuilder.DetectStyleFromMessage(userMessage);
        if (intent == ChatIntent.MealRecommendation && mealStyle != null)
        {
            sb.AppendLine();
            sb.AppendLine("=== COMBO GỢI Ý SẴN (bám đúng tên món + SP; không tự chế combo lạ) ===");
            sb.AppendLine(_recommendationService.BuildCombosSection(customerUserId, mealStyle));
        }

        sb.AppendLine();
        sb.AppendLine();
        sb.Append(_recommendationService.BuildCrossSellPromptSection(customerUserId));

        sb.AppendLine();
        sb.Append(_recommendationService.BuildMealCatalogSection(customerUserId));



        sb.AppendLine();

        sb.AppendLine("=== ĐƠN HÀNG CỦA KHÁCH (chỉ dùng khi hỏi đơn) ===");

        var orders = _orderRepo.GetOrdersByUser(customerUserId).Take(3).ToList();

        if (orders.Count == 0)

        {

            sb.AppendLine("(Chưa có đơn)");

        }

        else

        {

            foreach (var o in orders)

            {

                sb.AppendLine(

                    $"- Đơn #{o.Id}: {o.Status}, tổng {o.TotalPrice:N0}đ, {o.CreatedAt:dd/MM/yyyy}");

            }

        }



        return sb.ToString();

    }



    private static void AppendIntentInstructions(

        StringBuilder sb,

        ChatIntent intent,

        string userMessage,

        IReadOnlyList<(string Role, string Content)> history)

    {

        switch (intent)

        {

            case ChatIntent.MealRecommendation:

                var styleChosen = ChatIntentHelper.HasChosenMealStyle(userMessage)

                                  || (ChatIntentHelper.BotAskedMealStyle(history) && !IsVagueMealAsk(userMessage));

                sb.AppendLine(

                    """

                    === HƯỚNG DẪN INTENT: GỢI Ý MÓN / COMBO ===

                    "Gợi ý món" = gợi ý BỮA ĂN / COMBO / MỤC ĐÍCH, KHÔNG phải liệt kê ngẫu nhiên từng SP lẻ.

                    """);

                if (!styleChosen && IsVagueMealAsk(userMessage))

                {

                    sb.AppendLine(

                        """

                        Khách chưa chọn phong cách → mở đầu thân thiện (vd: "Bạn thích kiểu nào? Mình sẽ gợi ý món phù hợp 🍽️")
                        rồi đưa ĐÚNG 4 lựa chọn sau (copy nguyên văn, mỗi lựa chọn 2 dòng):

                        🥗 Ăn healthy
                        Ít dầu mỡ, nhiều rau xanh

                        ⚡ Nấu nhanh
                        Có món dưới 20 phút

                        🍱 Cơm gia đình
                        Đủ dinh dưỡng cho bữa chính

                        🍎 Ăn nhẹ / tráng miệng
                        Trái cây, sữa, đồ ăn vặt

                        Kết: "Chọn 1 kiểu ăn nhé (Healthy / Nấu nhanh / Cơm gia đình / Ăn nhẹ) 👇"
                        KHÔNG liệt kê sản phẩm chi tiết ở bước này. KHÔNG viết "Bạn muốn ăn món gì?".

                        """);

                }

                else

                {

                    sb.AppendLine(

                        """

                        Khách đã chọn phong cách → Gợi ý 1–2 COMBO từ block "COMBO GỢI Ý SẴN" (nếu có).
                        Mở đầu cá nhân hóa nếu có dữ liệu (vd: "Vì bạn hay mua rau củ, mình gợi ý...").
                        Nhắc khuyến mãi đang chạy nếu SP/combo liên quan (không bịa %).
                        Cuối có thể nhắc 1–2 SP từ "MUA KÈM" (vd: "Thường khách mua thêm bắp cải, tỏi...").
                        Cấu trúc mỗi combo:
                        - Tên món (đúng tên trong COMBO GỢI Ý SẴN, vd: "Thịt bò xào bắp cải")
                        - Thành phần: emoji + tên SP – giá/đơn vị + 1 dòng cách nấu/dùng
                        - Tổng ước tính: ~XXXk
                        KHÔNG ghép nguyên liệu lạ (vd salad + táo + bắp cải không cùng món). Chỉ combo khả thi.
                        Kết: nhắc bấm nút thêm combo bên dưới nếu hệ thống đã gợi ý combo có giá.

                        """);

                }

                break;



            case ChatIntent.ProductSearch:

                sb.AppendLine(

                    """

                    === HƯỚNG DẪN INTENT: TÌM SẢN PHẨM ===

                    Trả lời trực tiếp: có/không, giá, gợi ý dùng. CHỈ liệt kê SP có tên trong CATALOG (copy đúng tên).

                    Nếu khách hỏi loại khác / còn gì nữa:
                    - Đếm SP cùng loại trong CATALOG (vd tất cả có "nước" trong tên).
                    - Chỉ có 1 → "Xin lỗi, hiện shop chỉ còn [tên SP] thôi" — KHÔNG liệt kê SP không có trong catalog.
                    - Có nhiều → liệt kê đủ các SP thật, không thêm.

                    Nước uống: cách dùng = uống/giải khát, không nấu ăn.

                    """);

                break;



            case ChatIntent.OrderStatus:

                sb.AppendLine(

                    """

                    === HƯỚNG DẪN INTENT: ĐƠN HÀNG ===

                    Dùng block ĐƠN HÀNG. Giải thích trạng thái bằng tiếng Việt dễ hiểu.

                    """);

                break;



            case ChatIntent.Promotion:

                sb.AppendLine(

                    """

                    === HƯỚNG DẪN INTENT: KHUYẾN MÃI ===

                    Hướng dẫn xem tab Voucher trên app. Không bịa mã giảm giá.

                    """);

                break;



            default:

                sb.AppendLine(

                    """

                    === HƯỚNG DẪN CHUNG ===

                    Nếu câu hỏi mơ hồ về "ăn gì" → chuyển sang hỏi 4 phong cách như gợi ý món.

                    Còn lại: tư vấn SP, đặt hàng COD/VNPay, giao hàng, hủy đơn chờ xác nhận.

                    """);

                break;

        }

    }



    private static bool IsVagueMealAsk(string message)

    {

        var t = message.Trim().ToLowerInvariant();

        return ContainsAny(t, "gợi ý", "goi y", "ăn gì", "an gi", "món gì", "mon gi", "mua gì", "nên mua")

               && !ChatIntentHelper.HasChosenMealStyle(message);

    }



    private static bool ContainsAny(string text, params string[] parts) =>

        parts.Any(p => text.Contains(p, StringComparison.Ordinal));

}


