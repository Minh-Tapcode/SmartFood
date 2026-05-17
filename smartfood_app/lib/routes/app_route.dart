import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/user/account/screen/account_screen.dart';
import 'package:smartfood_app/screen/user/account/screen/contact_support_screen.dart';
import 'package:smartfood_app/screen/user/account/screen/profile_edit_screen.dart';
import 'package:smartfood_app/screen/user/account/screen/settings_screen.dart';
import 'package:smartfood_app/screen/user/account/screen/support_center_screen.dart';
import 'package:smartfood_app/screen/user/cart/cart_screen.dart';
import 'package:smartfood_app/screen/user/favorite/favorite_screen.dart';
import 'package:smartfood_app/screen/user/home/screen/home_screen.dart';
import 'package:smartfood_app/screen/user/product/product_detail_screen.dart';
import 'package:smartfood_app/screen/user/checkout/checkout_screen.dart';
import 'package:smartfood_app/screen/user/login/login_screen.dart';
import 'package:smartfood_app/screen/admin/dashboard/admin_dashboard_screen.dart';
import '../models/cart_item.dart';
import '../screen/main_screen.dart';
import '../screen/user/oder/oder_detail/oder_detail_screen.dart';
import '../screen/user/oder/oder_list/order_list_screen.dart';
import '../screen/user/product/product_review/product_review_screen.dart';
import '../screen/user/product/product_review/review_center_screen.dart';

class AppRoute {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String favorite = '/favorite';
  static const String account = '/account';
  static const String profileEdit = '/profile-edit';
  static const String settings = '/settings';
  static const String supportCenter = '/support-center';
  static const String contactSupport = '/contact-support';
  static const String checkout = '/checkout';
  static const String orderList = '/order-list';
  static const String orderDetail = '/order-detail';
  static const String productDetail = '/product-detail';
  static const String productReview = '/product-review';
  static const String reviewCenter = '/review-center';
  static const String adminDashboard = '/admin-dashboard';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments;
    final routeName = routeSettings.name;

    switch (routeName) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case favorite:
        return MaterialPageRoute(builder: (_) => const FavoritePage());
      case account:
        return MaterialPageRoute(builder: (_) => const AccountScreen());
      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case supportCenter:
        return MaterialPageRoute(builder: (_) => const SupportCenterPage());
      case contactSupport:
        return MaterialPageRoute(builder: (_) => const ContactSupportPage());
      case productDetail:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: args['productId'] as int,
              userId: args['userId'] as int,
            ),
          );
        }
        throw Exception('ProductDetail cần productId + userId');
      case checkout:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CheckoutScreen(
              selectedItems: args['selectedItems'] as List<CartItem>,
              totalAmount: args['totalAmount'] as double,
            ),
          );
        }
        throw Exception('Checkout cần selectedItems + totalAmount');
      case orderDetail:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: args),
          );
        }
        throw Exception('OrderDetail cần orderId');
      case orderList:
        return MaterialPageRoute(builder: (_) => const OrderListPage());
      case productReview:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ProductReviewScreen(productId: args),
          );
        }
        if (args is Map) {
          final map = Map<String, dynamic>.from(args);
          final rawProductId = map['productId'];
          final productId = rawProductId?.toString() ?? '';
          if (productId.isEmpty) {
            throw Exception('ProductReview cần productId');
          }
          return MaterialPageRoute(
            builder: (_) => ProductReviewScreen(
              productId: productId,
              popOnSubmit: map['popOnSubmit'] == true,
              forceNewReview: map['forceNewReview'] == true,
              orderId: map['orderId'] is int
                  ? map['orderId'] as int
                  : int.tryParse('${map['orderId']}'),
            ),
          );
        }
        throw Exception('ProductReview cần productId');
      case reviewCenter:
        return MaterialPageRoute(builder: (_) => const ReviewCenterScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route không tồn tại: $routeName'),
            ),
          ),
        );
    }
  }

  // Generic navigation helpers
  static Future<T?> push<T>(BuildContext context, String routeName,
      {Object? arguments}) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
      BuildContext context, String routeName,
      {Object? arguments, TO? result}) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
      BuildContext context, String routeName,
      {Object? arguments, bool Function(Route<dynamic>)? predicate}) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  static void popUntil(
      BuildContext context, bool Function(Route<dynamic>) predicate) {
    Navigator.popUntil(context, predicate);
  }

  // Specific navigation helpers
  static Future<void> toProductDetail(
      BuildContext context, int productId, int userId) async {
    await push(context, productDetail, arguments: {
      'productId': productId,
      'userId': userId,
    });
  }

  static Future<void> toOrderDetail(
      BuildContext context, String orderId) async {
    await push(context, orderDetail, arguments: orderId);
  }

  static Future<void> toCheckout(BuildContext context,
      List<CartItem> selectedItems, double totalAmount) async {
    await push(context, checkout, arguments: {
      'selectedItems': selectedItems,
      'totalAmount': totalAmount,
    });
  }

  static Future<void> toProductReview(
      BuildContext context, String productId,
      {bool popOnSubmit = false, bool forceNewReview = false, int? orderId}) async {
    if (popOnSubmit || forceNewReview || orderId != null) {
      await push(context, productReview, arguments: {
        'productId': productId,
        'popOnSubmit': popOnSubmit,
        'forceNewReview': forceNewReview,
        if (orderId != null) 'orderId': orderId,
      });
      return;
    }
    await push(context, productReview, arguments: productId);
  }

  static Future<void> toReviewCenter(BuildContext context) async {
    await push(context, reviewCenter);
  }

  static Future<bool?> toProfileEdit(BuildContext context) async {
    final result = await push(context, profileEdit);
    if (result is bool) return result;
    return null;
  }

  static Future<void> toSettings(BuildContext context) async {
    await push(context, settings);
  }

  static Future<void> toSupportCenter(BuildContext context) async {
    await push(context, supportCenter);
  }

  static Future<void> toContactSupport(BuildContext context) async {
    await push(context, contactSupport);
  }

  static Future<void> toOrderList(BuildContext context) async {
    await push(context, orderList);
  }

  static Future<void> toFavorite(BuildContext context) async {
    await push(context, favorite);
  }

  static Future<void> toCart(BuildContext context) async {
    await push(context, cart);
  }

  static Future<void> toLogin(BuildContext context) async {
    await pushAndRemoveUntil(context, login);
  }

  static Future<void> toMain(BuildContext context) async {
    await pushAndRemoveUntil(context, main);
  }

  static Future<void> toAdminDashboard(BuildContext context) async {
    await pushAndRemoveUntil(context, adminDashboard);
  }
}
