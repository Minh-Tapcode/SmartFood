class Favorite {
  final int userId;
  final int productId;
  final DateTime createdAt;
  final String? userName;
  final String? productName;

  Favorite({
    required this.userId,
    required this.productId,
    required this.createdAt,
    this.userName,
    this.productName,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      userId: json['userId'],
      productId: json['productId'],
      createdAt: DateTime.parse(json['createdAt']),
      userName: json['userName'],
      productName: json['productName'],
    );
  }
}