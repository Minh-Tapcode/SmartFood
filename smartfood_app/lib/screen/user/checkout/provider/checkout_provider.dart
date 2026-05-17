import 'package:flutter/material.dart';
import 'package:smartfood_app/services/api/promotion_api.dart';

import '../../../../models/cart_item.dart';
import 'checkout_service.dart';
import 'checkout_state.dart';

class CheckoutProvider with ChangeNotifier {
  final CheckoutService _service = CheckoutService();
  final PromotionApi _promotionApi = PromotionApi();
  CheckoutState _state;

  CheckoutProvider({
    required List<CartItem> selectedItems,
    required double totalAmount,
  }) : _state = CheckoutState(
          selectedItems: selectedItems,
          totalAmount: totalAmount,
        );

  CheckoutState get state => _state;
  bool get isLoading => _state.isLoading;
  bool get isProcessing => _state.isProcessing;

  Future<void> initialize() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    final userInfo = await _service.getCurrentUserInfo();
    await _promotionApi.syncUsedVouchersFromServer();
    final savedIds = await _promotionApi.getSavedVoucherIds();
    final usedIds = await _promotionApi.getUsedVoucherIds();
    final allPromotions = await _promotionApi.fetchActive();
    final savedVouchers = allPromotions.where((p) {
      final raw = p['id'] ?? p['Id'];
      final id = raw is int ? raw : int.tryParse('$raw') ?? 0;
      return id > 0 && savedIds.contains(id) && !usedIds.contains(id);
    }).toList();
    _state = _state.copyWith(
      isLoading: false,
      receiverName: userInfo?['name'] ?? '',
      receiverPhone: userInfo?['phone'] ?? '',
      savedVouchers: savedVouchers,
    );
    _recalculateDiscount();
    notifyListeners();
  }

  void updateReceiverName(String value) {
    _state = _state.copyWith(receiverName: value);
    notifyListeners();
  }

  void updateReceiverPhone(String value) {
    _state = _state.copyWith(receiverPhone: value);
    notifyListeners();
  }

  void updateAddress(String value) {
    _state = _state.copyWith(address: value);
    notifyListeners();
  }

  void updateNote(String value) {
    _state = _state.copyWith(note: value);
    notifyListeners();
  }

  void updatePaymentMethod(String value) {
    _state = _state.copyWith(paymentMethod: value);
    notifyListeners();
  }

  void selectVoucher(int? voucherId) {
    _state = _state.copyWith(selectedVoucherId: voucherId);
    _recalculateDiscount();
    notifyListeners();
  }

  void clearVoucher() {
    _state = _state.copyWith(clearSelectedVoucher: true, discountAmount: 0);
    notifyListeners();
  }

  void _recalculateDiscount() {
    final selectedId = _state.selectedVoucherId;
    if (selectedId == null) {
      _state = _state.copyWith(discountAmount: 0);
      return;
    }
    final selected = _state.savedVouchers.firstWhere(
      (p) {
        final raw = p['id'] ?? p['Id'];
        final id = raw is int ? raw : int.tryParse('$raw') ?? 0;
        return id == selectedId;
      },
      orElse: () => <String, dynamic>{},
    );
    if (selected.isEmpty) {
      _state = _state.copyWith(discountAmount: 0);
      return;
    }
    final percentRaw = selected['discountPercent'] ?? selected['DiscountPercent'] ?? 0;
    final percent = percentRaw is num ? percentRaw.toDouble() : double.tryParse('$percentRaw') ?? 0;
    final discount = _state.totalAmount * (percent / 100.0);
    _state = _state.copyWith(discountAmount: discount);
  }

  bool validateForm() {
    return _state.receiverName.trim().isNotEmpty &&
        _state.receiverPhone.trim().isNotEmpty &&
        _state.address.trim().isNotEmpty;
  }

  Future<Map<String, dynamic>> submitOrder() async {
    final userId = await _service.getCurrentUserId();
    if (userId == null) {
      throw Exception('Vui lòng đăng nhập để đặt hàng');
    }
    _state = _state.copyWith(isProcessing: true);
    notifyListeners();
    try {
      final res = await _service.createOrder(
        userId: userId,
        receiverName: _state.receiverName.trim(),
        receiverPhone: _state.receiverPhone.trim(),
        address: _state.address.trim(),
        note: _state.note.trim(),
        paymentMethod: _state.paymentMethod,
        shippingFee: _state.shippingFee,
        discountAmount: _state.discountAmount,
        finalAmount: _state.payableAmount,
        cartItemIds: _state.selectedItems.map((e) => e.id).toList(),
        promotionId: _state.selectedVoucherId,
      );
      final selectedVoucherId = _state.selectedVoucherId;
      if (selectedVoucherId != null) {
        await _promotionApi.markVoucherUsed(selectedVoucherId);
        _state = _state.copyWith(
          savedVouchers: _state.savedVouchers.where((p) {
            final raw = p['id'] ?? p['Id'];
            final id = raw is int ? raw : int.tryParse('$raw') ?? 0;
            return id != selectedVoucherId;
          }).toList(),
          clearSelectedVoucher: true,
          discountAmount: 0,
        );
      }
      return res;
    } finally {
      _state = _state.copyWith(isProcessing: false);
      notifyListeners();
    }
  }

  String formatPrice(double price) => _service.formatPrice(price);
}
