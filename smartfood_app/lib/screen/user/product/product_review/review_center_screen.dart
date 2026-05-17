import 'package:flutter/material.dart';
import 'package:smartfood_app/routes/app_route.dart';
import 'package:smartfood_app/services/api/order_api.dart';
import 'package:smartfood_app/services/api/auth_api.dart';
import 'package:smartfood_app/services/api/cart_api.dart';
import 'package:smartfood_app/services/api/rating_api.dart';
import 'package:smartfood_app/core/constants.dart';
import 'package:smartfood_app/utils/order_status_helpers.dart';

class ReviewCenterScreen extends StatefulWidget {
  const ReviewCenterScreen({super.key});

  @override
  State<ReviewCenterScreen> createState() => _ReviewCenterScreenState();
}

class _ReviewCenterScreenState extends State<ReviewCenterScreen> {
  final _orderApi = OrderApi();
  final _authApi = AuthApi();
  final _cartApi = CartApi();
  final _ratingApi = RatingApi();
  bool _loading = true;
  List<_OrderReviewItem> _items = const [];
  String _tab = 'all'; // all | reviewed | unreviewed

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await _authApi.getCurrentUser();
      if (user == null) throw Exception('Bạn chưa đăng nhập');
      final orders = await _orderApi.getOrdersByUser();
      final completedOrders = orders
          .where((o) => normalizeFulfillmentStatus(o.trangThai) == 'completed')
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final itemTasks = completedOrders.map((order) async {
        final detailFuture = _orderApi.getOrderDetail(order.id.toString());
        final reviewedFuture = _ratingApi.hasReviewedOrder(
          userId: user.id,
          orderId: order.id,
        );
        final detail = await detailFuture;
        final reviewed = await reviewedFuture;

        final lines = detail['orderDetails'] ?? detail['OrderDetails'];
        if (lines is! List || lines.isEmpty) return null;

        final first = lines.first;
        final map = first is Map<String, dynamic>
            ? first
            : Map<String, dynamic>.from(first as Map);
        final pidRaw = map['productId'] ?? map['ProductId'];
        final pnameRaw = map['productName'] ?? map['ProductName'];
        final imageRaw = map['imageUrl'] ?? map['ImageUrl'];
        final pid = pidRaw is int ? pidRaw : int.tryParse('$pidRaw') ?? 0;
        if (pid <= 0) return null;

        return _OrderReviewItem(
          orderId: order.id,
          createdAt: order.createdAt,
          productId: pid,
          productName: (pnameRaw ?? 'Sản phẩm').toString(),
          imageUrl: imageRaw?.toString(),
          isReviewed: reviewed,
        );
      }).toList();
      final items = (await Future.wait(itemTasks)).whereType<_OrderReviewItem>().toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<_OrderReviewItem> _filtered() {
    final items = _items;
    if (_tab == 'reviewed') return items.where((e) => e.isReviewed).toList();
    if (_tab == 'unreviewed') return items.where((e) => !e.isReviewed).toList();
    return items;
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return '--/--/----';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _buyAgainSingleProduct(int productId) async {
    final user = await _authApi.getCurrentUser();
    if (user == null) throw Exception('Bạn chưa đăng nhập');
    await _cartApi.addToCart(user.id, productId, 1);
    if (!mounted) return;
    await AppRoute.toCart(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _filtered();
    final reviewedCount = _items.where((e) => e.isReviewed).length;
    final pendingCount = _items.length - reviewedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Đánh giá của tôi'),
        backgroundColor: const Color(0xFFEE4D2D),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          children: [
            _buildTopBanner(reviewedCount, pendingCount),
            const SizedBox(height: 12),
            _buildFilterTabs(),
            const SizedBox(height: 12),
            if (items.isEmpty) _buildEmptyState(),
            ...items.map((e) => _buildReviewCard(e, pendingCount)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(int reviewedCount, int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFEE4D2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.reviews_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá sản phẩm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Còn $pendingCount đơn hàng chờ bạn đánh giá',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _metricPill(reviewedCount, 'Đã đánh giá'),
        ],
      ),
    );
  }

  Widget _metricPill(int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    Widget tab({
      required String id,
      required String text,
      required IconData icon,
    }) {
      final selected = _tab == id;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _tab = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEE4D2D) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? const Color(0xFFEE4D2D) : const Color(0xFFE4E4E4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(id: 'all', text: 'Tất cả', icon: Icons.widgets_outlined),
        const SizedBox(width: 8),
        tab(id: 'unreviewed', text: 'Chờ đánh giá', icon: Icons.pending_actions_rounded),
        const SizedBox(width: 8),
        tab(id: 'reviewed', text: 'Đã đánh giá', icon: Icons.verified_rounded),
      ],
    );
  }

  Widget _buildReviewCard(_OrderReviewItem e, int pendingCount) {
    final isPending = !e.isReviewed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  'Đơn #${e.orderId}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  isPending ? 'Chờ đánh giá' : 'Đã đánh giá',
                  style: TextStyle(
                    color: isPending ? const Color(0xFFEE4D2D) : Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: e.fullImageUrl.isNotEmpty
                        ? Image.network(
                            e.fullImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          )
                        : const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPending
                            ? 'Hãy chia sẻ cảm nhận của bạn'
                            : 'Đã đánh giá đơn hàng • ${_fmtDate(e.createdAt)}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                if (isPending)
                  Text(
                    '$pendingCount đơn hàng đang chờ đánh giá',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  )
                else
                  Text(
                    'Bạn đã đánh giá đơn này',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () async {
                    if (isPending) {
                      final result = await AppRoute.push(
                        context,
                        AppRoute.productReview,
                        arguments: {
                          'productId': e.productId.toString(),
                          'orderId': e.orderId,
                          'popOnSubmit': true,
                          'forceNewReview': true,
                        },
                      );
                      if (result == true) {
                        setState(() {
                          _items = _items
                              .map((x) => x.orderId == e.orderId
                                  ? x.copyWith(isReviewed: true)
                                  : x)
                              .toList();
                        });
                      }
                    } else {
                      await _buyAgainSingleProduct(e.productId);
                    }
                    if (!mounted) return;
                    await _load();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEE4D2D),
                    side: const BorderSide(color: Color(0xFFEE4D2D)),
                    minimumSize: const Size(110, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(isPending ? 'Đánh giá' : 'Mua lại'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 42, color: Colors.black38),
          SizedBox(height: 10),
          Text(
            'Không có sản phẩm trong mục này',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ],
      ),
    );
  }

}

class _OrderReviewItem {
  final int orderId;
  final DateTime createdAt;
  final int productId;
  final String productName;
  final String? imageUrl;
  final bool isReviewed;

  const _OrderReviewItem({
    required this.orderId,
    required this.createdAt,
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.isReviewed,
  });

  String get fullImageUrl {
    final raw = imageUrl;
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final uri = Uri.parse(Constant().baseUrl);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
    return '$origin$normalizedPath';
  }

  _OrderReviewItem copyWith({
    bool? isReviewed,
  }) {
    return _OrderReviewItem(
      orderId: orderId,
      createdAt: createdAt,
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}
