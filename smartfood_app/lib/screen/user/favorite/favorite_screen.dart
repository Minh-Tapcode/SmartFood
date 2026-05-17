import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product.dart';
import 'provider/favorite_provider.dart';
import 'widget/favorite_delete_dialog.dart';
import 'widget/favorite_empty_screen.dart';
import 'widget/favorite_error_screen.dart';
import 'widget/favorite_item_widget.dart';
import 'widget/favorite_loading_screen.dart';
import 'widget/favorite_login_required.dart';
import 'widget/favorite_snackbar_widgets.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  late final FavoriteProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = FavoriteProvider()..initialize();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider<FavoriteProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Sản phẩm yêu thích',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: theme.textTheme.titleLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: theme.iconTheme.color),
          shadowColor: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1),
          surfaceTintColor: theme.appBarTheme.surfaceTintColor,
        ),
        body: Consumer<FavoriteProvider>(
          builder: (context, provider, child) {
            // Xử lý các trạng thái loading, error, etc.
            if (provider.isLoading) {
              return const FavoriteLoadingScreen();
            }

            if (provider.hasError) {
              return FavoriteErrorScreen(provider: provider);
            }

            if (!provider.isLoggedIn) {
              return const FavoriteLoginRequired();
            }

            return _buildFavoriteList(provider);
          },
        ),
      ),
    );
  }


  Widget _buildFavoriteList(FavoriteProvider provider) {
    if (provider.isEmpty) {
      return const FavoriteEmptyScreen();
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFavorites(),
      backgroundColor: Colors.white,
      color: const Color(0xFFFF6B6B),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favoriteProducts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = provider.favoriteProducts[index];
          return FavoriteItemWidget(
            provider: provider,
            product: product,
            onDelete: () => _showDeleteConfirmation(provider, product),
            onAddToCart: (quantity) => _addToCart(provider, product, quantity),
          );
        },
      ),
    );
  }


  void _showDeleteConfirmation(FavoriteProvider provider, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FavoriteDeleteDialog(
          product: product,
          onConfirm: () => _removeFromFavorites(provider, product),
        );
      },
    );
  }

  Future<void> _removeFromFavorites(
      FavoriteProvider provider, Product product) async {
    try {
      await provider.removeFromFavorites(product);
      FavoriteSnackbarWidgets.showSuccess(
          context, 'Đã xóa "${product.name}" khỏi yêu thích');
    } catch (e) {
      FavoriteSnackbarWidgets.showError(context, 'Lỗi khi xóa: $e');
    }
  }

  Future<void> _addToCart(
    FavoriteProvider provider,
    Product product,
    int quantity,
  ) async {
    try {
      await provider.addToCart(product, quantity);
      FavoriteSnackbarWidgets.showSuccess(
        context,
        'Đã thêm $quantity "${product.name}" vào giỏ hàng',
      );
    } catch (e) {
      FavoriteSnackbarWidgets.showError(context, 'Lỗi thêm giỏ hàng: $e');
    }
  }
}
