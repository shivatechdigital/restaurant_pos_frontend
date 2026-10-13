import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/menu_model.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../config/socket_service.dart';
import '../config/responsive.dart';
import '../services/session_service.dart';
import '../widgets/menu_item_card.dart';
import 'cart_screen.dart';
import 'landing_screen.dart';
import 'order_history_screen.dart';
import 'payment_screen.dart';

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
      context.read<OrderProvider>().setSessionId(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
    final filtered = menu.filteredCategories;

    final selectedCategories = filtered
        .where((category) => category.id == _selectedCategoryId)
        .toList();
    final displayCategories = selectedCategories.isEmpty
        ? filtered
        : selectedCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      // ---- APP BAR ----
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFFF45B15),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sarjapur PetPooja',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Color(0xFFF45B15),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Dine In  •  Table ${widget.tableNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF75787E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Order History
          IconButton(
            icon: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF1E2022),
            ),
            tooltip: 'Order History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrderHistoryScreen(tableNumber: widget.tableNumber),
                ),
              );
            },
          ),
          // Call Waiter
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
                  content: const Row(
                    children: [
                      Text('🛎️ '),
                      Text('Waiter ko alert bhej diya gaya hai!'),
                    ],
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
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),

      body: menu.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF45B15)),
                  SizedBox(height: 12),
                  Text('Menu load ho raha hai...'),
                ],
              ),
            )
          : menu.error.isNotEmpty
          ? _errorView(menu)
          : Column(
              children: [
                Padding(
                  padding: CustomerResponsive.pagePadding(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: menu.search,
                          decoration: InputDecoration(
                            hintText: 'Search dishes',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchCtrl.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      menu.search('');
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Veg only',
                            style: TextStyle(fontSize: 11),
                          ),
                          SizedBox(
                            height: 30,
                            child: Switch.adaptive(
                              value: menu.vegOnly,
                              activeTrackColor: const Color(0xFFF45B15),
                              onChanged: menu.setVegOnly,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildCategoryRail(filtered),

                // ---- MENU ITEMS ----
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Koi item nahi mila',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            _buildFeaturedBanner(menu.categories),
                            _buildTablePinCard(),
                            ...displayCategories.map(
                              (category) => _buildCategorySection(category),
                            ),
                            _buildRestaurantFooter(),
                          ],
                        ),
                ),
              ],
            ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!cart.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _openCart,
                    child: Text(
                      'CONFIRM ORDER (${cart.totalItems} ${cart.totalItems == 1 ? 'item' : 'items'})',
                    ),
                  ),
                ),
              ),
            NavigationBar(
              height: 64,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFFFE5D8),
              selectedIndex: 0,
              onDestinationSelected: _selectBottomTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Menu',
                ),
                NavigationDestination(
                  icon: Icon(Icons.room_service_outlined),
                  selectedIcon: Icon(Icons.room_service),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Pay Bill',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRail(List<Category> categories) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          _categoryTile(null, 'All', null),
          ...categories.map((category) {
            final image = category.items
                .where((item) => item.imageUrl?.isNotEmpty == true)
                .firstOrNull
                ?.imageUrl;
            return _categoryTile(category.id, category.name, image);
          }),
        ],
      ),
    );
  }

  Widget _categoryTile(int? id, String name, String? imageUrl) {
    final selected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF45B15) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFF45B15) : const Color(0xFFE5E7EB),
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x35F45B15),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFFFF2EB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  id == null
                      ? Icons.grid_view_rounded
                      : Icons.restaurant_rounded,
                  size: 16,
                  color: selected ? Colors.white : const Color(0xFFF45B15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1E2022),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner(List<Category> categories) {
    final featured = categories
        .expand((category) => category.items)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
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
            if (featured?.imageUrl?.isNotEmpty == true)
              Positioned(
                right: -20,
                top: -10,
                bottom: -10,
                width: 190,
                child: Opacity(
                  opacity: 0.85,
                  child: Image.network(
                    featured!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF45B15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SPECIAL DEAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Delicious Food For\nEvery Mood',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fresh Ingredients • Great Taste',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablePinCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order together',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share your table PIN with your companions.',
                    style: TextStyle(color: Color(0xFF777777), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
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
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB8E4D1)),
                ),
                child: Text(
                  widget.roomCode,
                  style: const TextStyle(
                    color: Color(0xFF17885E),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
            child: Text(
              category.name,
              style: const TextStyle(
                color: Color(0xFF263343),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 2 : 1;
              final itemWidth =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 4,
                children: category.items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: MenuItemCard(item: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'Sarjapur PetPooja  •  Table ${widget.tableNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Terms & Conditions     Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF777777), fontSize: 12),
          ),
        ],
      ),
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
              child: const Text('Table chhodo aur wapas jao'),
            ),
          ],
        ),
      ),
    );
  }
}
