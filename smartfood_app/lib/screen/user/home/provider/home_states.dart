import '../../../../models/category.dart';
import '../../../../models/product.dart';

class HomeState {
  final List<Category> categories;
  final List<Product> products;
  final List<Product> filteredProducts;
  final int userId;
  final bool isLoading;
  final bool isLoadingCategories;
  final bool isSearching;

  final String selectedCategoryId;
  final String searchKeyword;

  final Set<String> favoriteProductIds;

  const HomeState({
    this.categories = const [],
    this.products = const [],
    this.userId = 0,
    this.filteredProducts = const [],
    this.isLoading = true,
    this.isLoadingCategories = true,
    this.isSearching = false,
    this.selectedCategoryId = 'all',
    this.searchKeyword = '',
    this.favoriteProductIds = const {},
  });

  HomeState copyWith({
    List<Category>? categories,
    List<Product>? products,
    List<Product>? filteredProducts,
    bool? isLoading,
    int? userId,
    bool? isLoadingCategories,
    bool? isSearching,
    String? selectedCategoryId,
    String? searchKeyword,
    Set<String>? favoriteProductIds,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingCategories:
      isLoadingCategories ?? this.isLoadingCategories,
      userId: userId ?? this.userId,
      isSearching: isSearching ?? this.isSearching,
      selectedCategoryId:
      selectedCategoryId ?? this.selectedCategoryId,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      favoriteProductIds:
      favoriteProductIds ?? this.favoriteProductIds,
    );
  }
}