import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Cài đặt',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingsSection(
              title: 'Thông báo',
              children: [
                SwitchListTile(
                  title: const Text('Bật thông báo'),
                  subtitle: const Text('Nhận cập nhật về đơn hàng và khuyến mãi'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _saveSetting('notifications_enabled', value);
                  },
                  activeColor: const Color(0xFF667EEA),
                ),
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: SwitchListTile(
                    title: const Text('Thông báo email'),
                    subtitle: const Text('Nhận email khi có thay đổi quan trọng'),
                    value: _emailNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) {
                      setState(() => _emailNotifications = value);
                      _saveSetting('email_notifications', value);
                    }
                        : null,
                    activeColor: const Color(0xFF667EEA),
                  ),
                ),
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: SwitchListTile(
                    title: const Text('Thông báo đẩy'),
                    subtitle: const Text('Nhận thông báo ngay trên thiết bị'),
                    value: _pushNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) {
                      setState(() => _pushNotifications = value);
                      _saveSetting('push_notifications', value);
                    }
                        : null,
                    activeColor: const Color(0xFF667EEA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              title: 'Giao diện',
              children: [
                ListTile(
                  leading: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: const Color(0xFF667EEA),
                  ),
                  title: const Text('Chế độ sáng/tối'),
                  subtitle: Text(isDark ? 'Đang bật tối' : 'Đang bật sáng'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showComingSoon('Đổi giao diện');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFF667EEA)),
                  title: const Text('Ngôn ngữ'),
                  subtitle: const Text('Tiếng Việt'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showComingSoon('Đổi ngôn ngữ');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              title: 'Khác',
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined,
                      color: Color(0xFF667EEA)),
                  title: const Text('Lưu trữ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showComingSoon('Lưu trữ');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Tính năng đang phát triển'),
        backgroundColor: const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
