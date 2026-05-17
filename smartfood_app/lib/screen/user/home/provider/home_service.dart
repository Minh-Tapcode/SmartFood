import 'package:smartfood_app/services/api/auth_api.dart';

import '../../../../models/category.dart';
import '../../../../models/product.dart';
import '../../../../services/api/cart_api.dart';
import '../../../../services/api/category_api.dart';
import '../../../../services/api/favorite_api.dart';
import '../../../../services/api/product_api.dart';

class HomeService {
  final CategoryApi _categoryApi = CategoryApi();
  final ProductApi _productApi = ProductApi();
  final FavoriteApi _favoriteApi = FavoriteApi();
  final CartApi _cartApi = CartApi();
  final AuthApi _userApi = AuthApi();

  // ===== CATEGORY =====
  Future<List<Category>> getCategories() async {
    return await _categoryApi.getCategories();
  }

  // ===== PRODUCT =====
  Future<List<Product>> getProducts() async {
    return await _productApi.getProducts();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    if (categoryId == 'all') {
      return await _productApi.getProducts();
    }
    return await _categoryApi.getProductsByCategory(categoryId);
  }

  Future<List<Product>> searchProducts(String keyword) async {
    return await _productApi.searchProducts(keyword);
  }

  // ===== FAVORITE =====
  Future<List<Product>> getFavorites() async {
    return await _favoriteApi.getFavorites();
  }

  Future<String> toggleFavorite(int productId) async {
    return await _favoriteApi.toggleFavorite(productId);
  }

  // ===== CART =====
  Future<void> addToCart(int userId, int productId, int quantity) async {
    await _cartApi.addToCart(userId, productId, quantity);
  }

  // ===== USER =====
  Future<bool> isLoggedIn() async {
    return await _userApi.isLoggedIn();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return await _userApi.getUserInfo();
  }
}