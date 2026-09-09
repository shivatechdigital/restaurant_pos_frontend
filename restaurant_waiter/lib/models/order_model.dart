double _parseAmount(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

class WaiterOrder {
  final int orderId;
  final int? sessionId;
  final int tableId;
  final String tableNumber;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final DateTime placedAt;
  final int minutesAgo;
  final String? notes;
  final List<WaiterOrderItem> items;

  WaiterOrder({
    required this.orderId,
    this.sessionId,
    required this.tableId,
    required this.tableNumber,
    required this.status,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.placedAt,
    required this.minutesAgo,
    this.notes,
    this.items = const [],
  });

  factory WaiterOrder.fromJson(Map<String, dynamic> json) {
    return WaiterOrder(
      orderId: _parseInt(json['id']),
      sessionId: _parseInt(json['session_id'], fallback: 0) == 0 ? null : _parseInt(json['session_id']),
      tableId: _parseInt(json['table_id'], fallback: 0),
      tableNumber: json['table_number']?.toString() ?? 'T?',
      status: json['status']?.toString() ?? 'placed',
      customerName: json['ordered_by_name']?.toString(),
      customerPhone: json['ordered_by_phone']?.toString(),
      totalAmount: json['final_amount'] != null ? _parseAmount(json['final_amount']) : 0,
      placedAt: DateTime.tryParse(json['placed_at'] ?? '') ?? DateTime.now(),
      minutesAgo: _parseInt(json['minutes_ago'], fallback: 0),
      notes: json['notes']?.toString(),
      items: (json['items'] as List?)
              ?.map((i) => WaiterOrderItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isServed => status == 'served';
  bool get isActive =>
      status == 'pending' ||
      status == 'placed' ||
      status == 'accepted' ||
      status == 'preparing' ||
      status == 'ready';
}

class WaiterOrderItem {
  final String name;
  final int quantity;
  final double totalPrice;
  final String status;

  WaiterOrderItem({
    required this.name,
    required this.quantity,
    required this.totalPrice,
    required this.status,
  });

  factory WaiterOrderItem.fromJson(Map<String, dynamic> json) {
    return WaiterOrderItem(
      name: json['item_name']?.toString() ?? 'Unknown',
      quantity: _parseInt(json['quantity'], fallback: 1),
      totalPrice: json['total_price'] != null
          ? _parseAmount(json['total_price'])
          : 0,
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

class BillData {
  final String tableNumber;
  final List<BillItem> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double serviceCharge;
  final double finalAmount;
  final double paidAmount;
  final double outstandingAmount;

  BillData({
    required this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.serviceCharge,
    required this.finalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  factory BillData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return BillData(
      tableNumber: json['table_number'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => BillItem.fromJson(i))
              .toList() ??
          [],
      subtotal: _parseAmount(summary['subtotal']),
      cgst: _parseAmount(summary['cgst']),
      sgst: _parseAmount(summary['sgst']),
      serviceCharge: _parseAmount(summary['service_charge']),
      finalAmount: _parseAmount(summary['final_amount']),
      paidAmount: _parseAmount(summary['paid_amount'] ?? 0),
      outstandingAmount: _parseAmount(summary['outstanding_amount'] ?? summary['final_amount']),
    );
  }
}

class BillItem {
  final int id;
  final String name;
  final int quantity;
  final double totalPrice;

  BillItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.totalPrice,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] ?? 0,
      name: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      totalPrice: json['total_price'] != null
          ? _parseAmount(json['total_price'])
          : 0,
    );
  }
}
