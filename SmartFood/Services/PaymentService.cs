using Microsoft.Extensions.Configuration;
using SmartFood.Models;
using SmartFood.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Security.Cryptography;
using System.Text;
using System.Globalization;
using System.Text.RegularExpressions;

namespace SmartFood.Services
{
    public interface IPaymentService
    {
        Task<PaymentResult> PayWithVNPay(int orderId, string? bankCode = null);
        Task<PaymentResult> PayOnDelivery(int orderId);
        Task<PaymentResult> ChangePaymentMethod(int orderId, string method);
        Task<bool> ProcessVNPayCallback(Dictionary<string, string> queryParams);
    }

    public class PaymentService : IPaymentService
    {
        private readonly OrderRepository _orderRepo;
        private readonly PaymentRepository _paymentRepo;

        private readonly string vnp_TmnCode;
        private readonly string vnp_HashSecret;
        private readonly string vnp_Url;
        private readonly string vnp_ReturnUrl;

        public PaymentService(OrderRepository orderRepo, PaymentRepository paymentRepo, IConfiguration configuration)
        {
            _orderRepo = orderRepo;
            _paymentRepo = paymentRepo;
            var vnp = configuration.GetSection("Vnpay");
            vnp_TmnCode = (vnp["TmnCode"] ?? "TKX0IP26").Trim();
            vnp_HashSecret = (vnp["HashSecret"] ?? "WJ15Z6G1IVZ27NLCBVVTMFOTLMO80QRH").Trim();
            vnp_Url = vnp["BaseUrl"] ?? "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
            vnp_ReturnUrl = vnp["ReturnUrl"] ?? "https://localhost:7145/api/payment/vnpay-callback";
        }

        // Thanh toán COD
        public Task<PaymentResult> PayOnDelivery(int orderId)
        {
            var order = _orderRepo.GetOrder(orderId);
            if (order == null) throw new Exception("Order not found");

            order.Status = "pending";
            _orderRepo.UpdateOrder(order);

            var payment = _paymentRepo.GetPaymentByOrderId(order.Id);
            if (payment == null || (payment.Method ?? "").ToUpperInvariant() != "COD")
            {
                payment = new Payment
                {
                    OrderId = order.Id,
                    Amount = order.TotalPrice,
                    Method = "COD",
                    Status = "pending",
                    CreatedAt = DateTime.Now
                };
                _paymentRepo.Create(payment);
            }
            else
            {
                payment.Amount = order.TotalPrice;
                payment.Status = "pending";
                payment.CreatedAt = DateTime.Now;
                _paymentRepo.Update(payment);
            }

            return Task.FromResult(new PaymentResult
            {
                OrderId = order.Id,
                Method = "COD",
                Status = payment.Status
            });
        }

        public Task<PaymentResult> ChangePaymentMethod(int orderId, string method)
        {
            var normalized = (method ?? "").Trim().ToUpperInvariant();
            if (normalized != "COD" && normalized != "VNPAY")
                throw new Exception("Payment method must be COD or VNPAY");

            var order = _orderRepo.GetOrder(orderId);
            if (order == null) throw new Exception("Order not found");

            var status = (order.Status ?? "pending").Trim().ToLowerInvariant();
            if (status != "pending")
                throw new Exception("Chỉ đổi phương thức thanh toán được khi đơn đang chờ xác nhận.");

            if (normalized == "COD")
                return PayOnDelivery(orderId);

            order.Status = "pending";
            _orderRepo.UpdateOrder(order);

            var payment = _paymentRepo.GetPaymentByOrderId(order.Id);
            if (payment == null || (payment.Method ?? "").ToUpperInvariant() != "VNPAY")
            {
                payment = new Payment
                {
                    OrderId = order.Id,
                    Amount = order.TotalPrice,
                    Method = "VNPAY",
                    Status = "pending",
                    CreatedAt = DateTime.Now
                };
                _paymentRepo.Create(payment);
            }
            else
            {
                payment.Amount = order.TotalPrice;
                payment.Status = "pending";
                payment.CreatedAt = DateTime.Now;
                _paymentRepo.Update(payment);
            }

            return Task.FromResult(new PaymentResult
            {
                OrderId = order.Id,
                Method = "VNPAY",
                Status = payment.Status
            });
        }

        private static string VnpPhpStyleUrlEncode(string? s)
        {
            if (string.IsNullOrEmpty(s)) return string.Empty;
            var encoded = HttpUtility.UrlEncode(s);
            return Regex.Replace(encoded, @"%[a-fA-F0-9]{2}", m => m.Value.ToUpperInvariant());
        }

        private static string BuildVnpSignData(IEnumerable<KeyValuePair<string, string>> sortedPairs) =>
            string.Join("&", sortedPairs.Select(kvp =>
                $"{VnpPhpStyleUrlEncode(kvp.Key)}={VnpPhpStyleUrlEncode(kvp.Value)}"));

