import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smartfood_app/screen/user/account/screen/account_screen.dart';
import 'package:smartfood_app/screen/user/cart/cart_screen.dart';
import 'package:smartfood_app/screen/user/favorite/favorite_screen.dart';
import 'package:smartfood_app/screen/user/home/screen/home_screen.dart';
import 'package:smartfood_app/screen/user/voucher/voucher_screen.dart';
import 'package:smartfood_app/screen/user/account/screen/support_chat_screen.dart';
import '../services/api/chat_api.dart';
import '../services/api/promotion_api.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final ChatApi _chatApi = ChatApi();
  Timer? _chatTimer;
  int _chatUnreadCount = 0;
  bool _chatPollInitialized = false;

  static final List<Widget> _pages = [
    const HomeScreen(),
    const VoucherScreen(),
    const CartScreen(),
    const SupportChatScreen(),
    const FavoritePage(),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 3) {
      _chatApi.markUserInboxSeenNow();
      if (mounted) {
        setState(() => _chatUnreadCount = 0);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapChatNotifications();
    PromotionApi().syncUsedVouchersFromServer();
  }

  Future<void> _bootstrapChatNotifications() async {
    await _chatApi.ensureInboxBaselineOnce();
    if (!mounted) return;
    setState(() => _chatPollInitialized = true);
    _chatTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshUnreadChatCount(),
    );
    await _refreshUnreadChatCount();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _chatApi.markUserInboxSeenNow();
    } else if (state == AppLifecycleState.resumed && _chatPollInitialized) {
      _refreshUnreadChatCount();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatTimer?.cancel();
    _chatApi.markUserInboxSeenNow();
    super.dispose();
  }

  Future<void> _refreshUnreadChatCount() async {
    if (!_chatPollInitialized) return;
    try {
      final count = await _chatApi.getUserUnreadCount();
      if (!mounted) return;

      if (count > _chatUnreadCount && _selectedIndex != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ban co tin nhan ho tro moi')),
        );
      }
      setState(() => _chatUnreadCount = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _selectedIndex == 5 ? _buildAccountAppBar(context) : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.cardColor,
            selectedItemColor: theme.primaryColor,
            unselectedItemColor: theme.unselectedWidgetColor,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: theme.unselectedWidgetColor,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 0
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        size: 24,
                        color: _selectedIndex == 0
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 1
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.explore_outlined,
                        size: 24,
                        color: _selectedIndex == 1
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.explore,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Vourcher',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 2
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 24,
                        color: _selectedIndex == 2
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final base = Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 3
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 24,
                        color: _selectedIndex == 3
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                    if (_chatUnreadCount > 0) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          base,
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _chatUnreadCount > 99 ? '99+' : '$_chatUnreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        ],
                      );
                    }
                    return base;
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.chat_bubble,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 4
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        size: 24,
                        color: _selectedIndex == 4
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final base = Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedIndex == 5
                            ? theme.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 24,
                        color: _selectedIndex == 5
                            ? theme.primaryColor
                            : theme.unselectedWidgetColor,
                      ),
                    );
                    return base;
                  },
                ),
                activeIcon: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: theme.primaryColor,
                      ),
                    );
                  },
                ),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAccountAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      centerTitle: true,
      title: Text(
        'Tài khoản',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: theme.textTheme.titleLarge?.color,
        ),
      ),
      backgroundColor:
      theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      elevation: 0,
    );
  }
}
