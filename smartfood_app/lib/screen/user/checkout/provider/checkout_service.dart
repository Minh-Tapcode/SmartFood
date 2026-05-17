import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants.dart';
import '../../../../services/ApiService.dart';
import '../../../../services/api/auth_api.dart';

class CheckoutService {
  final AuthApi _authApi = AuthApi();

  Future<int?> getCurrentUserId() async {
    final user = await _authApi.getCurrentUser();
    return user?.id;
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final user = await _authApi.getCurrentUser();
    if (user == null) return null;
    return {
      'name': user.name,
      'phone': user.phone ?? '',
    };
  }

  Future<Map<String, dynamic>> createOrder({
    required int userId,
    required String receiverName,
    required String receiverPhone,
    required String address,
    required String note,
    required String paymentMethod,
    required double shippingFee,
    required double discountAmount,
    required double finalAmount,
    required List<int> cartItemIds,
    int? promotionId,
  }) async {
    final res = await http.post(
      Uri.parse('${Constant().baseUrl}/orders?userId=$userId'),
      headers: await ApiService().getHeaders(),
      body: jsonEncode({
        'address': address,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'note': note,
        'paymentMethod': paymentMethod, // COD | VNPAY
        'shippingFee': shippingFee,
        'discountAmount': discountAmount,
        'finalAmount': finalAmount,
        'cartItemIds': cartItemIds,
        if (promotionId != null) 'promotionId': promotionId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Tạo đơn hàng thất bại: ${res.statusCode} - ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'raw': data};
  }

  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}