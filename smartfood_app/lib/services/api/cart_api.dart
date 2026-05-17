import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../models/cart_item.dart';
import '../ApiService.dart';

class CartApi {
  Exception _errorFromResponse(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        return Exception(decoded['message'].toString());
      }
    } catch (_) {}
    return Exception('$fallback (${res.statusCode}): ${res.body}');
  }

  // ===== GET CART =====
  Future<List<CartItem>> getCart(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('${Constant().baseUrl}/cart/$userId'),
        headers: await ApiService().getHeaders(),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => CartItem.fromJson(e)).toList();
      } else {
        throw Exception('Load cart failed: ${res.body}');
      }
    } catch (e) {
      throw Exception('Error getCart: $e');
    }
  }

  // ===== ADD =====
  Future<void> addToCart(int userId, int productId, int quantity) async {
    try {
      final res = await http.post(
        Uri.parse('${Constant().baseUrl}/cart/add?userId=$userId'),
        headers: await ApiService().getHeaders(),
        body: jsonEncode({
          "productId": productId,
          "quantity": quantity,
        }),
      );

      if (res.statusCode != 200) {
        throw _errorFromResponse(res, 'Không thêm được vào giỏ hàng');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error addToCart: $e');
    }
  }

  // ===== UPDATE =====
  Future<void> updateCart(int cartItemId, int quantity) async {
    try {
      final res = await http.put(
        Uri.parse('${Constant().baseUrl}/cart/update'),
        headers: await ApiService().getHeaders(),
        body: jsonEncode({
          "cartItemId": cartItemId,
          "quantity": quantity,
        }),
      );

      if (res.statusCode != 200) {
        throw _errorFromResponse(res, 'Không cập nhật được giỏ hàng');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error updateCart: $e');
    }
  }

  // ===== DELETE =====
  Future<bool> deleteCartItem(int cartItemId) async {
    try {
      final res = await http.delete(
        Uri.parse('${Constant().baseUrl}/cart/$cartItemId'),
        headers: await ApiService().getHeaders(),
      );

      return res.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleteCartItem: $e');
    }
  }
}