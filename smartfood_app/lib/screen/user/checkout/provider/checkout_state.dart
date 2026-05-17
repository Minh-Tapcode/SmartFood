import '../../../../models/cart_item.dart';

class CheckoutState {
  final List<CartItem> selectedItems;
  final double totalAmount;
  final double shippingFee;
  final List<Map<String, dynamic>> savedVouchers;
  final int? selectedVoucherId;
  final double discountAmount;

  final String receiverName;
  final String receiverPhone;
  final String address;
  final String note;
  final String paymentMethod; // COD | VNPAY
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;

  CheckoutState({
    required this.selectedItems,
    required this.totalAmount,
    this.shippingFee = 15000,
    this.savedVouchers = const [],
    this.selectedVoucherId,
    this.discountAmount = 0,
    this.receiverName = '',
    this.receiverPhone = '',
    this.address = '',
    this.note = '',
    this.paymentMethod = 'COD',
    this.isLoading = false,
    this.isProcessing = false,
    this.errorMessage,
  });

  CheckoutState copyWith({
    List<CartItem>? selectedItems,
    double? totalAmount,
    double? shippingFee,
    List<Map<String, dynamic>>? savedVouchers,
    int? selectedVoucherId,
    bool clearSelectedVoucher = false,
    double? discountAmount,
    String? receiverName,
    String? receiverPhone,
    String? address,
    String? note,
    String? paymentMethod,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return CheckoutState(
      selectedItems: selectedItems ?? this.selectedItems,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      savedVouchers: savedVouchers ?? this.savedVouchers,
      selectedVoucherId: clearSelectedVoucher
          ? null
          : (selectedVoucherId ?? this.selectedVoucherId),
      discountAmount: discountAmount ?? this.discountAmount,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      address: address ?? this.address,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get payableAmount {
    final amount = totalAmount + shippingFee - discountAmount;
    return amount < 0 ? 0 : amount;
  }
}
