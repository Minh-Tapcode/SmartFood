import '../core/constants.dart';

class CartItem {
  final int id; // cart item id
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;
  /// Tồn kho hiện tại; -1 nếu API cũ không trả về (không giới hạn trên client).
  final int stock;
  final bool isSelected;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.stock = -1,
    this.isSelected = true,
  });

  String get fullImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final base = Constant().baseUrl;
    final uri = Uri.parse(base);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '$origin$normalizedPath';
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawStock = json['stock'] ?? json['Stock'];
    return CartItem(
      id: _asInt(json['id']),
      productId: _asInt(json['productId']),
      productName: (json['productName'] ?? '') as String,
      price: (json['price'] as num).toDouble(),
      quantity: _asInt(json['quantity']),
      imageUrl: json['imageUrl']?.toString(),
      stock: rawStock == null ? -1 : _asInt(rawStock),
      isSelected: true,
    );
  }

  CartItem copyWith({
    int? id,
    int? productId,
    String? productName,
    double? price,
    int? quantity,
    String? imageUrl,
    int? stock,
    bool? isSelected,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'stock': stock,
      'isSelected': isSelected,
    };
  }
}