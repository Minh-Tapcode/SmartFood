namespace SmartFood.DTOs
{
    public class CartDto
    {
        public class AddToCartDto
        {
            public int ProductId { get; set; }
            public int Quantity { get; set; }
        }
        public class UpdateCartDto
        {
            public int CartItemId { get; set; }
            public int Quantity { get; set; }
        }
        public class CartItemResponseDto
        {
            public int Id { get; set; }
            public int Quantity { get; set; }

            public int ProductId { get; set; }
            public string ProductName { get; set; }
            public decimal Price { get; set; }
        }
    }
}
