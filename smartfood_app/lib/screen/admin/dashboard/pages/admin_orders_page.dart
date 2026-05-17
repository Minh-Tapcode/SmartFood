import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/pages/order_manager/order_detail_screen.dart';
import 'package:smartfood_app/screen/admin/services/admin_order_service.dart';
import 'package:smartfood_app/utils/order_status_helpers.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _service = AdminOrderService();
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  String _search = '';
  String _statusFilter = 'all';

  static const List<(String, String)> _filters = [
    ('all', 'Tất cả'),
    ('pending', 'Chờ xác nhận'),
    ('picking', 'Chờ lấy hàng'),
    ('shipping', 'Chờ giao hàng'),
    ('completed', 'Đã giao'),
    ('cancelled', 'Đã hủy'),
    ('returned', 'Trả hàng'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getOrders();
      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  bool _rowMatchesFilter(Map<String, dynamic> o) {
    final id = (o['id'] ?? o['Id'] ?? '').toString().toLowerCase();
    final status =
        (o['status'] ?? o['Status'] ?? '').toString().toLowerCase();
    final bySearch = _search.isEmpty || id.contains(_search.toLowerCase());
    if (!bySearch) return false;
    if (_statusFilter == 'all') return true;
    if (_statusFilter == 'picking') {
      return status == 'picking' || status == 'processing';
    }
    return status == _statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final list = _orders.where(_rowMatchesFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Tìm theo mã đơn...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final e = _filters[i];
              final sel = _statusFilter == e.$1;
              return FilterChip(
                label: Text(e.$2),
                selected: sel,
                onSelected: (_) => setState(() => _statusFilter = e.$1),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: list.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 48),
                      Center(child: Text('Không có đơn hàng phù hợp.')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final o = list[index];
                      final id = (o['id'] ?? o['Id'] ?? '').toString();
                      final status =
                          (o['status'] ?? o['Status'] ?? '').toString();
                      final total =
                          (o['totalPrice'] ?? o['TotalPrice'] ?? 0).toString();
                      final orderId = int.tryParse(id);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: Text('Đơn #$id'),
                          subtitle: Text(
                            'Tổng: $total VND\n${fulfillmentDisplayLabel(status)}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: orderId == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminOrderDetailScreen(orderId: orderId),
                                    ),
                                  );
                                },
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
