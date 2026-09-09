double _parseAmount(dynamic value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

class KitchenOrder {
  final int orderId;
  final int? tableId;
  final String tableNumber;
  final String status;
  final String? orderedByName;
  final String? orderedByPhone;
  final String? notes;
  final DateTime placedAt;
  final DateTime? acceptedAt;
  final DateTime? servedAt;
  final int minutesAgo;
  final double totalAmount;
  final List<KitchenOrderItem> items;
  final String? section;

  KitchenOrder({
    required this.orderId,
    this.tableId,
    required this.tableNumber,
    required this.status,
    this.orderedByName,
    this.orderedByPhone,
    this.notes,
    required this.placedAt,
    this.acceptedAt,
    this.servedAt,
    required this.minutesAgo,
    required this.totalAmount,
    this.items = const [],
    this.section,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    return KitchenOrder(
      orderId: json['id'],
      tableId: json['table_id'],
      tableNumber: json['table_number'] ?? 'T?',
      status: json['status'] ?? 'placed',
      orderedByName: json['ordered_by_name'],
      orderedByPhone: json['ordered_by_phone'],
      notes: json['notes'],
      placedAt: DateTime.tryParse(json['placed_at'] ?? '') ?? DateTime.now(),
      acceptedAt: DateTime.tryParse(json['accepted_at'] ?? ''),
      servedAt: DateTime.tryParse(json['served_at'] ?? ''),
      minutesAgo: json['minutes_ago'] ?? 0,
      totalAmount: json['final_amount'] != null
          ? _parseAmount(json['final_amount'])
          : 0,
      items: (json['items'] as List?)
              ?.map((i) => KitchenOrderItem.fromJson(i))
              .toList() ??
          [],
        section: json['section'],
    );
  }

  // Status ke hisaab se color
  String get statusColor {
    switch (status) {
      case 'placed':
        return 'red';
      case 'accepted':
        return 'orange';
      case 'preparing':
        return 'yellow';
      case 'ready':
        return 'green';
      case 'served':
        return 'grey';
      default:
        return 'grey';
    }
  }

  // Urgent hai kya? (10 min se zyada ho gaye)
  bool get isUrgent => minutesAgo >= 10 && status != 'ready' && status != 'served';

  // Very urgent? (20 min+)
  bool get isVeryUrgent => minutesAgo >= 20 && status != 'ready' && status != 'served';
}

class KitchenOrderItem {
  final int id;
  final String name;
  final int quantity;
  final String? specialInstructions;
  final List<String> modifiers;
  final String status;

  KitchenOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.specialInstructions,
    this.modifiers = const [],
    this.status = 'pending',
  });

  factory KitchenOrderItem.fromJson(Map<String, dynamic> json) {
    // Modifiers JSON array se parse karo
    List<String> mods = [];
    if (json['modifiers'] != null) {
      if (json['modifiers'] is List) {
        for (var m in json['modifiers']) {
          if (m is Map && m['name'] != null) {
            mods.add(m['name']);
          } else if (m is String) {
            mods.add(m);
          }
        }
      }
    }

    return KitchenOrderItem(
      id: json['id'],
      name: json['item_name'] ?? 'Unknown',
      quantity: json['quantity'] ?? 1,
      specialInstructions: json['special_instructions'],
      modifiers: mods,
      status: json['status'] ?? 'pending',
    );
  }
}
