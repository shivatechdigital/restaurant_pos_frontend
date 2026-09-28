// Postgres NUMERIC columns JSON mein string ke roop mein aate hain
double _parsePrice(dynamic value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

class Category {
  final int id;
  final String name;
  final int displayOrder;
  final List<MenuItem> items;

  Category({
    required this.id,
    required this.name,
    this.displayOrder = 0,
    this.items = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      displayOrder: json['display_order'] ?? 0,
      items:
          (json['items'] as List?)?.map((i) => MenuItem.fromJson(i)).toList() ??
          [],
    );
  }
}

class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isVeg;
  final bool isAvailable;
  final int prepTimeMinutes;
  final List<Modifier> modifiers;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.isVeg,
    required this.isAvailable,
    required this.prepTimeMinutes,
    this.modifiers = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: _parsePrice(json['price']),
      imageUrl: json['image_url'],
      isVeg: json['is_veg'] ?? true,
      isAvailable: json['is_available'] ?? true,
      prepTimeMinutes: json['prep_time_minutes'] ?? 10,
      modifiers:
          (json['modifiers'] as List?)
              ?.map((m) => Modifier.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class Modifier {
  final int id;
  final String name;
  final double price;
  final bool isDefault;

  Modifier({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'],
      name: json['name'],
      price: _parsePrice(json['price']),
      isDefault: json['is_default'] ?? false,
    );
  }
}
