import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/reception_api.dart';
import '../widgets/reception_sidebar.dart';
import '../widgets/reception_topbar.dart';

class ReceptionPosScreen extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;
  final dynamic initialTable;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTableMgmt;
  final VoidCallback? onNavigateToReports;
  final VoidCallback? onNavigateToMenu;
  final VoidCallback? onNavigateToSettings;

  const ReceptionPosScreen({
    super.key,
    required this.token,
    required this.receptionistName,
    required this.onLogout,
    this.initialTable,
    this.onNavigateToDashboard,
    this.onNavigateToTableMgmt,
    this.onNavigateToReports,
    this.onNavigateToMenu,
    this.onNavigateToSettings,
  });

  @override
  State<ReceptionPosScreen> createState() => _ReceptionPosScreenState();
}

class _ReceptionPosScreenState extends State<ReceptionPosScreen> {
  late ReceptionApi _api;
  final _searchCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _deliveryAddressCtrl = TextEditingController();

  // Menu Data
  List<dynamic> _categories = [];
  int _activeCategoryIndex = 0;
  bool _loading = true;

  // Cart Data
  final List<Map<String, dynamic>> _cart = [];

  // Table + Order Details
  String _orderMode = 'dine-in';
  int? _tableId;
  List<dynamic> _tables = [];
  List<dynamic> _existingItems = [];
  double _existingTotal = 0;
  bool _showPreviousOrders = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _api = ReceptionApi(widget.token);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _instructionsCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final menuResp = await _api.getMenu();
    final tables = await _api.getTables();
    if (!mounted) return;

    setState(() {
      _categories = menuResp['success'] == true
          ? (menuResp['data']?['menu'] ?? [])
          : _demoCategories();
      if (_categories.isEmpty) _categories = _demoCategories();
      _tables = tables.isNotEmpty ? tables : [];

      if (widget.initialTable != null) {
        _orderMode = 'dine-in';
        _tableId = _toInt(widget.initialTable['id']);
      }
      _loading = false;
    });

