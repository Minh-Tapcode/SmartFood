import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'account_service.dart';
import 'account_state.dart';


class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();

  AccountState _state = const AccountState();
  AccountState get state => _state;

  // Initialize
  Future<void> initialize() async {
    await checkLoginStatus();
  }

  // Check login status
  Future<void> checkLoginStatus() async {
    final isLoggedIn = await _accountService.isLoggedIn();
    _state = _state.copyWith(isLoggedIn: isLoggedIn);
    notifyListeners();

    if (isLoggedIn) {
      await loadUserInfo();
      await loadStatistics();
    } else {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // Load user info
  Future<void> loadUserInfo() async {
    try {
      final userInfo = await _accountService.getUserInfo();
      _state = _state.copyWith(userInfo: userInfo);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final results = await Future.wait<int>([
        _accountService.getOrderCount(),
        _accountService.getFavoriteCount(),
      ]);

      _state = _state.copyWith(
        orderCount: results[0],
        favoriteCount: results[1],
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final success = await _accountService.logout();
      if (success) {
        _state = const AccountState(
          isLoading: false,
          isLoggedIn: false,
        );
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }

  // Get purchased products for review
  Future<List<Map<String, dynamic>>> getPurchasedProducts() async {
    return await _accountService.getPurchasedProducts();
  }

  // Refresh data
  Future<void> refresh() async {
    if (_state.isLoggedIn) {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();
      await Future.wait([
        loadUserInfo(),
        loadStatistics(),
      ]);
    }
  }
}