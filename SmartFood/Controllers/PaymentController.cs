using Microsoft.AspNetCore.Mvc;
using SmartFood.Services;
using System.Collections.Generic;

namespace SmartFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        // Thanh toán COD
        [HttpPost("cod/{orderId}")]
        public async Task<IActionResult> PayCOD(int orderId)
        {
            var result = await _paymentService.PayOnDelivery(orderId);
            return Ok(result);
        }

        // Tạo URL thanh toán VNPAY
        [HttpGet("vnpay/{orderId}")]
        public async Task<IActionResult> PayVNPay(int orderId, [FromQuery] string? bankCode = null)
        {
            try
            {
                var result = await _paymentService.PayWithVNPay(orderId, bankCode);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("method/{orderId}")]
        public async Task<IActionResult> ChangeMethod(int orderId, [FromBody] Dictionary<string, string> payload)
        {
            if (payload == null || !payload.TryGetValue("method", out var method) || string.IsNullOrWhiteSpace(method))
                return BadRequest(new { message = "method is required" });
            try
            {
                var result = await _paymentService.ChangePaymentMethod(orderId, method);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        // Callback / IPN từ VNPAY
        [HttpGet("vnpay-callback")]
        public async Task<IActionResult> VNPayCallback()
        {
            var queryParams = new Dictionary<string, string>();
            foreach (var key in Request.Query.Keys)
                queryParams[key] = Request.Query[key];

            bool success = await _paymentService.ProcessVNPayCallback(queryParams);

            var rspCode = success ? "00" : "97"; // 00 = thành công, 97 = lỗi
            var message = success ? "Confirm Success" : "Confirm Fail";

            return Ok(new { RspCode = rspCode, Message = message });
        }

        // Callback from mobile app after intercepting VNPay return URL.
        [HttpPost("vnpay-client-callback")]
        public async Task<IActionResult> VNPayClientCallback([FromBody] Dictionary<string, string> queryParams)
        {
            if (queryParams == null || queryParams.Count == 0)
                return BadRequest(new { success = false, message = "Missing query params" });

            bool success = await _paymentService.ProcessVNPayCallback(queryParams);
            return Ok(new { success });
        }
    }
}