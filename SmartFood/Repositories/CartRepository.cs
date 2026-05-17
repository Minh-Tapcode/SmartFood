using SmartFood.Data;
using SmartFood.Models;
using System;

public class CartRepository
{
    private readonly SmartFoodContext  _context;

    public CartRepository(SmartFoodContext context)
    {
        _context = context;
    }

    public Cart GetCartByUser(int userId)
    {
        return _context.Cart.FirstOrDefault(x => x.UserId == userId);
    }

    public Cart CreateCart(int userId)
    {
        var cart = new Cart { UserId = userId };
        _context.Cart.Add(cart);
        _context.SaveChanges();
        return cart;
    }

    public CartItem GetCartItem(int cartId, int productId)
    {
        return _context.CartItems
            .FirstOrDefault(x => x.CartId == cartId && x.ProductId == productId);
    }

    public List<CartItem> GetCartItems(int cartId)
    {
        return _context.CartItems
            .Where(x => x.CartId == cartId)
            .ToList();
    }

    public CartItem GetById(int id)
    {
        return _context.CartItems.Find(id);
    }

    public void AddItem(CartItem item)
    {
        _context.CartItems.Add(item);
        _context.SaveChanges();
    }

    public void UpdateItem(CartItem item)
    {
        _context.CartItems.Update(item);
        _context.SaveChanges();
    }

    public void RemoveItem(CartItem item)
    {
        _context.CartItems.Remove(item);
        _context.SaveChanges();
    }

    public Product GetProduct(int productId)
    {
        return _context.Products.Find(productId);
    }
}