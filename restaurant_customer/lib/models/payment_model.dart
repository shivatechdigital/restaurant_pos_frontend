class PaymentOrder {
  final String razorpayOrderId;
  final double amount;
  final int amountInPaisa;
  final String currency;
  final String keyId;

  PaymentOrder({
    required this.razorpayOrderId,
    required this.amount,
    required this.amountInPaisa,
    required this.currency,
    required this.keyId,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      razorpayOrderId: json['razorpay_order_id'],
      amount: (json['amount'] as num).toDouble(),
      amountInPaisa: json['amount_in_paisa'],
      currency: json['currency'] ?? 'INR',
      keyId: json['key_id'],
    );
  }
}

class PaymentResult {
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;

  PaymentResult({
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
  });
}

class PaymentStatus {
  static const String pending = 'pending';
  static const String success = 'success';
  static const String failed = 'failed';
  static const String cash = 'cash';
}
