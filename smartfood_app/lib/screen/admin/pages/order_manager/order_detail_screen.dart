import 'package:flutter/material.dart';
import 'package:smartfood_app/screen/admin/services/admin_order_service.dart';
import 'package:smartfood_app/utils/order_status_helpers.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final _service = AdminOrderService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn #${widget.orderId}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final orderMap = _unwrapOrderMap(data);
          final details =
              (data['orderDetails'] ?? data['OrderDetails'] ?? const []) as List;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _service.getOrderDetail(widget.orderId);
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _infoCard('Thông tin đơn hàng', [
                  _row('Mã đơn', '${orderMap['id'] ?? orderMap['Id'] ?? widget.orderId}'),
                  _row(
                    'Trạng thái',
                    fulfillmentDisplayLabel(
                      '${orderMap['status'] ?? orderMap['Status'] ?? ''}',
                    ),
                  ),
                  _row(
                      'Thanh toán',
                      '${orderMap['paymentStatus'] ?? orderMap['PaymentStatus'] ?? '--'}'),
                  _row(
                      'Phương thức',
                      '${orderMap['paymentMethod'] ?? orderMap['PaymentMethod'] ?? '--'}'),
                  _row(
                      'Tổng tiền',
                      '${orderMap['totalPrice'] ?? orderMap['TotalPrice'] ?? 0} VND'),
                  _row(
                      'Phí vận chuyển',
                      '${orderMap['shippingFee'] ?? orderMap['ShippingFee'] ?? 0} VND'),
                  _row(
                      'Giảm giá',
                      '${orderMap['discountAmount'] ?? orderMap['DiscountAmount'] ?? 0} VND'),
                  if ((orderMap['promotionTitle'] ?? orderMap['PromotionTitle']) != null &&
                      '${orderMap['promotionTitle'] ?? orderMap['PromotionTitle']}'.isNotEmpty)
                    _row(
                        'Mã / chương trình',
                        '${orderMap['promotionTitle'] ?? orderMap['PromotionTitle']}'),
                  _row(
                      'Ngày tạo',
                      '${orderMap['createdAt'] ?? orderMap['CreatedAt'] ?? '--'}'),
                ]),
                const SizedBox(height: 12),
                _infoCard('Thông tin nhận hàng', [
                  _row('Người nhận',
                      '${orderMap['receiverName'] ?? orderMap['ReceiverName'] ?? '--'}'),
                  _row('Số điện thoại',
                      '${orderMap['receiverPhone'] ?? orderMap['ReceiverPhone'] ?? '--'}'),
                  _row('Địa chỉ', '${orderMap['address'] ?? orderMap['Address'] ?? '--'}'),
                  _row('Ghi chú', '${orderMap['note'] ?? orderMap['Note'] ?? '--'}'),
                ]),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Danh sách sản phẩm',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (details.isEmpty)
                          const Text('Không có dữ liệu sản phẩm trong đơn'),
                        ...details.map((e) {
                          final item = Map<String, dynamic>.from(e as Map);
                          final linePrice = item['price'] ??
                              item['Price'] ??
                              item['unitPrice'] ??
                              item['UnitPrice'] ??
                              0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                                '${item['productName'] ?? item['ProductName'] ?? 'Sản phẩm'}'),
                            subtitle: Text(
                                'SL: ${item['quantity'] ?? item['Quantity'] ?? 0}'),
                            trailing: Text('$linePrice VND'),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  /// API trả `{ order, orderDetails }` (camelCase/PascalCase); hỗ trợ cả dữ liệu phẳng cũ.
  Map<String, dynamic> _unwrapOrderMap(Map<String, dynamic> data) {
    final nested = data['order'] ?? data['Order'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return data;
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
