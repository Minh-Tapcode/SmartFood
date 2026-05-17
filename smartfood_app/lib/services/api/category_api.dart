import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../models/category.dart';
import '../../models/product.dart'; // ✅ THÊM
import '../ApiService.dart';

class CategoryApi {
  // ===== GET ALL =====
  Future<List<Category>> getCategories() async {
    final headers = await ApiService().getHeaders();

    final response = await http.get(
      Uri.parse('${Constant().baseUrl}/Category'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Load category failed');
    }
  }

  // ===== CREATE =====
  Future<bool> addCategory(String name, File? iconFile, {String? iconPath}) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constant().baseUrl}/Category'),
    );

    request.fields['Name'] = name;
    if (iconPath != null && iconPath.isNotEmpty) {
      request.fields['CurrentIconPath'] = iconPath;
    }

    if (iconFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('IconFile', iconFile.path),
      );
    }

    var res = await request.send();
    return res.statusCode == 200;
  }

  // ===== UPDATE =====
  Future<bool> updateCategory(
    int id,
    String name,
    File? iconFile, {
    String? currentIcon,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('${Constant().baseUrl}/Category/$id'),
    );

    request.fields['Name'] = name;

    if (currentIcon != null) {
      request.fields['CurrentIconPath'] = currentIcon;
    }

    if (iconFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('IconFile', iconFile.path),
      );
    }

    var res = await request.send();
    return res.statusCode == 200;
  }

  // ===== DELETE =====
  Future<bool> deleteCategory(int id) async {
    final res = await http.delete(
      Uri.parse('${Constant().baseUrl}/Category/$id'),
    );

    return res.statusCode == 200;
  }

  // ===== SEARCH =====
  Future<List<Category>> searchCategories(String keyword) async {
    final headers = await ApiService().getHeaders();

    final res = await http.get(
      Uri.parse('${Constant().baseUrl}/Category/search')
          .replace(queryParameters: {'keyword': keyword}),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Category.fromJson(e)).toList();
    }

    return [];
  }

  // ================== 🔥 THÊM ĐOẠN NÀY ==================
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Category/$categoryId/products'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map((e) => Product.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }
}