    final sessionId = widget.initialTable?['active_session_id'];
    if (sessionId != null) await _loadExistingBill(sessionId);
  }

  Future<void> _loadExistingBill(dynamic sessionId) async {
    final data = await _api.getBill(sessionId);
    if (!mounted || data == null) return;
    setState(() {
      _existingItems = data['items'] as List? ?? [];
      _existingTotal = _money(data['summary']?['final_amount']);
    });
  }

  double _money(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  int? _toInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '');

  // ============ DEMO FALLBACK ============
  List<Map<String, dynamic>> _demoCategories() {
    return [
      {
        'name': 'Starters',
        'items': [
          {'id': 1, 'name': 'Chicken Tikka', 'price': 280, 'is_veg': false, 'is_available': true, 'description': 'Spicy & juicy'},
          {'id': 2, 'name': 'Paneer Tikka', 'price': 240, 'is_veg': true, 'is_available': true, 'description': 'Grilled cottage cheese'},
          {'id': 3, 'name': 'French Fries', 'price': 140, 'is_veg': true, 'is_available': true, 'description': 'Crispy & salted'},
        ]
      },
      {
        'name': 'Main Course',
        'items': [
          {'id': 4, 'name': 'Paneer Butter Masala', 'price': 260, 'is_veg': true, 'is_available': true, 'description': 'Rich & creamy'},
          {'id': 5, 'name': 'Masala Dosa', 'price': 180, 'is_veg': true, 'is_available': true, 'description': 'South Indian special'},
        ]
      },
      {
        'name': 'Biryani',
        'items': [
          {'id': 6, 'name': 'Chicken Biryani', 'price': 320, 'is_veg': false, 'is_available': true, 'description': 'Hyderabadi style', 'popular': true},
        ]
      },
      {
        'name': 'Chinese',
        'items': [
          {'id': 7, 'name': 'Veg Manchurian', 'price': 220, 'is_veg': true, 'is_available': true, 'description': 'Indo-Chinese favorite'},
        ]
      },
      {
        'name': 'Pizza',
        'items': [
          {'id': 8, 'name': 'Margherita Pizza', 'price': 249, 'is_veg': true, 'is_available': true, 'description': 'Classic delight'},
        ]
      },
      {
        'name': 'Beverages',
        'items': [
          {'id': 9, 'name': 'Cold Coffee', 'price': 120, 'is_veg': true, 'is_available': true, 'description': 'Chilled & refreshing'},
        ]
      },
      {
        'name': 'Desserts',
        'items': [
          {'id': 10, 'name': 'Gulab Jamun', 'price': 110, 'is_veg': true, 'is_available': true, 'description': 'Sweet & soft'},
          {'id': 11, 'name': 'Chocolate Brownie', 'price': 190, 'is_veg': true, 'is_available': true, 'description': 'With ice cream'},
        ]
      },
    ];
  }

  IconData _categoryIcon(String name) {
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

  // ============ FILTER LOGIC ============
  List<dynamic> _visibleItems() {
    List<dynamic> all = [];
    if (_activeCategoryIndex == 0) {
      for (final cat in _categories) {
        all.addAll(cat['items'] as List? ?? []);
      }
    } else if (_activeCategoryIndex - 1 < _categories.length) {
      all = List.from(_categories[_activeCategoryIndex - 1]['items'] ?? []);
    }
    final q = _searchCtrl.text.toLowerCase();
    return all.where((item) {
      final available = item['is_available'] ?? true;
      final matchesSearch = q.isEmpty ||
          (item['name'] ?? '').toString().toLowerCase().contains(q);
      return available && matchesSearch;
    }).toList();
  }

  // ============ CART OPERATIONS ============
  void _addToCart(dynamic item) {
    final idx = _cart.indexWhere((c) => c['id'] == item['id']);
    setState(() {
      if (idx < 0) {
        _cart.add({
          'id': item['id'],
          'name': item['name'],
          'price': _money(item['price']),
          'qty': 1,
          'is_veg': item['is_veg'] ?? true,
        });
      } else {
        _cart[idx]['qty'] = (_cart[idx]['qty'] as int) + 1;
      }
    });
  }

  void _updateQty(int idx, int delta) {
    setState(() {
      final newQty = (_cart[idx]['qty'] as int) + delta;
      if (newQty < 1) {
        _cart.removeAt(idx);
      } else {
        _cart[idx]['qty'] = newQty;
      }
    });
  }

  void _removeFromCart(int idx) => setState(() => _cart.removeAt(idx));

  double get _subtotal =>
      _cart.fold(0.0, (s, i) => s + (_money(i['price']) * (i['qty'] as int)));
  double get _gst => _subtotal * 0.05;
  double get _service => _subtotal * 0.10;
  double get _total => _subtotal + _gst + _service;

  // ============ PLACE ORDER ============
  Future<void> _placeOrder({bool kotOnly = false}) async {
    if (_cart.isEmpty) {
      _snack('Cart is empty');
      return;
    }
    if (_orderMode == 'dine-in' && _tableId == null) {
      _snack('Please select a table');
      return;
    }
    if (_orderMode == 'delivery' && _deliveryAddressCtrl.text.trim().isEmpty) {
      _snack('Please enter the delivery address');
      return;
    }
    setState(() => _saving = true);

    final result = await _api.createOrder({
      'order_type': _orderMode,
      if (_tableId != null) 'table_id': _tableId,
      'items': _cart
          .map((c) => {'menu_item_id': c['id'], 'quantity': c['qty']})
          .toList(),
      if (_instructionsCtrl.text.trim().isNotEmpty)
        'notes': _instructionsCtrl.text.trim(),
      if (_deliveryAddressCtrl.text.trim().isNotEmpty)
        'delivery_address': _deliveryAddressCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      final orderId = result['data']?['order_id'] ?? '';
      _snack('${kotOnly ? "KOT" : "Order"} placed successfully! #$orderId', success: true);
      setState(() {
        _cart.clear();
        _instructionsCtrl.clear();
        _deliveryAddressCtrl.clear();
      });
    } else {
      _snack(result['message'] ?? 'Failed to place order');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : AppTheme.brand,
      duration: const Duration(seconds: 2),
    ));
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1200;
    final isTablet = w >= 800 && w < 1200;
    final isMobile = w < 800;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.sidebarBg,
              child: ReceptionSidebar(
                activeLabel: 'POS / Orders',
                onItemTap: _handleSidebarNavigation,
              ),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              SizedBox(
                width: 230,
                child: ReceptionSidebar(
                  activeLabel: 'POS / Orders',
                  onItemTap: _handleSidebarNavigation,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  ReceptionTopBar(
                    receptionistName: widget.receptionistName,
                    onLogout: widget.onLogout,
                    searchHint: 'Search for dishes (e.g. Biryani, Pizza, Coffee)...',
                    onSearch: (v) => setState(() {}),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                        : _body(isMobile, isTablet, isDesktop),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isMobile && _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openCartSheet(context),
              backgroundColor: AppTheme.brand,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text('${_cart.length} • ₹${_total.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  void _handleSidebarNavigation(String label) {
    VoidCallback? destination;
    if (label == 'Dashboard') destination = widget.onNavigateToDashboard;
    if (label == 'Table Management') destination = widget.onNavigateToTableMgmt;
    if (label == 'Reports') destination = widget.onNavigateToReports;
    if (label == 'Menu Management') destination = widget.onNavigateToMenu;
    if (label == 'Settings') destination = widget.onNavigateToSettings;

    if (destination == null) return;
    Navigator.pop(context);
    destination();
  }

  Widget _body(bool isMobile, bool isTablet, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _leftSection(isMobile)),
        if (!isMobile)
          SizedBox(
            width: isDesktop ? 400 : 340,
            child: _cartPanel(),
          ),
      ],
    );
  }

  // ============ LEFT SECTION (Menu) ============
  Widget _leftSection(bool isMobile) {
    return Column(
      children: [
        _leftHeader(),
        _categoriesRow(),
        Expanded(child: _menuGrid(isMobile)),
      ],
    );
  }

  Widget _leftHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Items to Order',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Browse menu, select items and add to table order',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _snack('Menu customization coming soon');
            },
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Customize Menu'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriesRow() {
    // First is "All Items"
    final all = [
      {'name': 'All Items', 'icon': Icons.grid_view_rounded},
      ..._categories.map((c) => {'name': c['name'], 'icon': _categoryIcon(c['name'])}),
    ];

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: all.length,
        itemBuilder: (_, i) {
          final active = _activeCategoryIndex == i;
          final item = all[i];
          return GestureDetector(
            onTap: () => setState(() => _activeCategoryIndex = i),
            child: Container(
              width: 78,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active ? AppTheme.brand : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? AppTheme.brand : Colors.grey.shade200),
                boxShadow: active
                    ? [BoxShadow(color: AppTheme.brand.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData,
                      color: active ? Colors.white : Colors.orange.shade700, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    item['name'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.black87,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _menuGrid(bool isMobile) {
    final items = _visibleItems();
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No items found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Try changing category or search', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (ctx, cons) {
      final w = cons.maxWidth;
      int cols = w >= 1100 ? 4 : w >= 800 ? 3 : w >= 500 ? 2 : 2;
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (_, i) => _menuCard(items[i]),
      );
    });
  }

  Widget _menuCard(dynamic item) {
    final isVeg = item['is_veg'] ?? true;
    final isPopular = item['popular'] == true;
    final inCart = _cart.any((c) => c['id'] == item['id']);
    final cartItem = inCart ? _cart.firstWhere((c) => c['id'] == item['id']) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Icon area
          Stack(
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.orange.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Center(
                  child: Icon(_categoryIcon(item['name'] ?? ''),
                      size: 55, color: Colors.orange.shade900),
                ),
              ),
              if (isPopular)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.brand,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Popular',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
              ),
            ],
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹ ${_money(item['price']).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      inCart
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.brand,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _updateQty(
                                        _cart.indexWhere((c) => c['id'] == item['id']), -1),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('${cartItem!['qty']}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  InkWell(
                                    onTap: () => _updateQty(
                                        _cart.indexWhere((c) => c['id'] == item['id']), 1),
                                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                            )
                          : InkWell(
                              onTap: () => _addToCart(item),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add, size: 13, color: AppTheme.brand),
                                    SizedBox(width: 3),
                                    Text('Add',
                                        style: TextStyle(
                                            color: AppTheme.brand,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
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

  // ============ RIGHT CART PANEL ============
  Widget _cartPanel() {
    return Container(
        height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          _cartHeader(),
          _cartTabs(),
          Expanded(
            child: _showPreviousOrders ? _previousOrdersList() : _currentOrderList(),
          ),
          if (!_showPreviousOrders) _cartFooter(),
        ],
      ),
    );
  }

  Widget _cartHeader() {
    final tableName = widget.initialTable != null
        ? 'Table ${widget.initialTable['table_number']}'
        : (_orderMode == 'dine-in' ? 'Select Table' : _orderMode.toUpperCase());
    final guests = widget.initialTable?['guests'];
    final isOccupied = widget.initialTable?['active_session_id'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.brand,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tableName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (guests != null) ...[
                      const Icon(Icons.people, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text('$guests Guests',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                _orderSelectors(),
              ],
            ),
          ),
          if (isOccupied)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('Occupied',
                  style: TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'clear') setState(() => _cart.clear());
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear Cart')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderSelectors() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _selectorBox(
          icon: Icons.receipt_long,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _orderMode,
              isDense: true,
              style: const TextStyle(color: Colors.black, fontSize: 12),
              items: const [
                DropdownMenuItem(value: 'dine-in', child: Text('Dine-in')),
                DropdownMenuItem(value: 'takeaway', child: Text('Takeaway')),
                DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
              ],
              onChanged: widget.initialTable != null
                  ? null
                  : (value) => setState(() {
                        _orderMode = value ?? 'dine-in';
                        if (_orderMode != 'dine-in') _tableId = null;
                      }),
            ),
          ),
        ),
        if (_orderMode == 'dine-in')
          _selectorBox(
            icon: Icons.table_restaurant,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _tables.any((table) => _toInt(table['id']) == _tableId) ? _tableId : null,
                hint: const Text('Select table'),
                isDense: true,
                style: const TextStyle(color: Colors.black, fontSize: 12),
                items: _tables
                    .map((table) => DropdownMenuItem<int>(
                          value: _toInt(table['id']),
                          child: Text('Table ${table['table_number']}'),
                        ))
                    .where((item) => item.value != null)
                    .toList(),
                onChanged: widget.initialTable != null
                    ? null
                    : (value) => setState(() => _tableId = value),
              ),
            ),
          ),
        if (_orderMode == 'delivery')
          SizedBox(
            width: 260,
            child: TextField(
              controller: _deliveryAddressCtrl,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                hintText: 'Delivery address',
                border: OutlineInputBorder(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _selectorBox({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 17),
        const SizedBox(width: 6),
        DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white, fontSize: 12),
          child: child,
        ),
      ]),
    );
  }

  Widget _cartTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showPreviousOrders = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: !_showPreviousOrders ? AppTheme.brand : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  'Current Order',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_showPreviousOrders ? AppTheme.brand : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showPreviousOrders = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _showPreviousOrders ? AppTheme.brand : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  'Previous Orders (${_existingItems.length})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _showPreviousOrders ? AppTheme.brand : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentOrderList() {
    if (_cart.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 130;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: compact ? 36 : 60,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: compact ? 4 : 12),
                  const Text(
                    'Cart is empty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add items from the menu',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _cart.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, i) {
        final item = _cart[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.orange.shade200]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_categoryIcon(item['name']), color: Colors.orange.shade900, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('₹ ${_money(item['price']).toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              // Qty controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _updateQty(i, -1),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.remove, size: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('${item['qty']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    InkWell(
                      onTap: () => _updateQty(i, 1),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.add, size: 14, color: AppTheme.brand),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _removeFromCart(i),
                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _previousOrdersList() {
    if (_existingItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 55, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No previous orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFFFF8E1),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, size: 18, color: Color(0xFF8A6400)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Previous Bill Total',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D4D00))),
              ),
              Text('₹${_existingTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D4D00))),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _existingItems.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) {
              final item = _existingItems[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${item['quantity']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: AppTheme.brand)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['item_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('₹${_money(item['unit_price']).toStringAsFixed(2)} each',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('₹${_money(item['total_price']).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _cartFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Special instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _instructionsCtrl,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Add special instructions...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bill breakdown
          _billRow('Subtotal', _subtotal),
          const SizedBox(height: 4),
          _billRow('GST (5%)', _gst),
          const SizedBox(height: 4),
          _billRow('Service Charge (10%)', _service),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹ ${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppTheme.brand)),
            ],
          ),
          const SizedBox(height: 12),
          // Buttons
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving || _cart.isEmpty ? null : () => _placeOrder(kotOnly: true),
              icon: const Icon(Icons.print, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save as KOT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brand,
                backgroundColor: AppTheme.brandLight,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving || _cart.isEmpty ? null : () => _placeOrder(),
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              label: Text(_saving ? 'Placing...' : 'Place Order',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        Text('₹ ${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // Mobile bottom sheet for cart
  void _openCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: _cartPanel(),
      ),
    );
  }
}