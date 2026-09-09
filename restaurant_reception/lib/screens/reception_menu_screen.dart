import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/reception_api.dart';
import '../widgets/reception_sidebar.dart';
import '../widgets/reception_topbar.dart';

class ReceptionMenuScreen extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;
  final ValueChanged<String>? onNavigate;

  const ReceptionMenuScreen({
    super.key,
    required this.token,
    required this.receptionistName,
    required this.onLogout,
    this.onNavigate,
  });

  @override
  State<ReceptionMenuScreen> createState() => _ReceptionMenuScreenState();
}

class _ReceptionMenuScreenState extends State<ReceptionMenuScreen> {
  late ReceptionApi _api;
  List<dynamic> _categories = [];
  bool _loading = true;
  String _searchQuery = '';
  String _activeCategory = 'All';
  String _availabilityFilter = 'all'; // all, available, unavailable
  String _vegFilter = 'all'; // all, veg, non-veg
  String _viewMode = 'grid'; // grid or list

  @override
  void initState() {
    super.initState();
    _api = ReceptionApi(widget.token);
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _loading = true);
    final result = await _api.getMenu();
    if (!mounted) return;
    setState(() {
      _categories = result['success'] == true
          ? (result['data']?['menu'] ?? [])
          : _demoCategories();
      if (_categories.isEmpty) _categories = _demoCategories();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _demoCategories() {
    return [
      {
        'name': 'Starters',
        'items': [
          {'id': 1, 'name': 'Chicken Tikka', 'price': 280, 'is_veg': false, 'is_available': true, 'description': 'Spicy & juicy grilled chicken'},
          {'id': 2, 'name': 'Paneer Tikka', 'price': 240, 'is_veg': true, 'is_available': true, 'description': 'Grilled cottage cheese with spices'},
          {'id': 3, 'name': 'French Fries', 'price': 140, 'is_veg': true, 'is_available': true, 'description': 'Crispy & salted potato fries'},
        ]
      },
      {
        'name': 'Main Course',
        'items': [
          {'id': 4, 'name': 'Paneer Butter Masala', 'price': 260, 'is_veg': true, 'is_available': true, 'description': 'Rich & creamy paneer curry'},
          {'id': 5, 'name': 'Masala Dosa', 'price': 180, 'is_veg': true, 'is_available': true, 'description': 'South Indian rice crepe'},
          {'id': 12, 'name': 'Butter Chicken', 'price': 340, 'is_veg': false, 'is_available': false, 'description': 'Creamy tomato chicken curry'},
        ]
      },
      {
        'name': 'Biryani',
        'items': [
          {'id': 6, 'name': 'Chicken Biryani', 'price': 320, 'is_veg': false, 'is_available': true, 'description': 'Authentic Hyderabadi biryani'},
          {'id': 13, 'name': 'Veg Biryani', 'price': 220, 'is_veg': true, 'is_available': true, 'description': 'Fragrant rice with veggies'},
        ]
      },
      {
        'name': 'Chinese',
        'items': [
          {'id': 7, 'name': 'Veg Manchurian', 'price': 220, 'is_veg': true, 'is_available': true, 'description': 'Indo-Chinese favorite'},
          {'id': 14, 'name': 'Hakka Noodles', 'price': 200, 'is_veg': true, 'is_available': true, 'description': 'Stir-fried noodles with veggies'},
        ]
      },
      {
        'name': 'Pizza',
        'items': [
          {'id': 8, 'name': 'Margherita Pizza', 'price': 249, 'is_veg': true, 'is_available': true, 'description': 'Classic cheese & tomato'},
        ]
      },
      {
        'name': 'Beverages',
        'items': [
          {'id': 9, 'name': 'Cold Coffee', 'price': 120, 'is_veg': true, 'is_available': true, 'description': 'Chilled & refreshing'},
          {'id': 15, 'name': 'Fresh Lime Soda', 'price': 80, 'is_veg': true, 'is_available': true, 'description': 'Sweet & tangy'},
        ]
      },
      {
        'name': 'Desserts',
        'items': [
          {'id': 10, 'name': 'Gulab Jamun', 'price': 110, 'is_veg': true, 'is_available': true, 'description': 'Sweet & soft dessert'},
          {'id': 11, 'name': 'Chocolate Brownie', 'price': 190, 'is_veg': true, 'is_available': true, 'description': 'With vanilla ice cream'},
        ]
      },
    ];
  }

  IconData _catIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('starter')) return Icons.kebab_dining;
    if (n.contains('main')) return Icons.dinner_dining;
    if (n.contains('biryani')) return Icons.rice_bowl;
    if (n.contains('chinese')) return Icons.ramen_dining;
    if (n.contains('pizza')) return Icons.local_pizza;
    if (n.contains('burger')) return Icons.lunch_dining;
    if (n.contains('beverage') || n.contains('drink')) return Icons.local_drink;
    if (n.contains('dessert')) return Icons.cake;
    return Icons.restaurant;
  }

