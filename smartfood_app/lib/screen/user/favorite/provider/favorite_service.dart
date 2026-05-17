import '../../../../models/product.dart';
import '../../../../services/api/auth_api.dart';
import '../../../../services/api/cart_api.dart';
import '../../../../services/api/favorite_api.dart';

class FavoriteService {
  final FavoriteApi _favoriteApi = FavoriteApi();
  final AuthApi _authApi = AuthApi();
  final CartApi _cartApi = CartApi();

  // Check login status
  Future<bool> checkLoginStatus() async {
    try {
      return await _authApi.isLoggedIn();
    } catch (e) {
      throw Exception('Lỗi kiểm tra trạng thái đăng nhập: $e');
    }
  }

  Future<int?> getCurrentUserId() async {
    try {
      final user = await _authApi.getCurrentUser();
      return user?.id;
    } catch (_) {
      return null;
    }
  }

  // Load favorites
  Future<List<Product>> loadFavorites() async {
    try {
      return await _favoriteApi.getFavorites();
    } catch (e) {
      throw Exception('Lỗi tải danh sách yêu thích: $e');
    }
  }

  // Remove from favorites
  Future<bool> removeFromFavorites(int productId) async {
    try {
      return await _favoriteApi.removeFromFavoritesByProductId(
        productId: productId,
      );
    } catch (e) {
      throw Exception('Lỗi xóa khỏi danh sách yêu thích: $e');
    }
  }

  // Add to cart
  Future<void> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    await _cartApi.addToCart(userId, productId, quantity);
  }

  // Format price
  String formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }
}