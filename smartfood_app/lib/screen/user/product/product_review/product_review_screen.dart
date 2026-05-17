import 'package:flutter/material.dart';
import 'package:smartfood_app/models/rating.dart';
import 'package:smartfood_app/services/api/auth_api.dart';
import 'package:smartfood_app/services/api/product_api.dart';
import 'package:smartfood_app/services/api/rating_api.dart';

class ProductReviewScreen extends StatefulWidget {
  final String productId;
  final bool popOnSubmit;
  final bool forceNewReview;
  final int? orderId;

  const ProductReviewScreen({
    super.key,
    required this.productId,
    this.popOnSubmit = false,
    this.forceNewReview = false,
    this.orderId,
  });

  @override
  State<ProductReviewScreen> createState() => _ProductReviewScreenState();
}

class _ProductReviewScreenState extends State<ProductReviewScreen> {
  final _ratingApi = RatingApi();
  final _authApi = AuthApi();
  final _productApi = ProductApi();
  bool _loading = true;
  int _starFilter = 0; // 0=all
  RatingStats _stats = RatingStats(
    total: 0,
    average: 0,
    fiveStar: 0,
    fourStar: 0,
    threeStar: 0,
    twoStar: 0,
    oneStar: 0,
  );
  List<Rating> _ratings = [];
  Rating? _myRating;
  String _productName = 'Sản phẩm';

  int get _productId => int.tryParse(widget.productId) ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_productId <= 0) throw Exception('Mã sản phẩm không hợp lệ');
      final user = await _authApi.getCurrentUser();
      final product = await _productApi.getProductById(_productId);
      final stats = await _ratingApi.getProductRatingStats(_productId);
      final ratings = await _ratingApi.getRatingsByProduct(
        _productId,
        stars: _starFilter == 0 ? null : _starFilter,
      );
      Rating? my;
      if (user != null && !widget.forceNewReview) {
        for (final r in ratings) {
          if (r.userId == user.id) {
            my = r;
            break;
          }
        }
      }
      setState(() {
        _productName = product?.name ?? _productName;
        _stats = stats;
        _ratings = ratings;
        _myRating = my;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _openReviewDialog() async {
    final user = await _authApi.getCurrentUser();
    if (user == null || _productId <= 0) return;
    if (!mounted) return;
    final initialRating = widget.forceNewReview ? null : _myRating;
    final ctl = TextEditingController(text: initialRating?.noiDung ?? '');
    int selected = initialRating?.soSao ?? 5;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(initialRating == null ? 'Đánh giá sản phẩm' : 'Sửa đánh giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    onPressed: () => setLocal(() => selected = i + 1),
                    icon: Icon(
                      i + 1 <= selected ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: ctl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Nhập nhận xét'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _ratingApi.addOrUpdateRating(
      userId: user.id,
      productId: _productId,
      soSao: selected,
      noiDung: ctl.text.trim().isEmpty ? null : ctl.text.trim(),
      orderId: widget.orderId,
    );
    if (widget.popOnSubmit && mounted) {
      Navigator.of(context).pop(true);
      return;
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá sản phẩm')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReviewDialog,
        icon: const Icon(Icons.rate_review_outlined),
        label: Text((widget.forceNewReview || _myRating == null) ? 'Đánh giá' : 'Sửa đánh giá'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_productName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 6),
                Text('${_stats.average.toStringAsFixed(1)} / 5'),
                const SizedBox(width: 10),
                Text('(${_stats.total} đánh giá)', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _starFilter == 0,
                  onSelected: (_) {
                    setState(() => _starFilter = 0);
                    _load();
                  },
                ),
                ...List.generate(
                  5,
                  (i) => ChoiceChip(
                    label: Text('${i + 1} sao'),
                    selected: _starFilter == i + 1,
                    onSelected: (_) {
                      setState(() => _starFilter = i + 1);
                      _load();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_ratings.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Chưa có đánh giá'))),
            ..._ratings.map(
              (r) => Card(
                child: ListTile(
                  title: Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < r.soSao ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.userName?.isNotEmpty == true
                            ? r.userName!
                            : 'Người dùng #${r.userId}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(r.noiDung?.isNotEmpty == true ? r.noiDung! : 'Không có nhận xét'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}