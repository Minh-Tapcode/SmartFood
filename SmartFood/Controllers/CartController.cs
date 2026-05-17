using Microsoft.AspNetCore.Mvc;
using SmartFood.DTOs.Cart;

namespace SmartFood.Controllers
{
    [ApiController]
    [Route("api/cart")]
    public class CartController : ControllerBase
    {
        private readonly CartService _service;

        public CartController(CartService service)
        {
            _service = service;
        }

        [HttpPost("add")]
        public IActionResult Add(int userId, AddToCartDto dto)
        {
            try
            {
                var result = _service.AddToCart(userId, dto);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{userId}")]
        public IActionResult Get(int userId)
        {
            return Ok(_service.GetCart(userId));
        }

        [HttpPut("update")]
        public IActionResult Update(UpdateCartDto dto)
        {
            try
            {
                _service.Update(dto);
                return Ok("Updated");
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{cartItemId}")]
        public IActionResult Remove(int cartItemId)
        {
            _service.Remove(cartItemId);
            return Ok("Removed");
        }
    }
}
