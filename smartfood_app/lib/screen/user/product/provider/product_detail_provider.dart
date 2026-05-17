import 'package:flutter/material.dart';
import '../../../../models/product.dart';
import '../../../../models/rating.dart';
import 'product_detail_service.dart';
import 'product_detail_state.dart';

class ProductDetailProvider with ChangeNotifier {
  final ProductDetailService _service = ProductDetailService();

  ProductDetailState _state = ProductDetailState();

  ProductDetailState get state => _state;
  RatingStats get ratingStats => _state.ratingStats;
  List<Rating> get ratings => _state.ratings;
  Rating? get userRating => _state.userRating;
  bool get hasUserRated => _state.hasUserRated;
  bool get isLoadingRatings => _state.isLoadingRatings;
  Product? get product => _state.product;
  int get quantity => _state.quantity;
  bool get isFavorite => _state.isFavorite;

  // ===== LOAD PRODUCT =====
  Future<void> loadProductDetail(int productId) async {
    _setState(_state.loading());

    try {
      final product =
      await _service.getProductDetail(productId);

      if (product == null) {
        _setState(_state.error('Không tìm thấy sản phẩm'));
        return;
      }

      _setState(_state.success(product));
      await Future.wait([
        _loadRatings(productId),
        _checkFavorite(productId),
      ]);
    } catch (e) {
      _setState(_state.error(e.toString()));
    }
  }

  // ===== FAVORITE =====
  Future<void> _checkFavorite(int productId) async {
    try {
      final isFav =
      await _service.checkFavoriteStatus(productId);

      _setState(_state.toggleFavorite(isFav));
    } catch (e) {
      debugPrint('Favorite error: $e');
    }
  }

  Future<void> toggleFavorite(int productId) async {
    try {
      final newStatus = await _service.toggleFavorite(
        productId,
        _state.isFavorite,
      );

      _setState(_state.toggleFavorite(newStatus));
    } catch (e) {
      rethrow;
    }
  }

  // ===== RATING =====
  Future<void> _loadRatings(int productId) async {
    _setState(_state.loadingRatings());

    try {
      final stats = await _service.getRatingStats(productId);
      final ratings = await _service.getRatingsByProduct(productId);
      final userRating = await _service.getUserRating(productId);

      _setState(
        _state.ratingsSuccess(
          ratingStats: stats,
          ratings: ratings,
          userRating: userRating,
        ),
      );
    } catch (e) {
      _setState(_state.ratingsError());
    }
  }

  Future<bool> submitRating(Rating rating) async {
    try {
      final success = await _service.submitRating(rating);

      if (success) {
        await _loadRatings(rating.productId);
      }

      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteRating(int productId) async {
    try {
      final success = await _service.deleteRating(productId);

      if (success) {
        _setState(_state.removeUserRating());
        await _loadRatings(productId);
      }

      return success;
    } catch (e) {
      rethrow;
    }
  }

  // ===== CART =====
  Future<void> addToCart(int userId) async {
    if (_state.product == null) return;
    await _service.addToCart(
      userId,
      _state.product!.id,
      _state.quantity,
    );
  }

  // ===== QUANTITY =====
  void increaseQuantity() {
    if (_state.product != null &&
        _state.quantity < _state.product!.stock) {
      _setState(_state.updateQuantity(_state.quantity + 1));
    }
  }

  void decreaseQuantity() {
    if (_state.quantity > 1) {
      _setState(_state.updateQuantity(_state.quantity - 1));
    }
  }

  // ===== CORE =====
  void _setState(ProductDetailState newState) {
    _state = newState;
    notifyListeners();
  }

  bool get isOutOfStock => product!.stock <= 0;
  bool get isLowStock => (product?.stock ?? 0) < 10 && (product?.stock ?? 0) > 0;
}