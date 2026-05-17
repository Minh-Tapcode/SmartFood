class Rating {
  final int? id;
  final int userId;
  final int productId;
  final int? orderId;
  final int soSao;
  final String? noiDung;
  final String? userName;
  final DateTime? createdAt;

  Rating({
    this.id,
    required this.userId,
    required this.productId,
    this.orderId,
    required this.soSao,
    this.noiDung,
    this.userName,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      userId: json['userId'],
      productId: json['productId'],
      orderId: json['orderId'] ?? json['OrderId'],
      soSao: json['soSao'],
      noiDung: json['noiDung'],
      userName: (json['userName'] ?? json['UserName'])?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

}

class RatingStats {
  final int total;
  final double average;
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;

  RatingStats({
    required this.total,
    required this.average,
    required this.fiveStar,
    required this.fourStar,
    required this.threeStar,
    required this.twoStar,
    required this.oneStar,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      total: json['total'] ?? 0,
      average: (json['average'] ?? 0).toDouble(),
      fiveStar: json['fiveStar'] ?? 0,
      fourStar: json['fourStar'] ?? 0,
      threeStar: json['threeStar'] ?? 0,
      twoStar: json['twoStar'] ?? 0,
      oneStar: json['oneStar'] ?? 0,
    );
  }
}

class UserReviewItem {
  final int orderId;
  final int productId;
  final String productName;
  final String? productImage;
  final bool isReviewed;
  final int? soSao;
  final String? noiDung;
  final DateTime? ratedAt;

  const UserReviewItem({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.isReviewed,
    required this.soSao,
    required this.noiDung,
    required this.ratedAt,
  });

  factory UserReviewItem.fromJson(Map<String, dynamic> json) {
    final ratedAtRaw = json['ratedAt'] ?? json['RatedAt'];
    return UserReviewItem(
      orderId: json['orderId'] ?? json['OrderId'] ?? 0,
      productId: json['productId'] ?? json['ProductId'] ?? 0,
      productName: (json['productName'] ?? json['ProductName'] ?? '').toString(),
      productImage: (json['productImage'] ?? json['ProductImage'])?.toString(),
      isReviewed: (json['isReviewed'] ?? json['IsReviewed'] ?? false) == true,
      soSao: json['soSao'] ?? json['SoSao'],
      noiDung: (json['noiDung'] ?? json['NoiDung'])?.toString(),
      ratedAt: ratedAtRaw == null ? null : DateTime.tryParse(ratedAtRaw.toString()),
    );
  }
}

class UserReviewSummary {
  final int reviewed;
  final int unreviewed;
  final int total;
  final List<UserReviewItem> items;

  const UserReviewSummary({
    required this.reviewed,
    required this.unreviewed,
    required this.total,
    required this.items,
  });

  factory UserReviewSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] ?? const []) as List;
    return UserReviewSummary(
      reviewed: json['reviewed'] ?? 0,
      unreviewed: json['unreviewed'] ?? 0,
      total: json['total'] ?? 0,
      items: list
          .whereType<Map>()
          .map((e) => UserReviewItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}