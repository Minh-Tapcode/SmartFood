import '../../../../models/cart_item.dart';

class CartState {
  final List<CartItem> cartItems;
  final List<CartItem> selectedItems;
  final bool isLoading;
  final bool isLoggedIn;
  final bool selectAll;
  final double selectedTotal;

  const CartState({
    this.cartItems = const [],
    this.selectedItems = const [],
    this.isLoading = true,
    this.isLoggedIn = false,
    this.selectAll = false,
    this.selectedTotal = 0,
  });

  CartState copyWith({
    List<CartItem>? cartItems,
    List<CartItem>? selectedItems,
    bool? isLoading,
    bool? isLoggedIn,
    bool? selectAll,
    double? selectedTotal,
  }) {
    return CartState(
      cartItems: cartItems ?? this.cartItems,
      selectedItems: selectedItems ?? this.selectedItems,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      selectAll: selectAll ?? this.selectAll,
      selectedTotal: selectedTotal ?? this.selectedTotal,
    );
  }
}
