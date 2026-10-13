import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../widgets/order_status_stepper.dart';
import 'payment_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String sessionId;
  final String tableNumber;
  final String restaurantId;
  final int tableId;

  const OrderTrackingScreen({
    super.key,
    required this.sessionId,
    required this.tableNumber,
    required this.restaurantId,
    required this.tableId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().loadCancellationPolicy();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Tracking',
              style: TextStyle(color: Color(0xFF1E2022), fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              'Table ${widget.tableNumber} • Live Status',
              style: const TextStyle(color: Color(0xFF75787E), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          // Order cancel button (sirf "placed" status mein)
          if (order.customerSelfCancelEnabled && order.currentStatus == OrderStatus.placed)
            TextButton.icon(
              onPressed: () => _showCancelDialog(context, order),
              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
              label: const Text('Cancel', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Stepper
                    OrderStatusStepper(currentStatus: order.currentStatus),
                    
                    const SizedBox(height: 8),

                    // Status Highlight Card
                    _buildStatusCard(order),

                    const SizedBox(height: 16),

                    // Order Info Details
                    _buildOrderInfo(order),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            _buildBottomActions(context, order),
          ],
        ),
      ),
    );
  }

  // ---- STATUS CARD ----
  Widget _buildStatusCard(OrderProvider order) {
    final color = _getStatusColor(order.currentStatus);
    final icon = _getStatusIcon(order.currentStatus);
    final displayName = OrderStatus.getDisplayName(order.currentStatus);
    final message = order.statusMessage.isNotEmpty
        ? order.statusMessage
        : OrderStatus.getMessage(order.currentStatus);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Animated Icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = order.currentStatus == OrderStatus.preparing
                  ? 1.0 + (_pulseController.value * 0.15)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Color(0xFF75787E), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- ORDER INFO ----
  Widget _buildOrderInfo(OrderProvider order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          _infoRow(Icons.receipt_long_rounded, 'Order ID', '#${order.currentOrderId ?? "---"}'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFECECEC))),
          _infoRow(Icons.table_restaurant_rounded, 'Table', widget.tableNumber),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFECECEC))),
          _infoRow(Icons.timer_outlined, 'Estimated Time', _getEstimatedTime(order.currentStatus)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 18, color: const Color(0xFF75787E)),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Color(0xFF75787E), fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E2022))),
      ],
    );
  }

  // ---- BOTTOM ACTIONS ----
  Widget _buildBottomActions(BuildContext context, OrderProvider order) {
    if (order.currentStatus == OrderStatus.served) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 Enjoy your meal!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E2022))),
              const SizedBox(height: 4),
              const Text('Whenever you are ready, please proceed to pay.', style: TextStyle(color: Color(0xFF75787E), fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                        label: const Text('Add Items', style: TextStyle(fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF45B15),
                          side: const BorderSide(color: Color(0xFFF45B15), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(sessionId: widget.sessionId, tableNumber: widget.tableNumber)));
                        },
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: const Text('Pay Bill', style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (order.currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                order.resetForNewOrder();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Order Again', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF45B15),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      );
    }

    // Active order — Add Item + Call Waiter
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Add Items', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF45B15),
                    side: const BorderSide(color: Color(0xFFF45B15), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🛎️ Waiter has been notified!'), backgroundColor: Color(0xFFF45B15)),
                    );
                  },
                  icon: const Icon(Icons.room_service_rounded, size: 18),
                  label: const Text('Call Waiter', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2022),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- CANCEL DIALOG ----
  void _showCancelDialog(BuildContext context, OrderProvider order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Cancel Order?'),
          ],
        ),
        content: const Text('Are you sure you want to cancel this order? Once it reaches the kitchen, it cannot be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, Keep it', style: TextStyle(color: Color(0xFF75787E)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await order.cancelOrder();
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(order.error), backgroundColor: const Color(0xFFDC2626)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.placed: return const Color(0xFF3B82F6);
      case OrderStatus.accepted: return const Color(0xFF6366F1);
      case OrderStatus.preparing: return const Color(0xFFF59E0B);
      case OrderStatus.ready: return const Color(0xFF10B981);
      case OrderStatus.served: return const Color(0xFF16A34A);
      case OrderStatus.cancelled: return const Color(0xFFDC2626);
      default: return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case OrderStatus.placed: return Icons.receipt_long_rounded;
      case OrderStatus.accepted: return Icons.thumb_up_rounded;
      case OrderStatus.preparing: return Icons.soup_kitchen_rounded;
      case OrderStatus.ready: return Icons.room_service_rounded;
      case OrderStatus.served: return Icons.celebration_rounded;
      case OrderStatus.cancelled: return Icons.cancel_rounded;
      default: return Icons.hourglass_empty_rounded;
    }
  }

  String _getEstimatedTime(String status) {
    switch (status) {
      case OrderStatus.placed: return '15-20 min';
      case OrderStatus.accepted: return '12-18 min';
      case OrderStatus.preparing: return '5-10 min';
      case OrderStatus.ready: return '1-2 min';
      case OrderStatus.served: return 'Done! ✅';
      default: return '---';
    }
  }
}