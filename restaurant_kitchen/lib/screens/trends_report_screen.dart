import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrendsReportScreen extends StatefulWidget {
  const TrendsReportScreen({super.key});

  @override
  State<TrendsReportScreen> createState() => _TrendsReportScreenState();
}

class _TrendsReportScreenState extends State<TrendsReportScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _period = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getTrends(_period);
      if (result['success'] == true) {
        setState(() {
          _data = result['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: const Text('📈 Trends Report'),
        actions: [
          // Period Toggle
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'weekly', label: Text('Week')),
              ButtonSegment(value: 'monthly', label: Text('Month')),
            ],
            selected: {_period},
            onSelectionChanged: (val) {
              setState(() => _period = val.first);
              _loadTrends();
            },
            style: ButtonStyle(
              foregroundColor:
                  WidgetStateProperty.all(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
          : _data == null
              ? const Center(
                  child: Text('Data nahi mila',
                      style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              'Total Orders',
                              '${_data!['total_orders']}',
                              Icons.receipt,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryCard(
                              'Cancelled',
                              '${_data!['cancelled_orders']}',
                              Icons.cancel,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryCard(
                              'Cancel Rate',
                              '${_data!['cancellation_rate']}%',
                              Icons.pie_chart,
                              double.parse(
                                          '${_data!['cancellation_rate']}') >
                                      10
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Daily Trend Chart
                      _sectionTitle('📊 Daily Orders Trend'),
                      Card(
                        color: Colors.grey[850],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildTrendChart(
                              _data!['daily_trend'] ?? []),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Revenue Trend
                      _sectionTitle('💰 Daily Revenue'),
                      Card(
                        color: Colors.grey[850],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildRevenueChart(
                              _data!['daily_trend'] ?? []),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Status Distribution
                      _sectionTitle('📋 Status Distribution'),
                      Card(
                        color: Colors.grey[850],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: (_data!['status_distribution']
                                        as List?)
                                    ?.map((s) => _statusBar(
                                        s['status'],
                                        s['count']))
                                    .toList() ??
                                [],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style:
                    TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTrendChart(List trend) {
    if (trend.isEmpty) {
      return const SizedBox(
          height: 100,
          child: Center(
              child:
                  Text('No data', style: TextStyle(color: Colors.grey))));
    }

    final maxOrders = trend
        .map((d) => d['orders'] as int)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((d) {
          final orders = d['orders'] as int;
          final heightPct = maxOrders > 0 ? orders / maxOrders : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$orders',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: heightPct * 90 + 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.red[900]!, Colors.orange],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d['label'] ?? '',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 9),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueChart(List trend) {
    if (trend.isEmpty) return const SizedBox();

    final maxRev = trend
        .map((d) => (d['revenue'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((d) {
          final rev = (d['revenue'] as num).toDouble();
          final heightPct = maxRev > 0 ? rev / maxRev : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('₹${rev.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 9)),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: heightPct * 70 + 5,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusBar(String status, dynamic countValue) {
    final total = _data!['total_orders'] as int? ?? 1;
    final count = countValue is int
        ? countValue
        : int.tryParse(countValue.toString()) ?? 0;
    final pct = (count / total * 100).clamp(0, 100);

    Color color;
    switch (status) {
      case 'served':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'placed':
        color = Colors.blue;
        break;
      case 'preparing':
        color = Colors.orange;
        break;
      case 'ready':
        color = Colors.teal;
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(status.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: Colors.grey[800],
                valueColor:
                    AlwaysStoppedAnimation<Color>(color),
                minHeight: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
