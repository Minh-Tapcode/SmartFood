import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/user/product/widget/rating_list_widget.dart';
import 'package:smartfood_app/screen/user/product/widget/rating_stats_widget.dart';

import '../provider/product_detail_provider.dart';

class RatingSection extends StatelessWidget {
  final ProductDetailProvider provider;
  final int userId;
  const RatingSection({
    super.key,
    required this.provider,
    required this.userId,
  });
  @override
  Widget build(BuildContext context) {
    return _buildSection(
      icon: Icons.reviews_outlined,
      title: "Đánh giá khách hàng (${provider.ratingStats.total})",
      child: Column(
        children: [
          RatingStatsWidget(provider: provider),
          const SizedBox(height: 16),
          RatingListWidget(provider: provider),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

