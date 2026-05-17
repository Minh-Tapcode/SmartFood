import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartfood_app/core/constants.dart';
import 'package:smartfood_app/screen/admin/dashboard/models/admin_dashboard_data.dart';
import 'package:smartfood_app/services/ApiService.dart';

class AdminDashboardService {
  String get _baseUrl => Constant().baseUrl;

  Future<AdminDashboardData> fetchDashboardData() async {
    final headers = await ApiService().getHeaders();

    final results = await Future.wait([
      http.get(Uri.parse('$_baseUrl/Product'), headers: headers),
      http.get(Uri.parse('$_baseUrl/orders'), headers: headers),
      http.get(Uri.parse('$_baseUrl/Auth/all?page=1&pageSize=1'), headers: headers),
    ]);

    final productRes = results[0];
    final orderRes = results[1];
    final userRes = results[2];

    if (productRes.statusCode != 200) {
      throw Exception('Không tải được sản phẩm (${productRes.statusCode})');
    }
    if (orderRes.statusCode != 200) {
      throw Exception('Không tải được đơn hàng (${orderRes.statusCode})');
    }
    if (userRes.statusCode != 200) {
      throw Exception('Không tải được người dùng (${userRes.statusCode})');
    }

    final productsRaw = _asList(jsonDecode(productRes.body));
    final ordersRaw = _asList(jsonDecode(orderRes.body));
    final usersDecoded = jsonDecode(userRes.body);
    final usersRaw = usersDecoded is Map
        ? _asList(usersDecoded['items'] ?? usersDecoded['Items'])
        : _asList(usersDecoded);
    final totalUsers = usersDecoded is Map
        ? _toInt(usersDecoded['totalCount'] ?? usersDecoded['TotalCount'])
        : usersRaw.length;

    final pendingOrders = ordersRaw.where((o) {
      final status =
          (o['status'] ?? o['Status'] ?? '').toString().toLowerCase();
      return status == 'pending' || status.contains('chờ');
    }).length;

    final lowStockList = productsRaw.where((p) {
      final stock = _toInt(p['stock'] ?? p['Stock']);
      return stock <= 10;
    }).toList();

    double revenue = 0;
    for (final order in ordersRaw) {
      revenue += _toDouble(order['totalPrice'] ?? order['TotalPrice']);
    }

    final latestOrders = [...ordersRaw]..sort((a, b) {
        final dateA = DateTime.tryParse(
            (a['createdAt'] ?? a['CreatedAt'] ?? '').toString());
        final dateB = DateTime.tryParse(
            (b['createdAt'] ?? b['CreatedAt'] ?? '').toString());
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

    return AdminDashboardData(
      totalProducts: productsRaw.length,
      totalOrders: ordersRaw.length,
      totalUsers: totalUsers > 0 ? totalUsers : usersRaw.length,
      pendingOrders: pendingOrders,
      lowStockProducts: lowStockList.length,
      totalRevenue: revenue,
      latestOrders: latestOrders.take(6).toList(),
      lowStockItems: lowStockList.take(6).toList(),
    );
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
