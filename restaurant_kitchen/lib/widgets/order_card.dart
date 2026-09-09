import 'package:flutter/material.dart';
import '../models/kitchen_order_model.dart';
import 'live_timer_widget.dart';

class OrderCard extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback onTap;
  final Function(String) onQuickAction;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: order.isVeryUrgent
                ? Colors.red
                : order.isUrgent
                    ? Colors.orange
                    : Colors.grey[200]!,
            width: order.isUrgent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: order.isUrgent
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- HEADER ----
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _headerColor(),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Row(
                children: [
                  // Table Number
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.tableNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Urgent Tag
                  if (order.isVeryUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '🔥 URGENT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  else if (order.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⚠️ LATE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                  const Spacer(),

                  LiveTimerWidget(
                    placedAt: order.placedAt,
                    isUrgent: order.isUrgent,
                    isVeryUrgent: order.isVeryUrgent,
                  ),
                ],
              ),
            ),

            // ---- ITEMS PREVIEW ----
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items list (max 3 dikhao)
                  ...order.items.take(3).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}×',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.modifiers.isNotEmpty)
                              Text(
                                '+${item.modifiers.length}',
                                style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 11),
                              ),
                          ],
                        ),
                      )),
                  if (order.items.length > 3)
                    Text(
                      '+${order.items.length - 3} more items',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),

                  // Special Instructions
                  if (order.notes != null && order.notes!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.note,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.notes!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.orange),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ---- QUICK ACTION BUTTONS ----
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: _getActionButtons(),
              ),
            ),
          ],
        ),
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
      case 'served':
        return Colors.grey[500]!;
      default:
        return Colors.grey[600]!;
    }
  }

  List<Widget> _getActionButtons() {
    switch (order.status) {
      case 'placed':
        return [
          _actionBtn('✅ Accept', Colors.green, () => onQuickAction('accepted')),
          const SizedBox(width: 8),
          _actionBtn('🔥 Start', Colors.orange, () => onQuickAction('preparing')),
        ];
      case 'accepted':
        return [
          _actionBtn('🔥 Start Cooking', Colors.orange,
              () => onQuickAction('preparing')),
        ];
      case 'preparing':
        return [
          _actionBtn('✅ Mark Ready', Colors.green,
              () => onQuickAction('ready')),
        ];
      case 'ready':
        return [
          _actionBtn('🍽️ Served', Colors.blue,
              () => onQuickAction('served')),
        ];
      default:
        return [];
    }
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
