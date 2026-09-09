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

    // Socket listeners already setup in OrderProvider
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text('Table ${widget.tableNumber}'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Order cancel button (sirf "placed" status mein)
          if (order.customerSelfCancelEnabled && order.currentStatus == OrderStatus.placed)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel Order',
              onPressed: () => _showCancelDialog(context, order),
            ),
        ],
      ),
      body: Column(
        children: [
          // ---- STATUS STEPPER ----
          OrderStatusStepper(currentStatus: order.currentStatus),

          // ---- STATUS CARD ----
          _buildStatusCard(order),

          const SizedBox(height: 16),

          // ---- ORDER INFO ----
          _buildOrderInfo(order),

          const Spacer(),

          // ---- BOTTOM ACTIONS ----
          _buildBottomActions(context, order),
        ],
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.receipt,
            'Order ID',
            '#${order.currentOrderId ?? "---"}',
          ),
          const Divider(height: 20),
          _infoRow(
            Icons.table_restaurant,
            'Table',
            widget.tableNumber,
          ),
          const Divider(height: 20),
          _infoRow(
            Icons.timer_outlined,
            'Estimated Time',
            _getEstimatedTime(order.currentStatus),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  // ---- BOTTOM ACTIONS ----
  Widget _buildBottomActions(BuildContext context, OrderProvider order) {
    // Served hone par → Payment screen (Phase 4)
    if (order.currentStatus == OrderStatus.served) {
      return Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉 Enjoy your meal!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Jab ready ho, payment karo',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        label: const Text(
                          'Add Item',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                sessionId: widget.sessionId,
                                tableNumber: widget.tableNumber,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment, size: 20),
                        label: const Text(
                          'Pay Now',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

    // Cancelled hone par → New Order option
    if (order.currentStatus == OrderStatus.cancelled) {
      return Container(
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
                order.resetForNewOrder();
                Navigator.pop(context); // Menu par wapas jao
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Order Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      );
    }

    // Active order — Add Item + Call Waiter
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Add Item'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(color: Color(0xFF1B5E20)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // SocketService().emit('call_waiter', {...});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🛎️ Waiter ko bula liya gaya!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: const Text('Call Waiter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Order Cancel?'),
          ],
        ),
        content: const Text(
          'Kya aap sach mein yeh order cancel karna chahte ho? '
          'Kitchen tak order pahunch chuka hai toh cancel nahi hoga.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nahi, Rehne Do'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await order.cancelOrder();
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(order.error),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Haan, Cancel Karo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---- HELPERS ----

  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.placed:
        return Colors.blue;
      case OrderStatus.accepted:
        return Colors.indigo;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.served:
        return const Color(0xFF1B5E20);
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.receipt_long;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.local_fire_department;
      case OrderStatus.ready:
        return Icons.restaurant;
      case OrderStatus.served:
        return Icons.celebration;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getEstimatedTime(String status) {
    switch (status) {
      case OrderStatus.placed:
        return '15-20 min';
      case OrderStatus.accepted:
        return '12-18 min';
      case OrderStatus.preparing:
        return '5-10 min';
      case OrderStatus.ready:
        return '1-2 min';
      case OrderStatus.served:
        return 'Done! ✅';
      default:
        return '---';
    }
  }
}
