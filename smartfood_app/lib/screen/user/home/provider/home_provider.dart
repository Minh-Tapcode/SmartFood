import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../models/product.dart';
import 'home_service.dart';
import 'home_states.dart';

class HomeProvider with ChangeNotifier {
  final HomeService _homeService = HomeService();

  HomeState _state = const HomeState();
  HomeState get state => _state;

  int _currentBanner = 0;
  int get currentBanner => _currentBanner;

  void setCurrentBanner(int index) {
    _currentBanner = index;
    notifyListeners();
  }
  // ===== RESET SEARCH =====
  void resetSearch() {
    _state = _state.copyWith(
      filteredProducts: _state.products, // show all products again
      isSearching: false,
      searchKeyword: '',
    );
    notifyListeners();
  }
  // ===== INIT =====
  Future<void> initializeData() async {
    await Future.wait([
      fetchCategories(),
      fetchProducts(),
      _loadFavorites(),
    ]);
  }

  // ===== CATEGORY =====
  Future<void> fetchCategories() async {
    try {
      final categories = await _homeService.getCategories();

      _state = _state.copyWith(
        categories: categories,
        isLoadingCategories: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoadingCategories: false);
      notifyListeners();
    }
  }

  // ===== PRODUCT =====
  Future<void> fetchProducts() async {
    try {
      final products = await _homeService.getProducts();

      _state = _state.copyWith(
        products: products,
        filteredProducts: products,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> fetchProductsByCategory(String categoryId) async {
    // reset trạng thái tìm kiếm
    _state = _state.copyWith(
      isLoading: true,
      selectedCategoryId: categoryId,
      searchKeyword: '',
    );
    notifyListeners();

    // Nếu chọn "Tất cả" → hiển thị lại toàn bộ danh sách đã load
    if (categoryId == 'all') {
      _state = _state.copyWith(
        filteredProducts: _state.products,
        isLoading: false,
      );
      notifyListeners();
      return;
    }

    // Tìm tên danh mục tương ứng để lọc theo name (do Product chỉ có categoryName)
    var selectedCategoryName = '';
    for (final c in _state.categories) {
      if (c.id.toString() == categoryId) {
        selectedCategoryName = c.name;
        break;
      }
    }

    if (selectedCategoryName.isEmpty) {
      _state = _state.copyWith(
        filteredProducts: _state.products,
        isLoading: false,
      );
      notifyListeners();
      return;
    }

    final filtered = _state.products
        .where((p) => p.categoryName == selectedCategoryName)
        .toList();

    _state = _state.copyWith(
      filteredProducts: filtered,
      isLoading: false,
    );
    notifyListeners();
  }

  // ===== SEARCH =====
  Future<void> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      _state = _state.copyWith(
        filteredProducts: _state.products,
        isSearching: false,
        searchKeyword: '',
      );
      notifyListeners();
      return;
    }

    // đánh dấu đang tìm kiếm
    _state = _state.copyWith(
      isSearching: true,
      searchKeyword: keyword,
    );
    notifyListeners();

    try {
      // Gọi API search
      final results = await _homeService.searchProducts(keyword);

      _state = _state.copyWith(
        filteredProducts: results,
        isSearching: false,
      );
      notifyListeners();
    } catch (e) {
      // Nếu API lỗi, fallback sang lọc local để UX không bị trống
      final lower = keyword.toLowerCase();
      final localResults = _state.products.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.origin.toLowerCase().contains(lower) ||
            p.categoryName.toLowerCase().contains(lower);
      }).toList();

      _state = _state.copyWith(
        filteredProducts: localResults,
        isSearching: false,
      );
      notifyListeners();
    }
  }

  // ===== FAVORITE =====
  Future<void> _loadFavorites() async {
    try {
      final isLoggedIn = await _homeService.isLoggedIn();
      if (!isLoggedIn) return;

      final user = await _homeService.getUserInfo();
      final userId = user['id'];

      final favorites = await _homeService.getFavorites();

      final favoriteIds =
      favorites.map((p) => p.id.toString()).toSet();

      _state = _state.copyWith(
        userId: userId,
        favoriteProductIds: favoriteIds,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error load favorites: $e');
    }
  }

  Future<void> toggleFavorite(Product product) async {
    try {
      final isLoggedIn = await _homeService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Vui lòng đăng nhập');
      }

      final user = await _homeService.getUserInfo();
      final userId = user['id'];

      final result = await _homeService.toggleFavorite(product.id);

      final newSet = Set<String>.from(_state.favoriteProductIds);
      final normalized = result.trim().toLowerCase();

      if (normalized.contains('liked') && !normalized.contains('unliked')) {
        newSet.add(product.id.toString());
      } else {
        newSet.remove(product.id.toString());
      }

      _state = _state.copyWith(
        userId: userId,
        favoriteProductIds: newSet,
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addToCart(Product product) async {
    final isLoggedIn = await _homeService.isLoggedIn();
    if (!isLoggedIn) {
      throw Exception('Vui lòng đăng nhập');
    }

    final user = await _homeService.getUserInfo();
    final userId = user['id'];

    await _homeService.addToCart(
      userId,
      product.id,
      1,
    );
  }

  // ===== USER =====
  Future<Map<String, dynamic>> getUserInfo() async {
    return await _homeService.getUserInfo();
  }
}