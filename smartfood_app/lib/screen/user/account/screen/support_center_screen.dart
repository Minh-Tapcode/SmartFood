import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../services/api/chat_api.dart';
import 'support_chat_screen.dart';

class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  final ChatApi _chatApi = ChatApi();
  int _unreadCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshUnread());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final count = await _chatApi.getUserUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Trung tâm hỗ trợ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHelpSection(
              context: context,
              title: 'Câu hỏi thường gặp',
              items: [
                _buildHelpItem(
                  context: context,
                  icon: Icons.shopping_bag_outlined,
                  title: 'Làm thế nào để đặt hàng?',
                  description: 'Hướng dẫn đặt hàng và thanh toán',
                  onTap: () => _showHelpDialog(
                    context,
                    'Làm thế nào để đặt hàng?',
                    '1. Chọn sản phẩm bạn muốn mua\n'
                        '2. Thêm vào giỏ hàng\n'
                        '3. Kiểm tra giỏ hàng và chọn thanh toán\n'
                        '4. Điền thông tin giao hàng\n'
                        '5. Chọn phương thức thanh toán\n'
                        '6. Xác nhận đơn hàng',
                  ),
                ),
                _buildHelpItem(
                  context: context,
                  icon: Icons.payment_outlined,
                  title: 'Các phương thức thanh toán',
                  description: 'Tìm hiểu cách thanh toán đơn hàng',
                  onTap: () => _showHelpDialog(
                    context,
                    'Các phương thức thanh toán',
                    'Chúng tôi hỗ trợ các phương thức thanh toán sau:\n\n'
                        '• Thanh toán khi nhận hàng (COD)\n'
                        '• Chuyển khoản ngân hàng\n'
                        '• Ví điện tử\n'
                        '• Thẻ tín dụng/ghi nợ',
                  ),
                ),
                _buildHelpItem(
                  context: context,
                  icon: Icons.local_shipping_outlined,
                  title: 'Chính sách vận chuyển',
                  description:
                  'Thông tin về phí vận chuyển và thời gian giao hàng',
                  onTap: () => _showHelpDialog(
                    context,
                    'Chính sách vận chuyển',
                    '• Phí vận chuyển mặc định trong app: 15.000đ / đơn (có thể đổi theo chính sách từng thời điểm)\n'
                        '• Thời gian giao hàng: 2-5 ngày làm việc (ước lượng)\n'
                        '• Giao hàng theo khu vực hỗ trợ',
                  ),
                ),
                _buildHelpItem(
                  context: context,
                  icon: Icons.undo_outlined,
                  title: 'Chính sách đổi trả',
                  description: 'Quy định về đổi trả sản phẩm',
                  onTap: () => _showHelpDialog(
                    context,
                    'Chính sách đổi trả',
                    '• Đổi trả trong vòng 7 ngày kể từ ngày nhận hàng\n'
                        '• Sản phẩm phải còn nguyên vẹn, chưa sử dụng\n'
                        '• Có hóa đơn mua hàng\n'
                        '• Liên hệ hotline để được hỗ trợ đổi trả',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpSection(
              context: context,
              title: 'Liên hệ hỗ trợ',
              items: [
                _buildContactItem(
                  icon: Icons.phone,
                  title: 'Hotline',
                  subtitle: '1900 1234',
                  color: Colors.green,
                  onTap: () => _makePhoneCall(context, '19001234'),
                ),
                _buildContactItem(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: 'support@fresherfood.com',
                  color: Colors.blue,
                  onTap: () => _sendEmail(context, 'support@fresherfood.com'),
                ),
                _buildContactItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat trực tuyến',
                  subtitle: _unreadCount > 0
                      ? 'Ban co $_unreadCount tin nhan moi'
                      : 'Nhan tin voi admin',
                  color: Colors.orange,
                  trailingBadge: _unreadCount,
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                      builder: (_) => const SupportChatScreen(),
                      ),
                    );
                    await _chatApi.markUserInboxSeenNow();
                    await _refreshUnread();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required List<Widget> items,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.primaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color)),
      subtitle: Text(description,
          style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
      trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color),
      onTap: onTap,
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int trailingBadge = 0,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: trailingBadge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                trailingBadge > 99 ? '99+' : '$trailingBadge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showHelpDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gọi điện'),
        content: Text('Bạn có muốn gọi đến số $phoneNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gọi đến $phoneNumber'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gọi'),
          ),
        ],
      ),
    );
  }

  void _sendEmail(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi email'),
        content: Text('Bạn có muốn gửi email đến $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gửi email đến $email'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

}
