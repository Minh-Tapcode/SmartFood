class Order {
  final int id;
  final int userId;
  final double totalPrice;
  final String status;
  final String? address;
  final DateTime createdAt;
  final String receiverName;
  final String receiverPhone;
  final String? note;
  final String? paymentMethod;
  final String paymentStatus;
  final double shippingFee;
  final double discountAmount;
  final int? promotionId;
  final String? promotionTitle;

  const Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    this.address,
    required this.createdAt,
    required this.receiverName,
    required this.receiverPhone,
    this.note,
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.shippingFee = 0,
    this.discountAmount = 0,
    this.promotionId,
    this.promotionTitle,
  });

  String get maDonHang => '#OD$id';
  String get trangThai => status;
  DateTime get ngayDat => createdAt;
  String? get phuongThucThanhToan => paymentMethod;
  String get trangThaiThanhToan => paymentStatus;
  String? get soDienThoai => receiverPhone;
  String? get diaChiGiaoHang => address;
  String? get ghiChu => note;

  factory Order.fromJson(Map<String, dynamic> json) {
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) return json[key];
      }
      // Thử tìm case-insensitive nếu không thấy
      for (final entry in json.entries) {
        for (final key in keys) {
          if (entry.key.toLowerCase() == key.toLowerCase() && entry.value != null) {
            return entry.value;
          }
        }
      }
      return null;
    }

    final rawId = pick(['id', 'Id']) ?? 0;
    final rawUserId = pick(['userId', 'UserId', 'user_id']) ?? 0;
    final rawTotal = pick(['totalPrice', 'TotalPrice', 'total_price']) ?? 0;
    final rawDate = pick(['createdAt', 'CreatedAt', 'created_at']);

    final rawShip = pick(['shippingFee', 'ShippingFee', 'shipping_fee']);
    final rawDisc = pick(['discountAmount', 'DiscountAmount', 'discount_amount']);
    final rawPromoId = pick(['promotionId', 'PromotionId', 'promotion_id']);
    final rawPromoTitle = pick(['promotionTitle', 'PromotionTitle', 'promotion_title']);

    return Order(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      userId: rawUserId is int ? rawUserId : int.tryParse(rawUserId.toString()) ?? 0,
      totalPrice: rawTotal is num ? rawTotal.toDouble() : double.tryParse(rawTotal.toString()) ?? 0,
      status: (pick(['status', 'Status', 'trangThai', 'TrangThai']) ?? 'pending').toString(),
      address: pick(['address', 'Address', 'diaChi', 'DiaChi'])?.toString(),
      createdAt: rawDate == null ? DateTime.now() : DateTime.tryParse(rawDate.toString()) ?? DateTime.now(),
      receiverName: (pick(['receiverName', 'ReceiverName', 'receiver_name', 'tenNguoiNhan']) ?? '').toString(),
      receiverPhone: (pick(['receiverPhone', 'ReceiverPhone', 'receiver_phone', 'soDienThoai']) ?? '').toString(),
      note: pick(['note', 'Note', 'ghiChu'])?.toString(),
      paymentMethod: pick(['paymentMethod', 'PaymentMethod', 'phuongThucThanhToan'])?.toString(),
      paymentStatus: (pick(['paymentStatus', 'PaymentStatus', 'trangThaiThanhToan']) ?? 'unpaid').toString(),
      shippingFee: rawShip is num ? rawShip.toDouble() : double.tryParse('$rawShip') ?? 0,
      discountAmount: rawDisc is num ? rawDisc.toDouble() : double.tryParse('$rawDisc') ?? 0,
      promotionId: rawPromoId == null
          ? null
          : (rawPromoId is int ? rawPromoId : int.tryParse(rawPromoId.toString())),
      promotionTitle: rawPromoTitle?.toString(),
    );
  }
}
