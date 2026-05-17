import 'package:flutter/material.dart';

/// Trạng thái chuẩn: pending | picking | shipping | completed | cancelled | returned
/// (processing / paid / … được map về các giá trị trên để khớp admin & user.)
String normalizeFulfillmentStatus(String raw) {
  final s = raw.toLowerCase().trim();
  if (s == 'cancelled' || s == 'failed') return 'cancelled';
  if (s == 'returned' || s == 'refund') return 'returned';
  if (s == 'completed' || s == 'delivered') return 'completed';
  if (s == 'shipping') return 'shipping';
  if (s == 'picking' || s == 'processing' || s == 'confirmed') return 'picking';
  if (s == 'paid' || s == 'pending payment') return 'picking';
  if (s == 'pending') return 'pending';
  return 'pending';
}

String fulfillmentDisplayLabel(String raw) {
  switch (normalizeFulfillmentStatus(raw)) {
    case 'pending':
      return 'Chờ xác nhận';
    case 'picking':
      return 'Chờ lấy hàng';
    case 'shipping':
      return 'Chờ giao hàng';
    case 'completed':
      return 'Đã giao';
    case 'cancelled':
      return 'Đã hủy';
    case 'returned':
      return 'Trả hàng';
    default:
      return raw;
  }
}

Color fulfillmentStatusColor(String status) {
  switch (normalizeFulfillmentStatus(status)) {
    case 'pending':
      return const Color(0xFFFFA726);
    case 'picking':
      return const Color(0xFF42A5F5);
    case 'shipping':
      return const Color(0xFF7E57C2);
    case 'completed':
      return const Color(0xFF66BB6A);
    case 'cancelled':
      return const Color(0xFFEF5350);
    case 'returned':
      return const Color(0xFF8D6E63);
    default:
      return const Color(0xFF78909C);
  }
}

IconData fulfillmentStatusIcon(String status) {
  switch (normalizeFulfillmentStatus(status)) {
    case 'pending':
      return Icons.access_time_rounded;
    case 'picking':
      return Icons.inventory_2_outlined;
    case 'shipping':
      return Icons.local_shipping_rounded;
    case 'completed':
      return Icons.verified_rounded;
    case 'cancelled':
      return Icons.cancel_rounded;
    case 'returned':
      return Icons.assignment_return_rounded;
    default:
      return Icons.shopping_bag_rounded;
  }
}

/// 0–3: bước giao hàng; -1: đã hủy; -2: trả hàng
int fulfillmentStepIndex(String raw) {
  final n = normalizeFulfillmentStatus(raw);
  if (n == 'cancelled') return -1;
  if (n == 'returned') return -2;
  switch (n) {
    case 'pending':
      return 0;
    case 'picking':
      return 1;
    case 'shipping':
      return 2;
    case 'completed':
      return 3;
    default:
      return 0;
  }
}

String paymentDisplayLabel(String raw) {
  switch (raw.toLowerCase().trim()) {
    case 'paid':
      return 'Đã thanh toán';
    case 'pending':
      return 'Chưa thanh toán';
    case 'failed':
      return 'Thanh toán thất bại';
    case 'unpaid':
      return 'Chưa thanh toán';
    default:
      return raw.isEmpty ? '—' : raw;
  }
}

/// filterKey: all | pending | picking | shipping | completed | cancelled | returned
bool orderMatchesStatusFilter(String rawStatus, String filterKey) {
  if (filterKey == 'all') return true;
  return normalizeFulfillmentStatus(rawStatus) == filterKey;
}
