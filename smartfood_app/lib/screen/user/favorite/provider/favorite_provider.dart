import 'package:flutter/foundation.dart';

import '../../../../models/product.dart';
import 'favorite_service.dart';
import 'favorite_state.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteService _service = FavoriteService();
  FavoriteState _state = FavoriteState(
    favoriteProducts: [],
    isLoading: true,
    isLoggedIn: false,
  );

  // Getters
  FavoriteState get state => _state;
  List<Product> get favoriteProducts => _state.favoriteProducts;
  bool get isLoading => _state.isLoading;
  bool get isLoggedIn => _state.isLoggedIn;
  bool get hasError => _state.error != null;
  String? get error => _state.error;
  bool get isEmpty => _state.favoriteProducts.isEmpty;
  int? get currentUserId => _state.currentUserId;

  // State management methods
  void _updateState(FavoriteState newState) {
    _state = newState;
    notifyListeners();
  }

  // Business logic methods
  Future<void> initialize() async {
    try {
      _updateState(_state.loading());
      final isLoggedIn = await _service.checkLoginStatus();
      final userId = isLoggedIn ? await _service.getCurrentUserId() : null;
      _updateState(_state.loggedIn(isLoggedIn, userId));

      if (isLoggedIn && userId != null) {
        await loadFavorites();
      } else {
        _updateState(_state.copyWith(isLoading: false));
      }
    } catch (e) {
      _updateState(_state.errorState('Lỗi khởi tạo: $e'));
    }
  }

  Future<void> loadFavorites() async {
    try {
      _updateState(_state.loading());
      final favorites = await _service.loadFavorites();
      _updateState(_state.success(favorites));
    } catch (e) {
      _updateState(_state.errorState('Lỗi tải danh sách yêu thích: $e'));
    }
  }

  Future<void> removeFromFavorites(Product product) async {
    try {
      final success = await _service.removeFromFavorites(product.id);

      if (success) {
        final updatedFavorites = List<Product>.from(_state.favoriteProducts)
          ..removeWhere((p) => p.id == product.id);
        _updateState(_state.success(updatedFavorites));
      } else {
        throw Exception('Không thể xóa khỏi danh sách yêu thích');
      }
    } catch (e) {
      _updateState(_state.errorState('Lỗi xóa sản phẩm: $e'));
      rethrow;
    }
  }

  void clearError() {
    _updateState(_state.copyWith(error: null));
  }

  // Helper methods
  String formatPrice(double price) {
    return _service.formatPrice(price);
  }

  bool isProductInFavorites(String productId) {
    return _state.favoriteProducts.any((product) => product.id.toString() == productId);
  }

  void addProductToFavorites(Product product) {
    if (!isProductInFavorites(product.id.toString())) {
      final updatedFavorites = List<Product>.from(_state.favoriteProducts)..add(product);
      _updateState(_state.success(updatedFavorites));
    }
  }

  Future<void> addToCart(Product product, int quantity) async {
    final userId = _state.currentUserId;
    if (userId == null) {
      throw Exception('Bạn cần đăng nhập để thêm vào giỏ hàng');
    }
    if (quantity <= 0) {
      throw Exception('Số lượng không hợp lệ');
    }
    if (product.stock <= 0) {
      throw Exception('Sản phẩm đã hết hàng');
    }
    if (quantity > product.stock) {
      throw Exception('Số lượng vượt quá tồn kho');
    }

    await _service.addToCart(
      userId: userId,
      productId: product.id,
      quantity: quantity,
    );
  }
}