        private static DateTime GetVietnamTimeNow()
        {
            try
            {
                var tz = TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
                return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz);
            }
            catch (TimeZoneNotFoundException)
            {
                try
                {
                    var tz = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
                    return TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz);
                }
                catch
                {
                    return DateTime.Now;
                }
            }
        }

        // Tạo URL thanh toán VNPAY
        public Task<PaymentResult> PayWithVNPay(int orderId, string? bankCode = null)
        {
            var order = _orderRepo.GetOrder(orderId);
            if (order == null) throw new Exception("Order not found");

            var latestPay = _paymentRepo.GetPaymentByOrderId(order.Id);
            if (latestPay != null)
            {
                var method = (latestPay.Method ?? "").Trim().ToUpperInvariant();
                var st = (latestPay.Status ?? "").Trim().ToLowerInvariant();
                if (method == "VNPAY" && (st == "paid" || st == "success"))
                    throw new InvalidOperationException("Đơn hàng đã thanh toán VNPay, không thể thanh toán lại.");
            }

            var vnNow = GetVietnamTimeNow();
            var amountScaled = (long)Math.Round(order.TotalPrice * 100m, MidpointRounding.AwayFromZero);

            var vnp = new Dictionary<string, string>
            {
                { "vnp_Version", "2.1.0" },
                { "vnp_Command", "pay" },
                { "vnp_TmnCode", vnp_TmnCode },
                { "vnp_Amount", amountScaled.ToString(CultureInfo.InvariantCulture) },
                { "vnp_CreateDate", vnNow.ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture) },
                { "vnp_CurrCode", "VND" },
                { "vnp_ExpireDate", vnNow.AddMinutes(15).ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture) },
                { "vnp_TxnRef", order.Id.ToString(CultureInfo.InvariantCulture) },
                { "vnp_OrderInfo", $"Payment_for_order_{order.Id}" },
                { "vnp_ReturnUrl", vnp_ReturnUrl },
                { "vnp_IpAddr", "127.0.0.1" },
                { "vnp_Locale", "vn" },
                { "vnp_OrderType", "other" }
            };

            if (!string.IsNullOrEmpty(bankCode))
                vnp["vnp_BankCode"] = bankCode;

            // Sắp xếp key Ordinal, chuỗi ký = urlencode (theo tài liệu VNPay 2.1.0).
            var sorted = vnp.OrderBy(x => x.Key, StringComparer.Ordinal).ToList();
            var signData = BuildVnpSignData(sorted);

            using var hmac = new HMACSHA512(Encoding.UTF8.GetBytes(vnp_HashSecret));
            var hashBytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(signData));
            var hashValue = BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();

            // VNPay 2.1.0: chỉ nối vnp_SecureHash (không gửi vnp_SecureHashType).
            var paymentUrl = $"{vnp_Url}?{signData}&vnp_SecureHash={hashValue}";

            order.Status = "pending";
            _orderRepo.UpdateOrder(order);

            var payment = _paymentRepo.GetPaymentByOrderId(order.Id);
            if (payment == null || (payment.Method ?? "").ToUpperInvariant() != "VNPAY")
            {
                payment = new Payment
                {
                    OrderId = order.Id,
                    Amount = order.TotalPrice,
                    Method = "VNPAY",
                    Status = "pending",
                    CreatedAt = DateTime.Now
                };
                _paymentRepo.Create(payment);
            }
            else
            {
                payment.Amount = order.TotalPrice;
                payment.Status = "pending";
                payment.CreatedAt = DateTime.Now;
                _paymentRepo.Update(payment);
            }

            return Task.FromResult(new PaymentResult
            {
                OrderId = order.Id,
                Method = "VNPAY",
                PaymentUrl = paymentUrl,
                Status = payment.Status
            });
        }

        // Xử lý callback / IPN
        public Task<bool> ProcessVNPayCallback(Dictionary<string, string> queryParams)
        {
            if (!queryParams.TryGetValue("vnp_SecureHash", out var vnp_SecureHash) || string.IsNullOrEmpty(vnp_SecureHash))
                return Task.FromResult(false);

            // Chỉ tham số vnp_* tham gia ký; bỏ vnp_SecureHash / vnp_SecureHashType (theo tài liệu VNPay).
            var sorted = queryParams
                .Where(kvp => kvp.Key.StartsWith("vnp_", StringComparison.Ordinal))
                .Where(kvp => kvp.Key != "vnp_SecureHash" && kvp.Key != "vnp_SecureHashType")
                .OrderBy(kvp => kvp.Key, StringComparer.Ordinal)
                .ToList();
            var signData = BuildVnpSignData(sorted);

            using var hmac = new HMACSHA512(Encoding.UTF8.GetBytes(vnp_HashSecret));
            var hashBytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(signData));
            var computedHash = BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();

            if (!string.Equals(computedHash, vnp_SecureHash, StringComparison.OrdinalIgnoreCase))
                return Task.FromResult(false);

            if (!queryParams.TryGetValue("vnp_TxnRef", out var txnRef) || string.IsNullOrEmpty(txnRef))
                return Task.FromResult(false);
            if (!queryParams.TryGetValue("vnp_ResponseCode", out var responseCode) || string.IsNullOrEmpty(responseCode))
                return Task.FromResult(false);

            int orderId = int.Parse(txnRef);
            var order = _orderRepo.GetOrder(orderId);
            var payment = _paymentRepo.GetPaymentByOrderId(orderId);
            if (order == null || payment == null) return Task.FromResult(false);

            if (responseCode == "00")
            {
                order.Status = "pending";
                payment.Status = "paid";
                if (queryParams.TryGetValue("vnp_TransactionNo", out var txnNo))
                    payment.TransactionId = txnNo;
            }
            else
            {
                order.Status = "pending";
                payment.Status = "failed";
            }

            _orderRepo.UpdateOrder(order);
            _paymentRepo.Update(payment);

            return Task.FromResult(responseCode == "00");
        }
    }

    public class PaymentResult
    {
        public int OrderId { get; set; }
        public string Method { get; set; }
        public string Status { get; set; }
        public string? PaymentUrl { get; set; }
    }
}