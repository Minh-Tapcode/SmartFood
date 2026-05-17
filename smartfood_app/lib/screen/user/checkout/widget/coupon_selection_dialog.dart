import 'package:flutter/material.dart';
import '../provider/checkout_provider.dart';

class CouponSelectionDialog extends StatelessWidget {
  final CheckoutProvider provider;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color backgroundColor;
  final Color surfaceColor;

  const CouponSelectionDialog({
    super.key,
    required this.provider,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.backgroundColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: surfaceColor,
      title: Text('Mã giảm giá', style: TextStyle(color: textPrimary)),
      content: Text(
        'Chức năng coupon tạm thời chưa dùng trong luồng checkout mới.',
        style: TextStyle(color: textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        )
      ],
    );
  }
}

