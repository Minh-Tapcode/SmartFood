import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_route.dart';
import '../../../models/cart_item.dart';
import 'provider/cart_provider.dart';
import 'widget/cart_checkout_bar.dart';
import 'widget/cart_item_widget.dart';
import 'widget/delete_confirmation_dialog.dart';
import 'widget/zero_quantity_dialog.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().initialize();
    });
  }

  Future<void> _removeFromCart(
    CartItem item, {
    bool requireConfirmation = true,
  }) async {
    final cartProvider = context.read<CartProvider>();
    if (requireConfirmation) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeleteConfirmationDialog(cartItem: item),
      );
      if (shouldDelete != true) return;
    }

    final ok = await cartProvider.removeFromCart(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã xóa "${item.productName}"' : 'Không thể xóa sản phẩm')),
    );
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    final cartProvider = context.read<CartProvider>();
    if (newQuantity <= 0) {
      final remove = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ZeroQuantityDialog(),
      );
      if (remove == true && mounted) {
        await _removeFromCart(item, requireConfirmation: false);
      }
      return;
    }
    final msg = await cartProvider.updateQuantity(item, newQuantity);
    if (!mounted) return;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _checkout(CartProvider provider) {
    if (provider.state.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm')),
      );
      return;
    }
    AppRoute.toCheckout(
      context,
      provider.state.selectedItems,
      provider.state.selectedTotal,
    ).then((_) => provider.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, _) {
          final state = provider.state;
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.isLoggedIn) {
            return const Center(child: Text('Vui lòng đăng nhập để xem giỏ hàng'));
          }
          if (state.cartItems.isEmpty) {
            return const Center(child: Text('Giỏ hàng trống'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = state.cartItems[index];
                    return CartItemWidget(
                      cartItem: item,
                      provider: provider,
                      onUpdateQuantity: _updateQuantity,
                      onDelete: _removeFromCart,
                    );
                  },
                ),
              ),
              CartCheckoutBar(
                provider: provider,
                onCheckout: () => _checkout(provider),
              ),
            ],
          );
        },
      ),
    );
  }
}
