import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartfood_app/models/order_detail.dart';
import 'package:smartfood_app/routes/app_route.dart';
import 'package:smartfood_app/services/api/auth_api.dart';
import 'package:smartfood_app/services/api/order_api.dart';
import 'package:smartfood_app/screen/user/oder/oder_detail/provider/order_detail_provider.dart';
import 'package:smartfood_app/screen/user/checkout/widget/vnpay_webview_screen.dart';
import 'package:smartfood_app/utils/order_status_helpers.dart';
import 'package:smartfood_app/services/api/cart_api.dart';
import 'package:smartfood_app/services/api/rating_api.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _authApi = AuthApi();
  final _cartApi = CartApi();
  final _orderApi = OrderApi();
  final _ratingApi = RatingApi();

  bool _isVnpayMethod(String? raw) {
    final s = (raw ?? '').trim().toUpperCase();
    return s == 'VNPAY' || s.contains('VNPAY');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderDetailProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Làm mới',
                onPressed: () {
                  context.read<OrderDetailProvider>().loadOrderDetail(widget.orderId);
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.3),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Chi tiết đơn hàng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      primary.withOpacity(isDark ? 0.8 : 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Consumer<OrderDetailProvider>(
            builder: (context, orderDetailProvider, child) {
              if (orderDetailProvider.isLoading) {
                return _buildLoadingSliver();
              } else if (orderDetailProvider.errorMessage.isNotEmpty) {
                return _buildErrorSliver(orderDetailProvider);
              } else if (orderDetailProvider.order == null) {
                return _buildEmptySliver();
              } else {
                return _buildOrderDetailSliver(orderDetailProvider);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoadingAnimation(),
          const SizedBox(height: 24),
          Text(
            'Đang tải chi tiết đơn hàng...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSliver(OrderDetailProvider orderDetailProvider) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              orderDetailProvider.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => orderDetailProvider.retryLoading(widget.orderId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Thử lại',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySliver() {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE8F5E8),
                    const Color(0xFFC8E6C9),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 70,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Không tìm thấy đơn hàng',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Đơn hàng không tồn tại hoặc đã bị xóa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailSliver(OrderDetailProvider orderDetailProvider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildOrderInfoCard(orderDetailProvider),
          const SizedBox(height: 20),
          _buildTrackingCard(orderDetailProvider),
          const SizedBox(height: 20),
          _buildCancelOrderCard(context, orderDetailProvider),
          const SizedBox(height: 20),
          _buildProductListCard(orderDetailProvider),
          if (normalizeFulfillmentStatus(
                  orderDetailProvider.order!.trangThai) ==
              'completed') ...[
            const SizedBox(height: 12),
            _buildReviewButton(orderDetailProvider),
          ],
          if (normalizeFulfillmentStatus(
                  orderDetailProvider.order!.trangThai) ==
              'cancelled') ...[
            const SizedBox(height: 12),
            _buildBuyAgainButton(orderDetailProvider),
          ],
          const SizedBox(height: 20),
          _buildPaymentInfoCard(orderDetailProvider),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildBuyAgainButton(OrderDetailProvider orderDetailProvider) {
    final details = orderDetailProvider.orderDetails;
    if (details.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: OutlinedButton.icon(
          onPressed: () => _buyAgainFromDetails(details),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Mua lại'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButton(OrderDetailProvider orderDetailProvider) {
    final details = orderDetailProvider.orderDetails;
    if (details.isEmpty) return const SizedBox.shrink();
    final productIds = details
        .map((e) => e.productId)
        .where((id) => id > 0)
        .toSet()
        .toList();
    if (productIds.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: FutureBuilder<bool>(
          future: _isCurrentOrderReviewed(),
          builder: (context, snapshot) {
            final reviewed = snapshot.data == true;
            return OutlinedButton.icon(
              onPressed: () async {
                if (reviewed) {
                                await _buyAgainFromDetails(details);
                  return;
                }
                final result = await AppRoute.push(
                  context,
                  AppRoute.productReview,
                  arguments: {
                    'productId': productIds.first.toString(),
                    'orderId': int.tryParse(widget.orderId.replaceFirst('#OD', '').trim()),
                    'popOnSubmit': true,
                    'forceNewReview': true,
                  },
                );
                if (result == true) {
                  setState(() {});
                }
                if (!mounted) return;
                setState(() {});
              },
              icon: Icon(
                reviewed ? Icons.refresh_rounded : Icons.star_outline_rounded,
              ),
              label: Text(reviewed ? 'Mua lại' : 'Đánh giá sản phẩm'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _isCurrentOrderReviewed() async {
    final orderId = int.tryParse(widget.orderId.replaceFirst('#OD', '').trim()) ?? 0;
    if (orderId <= 0) return false;
    final user = await _authApi.getCurrentUser();
    if (user == null) return false;
    return await _ratingApi.hasReviewedOrder(userId: user.id, orderId: orderId);
  }

  Widget _buildOrderInfoCard(OrderDetailProvider orderDetailProvider) {
    final order = orderDetailProvider.order!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã đơn hàng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.maDonHang,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          orderDetailProvider
                              .getStatusColor(order.trangThai)
                              .withOpacity(0.9),
                          orderDetailProvider
                              .getStatusColor(order.trangThai)
                              .withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: orderDetailProvider
                              .getStatusColor(order.trangThai)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          orderDetailProvider.getStatusIcon(order.trangThai),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          orderDetailProvider.getStatusText(order.trangThai),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              _buildDetailInfoRow(
                provider: orderDetailProvider,
                icon: Icons.calendar_today_rounded,
                title: 'Ngày đặt hàng',
                value: orderDetailProvider.formatDate(order.ngayDat),
                subValue: orderDetailProvider.formatTime(order.ngayDat),
              ),
              if (order.phuongThucThanhToan != null &&
                  order.phuongThucThanhToan!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.payment_rounded,
                  title: 'Phương thức thanh toán',
                  value: order.phuongThucThanhToan!,
                ),
              _buildDetailInfoRow(
                provider: orderDetailProvider,
                icon: Icons.credit_card_rounded,
                title: 'Trạng thái thanh toán',
                value: orderDetailProvider.getPaymentDisplayLabel(order.trangThaiThanhToan),
                valueColor: order.trangThaiThanhToan.toLowerCase() == 'paid'
                    ? const Color(0xFF66BB6A)
                    : Colors.orange,
              ),
              if (order.soDienThoai != null && order.soDienThoai!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.phone_rounded,
                  title: 'Số điện thoại',
                  value: order.soDienThoai!,
                ),
              if (order.diaChiGiaoHang != null &&
                  order.diaChiGiaoHang!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.location_on_rounded,
                  title: 'Địa chỉ giao hàng',
                  value: order.diaChiGiaoHang!,
                  isMultiLine: true,
                ),
              if (order.ghiChu != null && order.ghiChu!.isNotEmpty)
                _buildDetailInfoRow(
                  provider: orderDetailProvider,
                  icon: Icons.note_rounded,
                  title: 'Ghi chú',
                  value: order.ghiChu!,
                  isMultiLine: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingCard(OrderDetailProvider orderDetailProvider) {
    final order = orderDetailProvider.order!;
    final stepIndex = orderDetailProvider.getFulfillmentStepIndex(order.trangThai);
    const stepKeys = ['pending', 'picking', 'shipping', 'completed'];

    if (stepIndex < 0) {
      final isReturned = stepIndex == -2;
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                isReturned
                    ? Icons.assignment_return_rounded
                    : Icons.cancel_outlined,
                color: isReturned ? Colors.brown.shade400 : Colors.red.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  orderDetailProvider.getFulfillmentDisplayLabel(order.trangThai),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final resolvedIndex = stepIndex.clamp(0, stepKeys.length - 1);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo dõi đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...stepKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isDone = index <= resolvedIndex;
              final isLast = index == stepKeys.length - 1;
              final label = orderDetailProvider.getFulfillmentDisplayLabel(item);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : Icons.circle_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 24,
                          color: isDone ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                          color: isDone ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListCard(OrderDetailProvider orderDetailProvider) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      size: 20,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sản phẩm đã đặt',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 20),
              ...orderDetailProvider.orderDetails.asMap().entries.map((entry) {
                final index = entry.key;
                final detail = entry.value;
                return _buildProductItem(orderDetailProvider, detail, index);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(
      OrderDetailProvider orderDetailProvider, OrderDetail detail, int index) {
    final subtotal = detail.giaBan * detail.soLuong;

    return Container(
      margin: EdgeInsets.only(
          bottom:
          index == orderDetailProvider.orderDetails.length - 1 ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFEFF3F6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: detail.fullImageUrl.isNotEmpty
                  ? Image.network(
                      detail.fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        size: 26,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.image_rounded,
                      size: 28,
                      color: Color(0xFF4CAF50),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.tenSanPham,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Số lượng: ${detail.soLuong}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      orderDetailProvider.formatCurrency(detail.giaBan),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      orderDetailProvider.formatCurrency(subtotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(OrderDetailProvider orderDetailProvider) {
    final order = orderDetailProvider.order!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_rounded,
                      size: 20,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thông tin thanh toán',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              _buildPaymentRow(
                provider: orderDetailProvider,
                label: 'Tổng tiền hàng',
                value: orderDetailProvider
                    .formatCurrency(orderDetailProvider.itemsSubtotal),
              ),
              const SizedBox(height: 12),
              _buildPaymentRow(
                provider: orderDetailProvider,
                label: 'Phí vận chuyển',
                value: orderDetailProvider.displayShippingFee <= 0
                    ? 'Miễn phí'
                    : orderDetailProvider
                        .formatCurrency(orderDetailProvider.displayShippingFee),
                valueColor: const Color(0xFF66BB6A),
              ),
              if (orderDetailProvider.showDiscountRow) ...[
                const SizedBox(height: 12),
                _buildPaymentRow(
                  provider: orderDetailProvider,
                  label: orderDetailProvider.orderPromotionTitle != null &&
                          orderDetailProvider.orderPromotionTitle!.isNotEmpty
                      ? 'Giảm giá (${orderDetailProvider.orderPromotionTitle})'
                      : (orderDetailProvider.order?.promotionId != null &&
                              orderDetailProvider.order!.promotionId! > 0)
                          ? 'Giảm giá (mã #${orderDetailProvider.order!.promotionId})'
                          : 'Giảm giá',
                  value: orderDetailProvider.orderDiscountAmount > 0.01
                      ? '-${orderDetailProvider.formatCurrency(orderDetailProvider.orderDiscountAmount)}'
                      : orderDetailProvider.formatCurrency(0),
                  valueColor: orderDetailProvider.orderDiscountAmount > 0.01
                      ? Colors.red.shade700
                      : Colors.grey.shade600,
                ),
              ],
              const SizedBox(height: 20),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildPaymentRow(
                provider: orderDetailProvider,
                label: 'Tổng thanh toán',
                value: orderDetailProvider
                    .formatCurrency(orderDetailProvider.totalAmount),
                isTotal: true,
              ),
              if (order.trangThaiThanhToan.toLowerCase() != 'paid') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (orderDetailProvider.canChangePaymentMethod) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _changePaymentMethod(order),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Đổi phương thức'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _isVnpayMethod(order.phuongThucThanhToan)
                          ? FilledButton.icon(
                              onPressed: () => _payPendingVnpay(order.id),
                              icon: const Icon(Icons.payment_rounded),
                              label: const Text('Thanh toán VNPay'),
                            )
                          : const OutlinedButton(
                              onPressed: null,
                              child: Text(
                                'COD — thanh toán khi nhận hàng',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payPendingVnpay(int orderId) async {
    try {
      final paymentUrl = await _orderApi.getVnpayPaymentUrl(orderId);
      if (!mounted) return;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được link thanh toán VNPay')),
        );
        return;
      }
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VnPayWebViewScreen(paymentUrl: paymentUrl),
        ),
      );
      if (!mounted) return;
      if (ok == true) {
        context.read<OrderDetailProvider>().loadOrderDetail(widget.orderId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanh toán thất bại: $e')),
      );
    }
  }

  Future<void> _changePaymentMethod(order) async {
    final current = (order.phuongThucThanhToan ?? '').toUpperCase();
    final nextMethod = current == 'VNPAY' ? 'COD' : 'VNPAY';
    try {
      await _orderApi.changePaymentMethod(order.id, nextMethod);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đổi phương thức sang $nextMethod')),
      );
      context.read<OrderDetailProvider>().loadOrderDetail(widget.orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đổi phương thức thanh toán thất bại: $e')),
      );
    }
  }

  Future<void> _buyAgainFromDetails(List<OrderDetail> details) async {
    try {
      final user = await _authApi.getCurrentUser();
      if (user == null) throw Exception('Bạn chưa đăng nhập');
      if (details.isEmpty) throw Exception('Không có sản phẩm để mua lại');
      var addedCount = 0;
      for (final d in details) {
        final quantity = d.soLuong <= 0 ? 1 : d.soLuong;
        try {
          await _cartApi.addToCart(user.id, d.productId, quantity);
          addedCount++;
        } catch (_) {}
      }
      if (!mounted) return;
      if (addedCount == 0) throw Exception('Không thể thêm sản phẩm vào giỏ');
      await AppRoute.toCart(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mua lại thất bại: $e')),
      );
    }
  }

  Widget _buildDetailInfoRow({
    required OrderDetailProvider provider,
    required IconData icon,
    required String title,
    required String value,
    String? subValue,
    Color? valueColor,
    bool isMultiLine = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
        isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isMultiLine)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: valueColor ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          color: valueColor ?? Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subValue != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subValue,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required OrderDetailProvider provider,
    required String label,
    required String value,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.black87 : Colors.grey.shade600,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            color: valueColor ??
                (isTotal ? const Color(0xFF4CAF50) : Colors.black87),
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelOrderCard(
    BuildContext context,
    OrderDetailProvider orderDetailProvider,
  ) {
    final order = orderDetailProvider.order!;
    final canCancel =
        normalizeFulfillmentStatus(order.trangThai) == 'pending';
    final busy = orderDetailProvider.isCancellingOrder;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Tooltip(
          message: canCancel
              ? 'Hủy đơn hàng (chỉ khi đang chờ xác nhận)'
              : 'Chỉ hủy được khi đơn đang chờ xác nhận',
          child: OutlinedButton.icon(
            onPressed: canCancel && !busy
                ? () => _confirmAndCancelOrder(context, orderDetailProvider)
                : null,
            icon: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: canCancel ? Colors.red.shade700 : Colors.grey,
                    ),
                  )
                : Icon(
                    Icons.cancel_outlined,
                    color: canCancel ? Colors.red.shade700 : Colors.grey,
                  ),
            label: Text(
              busy ? 'Đang hủy...' : 'Hủy đơn hàng',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: canCancel ? Colors.red.shade700 : Colors.grey,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: canCancel ? Colors.red.shade300 : Colors.grey.shade300,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndCancelOrder(
    BuildContext context,
    OrderDetailProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text(
          'Bạn có chắc muốn hủy đơn này? Hành động không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final err = await provider.cancelOrderIfPending(widget.orderId);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn hàng')),
      );
    }
  }

  Widget _buildLoadingAnimation() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 30,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(const Color(0xFF4CAF50)),
                backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
