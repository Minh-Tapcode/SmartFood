import 'package:flutter/material.dart';
import 'package:smartfood_app/routes/app_route.dart';
import 'package:smartfood_app/services/api/auth_api.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.settings_suggest, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cài đặt hệ thống quản trị',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Giao diện'),
            subtitle: Text('Tùy chỉnh màu sắc, bố cục, chế độ hiển thị'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Thông báo'),
            subtitle: Text('Bật/tắt thông báo hệ thống'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Thông tin cá nhân'),
            subtitle: Text('Cập nhật hồ sơ quản trị viên'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Bảo mật tài khoản'),
            subtitle: Text('Đổi mật khẩu và quản lý phiên đăng nhập'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Ngôn ngữ'),
            subtitle: Text('Tiếng Việt'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.backup_outlined),
            title: Text('Sao lưu dữ liệu'),
            subtitle: Text('Thiết lập lịch sao lưu tự động'),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Giới thiệu hệ thống'),
            subtitle: Text('Phiên bản 1.0.0'),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất'),
            subtitle: const Text('Yêu cầu xác nhận trước khi thoát'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xác nhận đăng xuất'),
                  content: const Text(
                      'Bạn có chắc chắn muốn đăng xuất khỏi phiên quản trị?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Đăng xuất')),
                  ],
                ),
              );
              if (ok != true) return;
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
