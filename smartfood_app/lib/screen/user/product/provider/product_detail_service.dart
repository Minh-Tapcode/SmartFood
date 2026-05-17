import '../../../../models/product.dart';
import '../../../../models/rating.dart';
import '../../../../services/api/auth_api.dart';
import '../../../../services/api/cart_api.dart';
import '../../../../services/api/favorite_api.dart';
import '../../../../services/api/product_api.dart';
import '../../../../services/api/rating_api.dart';

class ProductDetailService {
  final ProductApi _productApi = ProductApi();
  final FavoriteApi _favoriteApi = FavoriteApi();
  final CartApi _cartApi = CartApi();
  final RatingApi _ratingApi = RatingApi();
  final AuthApi _userApi = AuthApi();

  /// ================= PRODUCT =================
  Future<Product?> getProductDetail(int productId) async {
    try {
      return await _productApi.getProductById(productId);
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết sản phẩm: $e');
    }
  }

  /// ================= FAVORITE =================
  Future<bool> checkFavoriteStatus(int productId) async {
    try {
      final isLoggedIn = await _userApi.isLoggedIn();
      if (!isLoggedIn) return false;

      return await _favoriteApi.isFavorite(productId);
    } catch (e) {
      throw Exception('Lỗi kiểm tra trạng thái yêu thích: $e');
    }
  }

  Future<bool> toggleFavorite(int productId, bool currentStatus) async {
    try {
      final isLoggedIn = await _userApi.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Vui lòng đăng nhập');
      }

      final result = await _favoriteApi.toggleFavorite(productId);
      final normalized = result.trim().toLowerCase();

      if (normalized.contains('unliked')) return false;
      if (normalized.contains('liked')) return true;

      // Fallback khi backend trả text khác.
      return !currentStatus;
    } catch (e) {
      throw Exception('Lỗi toggle favorite: $e');
    }
  }

  /// ================= CART =================
  Future<void> addToCart(int userId, int productId, int quantity) async {
    await _cartApi.addToCart(userId, productId, quantity);
  }

  /// ================= RATING =================
  Future<RatingStats> getRatingStats(int productId) async {
    return await _ratingApi.getProductRatingStats(productId);
  }

  Future<List<Rating>> getRatingsByProduct(int productId) async {
    return await _ratingApi.getRatingsByProduct(productId);
  }

  Future<Rating?> getUserRating(int productId) async {
    final user = await _userApi.getCurrentUser();
    if (user == null) return null;

    final ratings = await _ratingApi.getRatingsByProduct(productId);

    try {
      return ratings.firstWhere((r) => r.userId == user.id);
    } catch (_) {
      return null; // tránh crash Bad state
    }
  }

  /// ⭐ QUAN TRỌNG: chỉ dùng 1 API
  Future<bool> submitRating(Rating rating) async {
    try {
      final user = await _userApi.getCurrentUser();
      if (user == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      return await _ratingApi.addOrUpdateRating(
        userId: user.id,
        productId: rating.productId,
        soSao: rating.soSao,
        noiDung: rating.noiDung,
      );
    } catch (e) {
      throw Exception('Lỗi gửi rating: $e');
    }
  }

  Future<bool> deleteRating(int productId) async {
    try {
      final user = await _userApi.getCurrentUser();
      if (user == null) {
        throw Exception('Chưa đăng nhập');
      }

      return await _ratingApi.deleteRating(
        userId: user.id,
        productId: productId,
      );
    } catch (e) {
      throw Exception('Lỗi xoá rating: $e');
    }
  }

  /// ================= AUTH =================
  Future<bool> isUserLoggedIn() async {
    return await _userApi.isLoggedIn();
  }
}