  double _money(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  // Get all items with category name attached
  List<Map<String, dynamic>> _allItems() {
    final List<Map<String, dynamic>> all = [];
    for (final cat in _categories) {
      final items = cat['items'] as List? ?? [];
      for (final item in items) {
        final map = Map<String, dynamic>.from(item as Map);
        map['_category'] = cat['name'];
        all.add(map);
      }
    }
    return all;
  }

  List<Map<String, dynamic>> _filteredItems() {
    var items = _allItems();

    if (_activeCategory != 'All') {
      items = items.where((i) => i['_category'] == _activeCategory).toList();
    }

    if (_availabilityFilter == 'available') {
      items = items.where((i) => (i['is_available'] ?? true) == true).toList();
    } else if (_availabilityFilter == 'unavailable') {
      items = items.where((i) => (i['is_available'] ?? true) == false).toList();
    }

    if (_vegFilter == 'veg') {
      items = items.where((i) => (i['is_veg'] ?? true) == true).toList();
    } else if (_vegFilter == 'non-veg') {
      items = items.where((i) => (i['is_veg'] ?? true) == false).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((i) =>
          (i['name'] ?? '').toString().toLowerCase().contains(q) ||
          (i['description'] ?? '').toString().toLowerCase().contains(q)).toList();
    }

    return items;
  }

  Future<void> _toggleAvailability(Map<String, dynamic> item) async {
    final current = item['is_available'] ?? true;
    setState(() => item['is_available'] = !current); // Optimistic UI

    final result = await _api.toggleItemAvailability(item['id'] as int, !current);
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => item['is_available'] = current); // Revert
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Failed to update'),
          backgroundColor: Colors.red));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${item['name']} marked ${!current ? "Available" : "Unavailable"}'),
          backgroundColor: !current ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 1)));
    }
  }

  int _countAvailable() =>
      _allItems().where((i) => i['is_available'] == true).length;
  int _countUnavailable() =>
      _allItems().where((i) => i['is_available'] == false).length;
  int _countVeg() => _allItems().where((i) => i['is_veg'] == true).length;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1100;
    final isMobile = w < 720;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.sidebarBg,
              child: ReceptionSidebar(activeLabel: 'Menu Management', onItemTap: widget.onNavigate),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              SizedBox(
                width: 230,
                child: ReceptionSidebar(activeLabel: 'Menu Management', onItemTap: widget.onNavigate),
              ),
            Expanded(
              child: Column(
                children: [
                  ReceptionTopBar(
                    receptionistName: widget.receptionistName,
                    onLogout: widget.onLogout,
                    searchHint: 'Search menu items...',
                    onSearch: (v) => setState(() => _searchQuery = v),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                        : _body(isMobile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroBanner(),
          const SizedBox(height: 20),
          _statsRow(),
          const SizedBox(height: 20),
          _categoryChips(),
          const SizedBox(height: 16),
          _filterBar(),
          const SizedBox(height: 16),
          _itemsSection(),
        ],
      ),
    );
  }

  // ============ HERO BANNER ============
  Widget _heroBanner() {
    final total = _allItems().length;
    final available = _countAvailable();
    final availabilityRate = total == 0 ? 0.0 : (available / total * 100);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B3410), Color(0xFF8B4513), Color(0xFFA0522D)],
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF8B4513).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.restaurant_menu,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Menu Management',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'View menu items, manage availability and browse categories',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _chip('$total Total Items', Colors.white),
                    const SizedBox(width: 8),
                    _chip('$available Active', Colors.greenAccent),
                    const SizedBox(width: 8),
                    _chip('${_categories.length} Categories', Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: availabilityRate / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${availabilityRate.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const Text('Available',
                              style: TextStyle(color: Colors.white60, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Menu Live Rate',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ============ STATS ============
  Widget _statsRow() {
    final stats = [
      ('Available', _countAvailable(), Icons.check_circle, AppTheme.statusAvailable),
      ('Unavailable', _countUnavailable(), Icons.remove_circle, Colors.red),
      ('Veg Items', _countVeg(), Icons.eco, Colors.green),
      ('Categories', _categories.length, Icons.category, AppTheme.brand),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats
            .map((s) => Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: s.$4.withOpacity(0.2))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: s.$4.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(s.$3, color: s.$4, size: 20)),
                          const Spacer(),
                          Text('${s.$2}',
                              style: TextStyle(
                                  color: s.$4,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(s.$1,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ============ CATEGORY CHIPS ============
  Widget _categoryChips() {
    final cats = ['All', ..._categories.map((c) => c['name'].toString())];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats.map((c) {
          final active = _activeCategory == c;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _activeCategory = c),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppTheme.brand : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? AppTheme.brand : Colors.grey.shade200),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: AppTheme.brand.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(c == 'All' ? Icons.grid_view_rounded : _catIcon(c),
                        size: 14, color: active ? Colors.white : Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(c,
                        style: TextStyle(
                            color: active ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============ FILTER BAR ============
  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dropdown('Availability',
                  {'all': 'All', 'available': 'Available', 'unavailable': 'Unavailable'},
                  _availabilityFilter,
                  (v) => setState(() => _availabilityFilter = v)),
              const SizedBox(width: 8),
              _dropdown('Type',
                  {'all': 'All', 'veg': 'Veg Only', 'non-veg': 'Non-Veg Only'},
                  _vegFilter,
                  (v) => setState(() => _vegFilter = v)),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_filteredItems().length} items',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              _viewBtn(Icons.grid_view_rounded, 'grid'),
              _viewBtn(Icons.view_list_rounded, 'list'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, Map<String, String> options, String current,
      Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<String>(
        value: current,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text('$label: ${e.value}')))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _viewBtn(IconData icon, String mode) {
    final active = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
            color: active ? AppTheme.brand : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: active ? Colors.white : Colors.grey.shade700, size: 16),
      ),
    );
  }

  // ============ ITEMS SECTION ============
  Widget _itemsSection() {
    final items = _filteredItems();
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No items found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Try changing filters or search', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    if (_viewMode == 'list') return _listView(items);
    return _gridView(items);
  }

  Widget _gridView(List<Map<String, dynamic>> items) {
    return LayoutBuilder(builder: (context, cons) {
      final w = cons.maxWidth;
      int cols = w >= 1200 ? 4 : w >= 900 ? 3 : w >= 500 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (_, i) => _itemCard(items[i]),
      );
    });
  }

  Widget _itemCard(Map<String, dynamic> item) {
    final isVeg = item['is_veg'] ?? true;
    final available = item['is_available'] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        border: Border.all(color: available ? Colors.transparent : Colors.red.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.orange.shade100, Colors.orange.shade200]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Center(
                  child: Icon(_catIcon(item['name'] ?? ''),
                      size: 50, color: Colors.orange.shade900),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isVeg ? Colors.green : Colors.red),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(item['_category'] ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
              if (!available)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
                    child: const Center(
                      child: Text('UNAVAILABLE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(item['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹ ${_money(item['price']).toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppTheme.brand)),
                      Switch(
                        value: available,
                        activeColor: Colors.green,
                        onChanged: (_) => _toggleAvailability(item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listView(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final item = items[i];
          final isVeg = item['is_veg'] ?? true;
          final available = item['is_available'] ?? true;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.orange.shade200]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(_catIcon(item['name'] ?? ''),
                    color: Colors.orange.shade900, size: 26),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isVeg ? Colors.green : Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(item['_category'] ?? '',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹ ${_money(item['price']).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.brand)),
                Switch(
                  value: available,
                  activeColor: Colors.green,
                  onChanged: (_) => _toggleAvailability(item),
                ),
              ],
            ),
            onTap: () => _showItemDetails(item),
          );
        },
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final isVeg = item['is_veg'] ?? true;
    final available = item['is_available'] ?? true;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.orange.shade200]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(_catIcon(item['name'] ?? ''),
                        color: Colors.orange.shade900, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.brandLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item['_category'] ?? '',
                            style: const TextStyle(
                                color: AppTheme.brand,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _detailRow(Icons.description, 'Description', item['description'] ?? 'No description'),
            _detailRow(Icons.currency_rupee, 'Price', '₹ ${_money(item['price']).toStringAsFixed(2)}'),
            _detailRow(isVeg ? Icons.eco : Icons.set_meal, 'Type', isVeg ? 'Vegetarian' : 'Non-Vegetarian'),
            _detailRow(Icons.check_circle, 'Status', available ? 'Available' : 'Unavailable',
                color: available ? Colors.green : Colors.red),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleAvailability(item);
                },
                icon: Icon(available ? Icons.remove_circle : Icons.check_circle, color: Colors.white),
                label: Text(available ? 'Mark as Unavailable' : 'Mark as Available',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: available ? Colors.orange : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color ?? Colors.black87)),
          ),
        ],
      ),
    );
  }
}