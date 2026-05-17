namespace SmartFood.DTOs.Order
{
    public class OrderDetailClientDto
    {
        public OrderListItemDto Order { get; set; } = null!;
        public List<OrderLineDto> OrderDetails { get; set; } = new();
    }
}
