import 'package:flutter/material.dart';
import '../provider/checkout_provider.dart';

class TotalSection extends StatelessWidget {
  final CheckoutProvider provider;
  final VoidCallback onPlaceOrder;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;

  const TotalSection({
    super.key,
    required this.provider,
    required this.onPlaceOrder,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
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
          _buildTotalRow('Tổng thanh toán', provider.state.totalAmount,
              provider: provider, isTotal: true),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isProcessing ? null : onPlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.isProcessing
                        ? Colors.grey
                        : (isDark
                        ? Colors.green.shade400
                        : primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: provider.isProcessing ? 0 : (isDark ? 6 : 3),
                    shadowColor: provider.isProcessing
                        ? Colors.transparent
                        : (isDark
                        ? Colors.green.shade400.withOpacity(0.5)
                        : primaryColor.withOpacity(0.4)),
                  ),
                  child: provider.isProcessing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_checkout, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ĐẶT HÀNG NGAY',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {required CheckoutProvider provider, bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? textPrimary : textSecondary,
          ),
        ),
        Text(
          '${isDiscount && amount > 0 ? '-' : ''}${provider.formatPrice(amount)}đ',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? primaryColor
                : isDiscount
                ? Colors.green
                : textPrimary,
          ),
        ),
      ],
    );
  }
}

