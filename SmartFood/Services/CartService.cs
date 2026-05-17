using SmartFood.DTOs.Cart;
using SmartFood.Models;

public class CartService
{
    private readonly CartRepository _repo;

    public CartService(CartRepository repo)
    {
        _repo = repo;
    }

    public CartItemResponseDto AddToCart(int userId, AddToCartDto dto)
    {
        var cart = _repo.GetCartByUser(userId);

        if (cart == null)
        {
            cart = _repo.CreateCart(userId);
        }

        var item = _repo.GetCartItem(cart.Id, dto.ProductId);

        var product = _repo.GetProduct(dto.ProductId);
        if (product == null)
            throw new Exception("Không tìm thấy sản phẩm");

        if (item != null)
        {
            var newQty = item.Quantity + dto.Quantity;
            if (product.Stock < newQty)
                throw new Exception($"Chỉ còn {product.Stock} sản phẩm trong kho (đang có {item.Quantity} trong giỏ).");
            item.Quantity = newQty;
            _repo.UpdateItem(item);
        }
        else
        {
            if (product.Stock < dto.Quantity)
                throw new Exception($"Chỉ còn {product.Stock} sản phẩm trong kho.");
            item = new CartItem
            {
                CartId = cart.Id,
                ProductId = dto.ProductId,
                Quantity = dto.Quantity
            };

            _repo.AddItem(item);
        }

        return new CartItemResponseDto
        {
            Id = item.Id,
            ProductId = product.Id,
            ProductName = product.Name,
            Price = product.Price,
            Quantity = item.Quantity,
            Stock = product.Stock,
            ImageUrl = product.ImageUrl
        };
    }

    public List<CartItemResponseDto> GetCart(int userId)
    {
        var cart = _repo.GetCartByUser(userId);
        if (cart == null) return new List<CartItemResponseDto>();

        var items = _repo.GetCartItems(cart.Id);

        return items.Select(x =>
        {
            var product = _repo.GetProduct(x.ProductId);

            return new CartItemResponseDto
            {
                Id = x.Id,
                ProductId = product.Id,
                ProductName = product.Name,
                Price = product.Price,
                Quantity = x.Quantity,
                Stock = product.Stock,
                ImageUrl = product.ImageUrl
            };
        }).ToList();
    }

    public void Update(UpdateCartDto dto)
    {
        var item = _repo.GetById(dto.CartItemId);
        if (item == null) throw new Exception("Không tìm thấy dòng giỏ hàng");

        var product = _repo.GetProduct(item.ProductId);
        if (product == null) throw new Exception("Không tìm thấy sản phẩm");
        if (dto.Quantity < 1) throw new Exception("Số lượng phải ít nhất là 1");
        if (product.Stock < dto.Quantity)
            throw new Exception($"Chỉ còn {product.Stock} sản phẩm trong kho.");

        item.Quantity = dto.Quantity;
        _repo.UpdateItem(item);
    }

    public void Remove(int cartItemId)
    {
        var item = _repo.GetById(cartItemId);
        if (item == null) throw new Exception("Item not found");

        _repo.RemoveItem(item);
    }

    public int AddMultipleToCart(int userId, IEnumerable<(int ProductId, int Quantity)> items)
    {
        var added = 0;
        foreach (var (productId, quantity) in items)
        {
            if (quantity < 1) continue;
            AddToCart(userId, new AddToCartDto { ProductId = productId, Quantity = quantity });
            added++;
        }
        return added;
    }
}