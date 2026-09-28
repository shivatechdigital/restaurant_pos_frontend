// Postgres NUMERIC columns JSON mein string ke roop mein aate hain
double _parseAmount(dynamic value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

class OrderData {
  final int orderId;
  final String status;
  final String? statusMessage;
  final double? totalAmount;
  final String? placedAt;
  final List<OrderItemData> items;

  OrderData({
    required this.orderId,
    required this.status,
    this.statusMessage,
    this.totalAmount,
    this.placedAt,
    this.items = const [],
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      orderId: json['order_id'] ?? json['id'],
      status: json['status'] ?? 'placed',
      statusMessage: json['message'],
      totalAmount: json['final_amount'] != null
          ? _parseAmount(json['final_amount'])
          : null,
      placedAt: json['placed_at'],
      items:
          (json['items'] as List?)
              ?.map((i) => OrderItemData.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class OrderItemData {
  final String name;
  final int quantity;
  final double totalPrice;

  OrderItemData({
    required this.name,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItemData.fromJson(Map<String, dynamic> json) {
    return OrderItemData(
      name: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      totalPrice: _parseAmount(json['total_price'] ?? 0),
    );
  }
}

class OrderStatus {
  static const String placed = 'placed';
  static const String accepted = 'accepted';
  static const String preparing = 'preparing';
  static const String ready = 'ready';
  static const String served = 'served';
  static const String cancelled = 'cancelled';

  // Status ka order (stepper ke liye)
  static int getStepIndex(String status) {
    switch (status) {
      case placed:
        return 0;
      case accepted:
        return 1;
      case preparing:
        return 2;
      case ready:
        return 3;
      case served:
        return 4;
      case cancelled:
        return -1;
      default:
        return 0;
    }
  }

  // Status ka display name
  static String getDisplayName(String status) {
    switch (status) {
      case placed:
        return 'Order Placed';
      case accepted:
        return 'Accepted by Kitchen';
      case preparing:
        return 'Preparing Your Food';
      case ready:
        return 'Ready to Serve';
      case served:
        return 'Served on Table';
      case cancelled:
        return 'Order Cancelled';
      default:
        return status;
    }
  }

  // Status ka message (customer ke liye)
  static String getMessage(String status) {
    switch (status) {
      case placed:
        return 'Aapka order kitchen tak pahunch gaya hai! 👨‍🍳';
      case accepted:
        return 'Kitchen ne order accept kar liya hai. Jaldi banega! ✅';
      case preparing:
        return 'Aapka khana ban raha hai... thoda wait karo 🔥';
      case ready:
        return 'Khana ready hai! Waiter laane wala hai 🍽️';
      case served:
        return 'Order serve ho gaya! Enjoy your meal! 🎉';
      case cancelled:
        return 'Order cancel ho gaya hai. ❌';
      default:
        return 'Processing...';
    }
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
      items:
          (json['items'] as List?)?.map((i) => BillItem.fromJson(i)).toList() ??
          [],
      subtotal: _parseAmount(summary['subtotal']),
      cgst: _parseAmount(summary['cgst']),
      sgst: _parseAmount(summary['sgst']),
      serviceCharge: _parseAmount(summary['service_charge']),
      finalAmount: _parseAmount(summary['final_amount']),
      paidAmount: _parseAmount(summary['paid_amount'] ?? 0),
      outstandingAmount: _parseAmount(
        summary['outstanding_amount'] ?? summary['final_amount'],
      ),
    );
  }
}

class BillItem {
  final String name;
  final int quantity;
  final double totalPrice;

  BillItem({
    required this.name,
    required this.quantity,
    required this.totalPrice,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      totalPrice: _parseAmount(json['total_price']),
    );
  }
}
