import 'package:flutter/material.dart';
import '../models/kitchen_order_model.dart';
import 'live_timer_widget.dart';

class KDSGridCard extends StatelessWidget {
  final KitchenOrder order;
  final Function(String) onAction;

  const KDSGridCard({
    super.key,
    required this.order,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: order.isVeryUrgent
              ? Colors.red
              : order.isUrgent
                  ? Colors.orange
                  : Colors.grey[300]!,
          width: order.isUrgent ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: order.isUrgent
                ? Colors.red.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- HEADER ----
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _headerColor(),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(
                  order.tableNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                if (order.isVeryUrgent)
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                LiveTimerWidget(
                  placedAt: order.placedAt,
                  isUrgent: order.isUrgent,
                  isVeryUrgent: order.isVeryUrgent,
                ),
              ],
            ),
          ),

          // ---- ITEMS ----
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListView(
                children: [
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.quantity}× ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB71C1C),
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (item.modifiers.isNotEmpty)
                                    Text(
                                      item.modifiers.join(', '),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[700]),
                                    ),
                                  if (item.specialInstructions != null &&
                                      item.specialInstructions!.isNotEmpty)
                                    Text(
                                      '⚠️ ${item.specialInstructions}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '📝 ${order.notes}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ---- ACTION BUTTON ----
          Padding(
            padding: const EdgeInsets.all(8),
            child: _getActionButton(),
          ),
        ],
      ),
    );
  }

  Color _headerColor() {
    switch (order.status) {
      case 'placed':
        return Colors.red[600]!;
      case 'accepted':
        return Colors.orange[600]!;
      case 'preparing':
        return Colors.amber[700]!;
      case 'ready':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _getActionButton() {
    String label;
    Color color;
    String nextStatus;

    switch (order.status) {
      case 'placed':
        label = '✅ Accept & Start';
        color = Colors.green;
        nextStatus = 'preparing';
        break;
      case 'accepted':
        label = '🔥 Start Cooking';
        color = Colors.orange;
        nextStatus = 'preparing';
        break;
      case 'preparing':
        label = '✅ Ready!';
        color = Colors.green;
        nextStatus = 'ready';
        break;
      case 'ready':
        label = '🍽️ Served';
        color = Colors.blue;
        nextStatus = 'served';
        break;
      default:
        return const SizedBox();
    }

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () => onAction(nextStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}
