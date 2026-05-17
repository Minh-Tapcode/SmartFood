import '../../../../models/product.dart';

class FavoriteState {
  final List<Product> favoriteProducts;
  final bool isLoading;
  final bool isLoggedIn;
  final int? currentUserId;
  final String? error;

  FavoriteState({
    required this.favoriteProducts,
    required this.isLoading,
    required this.isLoggedIn,
    this.currentUserId,
    this.error,
  });

  FavoriteState copyWith({
    List<Product>? favoriteProducts,
    bool? isLoading,
    bool? isLoggedIn,
    int? currentUserId,
    String? error,
  }) {
    return FavoriteState(
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUserId: currentUserId ?? this.currentUserId,
      error: error ?? this.error,
    );
  }

  FavoriteState loading() {
    return copyWith(isLoading: true, error: null);
  }

  FavoriteState success(List<Product> products) {
    return copyWith(
      favoriteProducts: products,
      isLoading: false,
      error: null,
    );
  }

  FavoriteState errorState(String errorMessage) {
    return copyWith(
      isLoading: false,
      error: errorMessage,
    );
  }

  FavoriteState loggedIn(bool loggedIn, int? userId) {
    return FavoriteState(
      favoriteProducts: favoriteProducts,
      isLoading: isLoading,
      isLoggedIn: loggedIn,
      currentUserId: userId,
      error: error,
    );
  }
}