import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_model.dart';
import '../models/menu_model.dart';

class CartProvider extends ChangeNotifier {
  static const _prefsKey = 'cart_items';
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  // Refresh ke baad bhi cart yaad rahe, isliye load karo
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final list = jsonDecode(raw) as List;
      _items
        ..clear()
        ..addAll(list.map((i) => CartItem.fromJson(i)));
      notifyListeners();
    } catch (_) {
      // Corrupt data ho toh ignore karo
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode(_items.map((i) => i.toJson()).toList()));
  }

  // ---- PRICE CALCULATIONS ----

  double get subtotal => _items.fold(0, (sum, item) => sum + item.itemTotal);
  double get gst => subtotal * 0.05;           // 5% GST
  double get serviceCharge => subtotal * 0.05;  // 5% Service
  double get totalAmount => subtotal + gst + serviceCharge;

  // ---- CART OPERATIONS ----

  // Item add karo
  void addItem({
    required MenuItem menuItem,
    List<SelectedModifier> modifiers = const [],
    String instructions = '',
  }) {
    final newItem = CartItem(
      menuItemId: menuItem.id,
      name: menuItem.name,
      unitPrice: menuItem.price,
      isVeg: menuItem.isVeg,
      imageUrl: menuItem.imageUrl,
      modifiers: modifiers,
      specialInstructions: instructions,
    );

    // Check karo same item + same config pehle se hai kya
    final existingIdx =
        _items.indexWhere((i) => i.uniqueKey == newItem.uniqueKey);

    if (existingIdx >= 0) {
      _items[existingIdx].quantity++;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
    _persist();
  }

  // Quantity badhao
  void increaseQty(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      notifyListeners();
      _persist();
    }
  }

  // Quantity ghatao
  void decreaseQty(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
      _persist();
    }
  }

  // Item remove karo
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
      _persist();
    }
  }

  // Cart khaali karo
  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  // API format mein convert karo (Phase 3 mein order place ke liye)
  List<Map<String, dynamic>> toApiFormat() {
    return _items.map((item) {
      return {
        'menu_item_id': item.menuItemId,
        'quantity': item.quantity,
        'modifiers': item.modifiers.map((m) => m.id).toList(),
        'special_instructions': item.specialInstructions,
      };
    }).toList();
  }

  // Kisi specific item ki quantity check karo (UI badge ke liye)
  int getItemQty(int menuItemId) {
    return _items
        .where((i) => i.menuItemId == menuItemId)
        .fold(0, (sum, i) => sum + i.quantity);
  }
}
