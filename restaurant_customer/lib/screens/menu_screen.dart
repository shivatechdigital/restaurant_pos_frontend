import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../config/socket_service.dart';
import '../services/session_service.dart';
import '../widgets/menu_item_card.dart';
import 'cart_screen.dart';
import 'landing_screen.dart';
import 'order_history_screen.dart';

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
  // -1 matlab "All" tab selected hai
  int _selectedCategoryIndex = -1;

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

    // "All" selected hai toh saari categories, warna sirf chuni hui category
    final displayCategories = (_selectedCategoryIndex == -1 ||
            _selectedCategoryIndex >= filtered.length)
        ? filtered
        : [filtered[_selectedCategoryIndex]];

    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ---- APP BAR ----
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table ${widget.tableNumber}',
                style: const TextStyle(fontSize: 16)),
            Text(
              'Room Code: ${widget.roomCode}  •  Share with friends',
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Order History
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Pichle Orders',
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
            icon: const Icon(Icons.notifications_active),
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
                      Text('Waiter ko bula liya gaya!'),
                    ],
                  ),
                  backgroundColor: Colors.orange[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ],
      ),

      body: menu.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 12),
                  Text('Menu load ho raha hai...'),
                ],
              ),
            )
          : menu.error.isNotEmpty
              ? _errorView(menu)
              : Column(
                  children: [
                    // ---- SEARCH BAR ----
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => menu.search(val),
                        decoration: InputDecoration(
                          hintText: '🔍 Search dish... (e.g., Paneer, Biryani)',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.grey),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    menu.search('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    // ---- CATEGORY TABS ----
                    if (filtered.length > 1)
                      SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: filtered.length + 1,
                          itemBuilder: (context, index) {
                            // Pehla chip hamesha "All"
                            final isAllChip = index == 0;
                            final catIndex = index - 1;
                            final isSelected = isAllChip
                                ? _selectedCategoryIndex == -1
                                : _selectedCategoryIndex == catIndex;
                            final label = isAllChip
                                ? 'All (${menu.totalItems})'
                                : '${filtered[catIndex].name} (${filtered[catIndex].items.length})';

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF1B5E20),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedCategoryIndex =
                                      isAllChip ? -1 : catIndex);
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    // ---- MENU ITEMS ----
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Koi item nahi mila',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 90),
                              itemCount: displayCategories.length,
                              itemBuilder: (context, catIndex) {
                                final category = displayCategories[catIndex];

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Category Header
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color:
                                                  const Color(0xFF1B5E20),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            category.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B5E20),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${category.items.length})',
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Items
                                    ...category.items
                                        .map((item) => MenuItemCard(
                                            item: item)),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),

      // ---- FLOATING CART BAR (hamesha dikhega, khaali ho tab bhi) ----
      bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                height: 64,
                child: Material(
                  color: cart.isEmpty
                      ? Colors.grey[400]
                      : const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(14),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: cart.isEmpty
                        ? null
                        : () {
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
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cart.totalItems} item${cart.totalItems != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '₹${cart.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            Text(menu.error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  menu.loadMenu(widget.restaurantId),
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
