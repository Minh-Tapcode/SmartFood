import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartfood_app/core/constants.dart';
import 'package:smartfood_app/services/ApiService.dart';

class AdminUserService {
  String get _baseUrl => Constant().baseUrl;

  Future<List<Map<String, dynamic>>> getUsers() async {
    final page = await getUsersPaged(page: 1, pageSize: 500);
    return page.items;
  }

  Future<({List<Map<String, dynamic>> items, int totalCount, bool hasMore})>
      getUsersPaged({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final q = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (search != null && search.trim().isNotEmpty) {
      q['search'] = search.trim();
    }
    final uri = Uri.parse('$_baseUrl/Auth/all').replace(queryParameters: q);
    final res = await http.get(uri, headers: await ApiService().getHeaders());
    if (res.statusCode != 200) {
      throw Exception('Không tải được danh sách user (${res.statusCode})');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final rawItems = map['items'] ?? map['Items'] ?? const [];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      final total = map['totalCount'] ?? map['TotalCount'] ?? items.length;
      final hasMore = map['hasMore'] ?? map['HasMore'] ?? false;
      return (
        items: items,
        totalCount: total is int ? total : int.tryParse('$total') ?? items.length,
        hasMore: hasMore == true,
      );
    }
    if (decoded is List) {
      final items = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return (items: items, totalCount: items.length, hasMore: false);
    }
    return (items: <Map<String, dynamic>>[], totalCount: 0, hasMore: false);
  }

  Future<List<Map<String, dynamic>>> getOrdersByUser(int userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders?userId=$userId'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Không tải được đơn của user ($userId)');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Không tải được chi tiết đơn ($orderId)');
    }
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<Map<String, dynamic>> getUserPurchaseInsights(int userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders/user/$userId/insights'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception(
          'Không tải được thống kê mua hàng ($userId): ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data is! Map) return {};
    final map = Map<String, dynamic>.from(data);

    final topRaw = map['topProducts'] ?? map['TopProducts'] ?? const [];
    final topProducts = topRaw is List
        ? topRaw
            .whereType<Map>()
            .map((e) => {
                  'name': (e['name'] ?? e['Name'] ?? 'Sản phẩm').toString(),
                  'quantity': e['quantity'] ?? e['Quantity'] ?? 0,
                })
            .toList()
        : <Map<String, dynamic>>[];

    final ordersRaw = map['orders'] ?? map['Orders'] ?? const [];
    final orders = ordersRaw is List
        ? ordersRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final lastAt = map['lastOrderAt'] ?? map['LastOrderAt'];
    return {
      'orders': orders,
      'totalOrders': map['totalOrders'] ?? map['TotalOrders'] ?? orders.length,
      'totalSpent': map['totalSpent'] ?? map['TotalSpent'] ?? 0,
      'lastOrderAt': lastAt?.toString(),
      'topProducts': topProducts,
    };
  }
}
