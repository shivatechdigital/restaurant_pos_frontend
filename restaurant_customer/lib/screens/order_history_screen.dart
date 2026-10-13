import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_model.dart';
import '../providers/order_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/menu_provider.dart';
import '../models/order_model.dart';
import 'payment_screen.dart';
import 'order_tracking_screen.dart';
import 'settled_session_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String tableNumber;
  final String roomCode;
  final String restaurantId;
  final int tableId;

  const OrderHistoryScreen({
    super.key,
    required this.tableNumber,
    required this.restaurantId,
    required this.tableId,
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
    if (order.isSessionSettled) {
      return SettledSessionScreen(
        sessionId: order.sessionId ?? '',
        tableNumber: widget.tableNumber,
      );
    }

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
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2EB),
              borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w800,
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
          : SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFECECEC)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF45B15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Previous Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: orders.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: const Color(0xFFF45B15),
                            onRefresh: () => context
                                .read<OrderProvider>()
                                .loadOrderHistory(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: orders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final orderData = orders[index];
                                return _buildOrderCard(orderData);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),

      // Bottom Payment Button (Functionality intact)
      bottomNavigationBar: orders.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
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
                        fontSize: 16,
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

  Widget _buildOrderCard(OrderData orderData) {
    // Generate simple summary text (e.g. "Margherita Pizza, Paneer Tikka (2 items)")
    final names = orderData.items.map((i) => i.name).take(2).join(', ');
    final suffix = orderData.items.length > 2
        ? '... (${orderData.items.length} items)'
        : ' (${orderData.items.length} items)';
    final summaryText = '$names$suffix';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openOrderTracking(orderData),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date/Time & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Order (Tap to view details)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF75787E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#ORD${orderData.orderId}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ],
                  ),
                  _statusBadge(orderData.status),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFECECEC), height: 1),
              ),

              // Items Summary row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fastfood_rounded,
                      size: 20,
                      color: Color(0xFFF45B15),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summaryText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E2022),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'View all items →',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF45B15),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9EA1A8),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFECECEC), height: 1),
              ),

              // Footer: Amount & Reorder Btn
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _showOrderDetailsDialog(orderData),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E2022),
                          side: const BorderSide(color: Color(0xFFECECEC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (orderData.items.isNotEmpty) {
                            _reorderItem(orderData.items.first);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF45B15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text(
                          'Reorder',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOrderTracking(OrderData orderData) {
    final orderProvider = context.read<OrderProvider>();
    orderProvider.trackOrder(
      orderData,
      restaurantId: widget.restaurantId,
      tableId: widget.tableId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          sessionId: orderProvider.sessionId ?? '',
          tableNumber: widget.tableNumber,
          restaurantId: widget.restaurantId,
          tableId: widget.tableId,
        ),
      ),
    );
  }

  // ---- ORDER DETAILS DIALOG ----
  void _showOrderDetailsDialog(OrderData orderData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #ORD${orderData.orderId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Table ${widget.tableNumber} • Dine In',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF75787E),
                      ),
                    ),
                  ],
                ),
                _statusBadge(orderData.status),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFECECEC)),
            const Text(
              'Items in this order',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2022),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: orderData.items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, color: Color(0xFFF5F5F5)),
                itemBuilder: (context, idx) {
                  final item = orderData.items[idx];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFF1E2022),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2022),
                          ),
                        ),
                      ),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 20, color: Color(0xFFECECEC)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  '₹${(orderData.totalAmount ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF45B15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                for (var item in orderData.items) {
                  _reorderItem(item);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reorder All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF45B15),
                side: const BorderSide(color: Color(0xFFF45B15)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isDone = status == OrderStatus.served;
    final isCancelled = status == OrderStatus.cancelled;

    Color bg = const Color(0xFFFFF7ED);
    Color text = const Color(0xFFF97316);
    String label = OrderStatus.getDisplayName(status);

    if (isDone) {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF16A34A);
      label = 'Completed';
    } else if (isCancelled) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
      label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                size: 36,
                color: Color(0xFFF45B15),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1E2022),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your past orders for this table will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF75787E), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: const Text('Explore Menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF45B15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
      SnackBar(
        content: Text('${orderItem.name} added to your cart'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
    Navigator.pop(context);
  }
}
