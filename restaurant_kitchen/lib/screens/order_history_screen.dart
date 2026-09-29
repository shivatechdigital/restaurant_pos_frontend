import 'package:flutter/material.dart';

import '../services/api_service.dart';

class KitchenHistoryScreen extends StatefulWidget {
  const KitchenHistoryScreen({super.key});

  @override
  State<KitchenHistoryScreen> createState() => _KitchenHistoryScreenState();
}

class _KitchenHistoryScreenState extends State<KitchenHistoryScreen> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filterStatus = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final result = await _api.getKitchenHistory(
        status: _filterStatus.isEmpty ? null : _filterStatus,
      );
      if (!mounted) return;
      setState(() {
        _orders = result['success'] == true
            ? List<dynamic>.from(result['data']?['orders'] ?? const [])
            : [];
        _error = result['success'] == true
            ? ''
            : result['message']?.toString() ?? 'History load nahi hui';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Retry karein.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: const Text('📜 Order History'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.grey[850],
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _filterBtn('All', ''),
                _filterBtn('✅ Served', 'served'),
                _filterBtn('❌ Cancelled', 'cancelled'),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _loadHistory,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _orders.isEmpty
                ? const Center(
                    child: Text(
                      'Koi history nahi mili',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _historyCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String label, String status) {
    final isActive = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isActive,
        selectedColor: const Color(0xFFB71C1C),
        backgroundColor: Colors.grey[800],
        labelStyle: TextStyle(
          color: isActive ? Colors.white : Colors.grey[400],
        ),
        onSelected: (_) {
          setState(() => _filterStatus = status);
          _loadHistory();
        },
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> order) {
    final isServed = order['status'] == 'served';
    final isCancelled = order['status'] == 'cancelled';
    final items = order['items'] as List? ?? [];
    final date = DateTime.tryParse(order['placed_at']?.toString() ?? '')
        ?.toLocal();
    final timeStr = date != null
        ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status icon
            Icon(
              isServed
                  ? Icons.check_circle
                  : isCancelled
                  ? Icons.cancel
                  : Icons.receipt,
              color: isServed
                  ? Colors.green
                  : isCancelled
                  ? Colors.red
                  : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${order['id']} • ${order['table_number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if ((order['waiter_name'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Waiter: ${order['waiter_name']}',
                        style: TextStyle(
                          color: Colors.blueGrey[200],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Text(
                    items.length <= 2
                        ? items
                              .map((i) => '${i['name']} ×${i['qty']}')
                              .join(', ')
                        : '${items.take(2).map((i) => i['name']).join(', ')} +${items.length - 2}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Prep time + Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${(order['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (order['prep_time'] != null)
                  Text(
                    '${order['prep_time']} min',
                    style: TextStyle(
                      color: (order['prep_time'] as num) > 15
                          ? Colors.red
                          : Colors.green,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
