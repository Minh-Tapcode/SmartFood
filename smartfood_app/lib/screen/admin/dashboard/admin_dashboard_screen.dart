import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/pages/category_manager/category_manager_screen.dart';
import 'package:smartfood_app/screen/admin/pages/chat_manager/admin_chat_manager_screen.dart';
import 'package:smartfood_app/screen/admin/pages/order_manager/order_manager_screen.dart';
import 'package:smartfood_app/screen/admin/pages/promotion_manager/promotion_manager_screen.dart';
import 'package:smartfood_app/screen/admin/pages/product_manager/product_manager_screen.dart';
import 'package:smartfood_app/screen/admin/pages/settings/settings_screen.dart';
import 'package:smartfood_app/screen/admin/pages/user_manager/user_manager_screen.dart';
import 'dart:async';

import '../pages/statistical/statistics_screen.dart';
import '../../../services/api/chat_api.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final ChatApi _chatApi = ChatApi();
  Timer? _chatPollingTimer;
  int _unreadChatCount = 0;
  int _prevUnreadChatCount = 0;
  DateTime _lastChatSeenAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _chatPollInitialized = false;

  final _titles = const [
    'Tổng quan',
    'Sản phẩm',
    'Danh mục',
    'Đơn hàng',
    'Chat hỗ trợ',
    'Giảm giá',
    'Người dùng',
    'Cài đặt',
  ];

  final _pages = const [
    StatisticsScreen(),
    ProductManagerScreen(),
    CategoryManagerScreen(),
    OrderManagerScreen(),
    AdminChatManagerScreen(),
    PromotionManagerScreen(),
    UserManagerScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startChatPolling();
  }

  @override
  void dispose() {
    _chatPollingTimer?.cancel();
    super.dispose();
  }

  void _startChatPolling() {
    _chatPollingTimer?.cancel();
    _chatPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final threads = await _chatApi.getAdminThreads();
        if (!mounted) return;

        // Lan poll dau sau khi vao app: chi khoi tao moc thoi gian,
        // khong show snackbar de tranh thong bao "tin cu" moi lan dang nhap.
        if (!_chatPollInitialized) {
          DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
          for (final t in threads) {
            final ts = _lastCustomerTimeOf(t);
            if (ts.isAfter(latest)) latest = ts;
          }
          setState(() {
            _lastChatSeenAt = latest;
            _unreadChatCount = 0;
            _prevUnreadChatCount = 0;
            _chatPollInitialized = true;
          });
          return;
        }

        if (_selectedIndex == 4) {
          setState(() {
            _lastChatSeenAt = DateTime.now();
            _unreadChatCount = 0;
          });
          return;
        }

        final unread = threads
            .where((t) => _lastCustomerTimeOf(t).isAfter(_lastChatSeenAt))
            .length;

        if (unread > _prevUnreadChatCount && _selectedIndex != 4) {
          final freshNames = threads
              .where((t) => _lastCustomerTimeOf(t).isAfter(_lastChatSeenAt))
              .map((t) => t.customerName)
              .toSet()
              .take(3)
              .toList();
          final who = freshNames.isEmpty ? 'khach hang' : freshNames.join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Co $unread tin nhan moi tu $who'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        setState(() {
          _unreadChatCount = unread;
          _prevUnreadChatCount = unread;
        });
      } catch (_) {
        // Khong chan UI neu poll that bai tam thoi.
      }
    });
  }

  DateTime _lastCustomerTimeOf(ChatThread t) {
    if (t.lastCustomerMessageAt != null) return t.lastCustomerMessageAt!;
    if ((t.lastSenderType ?? '') == 'customer') {
      return t.lastMessageAt ?? t.updatedAt;
    }
    // Fallback cho backend cu chua tra lastSenderType.
    return t.lastMessageAt ?? t.updatedAt;
  }

  void _openChatManager() {
    setState(() {
      _selectedIndex = 4;
      _lastChatSeenAt = DateTime.now();
      _unreadChatCount = 0;
      _prevUnreadChatCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Chat hỗ trợ',
                  onPressed: _openChatManager,
                  icon: const Icon(Icons.support_agent_outlined),
                ),
                if (_unreadChatCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        _unreadChatCount > 99 ? '99+' : '$_unreadChatCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Admin Panel',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _menu(0, Icons.insights_outlined, 'Tổng quan'),
            _menu(1, Icons.inventory_2_outlined, 'Quản lý sản phẩm'),
            _menu(2, Icons.category_outlined, 'Quản lý danh mục'),
            _menu(3, Icons.receipt_long_outlined, 'Quản lý đơn hàng'),
            _menu(4, Icons.support_agent_outlined, 'Chat hỗ trợ',
                badgeCount: _unreadChatCount),
            _menu(5, Icons.local_offer_outlined, 'Quản lý giảm giá'),
            _menu(6, Icons.people_outline, 'Quản lý người dùng'),
            _menu(7, Icons.settings_outlined, 'Cài đặt'),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _menu(int index, IconData icon, String text, {int badgeCount = 0}) {
    final selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: selected ? const Color(0xFF2E7D32) : null),
      title: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? const Color(0xFF2E7D32) : null,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      selected: selected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
          if (index == 4) {
            _lastChatSeenAt = DateTime.now();
            _unreadChatCount = 0;
            _prevUnreadChatCount = 0;
          }
        });
        Navigator.pop(context);
      },
    );
  }
}
