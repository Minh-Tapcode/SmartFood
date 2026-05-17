import 'package:flutter/material.dart';

import '../../../../models/cart_item.dart';
import 'cart_service.dart';
import 'cart_state.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  CartState _state = const CartState();
  CartState get state => _state;

  int? _userId;

  Future<void> initialize() async {
    await checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final isLoggedIn = await _cartService.isLoggedIn();
    _state = _state.copyWith(isLoggedIn: isLoggedIn);
    notifyListeners();

    if (!isLoggedIn) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    _userId = await _cartService.getCurrentUserId();
    await loadCart();
  }

  Future<void> loadCart() async {
    try {
      if (_userId == null) {
        _state = _state.copyWith(isLoading: false);
        notifyListeners();
        return;
      }
      final items = await _cartService.getCart(_userId!);
      _state = _state.copyWith(
        cartItems: items,
        isLoading: false,
      );
      _recalculateSelections();
      notifyListeners();
    } catch (_) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  void _recalculateSelections() {
    final selectedItems = _state.cartItems.where((item) => item.isSelected).toList();
    final selectedTotal = selectedItems.fold<double>(
      0,
      (total, item) => total + item.totalPrice,
    );
    final selectAll =
        _state.cartItems.isNotEmpty && _state.cartItems.every((item) => item.isSelected);
    _state = _state.copyWith(
      selectedItems: selectedItems,
      selectedTotal: selectedTotal,
      selectAll: selectAll,
    );
  }

  void toggleSelectAll(bool? value) {
    if (value == null) return;
    _state = _state.copyWith(
      cartItems: _state.cartItems.map((item) => item.copyWith(isSelected: value)).toList(),
    );
    _recalculateSelections();
    notifyListeners();
  }

  void toggleItemSelection(int cartItemId, bool? value) {
    if (value == null) return;
    _state = _state.copyWith(
      cartItems: _state.cartItems.map((item) {
        if (item.id == cartItemId) return item.copyWith(isSelected: value);
        return item;
      }).toList(),
    );
    _recalculateSelections();
    notifyListeners();
  }

  Future<bool> removeFromCart(CartItem item) async {
    final success = await _cartService.removeFromCart(item.id);
    if (!success) return false;

    _state = _state.copyWith(
      cartItems: _state.cartItems.where((e) => e.id != item.id).toList(),
    );
    _recalculateSelections();
    notifyListeners();
    return true;
  }


  Future<String?> updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) return null;
    if (item.stock >= 0 && newQuantity > item.stock) {
      return 'Chỉ còn ${item.stock} sản phẩm trong kho (đang có ${item.quantity} trong giỏ).';
    }
    try {
      await _cartService.updateCartItem(item.id, newQuantity);
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }

    _state = _state.copyWith(
      cartItems: _state.cartItems.map((e) {
        if (e.id == item.id) return e.copyWith(quantity: newQuantity);
        return e;
      }).toList(),
    );
    _recalculateSelections();
    notifyListeners();
    await loadCart();
    return null;
  }

  Future<void> refresh() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    await loadCart();
  }
}
