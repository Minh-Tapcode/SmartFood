import 'package:flutter/material.dart';
import 'package:smartfood_app/models/order.dart';
import 'package:smartfood_app/utils/order_status_helpers.dart';

import 'order_list_service.dart';
import 'order_list_state.dart';

class OrderListProvider with ChangeNotifier {
  final OrderListService _orderListService = OrderListService();
  OrderListState _state = const OrderListState();

  // Getters
  OrderListState get state => _state;
  List<Order> get orders => _state.orders;
  bool get isLoading => _state.isLoading;
  String get errorMessage => _state.errorMessage;

  // Methods
  Future<void> loadOrders() async {
    _updateState(_state.loading());

    try {
      final orders = await _orderListService.getOrdersByUser();
      _updateState(_state.success(orders));
    } catch (e) {
      _updateState(_state.error(e.toString()));
    }
  }

  void retryLoading() {
    loadOrders();
  }

  void clearError() {
    _updateState(_state.clearError());
  }

  // Private method
  void _updateState(OrderListState newState) {
    _state = newState;
    notifyListeners();
  }

  // Helper methods
  String getStatusText(String status) => fulfillmentDisplayLabel(status);

  Color getStatusColor(String status) => fulfillmentStatusColor(status);

  IconData getStatusIcon(String status) => fulfillmentStatusIcon(status);

  String formatDate(DateTime date) {
    return '${date.day} Th${date.month}, ${date.year}';
  }

  String formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}