import 'package:flutter_test/flutter_test.dart';
import 'package:smartfood_app/core/constants.dart';
import 'package:smartfood_app/routes/app_route.dart';

void main() {
  test('uses fallback API base URL when dart-define is missing', () {
    final baseUrl = Constant().baseUrl;
    expect(baseUrl, isNotEmpty);
    expect(baseUrl, startsWith('http'));
  });

  test('defines expected core routes', () {
    expect(AppRoute.login, equals('/login'));
    expect(AppRoute.main, equals('/main'));
    expect(AppRoute.adminDashboard, equals('/admin-dashboard'));
  });
}
