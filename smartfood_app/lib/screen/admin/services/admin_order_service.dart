import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartfood_app/core/constants.dart';
import 'package:smartfood_app/services/ApiService.dart';

class AdminOrderService {
  String get _baseUrl => Constant().baseUrl;

  Future<List<Map<String, dynamic>>> getOrders() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Không tải được danh sách đơn (${res.statusCode})');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/orders/$orderId/status'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({'status': status}),
    );
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Không tải được chi tiết đơn hàng');
    }
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<Map<String, dynamic>> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();
    final uri = Uri.parse('$_baseUrl/orders/statistics/summary')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: await ApiService().getHeaders());
    if (res.statusCode != 200) {
      throw Exception('Không tải được thống kê tổng quan');
    }
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<List<Map<String, dynamic>>> getRevenueByDay({int days = 7}) async {
    final uri = Uri.parse('$_baseUrl/orders/statistics/by-day')
        .replace(queryParameters: {'days': '$days'});
    final res = await http.get(uri, headers: await ApiService().getHeaders());
    if (res.statusCode != 200) {
      throw Exception('Không tải được thống kê theo ngày');
    }
    final data = jsonDecode(res.body);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Khoảng ngày tùy ý (tối đa ~366 ngày phía server). Ưu tiên hơn [getRevenueByDay].
  Future<List<Map<String, dynamic>>> getRevenueByDayRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final query = <String, String>{
      'startDate':
          DateTime(startDate.year, startDate.month, startDate.day).toIso8601String(),
      'endDate':
          DateTime(endDate.year, endDate.month, endDate.day).toIso8601String(),
    };
    final uri = Uri.parse('$_baseUrl/orders/statistics/by-day')
        .replace(queryParameters: query);
    final res = await http.get(uri, headers: await ApiService().getHeaders());
    if (res.statusCode != 200) {
      throw Exception('Không tải được thống kê theo ngày');
    }
    final data = jsonDecode(res.body);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRevenueByMonth({int? year}) async {
    final y = year ?? DateTime.now().year;
    final uri = Uri.parse('$_baseUrl/orders/statistics/by-month')
        .replace(queryParameters: {'year': '$y'});
    final res = await http.get(uri, headers: await ApiService().getHeaders());
    if (res.statusCode != 200) {
      throw Exception('Không tải được thống kê theo tháng');
    }
    final data = jsonDecode(res.body);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRevenueByYear() async {
    final uri = Uri.parse('$_baseUrl/orders/statistics/by-year');
    final res = await http.get(uri, headers: await ApiService().getHeaders());
    if (res.statusCode != 200) {
      throw Exception('Không tải được thống kê theo năm');
    }
    final data = jsonDecode(res.body);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
