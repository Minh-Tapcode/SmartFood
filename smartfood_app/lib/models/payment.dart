class Payment {
  final int id;
  final int orderId;
  final String? method; // COD, VNPAY
  final double amount;
  final String? status; // pending, success
  final String? transactionId;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.orderId,
    this.method,
    required this.amount,
    this.status,
    this.transactionId,
    required this.createdAt,
  });

  // JSON -> Object
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      method: json['method'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      transactionId: json['transaction_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Object -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'method': method,
      'amount': amount,
      'status': status,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}