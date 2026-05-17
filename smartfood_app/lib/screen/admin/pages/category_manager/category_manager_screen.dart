import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartfood_app/models/category.dart';
import 'package:smartfood_app/services/api/category_api.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final _api = CategoryApi();
  final _picker = ImagePicker();
  final _searchController = TextEditingController();
  bool _loading = true;
  List<Category> _all = [];
  List<Category> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getCategories();
      setState(() {
        _all = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack('Lỗi tải danh mục: $e', false);
    }
  }

  void _search(String value) {
    final q = value.toLowerCase().trim();
    setState(() {
      _filtered = _all.where((e) => e.name.toLowerCase().contains(q)).toList();
    });
  }

  void _snack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: ok ? Colors.green : Colors.red, content: Text(msg)),
    );
  }

  void _showAddEdit({Category? category}) {
    final name = TextEditingController(text: category?.name ?? '');
    File? pickedIcon;
    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final file = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (file != null) {
                        setModalState(() => pickedIcon = File(file.path));
                      }
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Chọn ảnh từ thiết bị'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (pickedIcon != null)
                CircleAvatar(
                  radius: 28,
                  backgroundImage: FileImage(pickedIcon!),
                )
              else if ((category?.icon ?? '').isNotEmpty)
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(category!.icon!),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final n = name.text.trim();
                if (n.isEmpty) {
                  _snack('Tên danh mục không được để trống', false);
                  return;
                }
                Navigator.pop(dialogContext);
                try {
                  final ok = category == null
                      ? await _api.addCategory(
                          n,
                          pickedIcon,
                        )
                      : await _api.updateCategory(
                          category.id,
                          n,
                          pickedIcon,
                          currentIcon: category.icon,
                        );
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  if (ok) {
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Lưu danh mục thành công'),
                      ),
                    );
                    _load();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Lưu danh mục thất bại'),
                      ),
                    );
                  }
                } catch (e) {
                  _snack('Lỗi lưu danh mục: $e', false);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text('Xóa danh mục "${c.name}"?'),
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
      final success = await _api.deleteCategory(c.id);
      if (success) {
        _snack('Xóa danh mục thành công', true);
        _load();
      } else {
        _snack('Xóa danh mục thất bại', false);
      }
    } catch (e) {
      _snack('Lỗi: $e', false);
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
                hintText: 'Tìm kiếm danh mục...',
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
                  final c = _filtered[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (c.icon != null && c.icon!.isNotEmpty)
                            ? NetworkImage(c.icon!)
                            : null,
                        child: (c.icon == null || c.icon!.isEmpty)
                            ? Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase())
                            : null,
                      ),
                      title: Text(c.name),
                      subtitle: Text('ID: ${c.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              onPressed: () => _showAddEdit(category: c),
                              icon: const Icon(Icons.edit_outlined)),
                          IconButton(
                              onPressed: () => _delete(c),
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
        onPressed: () => _showAddEdit(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
      ),
    );
  }
}
