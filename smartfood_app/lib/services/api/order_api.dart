import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood_app/core/constants.dart';
import 'package:smartfood_app/models/order.dart';
import 'package:smartfood_app/services/ApiService.dart';

class OrderApi {
  String get _baseUrl => Constant().baseUrl;

  Future<int> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('user');
    if (rawUser == null || rawUser.isEmpty) {
      throw Exception('Bạn chưa đăng nhập');
    }

    final decoded = jsonDecode(rawUser) as Map<String, dynamic>;
    final rawId = decoded['id'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId.toString()) ?? 0;
  }

  Future<List<Order>> getOrdersByUser() async {
    final userId = await _getCurrentUserId();
    final url = Uri.parse('$_baseUrl/orders?userId=$userId');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Tải đơn hàng thất bại: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body is! List) return const [];
    return body.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    final id = orderId.replaceAll(RegExp(r'[^0-9]'), '');

    final url = Uri.parse('$_baseUrl/orders/$id');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode != 200) {
      throw Exception('Tải chi tiết đơn hàng thất bại: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);

    if (body is! Map<String, dynamic>) {
      throw Exception('Dữ liệu chi tiết đơn hàng không hợp lệ');
    }
    return body;
  }

  Future<int> getOrderCount() async {
    final orders = await getOrdersByUser();
    return orders.length;
  }

  Future<String?> getVnpayPaymentUrl(int orderId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/payment/vnpay/$orderId'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Không tạo được link thanh toán VNPay (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return (body['paymentUrl'] ?? body['PaymentUrl'])?.toString();
    }
    return null;
  }

  /// Hủy đơn khi còn chờ xác nhận (pending). Backend hoàn tồn kho.
  Future<void> cancelOrderAsUser(int orderId) async {
    if (orderId <= 0) {
      throw Exception('Mã đơn không hợp lệ');
    }
    final userId = await _getCurrentUserId();
    final res = await http.put(
      Uri.parse('$_baseUrl/orders/$orderId/cancel?userId=$userId'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Hủy đơn thất bại (${res.statusCode})');
    }
  }

  Future<void> changePaymentMethod(int orderId, String method) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/payment/method/$orderId'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({'method': method}),
    );
    if (res.statusCode != 200) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Đổi phương thức thanh toán thất bại (${res.statusCode})');
    }
  }
}
