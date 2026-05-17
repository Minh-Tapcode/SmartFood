import '../core/constants.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryName;
  final String createdAt;
  final String expiryDate;
  final String origin;
  final String unit;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryName,
    required this.createdAt,
    required this.expiryDate,
    required this.origin,
    required this.unit,
    this.imageUrl,
  });

  String get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return '';
    return _buildImageUrl(imageUrl!);
  }

  static String _buildImageUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;

    final base = Constant().baseUrl;
    final uri = Uri.parse(base);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

    final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '$origin$normalizedPath';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    String? resolvedImage = json['imageUrl'] as String?;
    if ((resolvedImage == null || resolvedImage.isEmpty) &&
        json['images'] is List &&
        (json['images'] as List).isNotEmpty) {
      resolvedImage = (json['images'] as List).first?.toString();
    }

    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      expiryDate: json['expiryDate'],
      origin: json['origin'] ?? '',
      unit: json['unit']??'',
      imageUrl: resolvedImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'origin': origin,
      'unit': unit,
      'stock': stock,
    };
  }

  factory Product.fromFavoriteJson(Map<String, dynamic> json) {
    return Product(
      id: json['productId'],
      name: json['productName'] ?? '',
      description: '',
      price: (json['price'] as num).toDouble(),
      stock: 0,
      categoryName: '',
      createdAt: '',
      expiryDate: '',
      origin: '',
      unit:'',
      imageUrl: json['image'],
    );
  }
}