import 'package:smartfood_app/models/order.dart';
import 'package:smartfood_app/services/api/order_api.dart';

class OrderListService {
  final OrderApi _orderApi = OrderApi();

  Future<List<Order>> getOrdersByUser() async {
    try {
      final orders = await _orderApi.getOrdersByUser();
      return orders;
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách đơn hàng: $e');
    }
  }
}