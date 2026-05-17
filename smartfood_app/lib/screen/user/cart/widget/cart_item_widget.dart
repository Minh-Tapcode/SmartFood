import 'package:flutter/material.dart';

import '../../../../models/cart_item.dart';
import '../provider/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;
  final CartProvider provider;
  final Function(CartItem, int) onUpdateQuantity;
  final Function(CartItem) onDelete;

  const CartItemWidget({
    super.key,
    required this.cartItem,
    required this.provider,
    required this.onUpdateQuantity,
    required this.onDelete,
  });

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.'
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = cartItem.stock;
    final atStockCap = maxQty >= 0 && cartItem.quantity >= maxQty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox chọn sản phẩm
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: cartItem.isSelected ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Checkbox(
                    value: cartItem.isSelected,
                    onChanged: (value) => provider.toggleItemSelection(cartItem.id, value),
                    activeColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),

                // Ảnh sản phẩm
                Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    image: cartItem.fullImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(cartItem.fullImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: cartItem.fullImageUrl.isNotEmpty
                      ? null
                      : Center(
                          child: Text(
                            cartItem.productName.isNotEmpty ? cartItem.productName[0] : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                ),

                // Thông tin sản phẩm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cartItem.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatPrice(cartItem.price)}đ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade600,
                        ),
                      ),
                      if (maxQty >= 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kho: $maxQty',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Bộ chọn số lượng
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove,
                                  size: 18,
                                  color: Colors.grey.shade600),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => onUpdateQuantity(cartItem, cartItem.quantity - 1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${cartItem.quantity}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                size: 18,
                                color: atStockCap ? Colors.grey.shade400 : Colors.green.shade600,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: atStockCap
                                  ? null
                                  : () => onUpdateQuantity(cartItem, cartItem.quantity + 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tổng tiền và nút xóa
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(cartItem.totalPrice)}đ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                        padding: EdgeInsets.zero,
                        onPressed: () => onDelete(cartItem),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

