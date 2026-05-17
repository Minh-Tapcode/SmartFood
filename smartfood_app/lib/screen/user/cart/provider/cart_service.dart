import '../../../../models/cart_item.dart';
import '../../../../services/api/auth_api.dart';
import '../../../../services/api/cart_api.dart';

class CartService {
  final CartApi _cartApi = CartApi();
  final AuthApi _authApi = AuthApi();

  Future<bool> isLoggedIn() async {
    return _authApi.isLoggedIn();
  }

  Future<int?> getCurrentUserId() async {
    final user = await _authApi.getCurrentUser();
    return user?.id;
  }

  Future<List<CartItem>> getCart(int userId) async {
    return _cartApi.getCart(userId);
  }

  Future<bool> removeFromCart(int cartItemId) async {
    return _cartApi.deleteCartItem(cartItemId);
  }

  Future<void> updateCartItem(int cartItemId, int quantity) async {
    await _cartApi.updateCart(cartItemId, quantity);
  }
}