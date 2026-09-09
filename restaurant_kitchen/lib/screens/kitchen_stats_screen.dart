import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kitchen_provider.dart';

class KitchenStatsScreen extends StatefulWidget {
  const KitchenStatsScreen({super.key});

  @override
  State<KitchenStatsScreen> createState() => _KitchenStatsScreenState();
}

class _KitchenStatsScreenState extends State<KitchenStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<KitchenProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kitchen = context.watch<KitchenProvider>();
    final stats = kitchen.stats;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: const Text('📊 Kitchen Stats'),
      ),
      body: stats == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    '📅 ${stats['date']}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // ---- TOP STATS ROW ----
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total Orders',
                          _getTotalOrders(stats).toString(),
                          Icons.receipt,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          'Revenue',
                          '₹${(stats['total_revenue'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          Icons.currency_rupee,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Avg Prep Time',
                          '${stats['avg_prep_time']?['avg_minutes'] ?? 0} min',
                          Icons.timer,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          'Late Orders',
                          '${stats['late_orders'] ?? 0}',
                          Icons.warning,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---- PREP TIME BREAKDOWN ----
                  _sectionTitle('⏱️ Prep Time Breakdown'),
                  Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _prepTimeItem(
                            '🏃 Fastest',
                            '${stats['avg_prep_time']?['fastest'] ?? 0} min',
                            Colors.green,
                          ),
                          _prepTimeItem(
                            '📊 Average',
                            '${stats['avg_prep_time']?['avg_minutes'] ?? 0} min',
                            Colors.orange,
                          ),
                          _prepTimeItem(
                            '🐢 Slowest',
                            '${stats['avg_prep_time']?['slowest'] ?? 0} min',
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---- HOURLY ORDERS (Bar Chart) ----
                  _sectionTitle('📈 Hourly Orders'),
                  Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildHourlyChart(stats['hourly_orders'] ?? []),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---- TOP ITEMS ----
                  _sectionTitle('🏆 Top Items Today'),
                  Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: (stats['top_items'] as List?)
                                ?.asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final medals = ['🥇', '🥈', '🥉', '4.', '5.'];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Text(medals[index],
                                        style:
                                            const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['name'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${item['quantity']} sold',
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList() ??
                            [
                              const Text('No data yet',
                                  style: TextStyle(color: Colors.grey))
                            ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prepTimeItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHourlyChart(List hourlyData) {
    if (hourlyData.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.grey)),
      );
    }

    final maxOrders = hourlyData
        .map((h) => h['orders'] as int)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hourlyData.map((h) {
          final hour = h['hour'] as int;
          final orders = h['orders'] as int;
          final heightPercent =
              maxOrders > 0 ? (orders / maxOrders) : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$orders',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: heightPercent * 70 + 5,
                    decoration: BoxDecoration(
                      color: orders == maxOrders
                          ? Colors.red
                          : Colors.orange,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hour}h',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getTotalOrders(Map<String, dynamic> stats) {
    final counts = stats['status_counts'] as List? ?? [];
    return counts.fold(0, (sum, c) {
      final count = c['count'];
      final parsed = count is int ? count : int.tryParse(count.toString()) ?? 0;
      return sum + parsed;
    });
  }
}
