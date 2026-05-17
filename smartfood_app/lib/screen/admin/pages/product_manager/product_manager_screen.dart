import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartfood_app/models/category.dart';
import 'package:smartfood_app/models/product.dart';
import 'package:smartfood_app/services/api/category_api.dart';
import 'package:smartfood_app/services/api/product_api.dart';

class ProductManagerScreen extends StatefulWidget {
  const ProductManagerScreen({super.key});

  @override
  State<ProductManagerScreen> createState() => _ProductManagerScreenState();
}

class _ProductManagerScreenState extends State<ProductManagerScreen> {
  final _api = ProductApi();
  final _categoryApi = CategoryApi();
  final _picker = ImagePicker();
  final _searchController = TextEditingController();
  bool _loading = true;
  List<Product> _all = [];
  List<Product> _filtered = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getProducts(),
        _categoryApi.getCategories(),
      ]);
      final data = results[0] as List<Product>;
      final categories = results[1] as List<Category>;
      setState(() {
        _all = data;
        _filtered = data;
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Lỗi tải sản phẩm: $e', false);
    }
  }

  void _search(String value) {
    final q = value.toLowerCase().trim();
    setState(() {
      _filtered = _all.where((e) => e.name.toLowerCase().contains(q)).toList();
    });
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: ok ? Colors.green : Colors.red, content: Text(msg)),
    );
  }

  DateTime? _parseDateOnly(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String? _validateExpiryDate(String raw, {Product? product}) {
    final parsed = _parseDateOnly(raw);
    if (parsed == null) {
      return 'Hạn sử dụng phải đúng định dạng yyyy-MM-dd';
    }
    DateTime minDate;
    if (product != null && product.createdAt.trim().isNotEmpty) {
      final created = DateTime.tryParse(product.createdAt.trim());
      minDate = created != null ? _dateOnly(created) : _dateOnly(DateTime.now());
    } else {
      minDate = _dateOnly(DateTime.now());
    }
    if (parsed.isBefore(minDate)) {
      return 'Hạn sử dụng không được trước ngày tạo sản phẩm';
    }
    return null;
  }

  void _showAddEditDialog({Product? product}) {
    final name = TextEditingController(text: product?.name ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final price = TextEditingController(
        text: product == null ? '' : product.price.toStringAsFixed(0));
    final stock =
        TextEditingController(text: product == null ? '' : '${product.stock}');
    final origin = TextEditingController(text: product?.origin ?? '');
    final unit = TextEditingController(text: product?.unit ?? '');
    final expiryDate = TextEditingController(text: product?.expiryDate ?? '');
    File? pickedImage;
    int selectedCategoryId = _categories.isNotEmpty ? _categories.first.id : 0;
    if (product != null && _categories.isNotEmpty) {
      final found = _categories.where((c) => c.name == product.categoryName);
      if (found.isNotEmpty) selectedCategoryId = found.first.id;
    }

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: Text(product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Tên sản phẩm')),
                  TextField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'Mô tả')),
                  TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá')),
                  TextField(
                      controller: stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tồn kho')),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId == 0 ? null : selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: _categories
                        .map((e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => selectedCategoryId = v ?? 0),
                  ),
                  TextField(
                      controller: origin,
                      decoration: const InputDecoration(labelText: 'Xuất xứ')),
                  TextField(
                      controller: unit,
                      decoration:
                          const InputDecoration(labelText: 'Đơn vị tính')),
                  TextField(
                      controller: expiryDate,
                      decoration: const InputDecoration(
                          labelText: 'Hạn sử dụng (yyyy-MM-dd)')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? file = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (file != null) {
                            setModalState(() => pickedImage = File(file.path));
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Chọn ảnh từ thiết bị'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (pickedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        pickedImage!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if ((product?.fullImageUrl ?? '').isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product!.fullImageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final parsedPrice = double.tryParse(price.text.trim());
                final parsedStock = int.tryParse(stock.text.trim());
                if (name.text.trim().isEmpty ||
                    parsedPrice == null ||
                    parsedStock == null ||
                    selectedCategoryId == 0 ||
                    origin.text.trim().isEmpty ||
                    unit.text.trim().isEmpty ||
                    expiryDate.text.trim().isEmpty) {
                  _showSnack(
                      'Vui lòng nhập đủ và đúng định dạng dữ liệu', false);
                  return;
                }
                if (parsedPrice <= 0) {
                  _showSnack('Giá sản phẩm phải lớn hơn 0', false);
                  return;
                }
                if (parsedStock < 0) {
                  _showSnack('Tồn kho không được âm', false);
                  return;
                }
                final expiryError =
                    _validateExpiryDate(expiryDate.text, product: product);
                if (expiryError != null) {
                  _showSnack(expiryError, false);
                  return;
                }

                Navigator.pop(dialogContext);
                final payload = Product(
                  id: product?.id ?? 0,
                  name: name.text.trim(),
                  description: description.text.trim(),
                  price: parsedPrice,
                  stock: parsedStock,
                  categoryName: _categories
                      .firstWhere((c) => c.id == selectedCategoryId)
                      .name,
                  createdAt: product?.createdAt ?? '',
                  expiryDate: expiryDate.text.trim(),
                  origin: origin.text.trim(),
                  unit: unit.text.trim(),
                  imageUrl: product?.imageUrl,
                );

                try {
                  final ok = product == null
                      ? await _api.addProduct(
                          payload,
                          selectedCategoryId,
                          pickedImage,
                        )
                      : await _api.updateProduct(
                          product.id,
                          payload,
                          selectedCategoryId,
                          pickedImage,
                        );
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  if (ok) {
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Lưu sản phẩm thành công'),
                      ),
                    );
                    _load();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Lưu sản phẩm thất bại'),
                      ),
                    );
                  }
                } catch (e) {
                  _showSnack('Lỗi lưu sản phẩm: $e', false);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final success = await _api.deleteProduct(product.id);
      if (success) {
        _showSnack('Xóa thành công', true);
        _load();
      } else {
        _showSnack('Xóa thất bại', false);
      }
    } catch (e) {
      _showSnack('Lỗi xóa: $e', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final p = _filtered[index];
                  return Card(
                    child: ListTile(
                      leading: p.fullImageUrl.isEmpty
                          ? const CircleAvatar(
                              child: Icon(Icons.image_not_supported_outlined))
                          : CircleAvatar(
                              backgroundImage: NetworkImage(p.fullImageUrl),
                            ),
                      title: Text(p.name),
                      subtitle: Text(
                          'Kho: ${p.stock} | ${p.price.toStringAsFixed(0)} VND'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              onPressed: () => _showAddEditDialog(product: p),
                              icon: const Icon(Icons.edit_outlined)),
                          IconButton(
                              onPressed: () => _deleteProduct(p),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
      ),
    );
  }
}
