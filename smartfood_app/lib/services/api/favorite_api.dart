import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../models/product.dart';
import '../ApiService.dart';
import '../api/product_api.dart';

class FavoriteApi {
  final ProductApi _productApi = ProductApi();

  // ===== TOGGLE =====
  Future<String> toggleFavorite(int productId) async {
    final res = await http.post(
      Uri.parse('${Constant().baseUrl}/Favorite/$productId'),
      headers: await ApiService().getHeaders(),
    );

    if (res.statusCode == 200) {
      return res.body.replaceAll('"', '').trim(); // Liked/Unliked
    } else {
      throw Exception('Toggle favorite failed: ${res.statusCode}');
    }
  }

  // ===== GET FAVORITES =====
  Future<List<Product>> getFavorites() async {
    try {
      final res = await http.get(
        Uri.parse('${Constant().baseUrl}/Favorite'),
        headers: await ApiService().getHeaders(),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        final futures = data.map((item) async {
          try {
            final product = await _productApi.getProductById(item['productId']);
            return product;
          } catch (e) {
            debugPrint('Error load product ${item['productId']}: $e');
            return null;
          }
        }).toList();
        final products = await Future.wait(futures);
        return products.whereType<Product>().toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Favorite error: $e');
      return [];
    }
  }

  Future<int> getFavoriteCount() async {
    try {
      final res = await http.get(
        Uri.parse('${Constant().baseUrl}/Favorite'),
        headers: await ApiService().getHeaders(),
      );
      if (res.statusCode != 200) return 0;
      final data = jsonDecode(res.body);
      if (data is List) return data.length;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ===== CHECK =====
  Future<bool> isFavorite(int productId) async {
    final res = await http.get(
      Uri.parse('${Constant().baseUrl}/Favorite/check/$productId'),
      headers: await ApiService().getHeaders(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) == true;
    }
    return false;
  }

  // ===== REMOVE =====
  Future<bool> removeFromFavoritesByProductId({
    required int productId,
  }) async {
    final isFav = await isFavorite(productId);
    if (!isFav) return true;

    final result = await toggleFavorite(productId);
    return result.toLowerCase().contains('unliked');
  }
}