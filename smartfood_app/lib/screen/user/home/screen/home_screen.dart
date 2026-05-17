
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/home_provider.dart';
import '../widgets/banner_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/products_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late PageController _pageController;
  Timer? _timer;

  List<String> banners = [
    "lib/assets/image/anh1.png",
    "lib/assets/image/anh2.png",
    "lib/assets/image/anh3.png",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();

    // Initialize data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().initializeData();
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        final provider = context.read<HomeProvider>();
        int nextBanner = provider.currentBanner < banners.length - 1
            ? provider.currentBanner + 1
            : 0;
        _pageController.animateToPage(
          nextBanner,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      FocusScope.of(context).unfocus();
      context.read<HomeProvider>().searchProducts(keyword);
    } else {
      context.read<HomeProvider>().resetSearch();
    }
  }

  void _resetSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    context.read<HomeProvider>().resetSearch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          HomeAppBar(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onSearch: _handleSearch,
            onResetSearch: _resetSearch,
          ),
          // Banner section
          BannerSection(
            pageController: _pageController,
            banners: banners,
          ),
          // Categories section
          const CategoriesSection(),
          // Products section
          ProductsSection(
            searchController: _searchController,
            onResetSearch: _resetSearch,
          ),
        ],
      ),
    );
  }

}
