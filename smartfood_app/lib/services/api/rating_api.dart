import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../models/rating.dart';
import '../ApiService.dart';

class RatingApi {
  String get _baseUrl => Constant().baseUrl;

  /// ==================== LẤY RATING THEO PRODUCT ====================
  Future<List<Rating>> getRatingsByProduct(int productId, {int? stars}) async {
    try {
      final headers = await ApiService().getHeaders();
      final uri = Uri.parse('$_baseUrl/ratings/$productId').replace(
        queryParameters: stars == null ? null : {'stars': '$stars'},
      );

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Rating.fromJson(e)).toList();
      } else {
        throw Exception('Load rating fail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getRatingsByProduct: $e');
    }
  }

  /// ==================== THỐNG KÊ ====================
  Future<RatingStats> getProductRatingStats(int productId) async {
    try {
      final headers = await ApiService().getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/ratings/stats/$productId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return RatingStats.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Load stats fail');
      }
    } catch (e) {
      throw Exception('Error get stats: $e');
    }
  }

  /// ==================== ADD / UPDATE ====================
  Future<bool> addOrUpdateRating({
    required int userId,
    required int productId,
    required int soSao,
    String? noiDung,
    int? orderId,
  }) async {
    try {
      final headers = await ApiService().getHeaders();

      final url = Uri.parse(
        '$_baseUrl/ratings'
            '?userId=$userId'
            '&productId=$productId'
            '&soSao=$soSao'
            '&noiDung=${noiDung ?? ""}'
            '${orderId != null ? '&orderId=$orderId' : ''}',
      );

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Add rating fail');
      }
    } catch (e) {
      throw Exception('Error addOrUpdateRating: $e');
    }
  }

  /// ==================== DELETE ====================
  Future<bool> deleteRating({
    required int userId,
    required int productId,
    int? orderId,
  }) async {
    try {
      final headers = await ApiService().getHeaders();

      final url = Uri.parse(
        '$_baseUrl/ratings'
            '?userId=$userId&productId=$productId'
            '${orderId != null ? '&orderId=$orderId' : ''}',
      );

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Delete fail');
      }
    } catch (e) {
      throw Exception('Error deleteRating: $e');
    }
  }

  Future<UserReviewSummary> getUserReviewSummary(int userId) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/ratings/user/$userId/summary'),
        headers: headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Load review summary fail: ${response.statusCode}');
      }
      return UserReviewSummary.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Error getUserReviewSummary: $e');
    }
  }

  Future<bool> hasReviewedOrder({
    required int userId,
    required int orderId,
  }) async {
    try {
      final headers = await ApiService().getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/ratings/check-order?userId=$userId&orderId=$orderId'),
        headers: headers,
      );
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return body['reviewed'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}