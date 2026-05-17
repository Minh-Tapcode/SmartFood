import 'package:flutter/material.dart';
import 'package:smartfood_app/routes/app_route.dart';
import 'package:smartfood_app/services/api/auth_api.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Admin settings'),
            subtitle:
                Text('Khu vực cấu hình quản trị, dễ mở rộng thêm option.'),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất'),
            onTap: () async {
              await AuthApi().logout();
              if (!context.mounted) return;
              AppRoute.toLogin(context);
            },
          ),
        ),
      ],
    );
  }
}
