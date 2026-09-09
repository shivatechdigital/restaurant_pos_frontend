import 'dart:async';
import 'package:flutter/material.dart';
import '../models/waiter_request_model.dart';

class WaiterAlertBanner extends StatefulWidget {
  final List<WaiterRequest> requests;
  final Function(int) onDismiss;
  final VoidCallback onClearAll;

  const WaiterAlertBanner({
    super.key,
    required this.requests,
    required this.onDismiss,
    required this.onClearAll,
  });

  @override
  State<WaiterAlertBanner> createState() => _WaiterAlertBannerState();
}

class _WaiterAlertBannerState extends State<WaiterAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Timer? _autoHideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _startAutoRotate();
  }

  void _startAutoRotate() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (widget.requests.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.requests.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = widget.requests.where((r) => !r.isRead).toList();

    if (unread.isEmpty) return const SizedBox();

    final request = unread[_currentIndex % unread.length];
    final totalUnread = unread.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _getBannerColor(request.requestType),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji
          Text(
            request.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),

          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table ${request.tableNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  request.message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Counter badge
          if (totalUnread > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$totalUnread',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 8),

          // Dismiss button
          GestureDetector(
            onTap: () {
              final actualIndex =
                  widget.requests.indexOf(request);
              widget.onDismiss(actualIndex);
            },
            child: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),

          // Clear all
          if (totalUnread > 2) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: widget.onClearAll,
              child: const Icon(Icons.clear_all,
                  color: Colors.white54, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBannerColor(String type) {
    switch (type) {
      case 'water':
        return Colors.blue[700]!;
      case 'tissue':
        return Colors.brown[600]!;
      case 'bill':
        return Colors.green[700]!;
      case 'cleaning':
        return Colors.teal[700]!;
      case 'custom':
        return Colors.purple[700]!;
      default:
        return Colors.orange[700]!;
    }
  }
}
