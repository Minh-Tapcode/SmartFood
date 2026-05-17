import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/pages/order_manager/order_detail_screen.dart';
import 'package:smartfood_app/screen/admin/services/admin_order_service.dart';
import 'package:smartfood_app/utils/order_status_helpers.dart';

class OrderManagerScreen extends StatefulWidget {
  const OrderManagerScreen({super.key});

  @override
  State<OrderManagerScreen> createState() => _OrderManagerScreenState();
}

class _OrderManagerScreenState extends State<OrderManagerScreen> {
  final _service = AdminOrderService();
  Timer? _pollingTimer;
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  String _search = '';
  String _statusFilter = 'all';

  /// Giá trị gửi API khi đổi trạng thái (không dùng `processing` — map về picking).
  static const List<String> _updateStatuses = [
    'pending',
    'picking',
    'shipping',
    'completed',
    'cancelled',
    'returned',
  ];

  static const List<(String, String)> _filterOptions = [
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _service.getOrders();
      setState(() {
        _orders = data;
        if (!silent) _loading = false;
      });
    } catch (_) {
      if (!silent) setState(() => _loading = false);
    }
  }

  String _dropdownValue(String status) {
    final s = status.toLowerCase();
    if (s == 'processing') return 'picking';
    if (_updateStatuses.contains(s)) return s;
    if (s == 'paid' || s == 'pending payment') return 'picking';
    return 'pending';
  }

  bool _matches(Map<String, dynamic> o) {
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

    final list = _orders.where(_matches).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Tìm theo mã đơn...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final e = _filterOptions[i];
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
                    physics: const AlwaysScrollableScrollPhysics(),
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
                      final ddVal = _dropdownValue(status);
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text('Đơn #$id'),
                          subtitle: Text(
                            'Tổng tiền: $total VND\n${fulfillmentDisplayLabel(status)}',
                          ),
                          isThreeLine: true,
                          onTap: () {
                            final orderId = int.tryParse(id);
                            if (orderId == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdminOrderDetailScreen(orderId: orderId),
                              ),
                            );
                          },
                          trailing: DropdownButton<String>(
                            value: _updateStatuses.contains(ddVal)
                                ? ddVal
                                : 'pending',
                            items: _updateStatuses
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(fulfillmentDisplayLabel(s)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) async {
                              if (v == null) return;
                              final orderId = int.tryParse(id);
                              if (orderId == null) return;
                              final messenger = ScaffoldMessenger.of(context);
                              final ok =
                                  await _service.updateOrderStatus(orderId, v);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Cập nhật trạng thái thành công'
                                      : 'Cập nhật thất bại'),
                                  backgroundColor:
                                      ok ? Colors.green : Colors.red,
                                ),
                              );
                              if (ok) _load(silent: true);
                            },
                          ),
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
