import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';

class OrdersScreenBak extends StatefulWidget {
  const OrdersScreenBak({super.key});

  @override
  State<OrdersScreenBak> createState() => _OrdersScreenBakState();
}

class _OrdersScreenBakState extends State<OrdersScreenBak> {
  String _filter = 'all';
  String _statusFilter = '';
  final _orderSearchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _orderSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15213A),
        foregroundColor: Colors.white,
        title: Text('Orders (${admin.totalOrders})'),
      ),
        body: _orderFeed(admin.orders, admin.isOrdersLoading),
    );
  }

  Widget _orderFeed(List<dynamic> orders, bool isLoading) {
    final filtered = orders.where((order) {
      final matchesType = _filter == 'all' || order['order_type'] == _filter;
      final matchesStatus = _statusFilter.isEmpty || order['status'] == _statusFilter;
      return matchesType && matchesStatus;
    }).toList();
    final revenue = orders.fold<double>(0, (sum, order) => sum + _asDouble(order['final_amount']));
    final takeaway = orders.where((order) => order['order_type'] == 'takeaway').length;
    final dineIn = orders.where((order) => order['order_type'] == 'dine-in').length;
    final delivery = orders.where((order) => order['order_type'] == 'delivery').length;
    return LayoutBuilder(builder: (context, constraints) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Order overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF15213A))),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _metric('Orders', '${orders.length}', Icons.receipt_long, const Color(0xFF3F51B5)),
            _metric('Revenue', '₹${revenue.toStringAsFixed(0)}', Icons.payments, const Color(0xFF00897B)),
            _metric('Dine-in', '$dineIn', Icons.table_restaurant, const Color(0xFFEF6C00)),
            _metric('Takeaway', '$takeaway', Icons.shopping_bag_outlined, const Color(0xFF43A047)),
            _metric('Delivery', '$delivery', Icons.delivery_dining, const Color(0xFF8E24AA)),
          ]),
          const SizedBox(height: 22),
          Row(children: [Expanded(child: Text('Recent orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), if (isLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 8), Text('${filtered.length} shown', style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 10),
          TextField(
            controller: _orderSearchCtrl,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _searchOrders(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search exact order ID, e.g. 12',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.clear), tooltip: 'Clear search', onPressed: () { _orderSearchCtrl.clear(); context.read<AdminProvider>().loadOrders(); }),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _filterChip('All', 'all'), _filterChip('Dine-in', 'dine-in'), _filterChip('Takeaway', 'takeaway'), _filterChip('Delivery', 'delivery'),
          ])),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _statusFilterChip('All status', ''), _statusFilterChip('Placed', 'placed'), _statusFilterChip('Accepted', 'accepted'), _statusFilterChip('Preparing', 'preparing'), _statusFilterChip('Ready', 'ready'), _statusFilterChip('Served', 'served'), _statusFilterChip('Cancelled', 'cancelled'),
          ])),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_alt_off_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      _statusFilter.isNotEmpty || _filter != 'all' || _orderSearchCtrl.text.isNotEmpty
                          ? 'No orders in this filter'
                          : 'No orders yet',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusFilter.isNotEmpty || _filter != 'all' || _orderSearchCtrl.text.isNotEmpty
                          ? 'Change or clear the filters to see other orders.'
                          : 'New POS and customer orders will appear here.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ...filtered.map(_orderCard),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) => Container(
    width: 158,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: .18))),
    child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))])]),
  );

  Widget _filterChip(String label, String value) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: _filter == value, selectedColor: const Color(0xFF15213A), labelStyle: TextStyle(color: _filter == value ? Colors.white : const Color(0xFF37474F)), onSelected: (_) => setState(() => _filter = value)));

  Widget _statusFilterChip(String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _statusFilter == value,
      selectedColor: const Color(0xFF3F51B5),
      labelStyle: TextStyle(color: _statusFilter == value ? Colors.white : const Color(0xFF37474F)),
      onSelected: (_) {
        setState(() => _statusFilter = value);
      },
    ),
  );

  void _searchOrders() {
    final value = int.tryParse(_orderSearchCtrl.text.trim());
    context.read<AdminProvider>().loadOrders(orderId: value);
  }

  Widget _orderCard(dynamic order) {
    final status = order['status']?.toString() ?? '';
    final type = order['order_type']?.toString() ?? 'dine-in';
    final date = DateTime.tryParse(order['placed_at']?.toString() ?? '');
    final time = date == null ? '' : '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final color = _typeColor(type);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: const Color(0xFF15213A).withValues(alpha: .1))),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showOrderDetails(order),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(8)), child: Icon(_typeIcon(type), color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('#${order['id']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(width: 8), _statusChip(status)]),
            const SizedBox(height: 4),
            Text('${_typeLabel(type)} • ${order['table_number'] ?? 'No table'}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          Text('₹${_asDouble(order['final_amount']).toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF15213A))),
          const SizedBox(width: 8), const Icon(Icons.chevron_right, color: Colors.grey),
        ])),
      ),
    );
  }

  Color _typeColor(String type) => type == 'takeaway' ? const Color(0xFF43A047) : type == 'delivery' ? const Color(0xFF8E24AA) : const Color(0xFFEF6C00);
  IconData _typeIcon(String type) => type == 'takeaway' ? Icons.shopping_bag_outlined : type == 'delivery' ? Icons.delivery_dining : Icons.table_restaurant;
  String _typeLabel(String type) => type == 'takeaway' ? 'Takeaway' : type == 'delivery' ? 'Delivery' : 'Dine-in';
  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;

  Future<void> _showOrderDetails(dynamic order) async {
    final result = await ApiService().getPosBill(order['id']);
    if (!mounted) return;
    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order details load nahi hue'), backgroundColor: Colors.red));
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    final printableOrder = data['order'] as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    final summary = data['summary'] as Map<String, dynamic>;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: .78,
          minChildSize: .45,
          maxChildSize: .95,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Text('Order #${printableOrder['id']}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
                _statusChip(printableOrder['status']?.toString() ?? ''),
              ]),
              const SizedBox(height: 4),
              Text('${(printableOrder['order_type'] ?? '').toString().toUpperCase()} • ${printableOrder['table_number'] ?? 'No table'}'),
              if ((printableOrder['customer_name'] ?? '').toString().isNotEmpty)
                Text('Customer: ${printableOrder['customer_name']}'),
              const Divider(height: 28),
              const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(radius: 15, child: Text('${entry.key + 1}')),
                  title: Text(item['item_name'] ?? ''),
                  subtitle: Text('${item['quantity']} × ₹${_asDouble(item['unit_price']).toStringAsFixed(2)}'),
                  trailing: Text('₹${_asDouble(item['total_price']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
              const Divider(height: 28),
              _summaryRow('Subtotal', summary['subtotal']),
              _summaryRow('GST', summary['gst']),
              _summaryRow('Service charge', summary['service_charge']),
              if (_asDouble(summary['discount']) > 0) _summaryRow('Discount', -_asDouble(summary['discount'])),
              const Divider(),
              _summaryRow('Grand total', summary['final_amount'], bold: true),
              if ((printableOrder['notes'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Note: ${printableOrder['notes']}'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, dynamic amount, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)), Text('₹${_asDouble(amount).toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600))]),
  );

  Widget _statusChip(String status) {
    final color = status == 'served' ? Colors.green : status == 'cancelled' ? Colors.red : Colors.orange;
    return Chip(label: Text(status.toUpperCase()), labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11), backgroundColor: color.withValues(alpha: .1));
  }
}
