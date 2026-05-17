import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants.dart';
import '../../../../models/user.dart';

class AuthApi {
  Future<Map<String, dynamic>> getUserInfo() async {
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    return {
      'id': user.id,
      'tenTaiKhoan': user.name,
      'hoTen': user.name,
      'name': user.name,
      'email': user.email,
      'sdt': user.phone,
      'diaChi': '',
      'phone': user.phone,
      'role': user.role,
      'createdAt': user.createdAt,
    };
  }
  // ================= LOGIN =================
  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant().baseUrl}/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Login API status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['user'] == null || data['token'] == null) {
          throw Exception('Response không chứa user hoặc token');
        }

        // Map user DTO sang User object
        final userDto = data['user'];
        final role =
            (userDto['role'] ?? userDto['Role'] ?? ((userDto['isSeller'] ?? false) ? 'seller' : 'buyer')).toString();
        final user = User(
          id: userDto['id'] ?? 0,
          name: userDto['name'] ?? '',
          email: userDto['email'] ?? '',
          password: '', // Password không trả về từ API, để trống
          phone: userDto['phone'],
          role: role,
          createdAt: userDto['createdAt'] ?? DateTime.now().toIso8601String(),
        );

        final token = data['token'];

        // Lưu user + token
        await _saveUserInfo(user, token);
        if (kDebugMode) {
          debugPrint('User info + token saved');
        }

        return user;
      } else {
        throw Exception('Đăng nhập thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  // ================= REGISTER =================
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constant().baseUrl}/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone ?? '',
        }),
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        debugPrint('Register API status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend của bạn trả thẳng user (không bọc trong {"user":...})
        final data = jsonDecode(response.body);
        final Map<String, dynamic> userDto =
            data is Map<String, dynamic> ? data : <String, dynamic>{};
        final role =
            (userDto['role'] ?? userDto['Role'] ?? ((userDto['isSeller'] ?? false) ? 'seller' : 'buyer')).toString();

        final user = User(
          id: userDto['id'] ?? 0,
          name: userDto['name'] ?? name,
          email: userDto['email'] ?? email,
          password: password,
          phone: userDto['phone'] ?? phone,
          role: role,
          createdAt: userDto['createdAt'] ?? DateTime.now().toIso8601String(),
        );

        return user;
      } else {
        // cố gắng lấy message từ backend để hiện rõ lỗi trùng email/sđt
        String msg = response.body;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            msg = (decoded['message'] ??
                    decoded['error'] ??
                    decoded['title'] ??
                    decoded.toString())
                .toString();
          }
        } catch (_) {}
        throw Exception('Đăng ký thất bại: ${response.statusCode} - $msg');
      }
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (kDebugMode) {
      debugPrint('Đã logout');
    }
  }

  Future<bool> updateUserInfo(Map<String, dynamic> userData) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return false;
    final token = await getToken();

    final payload = {
      'name': (userData['hoTen'] ?? userData['tenNguoiDung'] ?? currentUser.name).toString(),
      'email': (userData['email'] ?? currentUser.email).toString(),
      'phone': (userData['sdt'] ?? currentUser.phone)?.toString(),
    };

    final response = await http.put(
      Uri.parse('${Constant().baseUrl}/Auth/${currentUser.id}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Cập nhật thất bại: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (data.containsKey(key) && data[key] != null) return data[key];
      }
      return null;
    }

    final updatedUser = User(
      id: pick(['id', 'Id']) ?? currentUser.id,
      name: (pick(['name', 'Name']) ?? currentUser.name).toString(),
      email: (pick(['email', 'Email']) ?? currentUser.email).toString(),
      password: currentUser.password,
      phone: pick(['phone', 'Phone'])?.toString(),
      role: (pick(['role', 'Role']) ?? currentUser.role).toString(),
      createdAt: (pick(['createdAt', 'CreatedAt']) ?? currentUser.createdAt).toString(),
    );

    if (token == null) return false;
    await _saveUserInfo(updatedUser, token);
    return true;
  }

  // ================= PRIVATE: SAVE USER =================
  Future<void> _saveUserInfo(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user.toJson()));
    await prefs.setBool('isLoggedIn', true);
  }

  // ================= GET CURRENT USER =================
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn) return null;

    final userJson = prefs.getString('user');
    if (userJson == null) return null;

    final userMap = jsonDecode(userJson);
    return User.fromJson(userMap);
  }

  // ================= GET TOKEN =================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }
}