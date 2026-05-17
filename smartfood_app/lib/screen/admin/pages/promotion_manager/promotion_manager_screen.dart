import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfood_app/services/api/promotion_api.dart';

class PromotionManagerScreen extends StatefulWidget {
  const PromotionManagerScreen({super.key});

  @override
  State<PromotionManagerScreen> createState() => _PromotionManagerScreenState();
}

class _PromotionManagerScreenState extends State<PromotionManagerScreen> {
  final _api = PromotionApi();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.fetchAll();
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách mã giảm giá: $e')),
      );
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? current}) async {
    final titleCtl = TextEditingController(text: (current?['title'] ?? '').toString());
    final discountCtl = TextEditingController(
      text: (current?['discountPercent'] ?? '').toString(),
    );
    DateTime startDate = DateTime.tryParse((current?['startDate'] ?? '').toString()) ?? DateTime.now();
    DateTime endDate = DateTime.tryParse((current?['endDate'] ?? '').toString()) ?? DateTime.now().add(const Duration(days: 30));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(current == null ? 'Thêm mã giảm giá' : 'Sửa mã giảm giá'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  TextField(
                    controller: discountCtl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Phần trăm giảm (%)'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày bắt đầu'),
                    subtitle: Text(startDate.toLocal().toString().split('.').first),
                    trailing: const Icon(Icons.date_range),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: startDate,
                      );
                      if (picked != null) setLocal(() => startDate = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ngày kết thúc'),
                    subtitle: Text(endDate.toLocal().toString().split('.').first),
                    trailing: const Icon(Icons.date_range),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: endDate,
                      );
                      if (picked != null) setLocal(() => endDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    final title = titleCtl.text.trim();
    final discount = int.tryParse(discountCtl.text.trim()) ?? 0;
    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề giảm giá')),
      );
      return;
    }
    if (discount <= 0 || discount > 100) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phần trăm giảm phải là số nguyên từ 1 đến 100')),
      );
      return;
    }
    if (endDate.isBefore(startDate)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')),
      );
      return;
    }

    try {
      if (current == null) {
        await _api.create(
          title: title,
          discountPercent: discount.toDouble(),
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        final rawId = current['id'];
        final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
        if (id <= 0) throw Exception('ID voucher không hợp lệ');
        await _api.update(
          id: id,
          title: title,
          discountPercent: discount.toDouble(),
          startDate: startDate,
          endDate: endDate,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(current == null ? 'Đã thêm mã giảm giá' : 'Đã cập nhật mã giảm giá')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = item['id'] as int?;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa mã giảm giá'),
        content: Text('Xóa "${item['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa mã giảm giá thành công')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa mã giảm giá thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm giảm giá'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final title = (item['title'] ?? '').toString();
            final discount = (item['discountPercent'] ?? '').toString();
            final active = (item['isActive'] ?? false) == true;
            return Card(
              child: ListTile(
                leading: Icon(Icons.local_offer, color: active ? Colors.green : Colors.grey),
                title: Text(title),
                subtitle: Text('Giảm $discount%'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _openEditor(current: item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => _delete(item),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
