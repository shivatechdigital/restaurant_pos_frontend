import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_sidebar.dart';
import 'print_preview_screen.dart';

class PosCounterScreen extends StatefulWidget {
  const PosCounterScreen({super.key});

  @override
  State<PosCounterScreen> createState() => _PosCounterScreenState();
}

class _PosCounterScreenState extends State<PosCounterScreen> {
  final _api = ApiService();

  final _search = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerName = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _deliveryLandmark = TextEditingController();
  final _notes = TextEditingController();
  final _couponCode = TextEditingController();
  final _managerPin = TextEditingController();
  final _manualDiscount = TextEditingController();
  final _loyaltyPoints = TextEditingController();

  bool _loading = true;
  bool _placing = false;
  String? _loadError;

  List<dynamic> _categories = [];
  List<dynamic> _tables = [];
  int _selectedCategoryIndex = 0;
  String _orderType = 'dine-in'; // dine-in | takeaway | delivery
  int? _selectedTableId;
  int _availableLoyaltyPoints = 0;

  final List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _search.dispose();
    _customerPhone.dispose();
    _customerName.dispose();
    _deliveryAddress.dispose();
    _deliveryLandmark.dispose();
    _notes.dispose();
    _couponCode.dispose();
    _managerPin.dispose();
    _manualDiscount.dispose();
    _loyaltyPoints.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final restaurantId = context.read<AdminProvider>().restaurantId.toString();
      final results = await Future.wait([
        _api.getMenu(restaurantId),
        _api.getTables(),
      ]);
      if (!mounted) return;
      final menuResult = results[0];
      final tablesResult = results[1];
      setState(() {
        _categories = menuResult['success'] == true
            ? (menuResult['data']['menu'] ?? [])
            : [];
        _tables = tablesResult['success'] == true ? (tablesResult['data'] ?? []) : [];
        _loading = false;
        _loadError = _categories.isEmpty ? 'Menu load nahi ho paaya' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Backend se connect nahi ho pa raha';
      });
    }
  }

  List<dynamic> get _visibleItems {
    final query = _search.text.trim().toLowerCase();
    List<dynamic> items;
    if (_selectedCategoryIndex == 0) {
      items = _categories.expand((c) => (c['items'] as List? ?? [])).toList();
    } else if (_selectedCategoryIndex - 1 < _categories.length) {
      items = (_categories[_selectedCategoryIndex - 1]['items'] as List?) ?? [];
    } else {
      items = [];
    }
    return items.where((item) {
      if (item['is_available'] == false) return false;
      if (query.isEmpty) return true;
      return (item['name'] ?? '').toString().toLowerCase().contains(query);
    }).toList();
  }

  double _money(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  double get subtotal => _cart.fold(
      0.0, (sum, item) => sum + (_money(item['price']) * (item['qty'] as int)));
  double get estimatedGst => subtotal * 0.05;
  double get manualDiscountAmount =>
      double.tryParse(_manualDiscount.text.trim()) ?? 0;
  double get estimatedTotal => subtotal + estimatedGst - manualDiscountAmount;

  void _addToCart(dynamic item) {
    final id = item['id'];
    setState(() {
      final index = _cart.indexWhere((c) => c['menu_item_id'] == id);
      if (index >= 0) {
        _cart[index]['qty'] = (_cart[index]['qty'] as int) + 1;
      } else {
        _cart.add({
          'menu_item_id': id,
          'name': item['name'],
          'price': _money(item['price']),
          'qty': 1,
          'is_veg': item['is_veg'] ?? true,
          'image_url': item['image_url'],
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${item['name']} added to cart'),
      duration: const Duration(seconds: 1),
      backgroundColor: const Color(0xFFE67E22),
    ));
  }

  void _changeQty(int index, int delta) {
    setState(() {
      final qty = (_cart[index]['qty'] as int) + delta;
      if (qty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['qty'] = qty;
      }
    });
  }

  void _removeFromCart(int index) => setState(() => _cart.removeAt(index));

  Future<void> _lookupLoyalty() async {
    final phone = _customerPhone.text.trim();
    if (phone.length < 10) {
      setState(() => _availableLoyaltyPoints = 0);
      return;
    }
    try {
      final result = await _api.getCustomers(search: phone);
      if (!mounted || result['success'] != true) return;
      final list = result['data'] as List? ?? [];
      final match = list.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['phone'] == phone,
            orElse: () => null,
          );
      setState(() {
        _availableLoyaltyPoints =
            match != null ? ((match['loyalty_points'] as num?)?.toInt() ?? 0) : 0;
        if (match != null && _customerName.text.trim().isEmpty) {
          _customerName.text = match['name'] ?? '';
        }
      });
    } catch (_) {
      // Loyalty lookup is a convenience feature; ignore failures silently.
    }
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) {
      _showMessage('Cart khali hai, pehle items add karo');
      return;
    }
    if (_orderType == 'dine-in' && _selectedTableId == null) {
      _showMessage('Dine-in ke liye table select karo');
      return;
    }
    if (_orderType == 'delivery' && _deliveryAddress.text.trim().isEmpty) {
      _showMessage('Delivery address chahiye');
      return;
    }

    setState(() => _placing = true);
    try {
      final body = {
        'order_type': _orderType,
        if (_orderType == 'dine-in') 'table_id': _selectedTableId,
        if (_customerPhone.text.trim().isNotEmpty)
          'customer_phone': _customerPhone.text.trim(),
        if (_customerName.text.trim().isNotEmpty)
          'customer_name': _customerName.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        if (_couponCode.text.trim().isNotEmpty)
          'coupon_code': _couponCode.text.trim(),
        if (_managerPin.text.trim().isNotEmpty)
          'manager_pin': _managerPin.text.trim(),
        if (manualDiscountAmount > 0) 'discount_amount': manualDiscountAmount,
        if (_loyaltyPoints.text.trim().isNotEmpty)
          'loyalty_points_to_redeem': int.tryParse(_loyaltyPoints.text.trim()) ?? 0,
        if (_orderType == 'delivery')
          'delivery_address': _deliveryAddress.text.trim(),
        if (_orderType == 'delivery' && _deliveryLandmark.text.trim().isNotEmpty)
          'delivery_landmark': _deliveryLandmark.text.trim(),
        'items': _cart
            .map((c) => {'menu_item_id': c['menu_item_id'], 'quantity': c['qty']})
            .toList(),
      };
      final result = await _api.createPosOrder(body);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'];
        final orderId = data['order_id'] as int;
        final finalAmount = _money(data['summary']?['final_amount']);
        _showMessage(
            'Order #$orderId placed \u2022 \u20b9${finalAmount.toStringAsFixed(0)}',
            color: Colors.green);
        _resetOrder();
        await _loadInitialData();
        if (!mounted) return;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PrintPreviewScreen(orderId: orderId, type: 'KOT')));
      } else {
        _showMessage(result['message']?.toString() ?? 'Order place nahi ho paaya');
      }
    } catch (_) {
      _showMessage(
          'Order request fail ho gayi ya timeout hua. Orders screen check karo phir retry karo.');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _resetOrder() {
    setState(() {
      _cart.clear();
      _selectedTableId = null;
      _customerPhone.clear();
      _customerName.clear();
      _deliveryAddress.clear();
      _deliveryLandmark.clear();
      _notes.clear();
      _couponCode.clear();
      _managerPin.clear();
      _manualDiscount.clear();
      _loyaltyPoints.clear();
      _availableLoyaltyPoints = 0;
    });
  }

  void _showMessage(String text, {Color color = const Color(0xFFE67E22)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;
    final isDesktop = width >= 1100;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: isMobile || isTablet ? _buildDrawer() : null,
      endDrawer: isMobile ? _buildCartDrawer() : null,
      appBar: (isMobile || isTablet) ? _buildAppBar(isMobile) : null,
      body: SafeArea(
        child: _loadError != null
            ? _buildErrorView()
            : Row(
                children: [
                  if (isDesktop) _buildSidebar(),
                  Expanded(
                    flex: isDesktop ? 5 : (isTablet ? 3 : 1),
                    child: Column(
                      children: [
                        if (!isMobile) _buildTopBar(isTablet),
                        _buildCategoriesBar(isMobile),
                        Expanded(
                          child: _visibleItems.isEmpty
                              ? Center(
                                  child: Text('Is category mein items nahi hain',
                                      style: TextStyle(color: Colors.grey.shade500)))
                              : SingleChildScrollView(
                                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                                  child: _buildFoodGrid(_visibleItems, isMobile, isTablet),
                                ),
                        ),
                        _buildBottomActionBar(),
                      ],
                    ),
                  ),
                  if (isTablet || isDesktop)
                    SizedBox(width: isDesktop ? 380 : 300, child: _buildCartPanel()),
                ],
              ),
      ),
      floatingActionButton: isMobile && _cart.isNotEmpty
          ? Builder(
              builder: (context) => FloatingActionButton.extended(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                backgroundColor: const Color(0xFFE67E22),
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  '${_cart.length} items \u2022 \u20b9${estimatedTotal.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFFE67E22), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('POS Counter',
              style:
                  TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        if (isMobile)
          Stack(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration:
                        const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_cart.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFE67E22)),
          const SizedBox(height: 12),
          Text(_loadError ?? 'Load error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22), foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: const Color(0xFF2D2D2D),
      child: const AppSidebar(activeLabel: 'POS Counter'),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF2D2D2D),
      child: const SafeArea(child: AppSidebar(activeLabel: 'POS Counter')),
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar(bool isTablet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search for dishes...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (!isTablet) ...[
            _buildOrderTypeButton('dine-in', 'Dine In', Icons.restaurant),
            _buildOrderTypeButton('takeaway', 'Take Away', Icons.takeout_dining),
            _buildOrderTypeButton('delivery', 'Delivery', Icons.delivery_dining),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTypeButton(String value, String label, IconData icon) {
    final isSelected = _orderType == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _orderType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== CATEGORIES ====================
  Widget _buildCategoriesBar(bool isMobile) {
    final tabs = ['All', ..._categories.map((c) => (c['name'] ?? '').toString())];
    return Container(
      height: isMobile ? 56 : 64,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                border:
                    Border.all(color: isSelected ? Colors.black : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(tabs[index],
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }

  // ==================== FOOD GRID ====================
  Widget _buildFoodGrid(List<dynamic> items, bool isMobile, bool isTablet) {
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 5);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildFoodCard(items[index]),
    );
  }

  Widget _buildFoodCard(dynamic item) {
    final isVeg = item['is_veg'] != false;
    final imageUrl = item['image_url']?.toString();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              color: Colors.grey.shade200,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.restaurant, size: 36, color: Colors.grey)),
                    )
                  : const Center(child: Icon(Icons.restaurant, size: 36, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (item['name'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: isVeg ? Colors.green : Colors.red, width: 1.5),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: isVeg ? Colors.green : Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('\u20b9 ${_money(item['price']).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToCart(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCE4D6),
                  foregroundColor: const Color(0xFFE67E22),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM ACTION BAR ====================
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: InkWell(
        onTap: _loadInitialData,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.refresh, color: Colors.blueAccent, size: 16),
            SizedBox(width: 5),
            Text('Refresh Menu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  // ==================== CART PANEL ====================
  Widget _buildCartPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: _resetOrder,
                child: Row(children: [
                  Icon(Icons.delete_outline, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 4),
                  Text('Clear All',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _buildCartTypeButton('dine-in', 'Dine In', Icons.restaurant),
              _buildCartTypeButton('takeaway', 'Take Away', Icons.takeout_dining),
              _buildCartTypeButton('delivery', 'Delivery', Icons.delivery_dining),
            ]),
          ),
          const SizedBox(height: 12),
          if (_orderType == 'dine-in') _buildTableSelector(),
          if (_orderType == 'delivery') _buildDeliveryFields(),
          _buildCustomerFields(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(children: [
              const Expanded(
                  flex: 3, child: Text('Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
              const Expanded(
                  flex: 2,
                  child: Text('Qty',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('Price',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('Total',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      textAlign: TextAlign.end)),
            ]),
          ),
          _cart.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No items in cart', style: TextStyle(color: Colors.grey.shade500)),
                    ]),
                  ),
                )
              : Column(children: List.generate(_cart.length, (index) => _buildCartItem(index))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _notes,
                  decoration: InputDecoration(
                    hintText: 'Add special instructions...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _buildCouponAndDiscount(),
          const SizedBox(height: 12),
          _buildBillRow('Subtotal', '\u20b9 ${subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          _buildBillRow('GST (5% est.)', '\u20b9 ${estimatedGst.toStringAsFixed(2)}'),
          if (manualDiscountAmount > 0) ...[
            const SizedBox(height: 4),
            _buildBillRow('Manual Discount', '- \u20b9 ${manualDiscountAmount.toStringAsFixed(0)}'),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Estimated Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('\u20b9 ${estimatedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 4),
          Text('Service charge, coupon & loyalty discount confirmed after placing order.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _placing ? null : _placeOrder,
              icon: _placing
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_forward, size: 16),
              label: Text(_placing ? 'Placing order...' : 'Place Order & KOT',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    final availableTables =
        _tables.where((t) => t['status'] == 'available' || t['id'] == _selectedTableId).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<int>(
        isDense: true,
        initialValue: _selectedTableId,
        decoration: const InputDecoration(labelText: 'Table', border: OutlineInputBorder(), isDense: true),
        items: availableTables
            .map((t) => DropdownMenuItem<int>(
                value: t['id'] as int, child: Text('${t['table_number']} (${t['status']})')))
            .toList(),
        onChanged: (value) => setState(() => _selectedTableId = value),
      ),
    );
  }

  Widget _buildDeliveryFields() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        TextField(
          controller: _deliveryAddress,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Delivery address', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _deliveryLandmark,
          decoration: const InputDecoration(labelText: 'Landmark (optional)', border: OutlineInputBorder(), isDense: true),
        ),
      ]),
    );
  }

  Widget _buildCustomerFields() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _customerPhone,
              keyboardType: TextInputType.phone,
              onChanged: (_) => _lookupLoyalty(),
              decoration: const InputDecoration(labelText: 'Customer phone', border: OutlineInputBorder(), isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _customerName,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder(), isDense: true),
            ),
          ),
        ]),
        if (_availableLoyaltyPoints > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Available loyalty points: $_availableLoyaltyPoints',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
            ),
          ),
      ]),
    );
  }

  Widget _buildCouponAndDiscount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _couponCode,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Coupon code', border: OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _manualDiscount,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration:
                  const InputDecoration(labelText: 'Manual discount (\u20b9)', border: OutlineInputBorder(), isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _managerPin,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Manager PIN', border: OutlineInputBorder(), isDense: true),
            ),
          ),
        ]),
        if (_availableLoyaltyPoints > 0) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _loyaltyPoints,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: 'Redeem loyalty points (max $_availableLoyaltyPoints)',
                border: const OutlineInputBorder(),
                isDense: true),
          ),
        ],
      ],
    );
  }

  Widget _buildCartTypeButton(String value, String label, IconData icon) {
    final isSelected = _orderType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _orderType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration:
              BoxDecoration(color: isSelected ? Colors.black : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 13, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = _cart[index];
    final price = _money(item['price']);
    final qty = item['qty'] as int;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Text(item['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),
        Expanded(
          flex: 3,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            InkWell(
              onTap: () => _changeQty(index, -1),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.remove, size: 12),
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            InkWell(
              onTap: () => _changeQty(index, 1),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.add, size: 12),
              ),
            ),
          ]),
        ),
        Expanded(
            flex: 2,
            child: Text('\u20b9 ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text('\u20b9 ${(price * qty).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.end)),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _removeFromCart(index),
          icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
        ),
      ]),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildCartDrawer() {
    return Drawer(width: MediaQuery.of(context).size.width * 0.9, child: SafeArea(child: _buildCartPanel()));
  }
}
