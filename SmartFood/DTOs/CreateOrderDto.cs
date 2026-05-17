public class CreateOrderDto
{
    public string Address { get; set; }
    public string ReceiverName { get; set; }
    public string ReceiverPhone { get; set; }
    public string Note { get; set; }

    public string PaymentMethod { get; set; } // COD | VNPAY
}