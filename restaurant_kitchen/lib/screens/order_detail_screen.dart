import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/kitchen_order_model.dart';
import '../providers/kitchen_provider.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';

class OrderDetailScreen extends StatelessWidget {
  final KitchenOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final kitchen = context.read<KitchenProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: Text('Order #${order.orderId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Table ${order.tableNumber}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${order.minutesAgo} minutes ago',
                          style: TextStyle(
                            color: order.isUrgent ? Colors.red : Colors.grey,
                            fontWeight:
                                order.isUrgent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(order.orderedByName ?? 'Customer',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.note,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Note: ${order.notes}',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items
            const Text('Items to Prepare',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...order.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB71C1C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.quantity}×',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (item.modifiers.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: item.modifiers
                                .map((m) => Chip(
                                      label: Text(m,
                                          style:
                                              const TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.orange[50],
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                        if (item.specialInstructions != null &&
                            item.specialInstructions!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.yellow[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber,
                                    size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.specialInstructions!,
                                    style: const TextStyle(
                                        color: Colors.orange, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context, kitchen),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, KitchenProvider kitchen) {
    switch (order.status) {
      case 'placed':
        return Column(
          children: [
            _bigBtn('✅ Accept Order', Colors.green, () async {
              await kitchen.updateStatus(order.orderId, 'accepted');
              if (context.mounted) Navigator.pop(context);
            }),
            const SizedBox(height: 8),
            _bigBtn('🔥 Start Cooking Directly', Colors.orange, () async {
              await kitchen.updateStatus(order.orderId, 'preparing');
              if (context.mounted) Navigator.pop(context);
            }),
          ],
        );
      case 'accepted':
        return _bigBtn('🔥 Start Cooking', Colors.orange, () async {
          await kitchen.updateStatus(order.orderId, 'preparing');
          if (context.mounted) Navigator.pop(context);
        });
      case 'preparing':
        return _bigBtn('✅ Mark as Ready', Colors.green, () async {
          await kitchen.updateStatus(order.orderId, 'ready');
          if (context.mounted) Navigator.pop(context);
        });
      case 'ready':
        return _bigBtn('🍽️ Mark as Served', Colors.blue, () async {
          await kitchen.updateStatus(order.orderId, 'served');
          if (context.mounted) Navigator.pop(context);
        });
      case 'served':
        return OutlinedButton.icon(
          onPressed: () => _showRecallDialog(context, kitchen),
          icon: const Icon(Icons.undo, size: 18),
          label: const Text('🔄 Recall to Kitchen'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  void _showRecallDialog(
      BuildContext context, KitchenProvider kitchen) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.undo, color: Colors.orange),
            SizedBox(width: 8),
            Text('Recall Order?',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yeh order wapas kitchen mein jayega. Reason batao:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Customer complaint, wrong item...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final api = ApiService();
              final result = await api.recallOrder(
                order.orderId,
                reasonCtrl.text,
              );
              if (result['success'] == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.orange,
                  ),
                );
                await kitchen.loadOrders(isSocketRefresh: true);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange),
            child: const Text('Recall 🔥',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _bigBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
