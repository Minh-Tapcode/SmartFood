import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/cart_item.dart';
import 'provider/checkout_provider.dart';
import 'widget/checkout_success_screen.dart';
import 'widget/vnpay_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.selectedItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  late final CheckoutProvider _checkoutProvider;
  bool _seededFormFromProvider = false;

  @override
  void initState() {
    super.initState();
    _checkoutProvider = CheckoutProvider(
      selectedItems: widget.selectedItems,
      totalAmount: widget.totalAmount,
    );
    _checkoutProvider.initialize();
  }

  void _seedFormFieldsOnce(CheckoutProvider provider) {
    if (_seededFormFromProvider) return;
    _seededFormFromProvider = true;
    final s = provider.state;
    _nameController.text = s.receiverName;
    _phoneController.text = s.receiverPhone;
    _addressController.text = s.address;
    _noteController.text = s.note;
  }

  @override
  void dispose() {
    _checkoutProvider.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CheckoutProvider>.value(
      value: _checkoutProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          title: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFF5F7F8),
          elevation: 0,
        ),
        body: Consumer<CheckoutProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            _seedFormFieldsOnce(provider);

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionCard(
                      title: 'Thông tin nhận hàng',
                      child: Column(
                        children: [
                          _roundedTextField(
                            controller: _nameController,
                            label: 'Họ và tên',
                            onChanged: provider.updateReceiverName,
                          ),
                          const SizedBox(height: 10),
                          _roundedTextField(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            onChanged: provider.updateReceiverPhone,
                          ),
                          const SizedBox(height: 10),
                          _roundedTextField(
                            controller: _addressController,
                            label: 'Địa chỉ giao hàng',
                            onChanged: provider.updateAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: 'Ghi chú đơn hàng',
                      child: _roundedTextField(
                        controller: _noteController,
                        label: 'Ghi chú',
                        minLines: 3,
                        maxLines: 4,
                        onChanged: provider.updateNote,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      title: 'Phương thức thanh toán',
                      child: Column(
                        children: [
                          _paymentOption(
                            value: 'COD',
                            current: provider.state.paymentMethod,
                            title: 'Thanh toán khi nhận hàng',
                            subtitle: 'Thanh toán bằng tiền mặt khi nhận đơn',
                            icon: Icons.payments_outlined,
                            onSelect: provider.updatePaymentMethod,
                          ),
                          const SizedBox(height: 10),
                          _paymentOption(
                            value: 'VNPAY',
                            current: provider.state.paymentMethod,
                            title: 'VNPay',
                            subtitle: 'Thanh toán online qua cổng VNPay',
                            icon: Icons.account_balance_wallet_outlined,
                            onSelect: provider.updatePaymentMethod,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionCard(
                      title: 'Sản phẩm đã chọn',
                      child: Column(
                        children: provider.state.selectedItems.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8ECEF)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: item.fullImageUrl.isNotEmpty
                                      ? Image.network(
                                          item.fullImageUrl,
                                          width: 58,
                                          height: 58,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 58,
                                          height: 58,
                                          color: const Color(0xFFF0F3F5),
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.image_outlined, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${provider.formatPrice(item.price)}đ x ${item.quantity}',
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                      if (item.stock >= 0)
                                        Text(
                                          'Tồn kho: ${item.stock}',
                                          style: const TextStyle(fontSize: 12, color: Colors.black45),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${provider.formatPrice(item.totalPrice)}đ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF14B789),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: 'Mã giảm giá',
                      child: DropdownButtonFormField<int>(
                        value: provider.state.selectedVoucherId,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Không áp dụng mã giảm giá'),
                          ),
                          ...provider.state.savedVouchers.map((p) {
                            final rawId = p['id'] ?? p['Id'];
                            final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
                            final title = (p['title'] ?? p['Title'] ?? 'Voucher').toString();
                            final percent = (p['discountPercent'] ?? p['DiscountPercent'] ?? '').toString();
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text('$title - $percent%'),
                            );
                          }),
                        ],
                        onChanged: provider.selectVoucher,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: 'Tổng thanh toán',
                      child: Column(
                        children: [
                          _moneyRow('Tổng tiền hàng', '${provider.formatPrice(provider.state.totalAmount)}đ'),
                          const SizedBox(height: 6),
                          _moneyRow('Phí vận chuyển', '${provider.formatPrice(provider.state.shippingFee)}đ'),
                          const SizedBox(height: 6),
                          _moneyRow(
                            'Giảm giá',
                            '-${provider.formatPrice(provider.state.discountAmount)}đ',
                            valueColor: Colors.redAccent,
                          ),
                          const Divider(height: 20),
                          _moneyRow(
                            'Tổng cần thanh toán',
                            '${provider.formatPrice(provider.state.payableAmount)}đ',
                            isBold: true,
                            valueColor: const Color(0xFF14B789),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B789),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      onPressed: provider.isProcessing
                          ? null
                          : () async {
                              if (!provider.validateForm()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng nhập đủ thông tin giao hàng'),
                                  ),
                                );
                                return;
                              }
                              try {
                                final result = await provider.submitOrder();
                                if (!mounted) return;
                                final paymentUrl = (result['paymentUrl'] ??
                                        result['PaymentUrl'] ??
                                        result['paymentURL'])
                                    ?.toString();
                                if (paymentUrl != null && paymentUrl.isNotEmpty) {
                                  final ok = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => VnPayWebViewScreen(
                                        paymentUrl: paymentUrl,
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (ok == true) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const CheckoutSuccessScreen(
                                          primaryColor: Color(0xFF14B789),
                                          secondaryColor: Color(0xFF0E9F6E),
                                          textPrimary: Colors.black87,
                                          textSecondary: Colors.black54,
                                          backgroundColor: Color(0xFFF5F7F8),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đơn đã tạo. Bạn có thể tiếp tục thanh toán VNPay sau.',
                                        ),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutSuccessScreen(
                                        primaryColor: Color(0xFF14B789),
                                        secondaryColor: Color(0xFF0E9F6E),
                                        textPrimary: Colors.black87,
                                        textSecondary: Colors.black54,
                                        backgroundColor: Color(0xFFF5F7F8),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi đặt hàng: $e')),
                                );
                              }
                            },
                      child: const Text('ĐẶT HÀNG NGAY', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                if (provider.isProcessing)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _roundedTextField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3E8)),
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required String current,
    required String title,
    required String subtitle,
    required IconData icon,
    required ValueChanged<String> onSelect,
  }) {
    final selected = value == current;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF2ECFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF8F64FF) : const Color(0xFFDDE3E8), width: 1.5),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: current,
              onChanged: (v) {
                if (v != null) onSelect(v);
              },
              activeColor: const Color(0xFF8F64FF),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF8F64FF) : const Color(0xFFEFF2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? Colors.white : Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(
    String label,
    String value, {
    Color valueColor = Colors.black87,
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      color: valueColor,
      fontSize: isBold ? 19 : 16,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
        Text(value, style: style),
      ],
    );
  }
}

