import 'package:smartfood_app/models/order.dart';
import 'package:smartfood_app/models/order_detail.dart';
import 'package:smartfood_app/services/api/order_api.dart';

class OrderDetailService {
  final OrderApi _orderApi = OrderApi();

  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final data = await _orderApi.getOrderDetail(orderId);
      final nested = data['order'] ?? data['Order'];
      final Map<String, dynamic> orderJson = nested is Map<String, dynamic>
          ? nested
          : nested is Map
              ? Map<String, dynamic>.from(nested)
              : Map<String, dynamic>.from(data);
      final detailsJson = (data['orderDetails'] ?? data['OrderDetails'] ?? const []) as List;

      final order = Order.fromJson(orderJson);
      final orderDetails = detailsJson
          .map((e) => OrderDetail.fromJson(e))
          .toList();

      final calculatedFromItems = _calculateTotalAmount(orderDetails);
      final totalAmount = order.totalPrice > 0 ? order.totalPrice : calculatedFromItems;

      return {
        'order': order,
        'orderDetails': orderDetails,
        'totalAmount': totalAmount,
        'error': null,
      };
    } catch (e) {
      return {
        'order': null,
        'orderDetails': [],
        'totalAmount': 0.0,
        'error': 'Lỗi khi tải chi tiết đơn hàng: $e',
      };
    }
  }

  double _calculateTotalAmount(List<OrderDetail> orderDetails) {
    double total = 0.0;
    for (var detail in orderDetails) {
      total += detail.giaBan * detail.soLuong;
    }
    return total;
  }

  /// null = thành công; chuỗi = lỗi hiển thị cho user.
  Future<String?> cancelOrderAsUser(String orderId) async {
    try {
      final id = int.tryParse(orderId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (id <= 0) return 'Mã đơn không hợp lệ';
      await _orderApi.cancelOrderAsUser(id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
