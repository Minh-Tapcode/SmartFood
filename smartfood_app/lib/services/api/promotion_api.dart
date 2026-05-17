import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfood_app/core/constants.dart';
import 'package:smartfood_app/services/ApiService.dart';

class PromotionApi {
  String get _baseUrl => Constant().baseUrl;
  static const String _savedVoucherKey = 'saved_voucher_ids';
  static const String _usedVoucherKey = 'used_voucher_ids';

  Future<int> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('user');
    if (rawUser == null || rawUser.isEmpty) return 0;
    final decoded = jsonDecode(rawUser) as Map<String, dynamic>;
    final rawId = decoded['id'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId.toString()) ?? 0;
  }

  Future<List<Map<String, dynamic>>> fetchActive() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/promotions'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception('Không tải được phiếu giảm giá (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/promotions/all'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Không tải được danh sách mã giảm giá (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> create({
    required String title,
    required double discountPercent,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/promotions'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({
        'title': title,
        'discountPercent': discountPercent,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      }),
    );
    if (res.statusCode != 200) {
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          throw Exception(body['message'].toString());
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Tạo mã giảm giá thất bại (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) return body;
    return {};
  }

  Future<Map<String, dynamic>> update({
    required int id,
    required String title,
    required double discountPercent,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/promotions/$id'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({
        'title': title,
        'discountPercent': discountPercent,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      }),
    );
    if (res.statusCode != 200) {
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          throw Exception(body['message'].toString());
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Cập nhật mã giảm giá thất bại (${res.statusCode})');
    }
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) return body;
    return {};
  }

  Future<void> delete(int id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/promotions/$id'),
      headers: await ApiService().getHeaders(),
    );
    if (res.statusCode != 200) {
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          throw Exception(body['message'].toString());
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Xóa mã giảm giá thất bại (${res.statusCode})');
    }
  }

  Future<Set<int>> getSavedVoucherIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedVoucherKey) ?? const [];
    return raw.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
  }

  Future<Set<int>> getUsedVoucherIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_usedVoucherKey) ?? const [];
    return raw.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
  }

  Future<void> saveVoucherId(int id) async {
    final usedIds = await getUsedVoucherIds();
    if (usedIds.contains(id)) {
      throw Exception('Mã này đã dùng rồi, không thể lưu lại.');
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = await getSavedVoucherIds();
    if (ids.contains(id)) {
      return;
    }
    ids.add(id);
    await prefs.setStringList(
      _savedVoucherKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> unsaveVoucherId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getSavedVoucherIds();
    ids.remove(id);
    await prefs.setStringList(
      _savedVoucherKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> markVoucherUsed(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final usedIds = await getUsedVoucherIds();
    usedIds.add(id);
    await prefs.setStringList(
      _usedVoucherKey,
      usedIds.map((e) => e.toString()).toList(),
    );
    await unsaveVoucherId(id);
  }

  /// Đồng bộ mã đã dùng từ server (nhẹ hơn tải toàn bộ đơn).
  Future<void> syncUsedVouchersFromServer() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId <= 0) return;

      final res = await http.get(
        Uri.parse('$_baseUrl/promotions/used?userId=$userId'),
        headers: await ApiService().getHeaders(),
      );
      if (res.statusCode != 200) return;

      final body = jsonDecode(res.body);
      if (body is! Map) return;
      final raw = body['promotionIds'] ?? body['PromotionIds'] ?? const [];
      final fromServer = <int>{};
      if (raw is List) {
        for (final e in raw) {
          final id = e is int ? e : int.tryParse('$e') ?? 0;
          if (id > 0) fromServer.add(id);
        }
      }
      if (fromServer.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final used = await getUsedVoucherIds();
      used.addAll(fromServer);
      await prefs.setStringList(
        _usedVoucherKey,
        used.map((e) => e.toString()).toList(),
      );

      final saved = await getSavedVoucherIds();
      saved.removeAll(used);
      await prefs.setStringList(
        _savedVoucherKey,
        saved.map((e) => e.toString()).toList(),
      );
    } catch (_) {
      // Chưa đăng nhập hoặc lỗi mạng — giữ local.
    }
  }
}
