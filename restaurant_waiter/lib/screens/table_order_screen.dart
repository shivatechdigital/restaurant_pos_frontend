import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../services/api_service.dart';

class TableOrderScreen extends StatefulWidget {
  final TableModel table;
  final String restaurantId;

  const TableOrderScreen({
    super.key,
    required this.table,
    required this.restaurantId,
  });

  @override
  State<TableOrderScreen> createState() => _TableOrderScreenState();
}

class _TableOrderScreenState extends State<TableOrderScreen> {
  final _api = ApiService();
  List<dynamic> _categories = [];
  final List<Map<String, dynamic>> _cart = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final result = await _api.getMenu(widget.restaurantId);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _categories = result['data']['menu'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Menu load nahi hua';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems =
        _cart.fold<int>(0, (sum, item) => sum + (item['qty'] as int));
    final totalAmount = _cart.fold<double>(
        0.0,
        (sum, item) =>
            sum + (item['price'] as double) * (item['qty'] as int));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text('Table ${widget.table.tableNumber}'),
        actions: [
          if (totalItems > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('$totalItems items • ₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.green,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(_error),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = '';
                          });
                          _loadMenu();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
          : Column(
              children: [
                // Menu
                Expanded(
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, catIdx) {
                      final cat = _categories[catIdx];
                      final items = cat['items'] as List? ?? [];
                      if (items.isEmpty) return const SizedBox();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              cat['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1)),
                            ),
                          ),
                          ...items.map((item) {
                            final isAvailable =
                                item['is_available'] ?? true;
                            return ListTile(
                              enabled: isAvailable,
                              leading: Icon(
                                (item['is_veg'] ?? true)
                                    ? Icons.circle
                                    : Icons.circle,
                                color: (item['is_veg'] ?? true)
                                    ? Colors.green
                                    : Colors.red,
                                size: 14,
                              ),
                              title: Text(item['name'] ?? ''),
                              subtitle: Text(
                                  '₹${_parsePrice(item['price']).toStringAsFixed(0)}'),
                              trailing: isAvailable
                                  ? _cartButton(item)
                                  : const Text('Out of Stock',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 11)),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                // Place Order Button
                if (totalItems > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2))
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _placeOrder(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Place Order ($totalItems items • ₹${totalAmount.toStringAsFixed(0)})',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _cartButton(Map<String, dynamic> item) {
    final cartIdx = _cart.indexWhere((c) => c['id'] == item['id']);
    final qty = cartIdx >= 0 ? _cart[cartIdx]['qty'] as int : 0;

    if (qty == 0) {
      return ElevatedButton(
        onPressed: () {
          setState(() {
            _cart.add({
              'id': item['id'],
              'name': item['name'],
              'price': _parsePrice(item['price']),
              'qty': 1,
            });
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('ADD'),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () {
            setState(() {
              if (qty > 1) {
                _cart[cartIdx]['qty'] = qty - 1;
              } else {
                _cart.removeAt(cartIdx);
              }
            });
          },
        ),
        Text('$qty',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () {
            setState(() => _cart[cartIdx]['qty'] = qty + 1);
          },
        ),
      ],
    );
  }

  Future<void> _placeOrder() async {
    int? sessionId;
    if (widget.table.isOccupied) {
      final sessionResult = await _api.getTableSessions(widget.table.id);
      if (sessionResult['success'] == true && sessionResult['data'] != null) {
        sessionId = sessionResult['data']['id'];
      }
    }

    final items = _cart
        .map((c) => {
              'menu_item_id': c['id'],
              'quantity': c['qty'],
              'modifiers': [],
            })
        .toList();

    final result = await _api.placeOrder({
      'table_id': widget.table.id,
      'restaurant_id': int.parse(widget.restaurantId),
      'phone': 'waiter',
      'name': 'Waiter Order',
      'items': items,
      'session_id': ?sessionId,
    });

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Order placed! Kitchen ko bhej diya.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _cart.clear());
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Order failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _parsePrice(dynamic value) =>
      value is num ? value.toDouble() : double.parse(value.toString());
}
