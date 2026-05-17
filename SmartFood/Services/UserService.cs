using Microsoft.IdentityModel.Tokens;
using SmartFood.DTOs;
using SmartFood.Models;
using SmartFood.Repositories;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace SmartFood.Services
{
    public class UserService
    {
        private readonly UserRepository _userRepo;

        public UserService(UserRepository userRepo)
        {
            _userRepo = userRepo;
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(bytes);
        }

        private static string NormalizeRole(string? role)
        {
            return string.IsNullOrWhiteSpace(role) ? "buyer" : role.Trim().ToLowerInvariant();
        }

        public async Task<(bool Success, string Message, object? Data)> RegisterAsync(RegisterDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Email) || string.IsNullOrWhiteSpace(dto.Password))
                return (false, "Dữ liệu không hợp lệ", null);

            var existing = await _userRepo.GetByEmailAsync(dto.Email);
            if (existing != null)
                return (false, "Email đã tồn tại", null);

            var user = new User
            {
                Name = dto.Name,
                Email = dto.Email,
                Password = HashPassword(dto.Password),
                Phone = dto.Phone,
                Role = "buyer"
            };

            await _userRepo.AddAsync(user);

            return (true, "", new
            {
                user.Id,
                user.Name,
                user.Email,
                user.Phone,
                Role = NormalizeRole(user.Role)
            });
        }

        public async Task<(bool Success, string Message, object? Data)> LoginAsync(LoginDto dto)
        {
            var user = await _userRepo.GetByEmailAsync(dto.Email);
            if (user == null)
                return (false, "Email hoặc mật khẩu không đúng", null);

            if (user.Password != HashPassword(dto.Password))
                return (false, "Email hoặc mật khẩu không đúng", null);

            var claims = new[]
{
    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
    new Claim(ClaimTypes.Email, user.Email),
    new Claim(ClaimTypes.Name, user.Name),
    new Claim(ClaimTypes.Role, NormalizeRole(user.Role))
};

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("12345678901234567890123456789012"));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                claims: claims,
                expires: DateTime.Now.AddHours(2),
                signingCredentials: creds
            );

            var jwt = new JwtSecurityTokenHandler().WriteToken(token);

            return (true, "", new
            {
                token = jwt,
                user = new
                {
                    user.Id,
                    user.Name,
                    user.Email,
                    user.Phone,
                    Role = NormalizeRole(user.Role)
                }
            });
        }

        public async Task<object?> GetByIdAsync(int id)
        {
            var user = await _userRepo.GetByIdAsync(id);
            if (user == null) return null;

            return new
            {
                user.Id,
                user.Name,
                user.Email,
                user.Phone,
                Role = NormalizeRole(user.Role),
                user.CreatedAt
            };
        }

        public async Task<IEnumerable<object>> GetAllAsync()
        {
            var users = await _userRepo.GetAllAsync();

            return users.Select(MapUserListItem);
        }

        public async Task<PagedUsersDto> GetPagedAsync(int page, int pageSize, string? search = null)
        {
            var (users, total) = await _userRepo.GetPagedAsync(page, pageSize, search);
            var totalPages = pageSize > 0 ? (int)Math.Ceiling(total / (double)pageSize) : 0;

            return new PagedUsersDto
            {
                Items = users.Select(u => (object)MapUserListItem(u)).ToList(),
                Page = page,
                PageSize = pageSize,
                TotalCount = total,
                TotalPages = totalPages,
                HasMore = page < totalPages
            };
        }

        private static object MapUserListItem(User u) => new
        {
            u.Id,
            u.Name,
            u.Email,
            u.Phone,
            Role = NormalizeRole(u.Role)
        };

        public async Task<(bool Success, string Message, object? Data)> UpdateProfileAsync(int id, UpdateUserDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Name) || string.IsNullOrWhiteSpace(dto.Email))
                return (false, "Dữ liệu không hợp lệ", null);

            var user = await _userRepo.GetByIdAsync(id);
            if (user == null)
                return (false, "Không tìm thấy người dùng", null);

            var sameEmailUser = await _userRepo.GetByEmailAsync(dto.Email);
            if (sameEmailUser != null && sameEmailUser.Id != id)
                return (false, "Email đã tồn tại", null);

            user.Name = dto.Name;
            user.Email = dto.Email;
            user.Phone = dto.Phone;
            await _userRepo.UpdateAsync(user);

            return (true, "", new
            {
                user.Id,
                user.Name,
                user.Email,
                user.Phone,
                Role = NormalizeRole(user.Role),
                user.CreatedAt
            });
        }
    }
}