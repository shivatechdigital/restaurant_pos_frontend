import 'package:flutter/material.dart';

import '../models/menu_model.dart';
import '../services/api_service.dart';

class MenuProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  bool _vegOnly = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  bool get vegOnly => _vegOnly;

  // Total items count
  int get totalItems =>
      _categories.fold(0, (sum, cat) => sum + cat.items.length);

  // Available items count
  int get availableItems => _categories.fold(
    0,
    (sum, cat) => sum + cat.items.where((i) => i.isAvailable).length,
  );

  // Menu load karo
  Future<void> loadMenu(String restaurantId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await _api.getMenu(restaurantId);

      if (result['success'] == true) {
        final menuList = result['data']['menu'] as List;
        _categories = menuList.map((c) => Category.fromJson(c)).toList();
      } else {
        _error = result['message'] ?? 'Menu load nahi hua';
      }
    } catch (e) {
      debugPrint('MenuProvider.loadMenu error: $e');
      _error = 'Network error. Server check karo.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search karo (local filter — fast)
  void search(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void setVegOnly(bool enabled) {
    _vegOnly = enabled;
    notifyListeners();
  }

  // Filtered categories (search ke hisaab se)
  List<Category> get filteredCategories {
    if (_searchQuery.isEmpty && !_vegOnly) return _categories;

    return _categories
        .map((cat) {
          final filteredItems = cat.items.where((item) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                item.name.toLowerCase().contains(_searchQuery) ||
                item.description.toLowerCase().contains(_searchQuery);
            return matchesSearch && (!_vegOnly || item.isVeg);
          }).toList();
          return Category(id: cat.id, name: cat.name, items: filteredItems);
        })
        .where((cat) => cat.items.isNotEmpty)
        .toList();
  }

  // Item availability update (Socket.io se Phase 3 mein)
  void updateItemAvailability(int itemId, bool available) {
    for (var cat in _categories) {
      final idx = cat.items.indexWhere((i) => i.id == itemId);
      if (idx >= 0) {
        // Rebuild list with updated item
        final oldItem = cat.items[idx];
        cat.items[idx] = MenuItem(
          id: oldItem.id,
          name: oldItem.name,
          description: oldItem.description,
          price: oldItem.price,
          imageUrl: oldItem.imageUrl,
          isVeg: oldItem.isVeg,
          isAvailable: available,
          prepTimeMinutes: oldItem.prepTimeMinutes,
          modifiers: oldItem.modifiers,
        );
        break;
      }
    }
    notifyListeners();
  }
}
