import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screens/reception_pos_screen.dart';

const _tableBrand = Color(0xFFB51E2B);
const _tableApiBaseUrl = 'https://petpooja.shivatechdigital.com/api';

class ReceptionTableView extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;

  const ReceptionTableView({super.key, required this.token, required this.receptionistName, required this.onLogout});

  @override
  State<ReceptionTableView> createState() => _ReceptionTableViewState();
}

class _ReceptionTableViewState extends State<ReceptionTableView> {
  List<dynamic> _tables = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final response = await http.get(
        Uri.parse('$_tableApiBaseUrl/tables/all'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
      final success = response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true;
      setState(() {
        _tables = success && data['data'] is List ? data['data'] as List<dynamic> : [];
        _loadError = success ? null : (data['message']?.toString() ?? 'Tables load nahi ho paayi (${response.statusCode})');
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tables = [];
        _loadError = 'Backend se connection nahi ho pa raha';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTables = _tables.where((table) => table['active_session_id'] != null).length;
    final availableTables = _tables.length - activeTables;
    return Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    appBar: AppBar(
      backgroundColor: _tableBrand,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 18,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RECEPTION DESK', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Color(0xFFFFCDD2), fontWeight: FontWeight.w700)),
        Text(widget.receptionistName.isEmpty ? 'Table Overview' : 'Hi, ${widget.receptionistName}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      ]),
      actions: [
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceptionPosScreen(token: widget.token, receptionistName: widget.receptionistName, onLogout: widget.onLogout))), icon: const Icon(Icons.local_shipping_outlined), tooltip: 'Pickup / Delivery'),
        IconButton(onPressed: _loadTables, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh tables'),
        IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout_rounded), tooltip: 'Logout'),
      ],
    ),
    body: _loading ? const Center(child: CircularProgressIndicator(color: _tableBrand)) : _loadError != null ? _errorView() : Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(18, 18, 18, 16), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(22))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Live floor status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF20252B))),
        const SizedBox(height: 4),
        const Text('Tap any table to open its order', style: TextStyle(fontSize: 12, color: Color(0xFF7A838C))),
        const SizedBox(height: 14),
        Row(children: [
          _summaryChip('TOTAL', '${_tables.length}', const Color(0xFFEEF1F4), const Color(0xFF39434D)),
          const SizedBox(width: 8),
          _summaryChip('AVAILABLE', '$availableTables', const Color(0xFFE8F7EF), const Color(0xFF18834F)),
          const SizedBox(width: 8),
          _summaryChip('RUNNING', '$activeTables', const Color(0xFFFFF0D8), const Color(0xFFB36B00)),
        ]),
        const SizedBox(height: 16),
        const Row(children: [_Legend(color: Colors.white, label: 'Available'), SizedBox(width: 16), _Legend(color: Color(0xFFFFE7A6), label: 'Running KOT'), SizedBox(width: 16), _Legend(color: Color(0xFFDDF3FF), label: 'Running table')]),
      ])),
      Expanded(child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final crossAxisCount = maxWidth < 430 ? 2 : maxWidth < 700 ? 3 : 4;
          final childAspectRatio = maxWidth < 430 ? 1.1 : 1.0;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _tables.length,
            itemBuilder: (_, index) => _tableCard(_tables[index]),
          );
        },
      )),
    ]),
  );
  }

  Widget _summaryChip(String label, String value, Color background, Color foreground) => Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: foreground)), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w700, color: foreground.withValues(alpha: .75)))])));

  Widget _errorView() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_rounded, size: 48, color: _tableBrand),
    const SizedBox(height: 12),
    const Text('Tables load nahi ho paayi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 6),
    Text(_loadError ?? 'Please try again', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: _loadTables, icon: const Icon(Icons.refresh), label: const Text('Retry'), style: ElevatedButton.styleFrom(backgroundColor: _tableBrand, foregroundColor: Colors.white)),
  ])));

  Widget _tableCard(dynamic table) {
    final active = table['active_session_id'] != null;
    final hasRunningKot = table['has_running_kot'] == true;
    final status = table['status']?.toString() ?? 'available';
    final amount = _amount(table['running_amount']);
    final started = DateTime.tryParse(table['session_started_at']?.toString() ?? '');
    final minutes = started == null ? 0 : DateTime.now().difference(started.toLocal()).inMinutes.clamp(0, 999);
    final color = active && hasRunningKot ? const Color(0xFFFFE7A6) : active || status == 'reserved' ? const Color(0xFFDDF3FF) : Colors.white;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ReceptionPosScreen(
          token: widget.token,
          receptionistName: widget.receptionistName,
          onLogout: widget.onLogout,
          initialTable: table,
        )));
        if (mounted) _loadTables();
      },
      child: Ink(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: active && hasRunningKot ? const Color(0xFFE0B63D) : active ? const Color(0xFF86C5E2) : const Color(0xFFE1E5E8), width: 1.2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(11)), child: Icon(active && hasRunningKot ? Icons.receipt_long_rounded : Icons.table_restaurant_rounded, color: active && hasRunningKot ? const Color(0xFF8B6900) : active ? const Color(0xFF226684) : const Color(0xFF68747D), size: 21)),
            Text('TABLE ${table['table_number']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueGrey[700])),
          ]),
          if (active) ...[
            const SizedBox(height: 12),
            Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.schedule_rounded, size: 13, color: Colors.blueGrey[500]), const SizedBox(width: 4), Text('${hasRunningKot ? 'KOT' : 'Served'}  •  $minutes min', style: TextStyle(fontSize: 11, color: Colors.blueGrey[600], fontWeight: FontWeight.w600))]),
            const Spacer(),
            SizedBox(width: double.infinity, height: 30, child: OutlinedButton.icon(onPressed: () => _showBill(table), icon: const Icon(Icons.receipt_long, size: 14), style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: const Color(0xFF6D4D00), side: BorderSide(color: Colors.black.withValues(alpha: .18))), label: const Text('View bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))),
          ] else ...[
            const Spacer(),
            Row(children: [Icon(Icons.check_circle_outline, size: 15, color: Colors.green[700]), const SizedBox(width: 5), Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold))]),
          ],
        ])),
      ),
    );
  }

  double _amount(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

  Future<void> _showBill(dynamic table) async {
    final sessionId = table['active_session_id'];
    final response = await http.get(Uri.parse('$_tableApiBaseUrl/orders/bill/$sessionId'), headers: {'Authorization': 'Bearer ${widget.token}'});
    if (!mounted) return;
    final result = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill load nahi hua'), backgroundColor: Colors.red));
      return;
    }
    final bill = result['data'] as Map<String, dynamic>;
    final items = bill['items'] as List? ?? [];
    final summary = bill['summary'] as Map<String, dynamic>;
    final outstanding = _amount(summary['outstanding_amount']);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: .8,
        minChildSize: .45,
        maxChildSize: .95,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(18),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 14),
            Row(children: [Expanded(child: Text('Table ${table['table_number']} Bill', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), Text('₹${outstanding.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _tableBrand))]),
            const Divider(height: 26),
            ...items.map((item) => ListTile(contentPadding: EdgeInsets.zero, title: Text(item['item_name'] ?? ''), subtitle: Text('${item['quantity']} × ₹${_amount(item['unit_price']).toStringAsFixed(2)}'), trailing: Text('₹${_amount(item['total_price']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)))),
            const Divider(height: 26),
            _billRow('Subtotal', summary['subtotal']),
            _billRow('GST', summary['total_gst']),
            _billRow('Service charge', summary['service_charge']),
            if (_amount(summary['paid_amount']) > 0) _billRow('Already paid', -_amount(summary['paid_amount'])),
            const Divider(),
            _billRow('Outstanding', outstanding, bold: true),
            const SizedBox(height: 16),
            SizedBox(height: 50, child: ElevatedButton.icon(onPressed: outstanding <= 0 ? null : () => _settleCash(ctx, sessionId, outstanding), icon: const Icon(Icons.payments), label: Text('Settle Cash ₹${outstanding.toStringAsFixed(0)}'), style: ElevatedButton.styleFrom(backgroundColor: _tableBrand, foregroundColor: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, dynamic value, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)), Text('₹${_amount(value).toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600))]));

  Future<void> _settleCash(BuildContext sheetContext, dynamic sessionId, double amount) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm Cash Payment'), content: Text('Receive ₹${amount.toStringAsFixed(2)} cash for this table?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm'))]));
    if (confirmed != true) return;
    final response = await http.post(Uri.parse('$_tableApiBaseUrl/payments/cash'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'}, body: jsonEncode({'session_id': sessionId, 'amount': amount}));
    if (!mounted) return;
    final result = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (result['success'] == true) {
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      await _loadTables();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cash payment recorded. Table is available.'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Payment failed'), backgroundColor: Colors.red));
    }
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8))), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 12))]);
}
