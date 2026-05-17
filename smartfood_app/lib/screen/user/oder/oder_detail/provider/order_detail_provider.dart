import 'package:flutter/material.dart';
import 'package:smartfood_app/models/order.dart';
import 'package:smartfood_app/models/order_detail.dart';
import 'package:smartfood_app/utils/order_status_helpers.dart';

import 'order_detail_service.dart';
import 'order_detail_state.dart';

class OrderDetailProvider with ChangeNotifier {
  final OrderDetailService _orderDetailService = OrderDetailService();
  OrderDetailState _state = const OrderDetailState();
  bool _isCancellingOrder = false;

  // Getters
  OrderDetailState get state => _state;
  Order? get order => _state.order;
  List<OrderDetail> get orderDetails => _state.orderDetails;
  bool get isLoading => _state.isLoading;
  bool get isCancellingOrder => _isCancellingOrder;
  String get errorMessage => _state.errorMessage;
  double get totalAmount => _state.totalAmount;

  double get itemsSubtotal => orderDetails.fold<double>(
        0,
        (sum, d) => sum + d.giaBan * d.soLuong,
      );

  double get orderShippingFee => order?.shippingFee ?? 0;

  double get orderDiscountAmount => order?.discountAmount ?? 0;

  String? get orderPromotionTitle => order?.promotionTitle;

  /// Phí ship từ API; nếu = 0 nhưng tổng đơn ≠ tổng hàng − giảm thì suy ra phần chênh (dữ liệu cũ / cột thiếu).
  double get displayShippingFee {
    final o = order;
    if (o == null) return 0;
    final explicit = o.shippingFee;
    if (explicit > 0.01) return explicit;
    final sub = itemsSubtotal;
    final implied = o.totalPrice - sub + o.discountAmount;
    if (implied > 0.01) return implied;
    return 0;
  }

  bool get hasPromotionMeta {
    final o = order;
    if (o == null) return false;
    final title = o.promotionTitle?.trim();
    if (title != null && title.isNotEmpty) return true;
    final id = o.promotionId;
    return id != null && id > 0;
  }

  bool get showDiscountRow =>
      orderDiscountAmount > 0.01 || hasPromotionMeta;

  /// Đổi COD/VNPay chỉ khi đơn còn chờ xác nhận (pending).
  bool get canChangePaymentMethod {
    final o = order;
    if (o == null) return false;
    if (o.trangThaiThanhToan.toLowerCase() == 'paid') return false;
    return normalizeFulfillmentStatus(o.trangThai) == 'pending';
  }

  // Methods
  Future<void> loadOrderDetail(String orderId) async {
    _updateState(_state.loading());

    final result = await _orderDetailService.getOrderDetail(orderId);

    if (result['error'] != null) {
      _updateState(_state.error(result['error']));
    } else {
      _updateState(_state.success(
        order: result['order'],
        orderDetails: result['orderDetails'],
        totalAmount: result['totalAmount'],
      ));
    }
  }

  void retryLoading(String orderId) {
    loadOrderDetail(orderId);
  }

  /// Hủy đơn khi backend cho phép (pending). Trả về null nếu thành công.
  Future<String?> cancelOrderIfPending(String orderId) async {
    _isCancellingOrder = true;
    notifyListeners();
    try {
      final err = await _orderDetailService.cancelOrderAsUser(orderId);
      if (err == null) {
        await loadOrderDetail(orderId);
      }
      return err;
    } finally {
      _isCancellingOrder = false;
      notifyListeners();
    }
  }

  void clearError() {
    _updateState(_state.clearError());
  }

  // Private method
  void _updateState(OrderDetailState newState) {
    _state = newState;
    notifyListeners();
  }

  // Helper methods — backend dùng pending / processing / shipping / completed (+ legacy)

  String getFulfillmentDisplayLabel(String raw) => fulfillmentDisplayLabel(raw);

  int getFulfillmentStepIndex(String raw) => fulfillmentStepIndex(raw);

  String getPaymentDisplayLabel(String raw) => paymentDisplayLabel(raw);

  String getStatusText(String status) => fulfillmentDisplayLabel(status);

  Color getStatusColor(String status) => fulfillmentStatusColor(status);

  IconData getStatusIcon(String status) => fulfillmentStatusIcon(status);

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  String formatDate(DateTime date) {
    return '${date.day} Th${date.month}, ${date.year}';
  }

  String formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}