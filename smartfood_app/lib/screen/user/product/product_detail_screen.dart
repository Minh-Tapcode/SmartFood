import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartfood_app/screen/user/product/provider/product_detail_provider.dart';
import 'package:smartfood_app/screen/user/product/widget/product_back_button.dart';
import 'package:smartfood_app/screen/user/product/widget/product_bottom_action_bar.dart';
import 'package:smartfood_app/screen/user/product/widget/product_details_section.dart';
import 'package:smartfood_app/screen/user/product/widget/product_image_section.dart';
import 'package:smartfood_app/screen/user/product/widget/product_info_card.dart';
import 'package:smartfood_app/screen/user/product/widget/rating_section.dart';
import 'package:smartfood_app/screen/user/product/widget/snackbar_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final int userId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.userId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _addToCartController;
  late Animation<double> _scaleAnimation;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();

    _addToCartController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _addToCartController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ProductDetailProvider>()
          .loadProductDetail(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProductDetailProvider>(
        builder: (context, provider, child) {
          if (provider.state.isLoading) {
            return _buildLoading();
          }

          if (provider.state.errorMessage.isNotEmpty) {
            return _buildError(provider.state.errorMessage);
          }

          if (provider.product == null) {
            return _buildError('Không tìm thấy sản phẩm');
          }

          return _buildContent(provider);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(String message) {
    return Center(child: Text(message));
  }

  Widget _buildContent(ProductDetailProvider provider) {
    final product = provider.product!;
    final List<String> productImages = product.fullImageUrl.isNotEmpty
        ? [product.fullImageUrl]
        : [];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            ProductImageSection(
              productImages: productImages,
              imagePageController: _imagePageController,
              currentImageIndex: _currentImageIndex,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              productId: product.id,
              isOutOfStock: provider.isOutOfStock,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    ProductInfoCard(
                      product: product,
                      provider: provider,
                    ),
                    const SizedBox(height: 20),
                    ProductDetailsSection(product: product),
                    const SizedBox(height: 20),
                    RatingSection(provider: provider, userId: widget.userId),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: const ProductBackButton(),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ProductBottomActionBar(
            provider: provider,
            addToCartController: _addToCartController,
            scaleAnimation: _scaleAnimation,
            onAddToCart: () => _addToCart(provider),
          ),
        ),
      ],
    );
  }

  Future<void> _addToCart(ProductDetailProvider provider) async {
    try {
      _addToCartController.forward().then((_) {
        _addToCartController.reverse();
      });
      await provider.addToCart(widget.userId);
      if (!mounted) return;
      SnackbarWidgets.showSuccess(
        context,
        'Đã thêm "${provider.product!.name}" vào giỏ hàng',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarWidgets.showError(context, 'Lỗi: $e');
    }
  }

  @override
  void dispose() {
    _addToCartController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }
}
