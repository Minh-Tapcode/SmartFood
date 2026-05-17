import 'package:flutter/material.dart';
import '../provider/checkout_provider.dart';
import 'payment_option_widget.dart';

class PaymentMethodSection extends StatelessWidget {
  final CheckoutProvider provider;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;

  const PaymentMethodSection({
    super.key,
    required this.provider,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          PaymentOptionWidget(
            provider: provider,
            value: 'COD',
            title: 'Thanh toán khi nhận hàng',
            subtitle: 'Trả tiền mặt khi nhận đơn',
            icon: Icons.money_outlined,
            color: primaryColor,
            isSelected: provider.state.paymentMethod == 'COD',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            backgroundColor: backgroundColor,
          ),
          const SizedBox(height: 12),
          PaymentOptionWidget(
            provider: provider,
            value: 'VNPAY',
            title: 'VNPay',
            subtitle: 'Thanh toán online qua VNPay',
            icon: Icons.account_balance_wallet_outlined,
            color: accentColor,
            isSelected: provider.state.paymentMethod == 'VNPAY',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            backgroundColor: backgroundColor,
          ),
        ],
      ),
    );
  }
}

