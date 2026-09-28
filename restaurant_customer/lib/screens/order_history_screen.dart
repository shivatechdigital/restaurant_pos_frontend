import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/menu_model.dart';
import '../providers/order_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../models/order_model.dart';
import 'payment_screen.dart';
import '../config/responsive.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String tableNumber;
  final String roomCode;

  const OrderHistoryScreen({
    super.key,
    required this.tableNumber,
    this.roomCode = '',
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<OrderProvider>().loadOrderHistory();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final orders = order.orderHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF191919),
        title: Text('Table ${widget.tableNumber} - Order History'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF45B15)),
            )
          : CustomerPage(
              child: Column(
                children: [
                  if (widget.roomCode.isNotEmpty) _tablePinCard(),
                  Expanded(
                    child: orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Abhi tak koi order nahi hai',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => context
                                .read<OrderProvider>()
                                .loadOrderHistory(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final orderData = orders[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Order #${orderData.orderId}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const Spacer(),
                                            _statusBadge(orderData.status),
                                          ],
                                        ),
                                        const Divider(height: 18),
                                        ...orderData.items.map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${item.quantity} x ${item.name}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '₹${item.totalPrice.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip:
                                                      'Reorder ${item.name}',
                                                  onPressed: () =>
                                                      _reorderItem(item),
                                                  icon: const Icon(
                                                    Icons.refresh,
                                                    color: Color(0xFFF45B15),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (orderData.totalAmount != null)
                                              Text(
                                                '₹${orderData.totalAmount!.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFF45B15),
                                                  fontSize: 15,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),

      // ---- BOTTOM: PROCEED TO BILL/PAYMENT ----
      bottomNavigationBar: orders.isEmpty
          ? null
          : Container(
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
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final sessionId = order.sessionId;
                      if (sessionId == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            sessionId: sessionId,
                            tableNumber: widget.tableNumber,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment, size: 20),
                    label: const Text(
                      'Bill / Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _statusBadge(String status) {
    final isDone = status == OrderStatus.served;
    final isCancelled = status == OrderStatus.cancelled;
    final color = isCancelled
        ? Colors.red
        : isDone
        ? const Color(0xFF1B5E20)
        : Colors.orange[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        OrderStatus.getDisplayName(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tablePinCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order together',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share this PIN with your companions at the table.',
                    style: TextStyle(color: Color(0xFF777777), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.roomCode));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Table PIN copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(widget.roomCode),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF17885E),
                side: const BorderSide(color: Color(0xFFB8E4D1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reorderItem(OrderItemData orderItem) {
    MenuItem? matchedItem;
    for (final category in context.read<MenuProvider>().categories) {
      for (final candidate in category.items) {
        if (candidate.isAvailable &&
            candidate.name.trim().toLowerCase() ==
                orderItem.name.trim().toLowerCase()) {
          matchedItem = candidate;
          break;
        }
      }
      if (matchedItem != null) break;
    }

    if (matchedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${orderItem.name} is currently unavailable')),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    for (var count = 0; count < orderItem.quantity; count++) {
      cart.addItem(menuItem: matchedItem);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${orderItem.name} added to your cart')),
    );
    Navigator.pop(context);
  }
}
