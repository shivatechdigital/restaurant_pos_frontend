import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'placed':
        return _StatusConfig('NEW', Colors.red);
      case 'accepted':
        return _StatusConfig('ACCEPTED', Colors.orange);
      case 'preparing':
        return _StatusConfig('COOKING', Colors.amber[700]!);
      case 'ready':
        return _StatusConfig('READY', Colors.green);
      case 'served':
        return _StatusConfig('SERVED', Colors.grey);
      case 'cancelled':
        return _StatusConfig('CANCELLED', Colors.red[900]!);
      default:
        return _StatusConfig(status.toUpperCase(), Colors.grey);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}
