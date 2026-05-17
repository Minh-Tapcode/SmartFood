import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/services/admin_user_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _service = AdminUserService();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getUsers();
      setState(() {
        _users = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          final name = (u['name'] ?? '').toString();
          final email = (u['email'] ?? '').toString();
          final role = (u['role'] ?? u['Role'])?.toString().toLowerCase();
          final isSeller = (role == 'seller' || role == 'admin') || (u['isSeller'] ?? false) == true;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
              ),
              title: Text(name.isEmpty ? 'Không tên' : name),
              subtitle: Text(email),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSeller
                      ? Colors.orange.withOpacity(0.12)
                      : Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isSeller ? 'Seller' : 'Buyer'),
              ),
            ),
          );
        },
      ),
    );
  }
}
