import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PrintPreviewScreen extends StatefulWidget {
  final int orderId;
  final String type;

  const PrintPreviewScreen({
    super.key,
    required this.orderId,
    required this.type,
  });

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = widget.type == 'KOT'
        ? await _api.getKot(widget.orderId)
        : await _api.getPosBill(widget.orderId);
    if (!mounted) return;
    setState(() {
      _data = result['success'] == true ? result['data'] : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Text('${widget.type} Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print integration next step')),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('Print data nahi mila'))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: widget.type == 'KOT' ? 300 : 360,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      color: Colors.white,
                      child: _receipt(data),
                    ),
                  ),
                ),
    );
  }

  Widget _receipt(Map<String, dynamic> data) {
    final order = data['order'] as Map<String, dynamic>;
    final restaurant = data['restaurant'] as Map<String, dynamic>;
    final items = data['items'] as List? ?? [];
    final summary = data['summary'] as Map<String, dynamic>;

    if (widget.type == 'KOT') {
      return _kotReceipt(order, restaurant, items, summary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.type,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          restaurant['name'] ?? 'Restaurant',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (restaurant['gst_number'] != null && widget.type == 'BILL')
          Text('GSTIN: ${restaurant['gst_number']}', textAlign: TextAlign.center),
        const Divider(),
        Text('Order #${order['id']}'),
        Text('Table: ${order['table_number']}'),
        Text('Type: ${order['order_type']}'),
        const Divider(),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(child: Text('${item['quantity']} x ${item['item_name']}')),
                if (widget.type == 'BILL')
                  Text('₹${_asDouble(item['total_price']).toStringAsFixed(0)}'),
              ],
            ),
          );
        }),
        if ((order['notes'] ?? '').toString().isNotEmpty) ...[
          const Divider(),
          Text('Notes: ${order['notes']}'),
        ],
        if (widget.type == 'BILL') ...[
          const Divider(),
          _row('Subtotal', summary['subtotal']),
          _row('GST', summary['gst']),
          _row('Service', summary['service_charge']),
          _row('Discount', summary['discount']),
          const Divider(),
          _row('TOTAL', summary['final_amount'], bold: true),
        ],
        const Divider(),
        const Text('Thank you', textAlign: TextAlign.center),
      ],
    );
  }

  Widget _kotReceipt(
      Map<String, dynamic> order, Map<String, dynamic> restaurant, List items, Map<String, dynamic> summary) {
    final placedAt = DateTime.tryParse(order['placed_at']?.toString() ?? '');
    final date = placedAt == null
        ? '-'
        : '${placedAt.day.toString().padLeft(2, '0')}/${placedAt.month.toString().padLeft(2, '0')}/${placedAt.year.toString().substring(2)} ${placedAt.hour.toString().padLeft(2, '0')}:${placedAt.minute.toString().padLeft(2, '0')}';
    final orderType = (order['order_type'] ?? 'dine-in').toString().toUpperCase();

    return DefaultTextStyle(
      style: const TextStyle(color: Colors.black, fontSize: 12, height: 1.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(restaurant['name'] ?? 'Restaurant', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if ((restaurant['address'] ?? '').toString().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 3), child: Text(restaurant['address'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
          if ((restaurant['phone'] ?? '').toString().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 2), child: Text('Contact: ${restaurant['phone']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 10),
          const Divider(thickness: 1, color: Colors.black),
          Row(children: [const Expanded(child: Text('KITCHEN ORDER TICKET', style: TextStyle(fontWeight: FontWeight.bold))), Text(orderType)]),
          const Divider(height: 10, thickness: 1, color: Colors.black),
          _kotInfo('Order No.', '#${order['id']}'),
          _kotInfo('Date', date),
          _kotInfo('Table', order['table_number'] ?? orderType),
          if ((order['customer_name'] ?? '').toString().isNotEmpty)
            _kotInfo('Name', order['customer_name']),
          const Divider(thickness: 1, color: Colors.black),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [SizedBox(width: 24, child: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 32, child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 45, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 51, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)))]),
          ),
          const Divider(height: 2, thickness: 1, color: Colors.black),
          ...items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 24, child: Text('$index')),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['item_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)), if ((item['special_instructions'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text('Note: ${item['special_instructions']}', style: const TextStyle(fontSize: 10))) ])),
                SizedBox(width: 32, child: Text('${item['quantity']}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 45, child: Text(_asDouble(item['unit_price']).toStringAsFixed(0), textAlign: TextAlign.right)),
                SizedBox(width: 51, child: Text(_asDouble(item['total_price']).toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
            );
          }),
          const Divider(thickness: 1, color: Colors.black),
          _kotInfo('Total Qty', '${items.fold<int>(0, (total, item) => total + ((item['quantity'] as num?)?.toInt() ?? 0))}'),
          const Divider(thickness: 1, color: Colors.black),
          _kotAmount('Subtotal', summary['subtotal']),
          _kotAmount('GST', summary['gst']),
          _kotAmount('Service Charge', summary['service_charge']),
          if (_asDouble(summary['discount']) > 0)
            _kotAmount('Discount', -_asDouble(summary['discount'])),
          const Divider(height: 12, thickness: 1, color: Colors.black),
          _kotAmount('GRAND TOTAL', summary['final_amount'], bold: true),
          if ((order['notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text('Order Note: ${order['notes']}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          const Text('*** KITCHEN COPY ***', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _kotInfo(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [SizedBox(width: 72, child: Text('$label:')), Expanded(child: Text(value?.toString() ?? '-'))]),
  );

  Widget _kotAmount(String label, dynamic value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
        Text('₹${_asDouble(value).toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ],
    ),
  );

  Widget _row(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${_asDouble(value).toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
}
