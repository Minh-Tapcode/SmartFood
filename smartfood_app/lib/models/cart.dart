import 'cart_item.dart';

class Cart {
  final int id;
  final int userId;
  final List<CartItem> cartItems;

  Cart({
    required this.id,
    required this.userId,
    required this.cartItems,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      cartItems: (json['cartItems'] as List<dynamic>? ?? [])
          .map((e) => CartItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cartItems': cartItems.map((e) => e.toJson()).toList(),
    };
  }
}