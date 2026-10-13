import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/menu_model.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../config/socket_service.dart';
import '../services/session_service.dart';
import '../widgets/menu_item_card.dart';
import 'cart_screen.dart';
import 'landing_screen.dart';
import 'order_history_screen.dart';
import 'payment_screen.dart';
import 'settled_session_screen.dart';

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final String tableNumber;
  final int tableId;
  final String sessionId;
  final String roomCode;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.tableNumber,
    required this.tableId,
    required this.sessionId,
    required this.roomCode,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _searchCtrl = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MenuProvider>().loadMenu(widget.restaurantId);
      final order = context.read<OrderProvider>();
      order.setSessionId(widget.sessionId);
      order.setupSocketListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final order = context.watch<OrderProvider>();
    if (order.isSessionSettled) {
      return SettledSessionScreen(
        sessionId: widget.sessionId,
        tableNumber: widget.tableNumber,
      );
    }
    final filteredCategories = menu.filteredCategories;

    final selectedCategories = filteredCategories
        .where((category) => category.id == _selectedCategoryId)
        .toList();
    final displayCategories = selectedCategories.isEmpty
        ? filteredCategories
        : selectedCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),

      // ---- APP BAR (Matching Design Header) ----
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              menu.restaurantName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E2022),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: Color(0xFFF45B15),
                ),
                const SizedBox(width: 4),
                Text(
                  'Dine In  •  Table ${widget.tableNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF75787E),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1E2022),
            ),
            tooltip: 'Call Waiter 🛎️',
            onPressed: () {
              SocketService().emit('call_waiter', {
                'restaurant_id': widget.restaurantId,
                'table_number': widget.tableNumber,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    '🛎️ Waiter ko alert bhej diya gaya hai!',
                  ),
                  backgroundColor: const Color(0xFFF45B15),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFECECEC), width: 2),
            ),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFFFF2EB),
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: Color(0xFFF45B15),
              ),
            ),
          ),
        ],
      ),

      body: menu.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF45B15)),
            )
          : menu.error.isNotEmpty
          ? _errorView(menu)
          : SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        // 1. Promotional Banner
                        _buildFeaturedBanner(),

                        // 2. Search & Filter Bar
                        _buildSearchBar(menu),

                        // 3. Category Horizontal List
                        _buildCategoryRail(filteredCategories),

                        // 4. Recommended For You (Horizontal)
                        if (_searchCtrl.text.isEmpty &&
                            _selectedCategoryId == null)
                          _buildRecommendedSection(menu.categories),

                        // 5. Order PIN Card
                        _buildTablePinCard(),

                        // 6. Full Menu List
                        if (filteredCategories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'No items found matching your search.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...displayCategories.map(
                            (category) => _buildCategorySection(category),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // ---- BOTTOM NAVIGATION & CART BAR ----
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Cart Button
            if (!cart.isEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0x40F45B15),
                    ),
                    onPressed: _openCart,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cart.totalItems} ITEM${cart.totalItems > 1 ? 'S' : ''} ADDED',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'View Cart',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Nav Bar
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 64,
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFFFF2EB),
                selectedIndex: 0,
                onDestinationSelected: _selectBottomTab,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(
                      Icons.restaurant_menu_rounded,
                      color: Color(0xFF75787E),
                    ),
                    selectedIcon: Icon(
                      Icons.restaurant_menu_rounded,
                      color: Color(0xFFF45B15),
                    ),
                    label: 'Menu',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF75787E),
                    ),
                    selectedIcon: Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFF45B15),
                    ),
                    label: 'Orders',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.payments_outlined,
                      color: Color(0xFF75787E),
                    ),
                    selectedIcon: Icon(
                      Icons.payments_rounded,
                      color: Color(0xFFF45B15),
                    ),
                    label: 'Pay Bill',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- WIDGET BUILDERS ----

  Widget _buildFeaturedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Container(
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A211D), Color(0xFF1B1614)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Placeholder background image
            Positioned(
              right: -30,
              top: -20,
              bottom: -20,
              width: 220,
              child: Opacity(
                opacity: 0.9,
                child: Image.network(
                  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop', // Burger placeholder
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E1714),
                    Color(0xD91E1714),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Delicious Food For\nEvery Mood',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fresh Ingredients\nGreat Taste',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF45B15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'View Offers →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(MenuProvider menu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFECECEC)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: menu.search,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for dishes...',
                  hintStyle: const TextStyle(color: Color(0xFF9EA1A8)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF75787E),
                  ),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            menu.search('');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => menu.setVegOnly(!menu.vegOnly),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: menu.vegOnly ? const Color(0xFFEAF8F2) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: menu.vegOnly
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFECECEC),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF16A34A),
                        width: 1.3,
                      ),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Veg',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.72,
                    child: Switch(
                      value: menu.vegOnly,
                      activeTrackColor: const Color(0xFF16A34A),
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFE5E7EB),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: menu.setVegOnly,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRail(List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _categoryTile(null, 'All', Icons.grid_view_rounded),
            ...categories.map(
              (cat) =>
                  _categoryTile(cat.id, cat.name, _getCategoryIcon(cat.name)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('start')) return Icons.restaurant_rounded;
    if (n.contains('main')) return Icons.dinner_dining_rounded;
    if (n.contains('bev') || n.contains('drink')) {
      return Icons.local_cafe_rounded;
    }
    if (n.contains('dessert') || n.contains('sweet')) return Icons.cake_rounded;
    if (n.contains('pizza')) return Icons.local_pizza_rounded;
    if (n.contains('burger')) return Icons.lunch_dining_rounded;
    return Icons.fastfood_rounded;
  }

  Widget _categoryTile(int? id, String name, IconData icon) {
    final selected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF45B15) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFF45B15)
                      : const Color(0xFFECECEC),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0x35F45B15),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected ? Colors.white : const Color(0xFFF45B15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: const Color(0xFF1E2022),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection(List<Category> allCategories) {
    final allAvailable = allCategories
        .expand((c) => c.items)
        .where((item) => item.isAvailable)
        .toList();

    if (allAvailable.isEmpty) return const SizedBox.shrink();

    // Pick top/popular items across different categories so it's diverse
    final List<MenuItem> diverseItems = [];
    int round = 0;
    while (diverseItems.length < 8 && round < 4) {
      bool anyAdded = false;
      for (var cat in allCategories) {
        final availableInCat = cat.items.where((i) => i.isAvailable).toList();
        if (round < availableInCat.length && diverseItems.length < 8) {
          diverseItems.add(availableInCat[round]);
          anyAdded = true;
        }
      }
      if (!anyAdded) break;
      round++;
    }
    final recommendedItems = diverseItems.isNotEmpty
        ? diverseItems
        : allAvailable.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E2022),
                ),
              ),
              Text(
                'Popular',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF45B15).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: recommendedItems.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 175,
                child: MenuItemCard(
                  item: recommendedItems[index],
                  isGrid: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Full Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2022),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTablePinCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFECECEC)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.group_add_rounded,
              color: Color(0xFF9EA1A8),
              size: 20,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Share Table PIN with friends',
                style: TextStyle(
                  color: Color(0xFF75787E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: widget.roomCode));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Table PIN copied')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.roomCode,
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(Category category) {
    if (category.items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_searchCtrl.text.isEmpty && _selectedCategoryId == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              category.name,
              style: const TextStyle(
                color: Color(0xFF1E2022),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int crossAxisCount = width >= 1200
                ? 4
                : width >= 800
                ? 3
                : width >= 500
                ? 2
                : 1;

            if (crossAxisCount == 1) {
              return Column(
                children: category.items
                    .map((item) => MenuItemCard(item: item, isGrid: false))
                    .toList(),
              );
            }

            final double itemWidth =
                (width - 32 - (crossAxisCount - 1) * 12) / crossAxisCount;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: category.items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: MenuItemCard(item: item, isGrid: true),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          tableId: widget.tableId,
          restaurantId: widget.restaurantId,
          sessionId: widget.sessionId,
          tableNumber: widget.tableNumber,
        ),
      ),
    );
  }

  void _selectBottomTab(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderHistoryScreen(
            tableNumber: widget.tableNumber,
            roomCode: widget.roomCode,
            restaurantId: widget.restaurantId,
            tableId: widget.tableId,
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          sessionId: widget.sessionId,
          tableNumber: widget.tableNumber,
        ),
      ),
    );
  }

  Widget _errorView(MenuProvider menu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 50, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              menu.error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => menu.loadMenu(widget.restaurantId),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await SessionService.clearSession();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                );
              },
              child: const Text('Exit Table'),
            ),
          ],
        ),
      ),
    );
  }
}
