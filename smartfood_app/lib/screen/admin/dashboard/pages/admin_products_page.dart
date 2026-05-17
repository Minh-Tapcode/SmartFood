import 'package:flutter/material.dart';
import 'package:smartfood_app/models/product.dart';
import 'package:smartfood_app/services/api/product_api.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _api = ProductApi();
  final _searchController = TextEditingController();
  List<Product> _all = [];
  List<Product> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await _api.getProducts();
      setState(() {
        _all = products;
        _filtered = products;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _search(String key) {
    final q = key.toLowerCase().trim();
    setState(() {
      _filtered = _all
          .where((p) => p.name.toLowerCase().contains(q))
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên sản phẩm',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final p = _filtered[index];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                        'Kho: ${p.stock} | Giá: ${p.price.toStringAsFixed(0)} VND'),
                    trailing: Text(p.categoryName),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
