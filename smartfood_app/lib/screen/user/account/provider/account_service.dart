import '../../../../services/api/auth_api.dart';
import '../../../../services/api/favorite_api.dart';
import '../../../../services/api/order_api.dart';

class AccountService {
  final AuthApi _userApi = AuthApi();
  final OrderApi _orderApi = OrderApi();
  final FavoriteApi _favoriteApi = FavoriteApi();

  // User methods
  Future<bool> isLoggedIn() async {
    return await _userApi.isLoggedIn();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return await _userApi.getUserInfo();
  }

  Future<bool> logout() async {
    await _userApi.logout();
    return true;
  }

  Future<int> getOrderCount() async {
    return await _orderApi.getOrderCount();
  }

  Future<int> getFavoriteCount() async {
    return await _favoriteApi.getFavoriteCount();
  }

  Future<List<Map<String, dynamic>>> getPurchasedProducts() async {
    await Future.delayed(const Duration(seconds: 1)); // Giả lập delay

    return [
      {
        'maSanPham': 'SP001',
        'tenSanPham': 'iPhone 14 Pro Max',
        'anh': 'https://example.com/iphone14.jpg'
      },
      {
        'maSanPham': 'SP002',
        'tenSanPham': 'Samsung Galaxy S23',
        'anh': 'https://example.com/galaxy-s23.jpg'
      },
      {
        'maSanPham': 'SP003',
        'tenSanPham': 'MacBook Air M2',
        'anh': 'https://example.com/macbook-air.jpg'
      },
    ];
  }
}