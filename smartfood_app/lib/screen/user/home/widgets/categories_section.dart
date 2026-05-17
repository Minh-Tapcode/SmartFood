import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/home_provider.dart';
import 'categories_item_section.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Danh mục",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  provider.state.isLoadingCategories
                      ? _buildCategoriesLoading()
                      : _buildCategoriesList(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesLoading() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryItemLoading(),
          _buildCategoryItemLoading(),
          _buildCategoryItemLoading(),
          _buildCategoryItemLoading(),
        ],
      ),
    );
  }

  Widget _buildCategoryItemLoading() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(HomeProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Danh mục "Tất cả"
          CategoryItemWidget(
            title: "Tất cả",
            icon: Icons.category,
            isActive: provider.state.selectedCategoryId == 'all',
            onTap: () => provider.fetchProductsByCategory('all'),
          ),
          // Các danh mục từ API
          ...provider.state.categories.map((category) => CategoryItemWidget(
            title: category.name,
            icon: _getCategoryIcon(category.name),
            isActive: provider.state.selectedCategoryId == category.id.toString(),
            onTap: () =>
                provider.fetchProductsByCategory(category.id.toString()),
          )),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase().trim();

    if (name.contains('rau') || name.contains('củ')) return Icons.eco;

    if (name.contains('trái') || name.contains('cây') || name.contains('quả')) {
      return Icons.apple;
    }

    if (name.contains('thịt bò') || name.contains('bò')) {
      return Icons.lunch_dining;
    }
    if (name.contains('thịt gà') || name.contains('gà')) return Icons.egg_alt;
    if (name.contains('thịt heo') || name.contains('heo') || name.contains('lợn')) {
      return Icons.set_meal;
    }

    if (name.contains('hải sản') || name.contains('tôm') || name.contains('mực')) {
      return Icons.phishing;
    }
    if (name.contains('cá')) return Icons.set_meal;
    if (name.contains('trứng')) return Icons.egg;

    if (name.contains('sữa') || name.contains('phô mai') || name.contains('yaourt')) {
      return Icons.breakfast_dining;
    }

    if (name.contains('gạo') || name.contains('ngũ cốc')) return Icons.grain;
    if (name.contains('đồ khô') || name.contains('khô')) return Icons.inventory_2;

    if (name.contains('gia vị')) return Icons.spa;
    if (name.contains('dầu') ||
        name.contains('nước chấm') ||
        name.contains('nước mắm')) {
      return Icons.oil_barrel;
    }

    if (name.contains('đồ hộp') || name.contains('hộp')) return Icons.inventory;
    if (name.contains('đông lạnh') || name.contains('frozen')) return Icons.ac_unit;

    if (name.contains('đồ ăn nhanh') ||
        name.contains('ăn nhanh') ||
        name.contains('fast food')) {
      return Icons.fastfood;
    }
    if (name.contains('bánh kẹo') || name.contains('kẹo') || name.contains('snack')) {
      return Icons.cookie;
    }
    if (name.contains('nước giải khát') ||
        name.contains('đồ uống') ||
        name.contains('uống') ||
        name.contains('nước')) {
      return Icons.local_drink;
    }

    return Icons.category;
  }
}

