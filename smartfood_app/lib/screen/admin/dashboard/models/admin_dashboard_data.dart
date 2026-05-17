class AdminDashboardData {
  final int totalProducts;
  final int totalOrders;
  final int totalUsers;
  final int pendingOrders;
  final int lowStockProducts;
  final double totalRevenue;
  final List<Map<String, dynamic>> latestOrders;
  final List<Map<String, dynamic>> lowStockItems;

  const AdminDashboardData({
    required this.totalProducts,
    required this.totalOrders,
    required this.totalUsers,
    required this.pendingOrders,
    required this.lowStockProducts,
    required this.totalRevenue,
    required this.latestOrders,
    required this.lowStockItems,
  });
}
