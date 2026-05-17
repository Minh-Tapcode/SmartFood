using Microsoft.AspNetCore.Mvc;
using SmartFood.DTOs;
using SmartFood.Services;

namespace SmartFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UserService _userService;

        public AuthController(UserService userService)
        {
            _userService = userService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterDto dto)
        {
            var result = await _userService.RegisterAsync(dto);

            if (!result.Success)
                return BadRequest(result.Message);

            return Ok(result.Data);
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginDto dto)
        {
            var result = await _userService.LoginAsync(dto);

            if (!result.Success)
                return Unauthorized(result.Message);

            return Ok(result.Data);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUser(int id)
        {
            var user = await _userService.GetByIdAsync(id);

            if (user == null)
                return NotFound();

            return Ok(user);
        }

        [HttpGet("all")]
        public async Task<IActionResult> GetAll(
            [FromQuery] int page = 0,
            [FromQuery] int pageSize = 0,
            [FromQuery] string? search = null)
        {
            if (page > 0 && pageSize > 0)
                return Ok(await _userService.GetPagedAsync(page, pageSize, search));

            var users = await _userService.GetAllAsync();
            return Ok(users);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(int id, UpdateUserDto dto)
        {
            var result = await _userService.UpdateProfileAsync(id, dto);
            if (!result.Success)
                return BadRequest(result.Message);
            return Ok(result.Data);
        }
    }
}