import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kitchen_provider.dart';
import '../widgets/kds_grid_card.dart';

class KDSTvMode extends StatefulWidget {
  const KDSTvMode({super.key});

  @override
  State<KDSTvMode> createState() => _KDSTvModeState();
}

class _KDSTvModeState extends State<KDSTvMode> {
  Timer? _autoScrollTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  bool _isScrollingDown = true;

  @override
  void initState() {
    super.initState();
    _startClock();
    _startAutoScroll();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _startAutoScroll() {
    // Har 8 second mein auto-scroll karo
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (_isScrollingDown) {
        if (currentScroll >= maxScroll - 10) {
          _isScrollingDown = false;
        } else {
          _scrollController.animateTo(
            currentScroll + 300,
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
          );
        }
      } else {
        if (currentScroll <= 10) {
          _isScrollingDown = true;
        } else {
          _scrollController.animateTo(
            currentScroll - 300,
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _clockTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitchen = context.watch<KitchenProvider>();
    final screenWidth = MediaQuery.of(context).size.width;

    // TV ke liye columns (badi screen = zyada columns)
    int columns;
    if (screenWidth > 1600) {
      columns = 5;
    } else if (screenWidth > 1200) {
      columns = 4;
    } else if (screenWidth > 800) {
      columns = 3;
    } else {
      columns = 2;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ---- TOP BAR (Clock + Stats) ----
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            color: const Color(0xFFB71C1C),
            child: Row(
              children: [
                // Logo
                const Text(
                  '🔥 KITCHEN DISPLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 20),

                // Live dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),

                const Spacer(),

                // Stats
                _tvStat('🔴 NEW', kitchen.newOrders),
                const SizedBox(width: 16),
                _tvStat('🟡 COOKING', kitchen.preparingOrders),
                const SizedBox(width: 16),
                _tvStat('🟢 READY', kitchen.readyOrders),
                const SizedBox(width: 16),
                if (kitchen.urgentOrders > 0)
                  _tvStat('🔥 LATE', kitchen.urgentOrders),

                const Spacer(),

                // Clock
                Text(
                  '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 16),

                // Exit button
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ---- ORDERS GRID (Auto-scroll) ----
          Expanded(
            child: kitchen.orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 80, color: Colors.grey[800]),
                        const SizedBox(height: 16),
                        Text(
                          'Waiting for orders...',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: kitchen.orders.length,
                    itemBuilder: (context, index) {
                      final order = kitchen.orders[index];
                      return KDSGridCard(
                        order: order,
                        onAction: (newStatus) async {
                          await kitchen.updateStatus(
                              order.orderId, newStatus);
                        },
                      );
                    },
                  ),
          ),

          // ---- BOTTOM TICKER ----
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Text(
                  '📊 Today: ${kitchen.totalActive} active orders',
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Auto-refresh ON • ${kitchen.isMuted ? '🔇 Muted' : '🔊 Sound ON'}',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tvStat(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
