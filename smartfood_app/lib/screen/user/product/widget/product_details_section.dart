import 'package:flutter/material.dart';
import '../../../../models/product.dart';

class ProductDetailsSection extends StatelessWidget {
  final Product product;

  const ProductDetailsSection({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return _buildSection(
      icon: Icons.info_outline_rounded,
      title: "Thông tin chi tiết",
      child: Column(
        children: [
          _buildDetailRow("Mã sản phẩm", product.id.toString()),
          _buildDetailRow("Danh mục", _fallback(product.categoryName)),
          _buildDetailRow("Xuất xứ", _fallback(product.origin)),
          _buildDetailRow("Đơn vị tính", _fallback(product.unit)),
          _buildDetailRow(
            "Số lượng tồn",
            "${product.stock} ${_fallback(product.unit, "sp")}",
          ),
          _buildDetailRow(
            "Giá bán",
            "${_formatPrice(product.price)}đ/${_fallback(product.unit, "sp")}",
          ),
          _buildDetailRow("Hạn sử dụng", _fallback(product.expiryDate)),
          _buildDetailRow("Ngày tạo", _fallback(product.createdAt)),
          _buildDetailRow("Mô tả", _fallback(product.description)),
        ],
      ),
    );
  }

  String _fallback(String value, [String defaultValue = "Đang cập nhật"]) {
    return value.trim().isEmpty ? defaultValue : value.trim();
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.');
  }

  Widget _buildSection(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.green.shade600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
