import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/user/product/widget/rating_item_widget.dart';
import '../provider/product_detail_provider.dart';

class RatingListWidget extends StatefulWidget {
  final ProductDetailProvider provider;

  const RatingListWidget({
    super.key,
    required this.provider,
  });

  @override
  State<RatingListWidget> createState() => _RatingListWidgetState();
}

class _RatingListWidgetState extends State<RatingListWidget> {
  int _starFilter = 0; // 0 = all

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    if (provider.isLoadingRatings) {
      return const Center(child: CircularProgressIndicator());
    }

    final all = provider.ratings;
    final filtered = _starFilter == 0
        ? all
        : all.where((e) => e.soSao == _starFilter).toList();

    if (all.isEmpty) {
      return const Column(
        children: [
          Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy là người đầu tiên đánh giá sản phẩm này',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: _starFilter == 0,
              onSelected: (_) => setState(() => _starFilter = 0),
            ),
            ...List.generate(
              5,
              (i) => ChoiceChip(
                label: Text('${i + 1} sao'),
                selected: _starFilter == i + 1,
                onSelected: (_) => setState(() => _starFilter = i + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Không có đánh giá với số sao này'),
          ),
        ...filtered.map(
          (rating) => RatingItemWidget(
            rating: rating,
            provider: provider,
          ),
        ),
      ],
    );
  }
}
