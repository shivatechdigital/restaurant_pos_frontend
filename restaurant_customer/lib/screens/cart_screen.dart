import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Your Cart'),
        centerTitle: true,
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cart Clear Karo?'),
                    content:
                        const Text('Saare items hat jayenge. Sure ho?'),
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
                            backgroundColor: Colors.red),
                        child: const Text('Haan, Clear Karo',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _emptyCart(context)
          : Column(
              children: [
                // ---- CART ITEMS LIST ----
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Dismissible(
                        key: ValueKey(item.uniqueKey),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => cart.removeItem(index),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
                                        width: 1.5),
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
                                            fontSize: 15),
                                      ),
                                      if (item.modifiers.isNotEmpty)
                                        Text(
                                          item.modifiers
                                              .map((m) => m.name)
                                              .join(', '),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[700]),
                                        ),
                                      if (item.specialInstructions
                                          .isNotEmpty)
                                        Text(
                                          '📝 ${item.specialInstructions}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                              fontStyle: FontStyle.italic),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${item.itemTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B5E20),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Controls
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey[300]!),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _qtyBtn(Icons.remove,
                                          () => cart.decreaseQty(index)),
                                      Padding(
                                        padding: const EdgeInsets
                                            .symmetric(horizontal: 10),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                      ),
                                      _qtyBtn(Icons.add,
                                          () => cart.increaseQty(index)),
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
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: cart.isEmpty
                                ? null
                                : () async {
                                    final order = context.read<OrderProvider>();
                                    order.setSessionId(sessionId);

                                    final success = await order.placeOrder(
                                      tableId: tableId,
                                      restaurantId: int.parse(restaurantId),
                                      items: cart.toApiFormat(),
                                    );

                                    if (success && context.mounted) {
                                      cart.clear();
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OrderTrackingScreen(
                                            sessionId: sessionId,
                                            tableNumber: tableNumber,
                                            restaurantId: restaurantId,
                                            tableId: tableId,
                                          ),
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(order.error.isNotEmpty
                                              ? order.error
                                              : 'Order place nahi hua'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.restaurant, size: 20),
                            label: const Text(
                              'Place Order',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
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

  Widget _emptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 70, color: Colors.grey[300]),
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
              backgroundColor: const Color(0xFF1B5E20),
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
              color: isBold ? const Color(0xFF1B5E20) : Colors.black87,
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
        child: Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
      ),
    );
  }
}
