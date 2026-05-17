using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class FavoriteController : ControllerBase
{
    private readonly FavoriteService _service;

    public FavoriteController(FavoriteService service)
    {
        _service = service;
    }

    [HttpPost("{productId}")]
    public IActionResult Toggle(int productId)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var result = _service.Toggle(userId, productId);

        return Ok(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetMyFavorites()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var favorites = await _service.GetByUser(userId);
        return Ok(favorites);
    }

    [HttpGet("check/{productId}")]
    public IActionResult Check(int productId)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        return Ok(_service.IsFavorite(userId, productId));
    }
}