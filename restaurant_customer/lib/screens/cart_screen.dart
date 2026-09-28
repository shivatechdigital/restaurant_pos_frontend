import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';
import 'order_tracking_screen.dart';
import '../config/responsive.dart';

class CartScreen extends StatefulWidget {
  final int tableId;
  final String restaurantId;
  final String sessionId;
  final String tableNumber;

  const CartScreen({
    super.key,
    required this.tableId,
    required this.restaurantId,
    required this.sessionId,
    required this.tableNumber,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double _slideProgress = 0;
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF191919),
        title: const Text('Confirm your order'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cart Clear Karo?'),
                    content: const Text('Saare items hat jayenge. Sure ho?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Nahi'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Haan, Clear Karo',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _emptyCart(context)
          : CustomerPage(
              child: Column(
                children: [
                  // ---- CART ITEMS LIST ----
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: cart.items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == cart.items.length) {
                          return _suggestions(context, cart);
                        }
                        final item = cart.items[index];
                        return Dismissible(
                          key: ValueKey(item.uniqueKey),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => cart.removeItem(index),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  // Veg badge
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: item.isVeg
                                            ? Colors.green
                                            : Colors.red,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: item.isVeg
                                              ? Colors.green
                                              : Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Item Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (item.modifiers.isNotEmpty)
                                          Text(
                                            item.modifiers
                                                .map((m) => m.name)
                                                .join(', '),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item.itemTotal.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF45B15),
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          initialValue:
                                              item.specialInstructions,
                                          onChanged: (value) => cart
                                              .updateInstructions(index, value),
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Add cooking instructions',
                                            prefixIcon: Icon(
                                              Icons.chat_bubble_outline,
                                            ),
                                            isDense: true,
                                            filled: true,
                                            fillColor: Color(0xFFFAFAFA),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8),
                                              ),
                                              borderSide: BorderSide(
                                                color: Color(0xFFE7E7E7),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quantity Controls
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _qtyBtn(
                                          Icons.remove,
                                          () => cart.decreaseQty(index),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        _qtyBtn(
                                          Icons.add,
                                          () => cart.increaseQty(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ---- BILL SUMMARY + PLACE ORDER ----
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          _billRow('Subtotal', cart.subtotal),
                          _billRow('GST (5%)', cart.gst),
                          _billRow('Service Charge (5%)', cart.serviceCharge),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Divider(thickness: 1.5),
                          ),
                          _billRow('Total', cart.totalAmount, isBold: true),
                          const SizedBox(height: 12),
                          _slideToPlace(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _suggestions(BuildContext context, CartProvider cart) {
    final suggestions = context
        .watch<MenuProvider>()
        .categories
        .expand((category) => category.items)
        .where(
          (item) =>
              item.isAvailable &&
              !cart.items.any((cartItem) => cartItem.menuItemId == item.id),
        )
        .take(4)
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 12, bottom: 10),
            child: Text(
              'You may also like',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = suggestions[index];
                return SizedBox(
                  width: 230,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 82,
                              height: 82,
                              child: item.imageUrl == null
                                  ? const ColoredBox(
                                      color: Color(0xFFFFE9DD),
                                      child: Icon(
                                        Icons.restaurant,
                                        color: Color(0xFFF45B15),
                                      ),
                                    )
                                  : Image.network(
                                      item.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const ColoredBox(
                                            color: Color(0xFFFFE9DD),
                                            child: Icon(Icons.restaurant),
                                          ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text('₹${item.price.toStringAsFixed(0)}'),
                                TextButton(
                                  onPressed: () => cart.addItem(menuItem: item),
                                  child: const Text('ADD'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _slideToPlace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbWidth = 54.0;
        final maxTravel = constraints.maxWidth - thumbWidth - 8;
        return GestureDetector(
          onHorizontalDragUpdate: _isPlacing
              ? null
              : (details) => setState(() {
                  _slideProgress =
                      (_slideProgress + details.delta.dx / maxTravel).clamp(
                        0.0,
                        1.0,
                      );
                }),
          onHorizontalDragEnd: _isPlacing
              ? null
              : (_) {
                  if (_slideProgress >= 0.84) {
                    _placeOrder();
                  } else {
                    setState(() => _slideProgress = 0);
                  }
                },
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              border: Border.all(color: const Color(0xFFF45B15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Slide to place order',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Order once placed cannot be cancelled',
                      style: TextStyle(fontSize: 11, color: Color(0xFF777777)),
                    ),
                  ],
                ),
                Positioned(
                  left: 4 + maxTravel * _slideProgress,
                  top: 4,
                  bottom: 4,
                  width: thumbWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF45B15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: _isPlacing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.keyboard_double_arrow_right,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final cart = context.read<CartProvider>();
    final order = context.read<OrderProvider>();
    order.setSessionId(widget.sessionId);
    final success = await order.placeOrder(
      tableId: widget.tableId,
      restaurantId: int.parse(widget.restaurantId),
      items: cart.toApiFormat(),
    );

    if (!mounted) return;
    if (success) {
      cart.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            sessionId: widget.sessionId,
            tableNumber: widget.tableNumber,
            restaurantId: widget.restaurantId,
            tableId: widget.tableId,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPlacing = false;
      _slideProgress = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          order.error.isNotEmpty ? order.error : 'Order not placed',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _emptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'Cart khaali hai!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Menu se kuch tasty add karo 🍕',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF45B15),
              foregroundColor: Colors.white,
            ),
            child: const Text('← Menu par jao'),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
              color: isBold ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 18 : 14,
              color: isBold ? const Color(0xFFF45B15) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: const Color(0xFFF45B15)),
      ),
    );
  }
}
