import '../core/constants.dart';

class OrderDetail {
  final int orderId;
  final int productId;
  final String tenSanPham;
  final String? imageUrl;
  final double giaBan;
  final int soLuong;

  const OrderDetail({
    required this.orderId,
    required this.productId,
    required this.tenSanPham,
    this.imageUrl,
    required this.giaBan,
    required this.soLuong,
  });

  String get fullImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final uri = Uri.parse(Constant().baseUrl);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '$origin$normalizedPath';
  }

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) return json[key];
      }
      return null;
    }

    final rawOrderId = pick(['orderId', 'OrderId']) ?? 0;
    final rawProductId = pick(['productId', 'ProductId']) ?? 0;
    final rawPrice = pick(['price', 'Price']) ?? 0;
    final rawQuantity = pick(['quantity', 'Quantity']) ?? 0;

    return OrderDetail(
      orderId: rawOrderId is int ? rawOrderId : int.tryParse(rawOrderId.toString()) ?? 0,
      productId: rawProductId is int ? rawProductId : int.tryParse(rawProductId.toString()) ?? 0,
      tenSanPham: (pick(['productName', 'ProductName']) ?? 'Sản phẩm').toString(),
      imageUrl: pick(['imageUrl', 'ImageUrl'])?.toString(),
      giaBan: rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0,
      soLuong: rawQuantity is int ? rawQuantity : int.tryParse(rawQuantity.toString()) ?? 0,
    );
  }
}
