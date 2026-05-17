import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/pages/user_manager/user_detail_screen.dart';
import 'package:smartfood_app/screen/admin/services/admin_user_service.dart';

class UserManagerScreen extends StatefulWidget {
  const UserManagerScreen({super.key});

  @override
  State<UserManagerScreen> createState() => _UserManagerScreenState();
}

class _UserManagerScreenState extends State<UserManagerScreen> {
  final _service = AdminUserService();
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  static const _pageSize = 20;

  bool _loading = true;
  bool _loadingMore = false;
  List<Map<String, dynamic>> _users = [];
  int _totalCount = 0;
  int _page = 1;
  bool _hasMore = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
      });
    }
    try {
      final result = await _service.getUsersPaged(
        page: 1,
        pageSize: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _users = result.items;
        _totalCount = result.totalCount;
        _hasMore = result.hasMore;
        _page = 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _service.getUsersPaged(
        page: nextPage,
        pageSize: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _users = [..._users, ...result.items];
        _hasMore = result.hasMore;
        _page = nextPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchSubmit(String value) {
    _searchQuery = value.trim();
    _load(reset: true);
  }

  bool isSellerRole(Map<String, dynamic> user) {
    final role = (user['role'] ?? user['Role'])?.toString().toLowerCase();
    if (role != null && role.isNotEmpty) {
      return role == 'seller' || role == 'admin';
    }
    return (user['isSeller'] ?? false) == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final sellerCount = _users.where(isSellerRole).length;
    final buyerCount = _users.length - sellerCount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearchSubmit,
            decoration: InputDecoration(
              hintText: 'Tìm người dùng (Enter để tìm)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchQuery = '';
                  _searchController.clear();
                  _load(reset: true);
                },
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _quickStat(
                  icon: Icons.people_outline,
                  label: 'Tổng user',
                  value: '$_totalCount',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickStat(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Buyer (trang)',
                  value: '$buyerCount',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickStat(
                  icon: Icons.storefront_outlined,
                  label: 'Seller (trang)',
                  value: '$sellerCount',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _users.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _users.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final u = _users[index];
                final name = (u['name'] ?? '').toString();
                final email = (u['email'] ?? '').toString();
                final seller = isSellerRole(u);
                final uid = (u['id'] ?? u['Id'] ?? '').toString();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                      ),
                    ),
                    title: Text(name.isEmpty ? 'Không tên' : name),
                    subtitle: Text('$email\nID: $uid'),
                    isThreeLine: true,
                    trailing: Chip(label: Text(seller ? 'Seller' : 'Buyer')),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(user: u),
                      ),
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

  Widget _quickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
