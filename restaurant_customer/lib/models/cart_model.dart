class CartItem {
  final int menuItemId;
  final String name;
  final double unitPrice;
  final bool isVeg;
  final String? imageUrl;
  int quantity;
  final List<SelectedModifier> modifiers;
  final String specialInstructions;

  CartItem({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.isVeg,
    this.imageUrl,
    this.quantity = 1,
    this.modifiers = const [],
    this.specialInstructions = '',
  });

  // Ek item ka total (modifiers ke saath)
  double get itemTotal {
    double modPrice = modifiers.fold(0, (sum, m) => sum + m.price);
    return (unitPrice + modPrice) * quantity;
  }

  // Unique key (same item + same modifiers = same cart entry)
  String get uniqueKey {
    final modIds = modifiers.map((m) => m.id).toList()..sort();
    return '${menuItemId}_${modIds.join(',')}_$specialInstructions';
  }

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'unit_price': unitPrice,
        'is_veg': isVeg,
        'image_url': imageUrl,
        'quantity': quantity,
        'modifiers': modifiers.map((m) => m.toJson()).toList(),
        'special_instructions': specialInstructions,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItemId: json['menu_item_id'],
      name: json['name'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      isVeg: json['is_veg'] ?? true,
      imageUrl: json['image_url'],
      quantity: json['quantity'] ?? 1,
      modifiers: (json['modifiers'] as List?)
              ?.map((m) => SelectedModifier.fromJson(m))
              .toList() ??
          [],
      specialInstructions: json['special_instructions'] ?? '',
    );
  }
}

class SelectedModifier {
  final int id;
  final String name;
  final double price;

  SelectedModifier({
    required this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};

  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
    );
  }
}
