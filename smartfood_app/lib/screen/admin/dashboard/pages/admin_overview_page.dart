import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/dashboard/models/admin_dashboard_data.dart';
import 'package:smartfood_app/screen/admin/dashboard/services/admin_dashboard_service.dart';
import 'package:smartfood_app/screen/admin/dashboard/widgets/admin_stat_card.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  final _service = AdminDashboardService();
  late Future<AdminDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDashboardData();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchDashboardData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final data = snapshot.data;
        if (data == null) return const Center(child: Text('Không có dữ liệu'));

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 34),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bảng điều khiển quản trị\nTheo dõi hệ thống theo thời gian thực',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                childAspectRatio: 2.15,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  AdminStatCard(
                    title: 'Sản phẩm',
                    value: '${data.totalProducts}',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  AdminStatCard(
                    title: 'Đơn hàng',
                    value: '${data.totalOrders}',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                  AdminStatCard(
                    title: 'Người dùng',
                    value: '${data.totalUsers}',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF9333EA),
                  ),
                  AdminStatCard(
                    title: 'Đơn chờ xử lý',
                    value: '${data.pendingOrders}',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Block(
                title: 'Doanh thu tạm tính',
                child: Text(
                  '${data.totalRevenue.toStringAsFixed(0)} VND',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              _Block(
                title: 'Sản phẩm sắp hết hàng (${data.lowStockProducts})',
                child: data.lowStockItems.isEmpty
                    ? const Text('Không có sản phẩm tồn kho thấp')
                    : Column(
                        children: data.lowStockItems.map((item) {
                          final name = (item['name'] ?? item['Name'] ?? 'N/A')
                              .toString();
                          final stock =
                              (item['stock'] ?? item['Stock'] ?? 0).toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange),
                            title: Text(name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text('Kho: $stock'),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),
              _Block(
                title: 'Đơn mới nhất',
                child: data.latestOrders.isEmpty
                    ? const Text('Chưa có đơn hàng')
                    : Column(
                        children: data.latestOrders.map((order) {
                          final id =
                              (order['id'] ?? order['Id'] ?? '').toString();
                          final status =
                              (order['status'] ?? order['Status'] ?? '')
                                  .toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text('Đơn #$id'),
                            subtitle: Text(status),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final Widget child;

  const _Block({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
