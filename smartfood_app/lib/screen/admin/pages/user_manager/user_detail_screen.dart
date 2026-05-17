import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/services/admin_user_service.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _service = AdminUserService();
  late Future<Map<String, dynamic>> _insightFuture;
  late final int _userId;

  @override
  void initState() {
    super.initState();
    final rawId = widget.user['id'] ?? widget.user['Id'] ?? 0;
    _userId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    _insightFuture = _service.getUserPurchaseInsights(_userId);
  }

  void _reloadInsights() {
    setState(() {
      _insightFuture = _service.getUserPurchaseInsights(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final name = (user['name'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();
    final role = (user['role'] ?? user['Role'])?.toString().toLowerCase();
    final seller = (role == 'seller' || role == 'admin') ||
        (user['isSeller'] ?? false) == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết người dùng')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reloadInsights();
          await _insightFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text(name.isEmpty ? 'Không tên' : name),
                subtitle: Text(email),
                trailing: Chip(label: Text(seller ? 'Seller' : 'Buyer')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Số điện thoại'),
                subtitle: Text(phone.isEmpty ? '-' : phone),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, dynamic>>(
              future: _insightFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Lỗi tải dữ liệu mua hàng: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reloadInsights,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final data = snapshot.data ?? {};
                final totalOrders = data['totalOrders'] ?? 0;
                final totalSpent = (data['totalSpent'] ?? 0) as num;
                final lastOrderAt = (data['lastOrderAt'] ?? '-').toString();
                final topProducts = (data['topProducts'] ?? const []) as List;
                final orders = (data['orders'] ?? const []) as List;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Tổng đơn',
                            value: '$totalOrders',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _statCard(
                            icon: Icons.monetization_on_outlined,
                            label: 'Đã chi',
                            value: '${totalSpent.toStringAsFixed(0)} VND',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Lần mua gần nhất'),
                        subtitle: Text(lastOrderAt == '-' ? '-' : lastOrderAt),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Người dùng đã từng mua',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (topProducts.isEmpty)
                              const Text('Chưa có dữ liệu sản phẩm đã mua'),
                            ...topProducts.map((e) {
                              final item =
                                  Map<String, dynamic>.from(e as Map);
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading:
                                    const Icon(Icons.shopping_cart_outlined),
                                title: Text(
                                    (item['name'] ?? 'Sản phẩm').toString()),
                                trailing:
                                    Text('SL: ${item['quantity'] ?? 0}'),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lịch sử đơn hàng',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (orders.isEmpty)
                              const Text('Chưa có lịch sử đơn hàng'),
                            ...orders.take(10).map((e) {
                              final o = Map<String, dynamic>.from(e as Map);
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                    'Đơn #${o['id'] ?? o['Id'] ?? '--'} - ${o['status'] ?? o['Status'] ?? '--'}'),
                                subtitle: Text(
                                    '${o['createdAt'] ?? o['CreatedAt'] ?? '--'}'),
                                trailing: Text(
                                    '${o['totalPrice'] ?? o['TotalPrice'] ?? 0} VND'),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
