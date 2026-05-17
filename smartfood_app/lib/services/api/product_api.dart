import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../models/product.dart';
import '../ApiService.dart';

class ProductApi {
  Future<List<Product>> getProducts() async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      return (jsonDecode(res.body) as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final res = await http
          .get(
            Uri.parse('${Constant().baseUrl}/Product/$id'),
            headers: await ApiService().getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) return Product.fromJson(data.first);
      if (data is Map<String, dynamic>) return Product.fromJson(data);

      return null;
    } catch (e) {
      return null;
    }
  }

  //search products by name
  Future<List<Product>> searchProducts(String name) async {
    try {
      // Backend: GET /api/Product/search?keyword=...
      final uri = Uri.parse('${Constant().baseUrl}/Product/search')
          .replace(queryParameters: {'keyword': name});

      final response = await http.get(
        uri,
        headers: await ApiService().getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi tìm kiếm sản phẩm: $e');
    }
  }

// Trong ApiService class
  Future<bool> addProduct(
      Product product, int categoryId, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('${Constant().baseUrl}/Product'));

      // Thêm các trường dữ liệu
      request.fields['Name'] = product.name;
      request.fields['Description'] = product.description;
      request.fields['Price'] = product.price.toString();
      request.fields['Stock'] = product.stock.toString();
      request.fields['Origin'] = product.origin;
      request.fields['ExpiryDate'] = product.expiryDate;
      request.fields['Unit'] = product.unit;
      request.fields['CategoryId'] = categoryId.toString();

      // Thêm file ảnh nếu có
      if (imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('ImageFile', imageFile.path));
      }

      var response = await request.send();
      await response.stream.bytesToString();

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Lỗi thêm sản phẩm: $e');
    }
  }

  Future<bool> updateProduct(
      int id, Product product, int categoryId, File? imageFile) async {
    try {
      var request = http.MultipartRequest(
          'PUT', Uri.parse('${Constant().baseUrl}/Product/$id'));

      // Thêm các trường dữ liệu
      request.fields['Name'] = product.name;
      request.fields['Description'] = product.description;
      request.fields['Price'] = product.price.toString();
      request.fields['Stock'] = product.stock.toString();
      request.fields['Origin'] = product.origin;
      request.fields['ExpiryDate'] = product.expiryDate;
      request.fields['Unit'] = product.unit;
      request.fields['CategoryId'] = categoryId.toString();

      // Thêm file ảnh nếu có
      if (imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('ImageFile', imageFile.path));
      }

      var response = await request.send();
      await response.stream.bytesToString();

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi cập nhật sản phẩm: $e');
    }
  }

  Future<bool> updateProductImage(int id, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${Constant().baseUrl}/Product/$id/image'),
      );
      request.headers.addAll(await ApiService().getHeaders());
      request.files.add(
        await http.MultipartFile.fromPath('ImageFile', imageFile.path),
      );

      final response = await request.send();
      await response.stream.bytesToString();
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi cập nhật ảnh sản phẩm: $e');
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constant().baseUrl}/Product/$id'),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi xóa sản phẩm: $e');
    }
  }
}
