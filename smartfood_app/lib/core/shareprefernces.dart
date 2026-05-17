import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class Shareprefernces {
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
}
