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
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1E2022),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_restaurant_rounded,
                  size: 14,
                  color: Color(0xFFF45B15),
                ),
                const SizedBox(width: 4),
                Text(
                  'Table ${widget.tableNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF45B15),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF45B15)),
            )
          : CustomerPage(
              maxWidth: 640,
              child: Column(
                children: [
                  if (widget.roomCode.isNotEmpty) _tablePinCard(),
                  Expanded(
                    child: orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF2EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 38,
                                    color: Color(0xFFF45B15),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No Orders Placed Yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: Color(0xFF1E2022),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Your orders for this table will appear here',
                                  style: TextStyle(
                                    color: Color(0xFF75787E),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFF45B15),
                            onRefresh: () => context
                                .read<OrderProvider>()
                                .loadOrderHistory(),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              itemCount: orders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final orderData = orders[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFECECEC),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x08000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order #${orderData.orderId}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: Color(0xFF1E2022),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${orderData.items.length} items',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF9EA1A8),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          _statusBadge(orderData.status),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Divider(
                                          color: Color(0xFFF2F2F2),
                                          height: 1,
                                        ),
                                      ),
                                      ...orderData.items.map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF3F4F6,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${item.quantity}x',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12,
                                                    color: Color(0xFF374151),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1E2022),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '₹${item.totalPrice.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1E2022),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Divider(
                                          color: Color(0xFFF2F2F2),
                                          height: 1,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Order Total',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF75787E),
                                                ),
                                              ),
                                              Text(
                                                '₹${(orderData.totalAmount ?? 0).toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFFF45B15),
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 36,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                if (orderData
                                                    .items
                                                    .isNotEmpty) {
                                                  _reorderItem(
                                                    orderData.items.first,
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFF45B15,
                                                ),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                              ),
                                              child: const Text(
                                                'Reorder',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
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
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    label: const Text(
                      'View Bill & Pay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
