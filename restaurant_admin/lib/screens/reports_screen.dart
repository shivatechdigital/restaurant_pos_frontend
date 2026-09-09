import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = context.read<AdminProvider>();
      admin.loadDashboard();
      admin.loadGST(now.month.toString(), now.year.toString());
      admin.loadDailyClosing();
      admin.loadCashShifts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final gst = admin.gstData;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isMobile = width < 700;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: const SafeArea(child: AppSidebar(activeLabel: 'Reports')),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              Container(
                width: 220,
                color: const Color(0xFF1E1E1E),
                child: const AppSidebar(activeLabel: 'Reports'),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Reports & GST',
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dailyClosingCard(admin),
                          const SizedBox(height: 20),
                          _cashShiftCard(admin),
                          const SizedBox(height: 20),
                          const Text('💰 Revenue Report',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: admin.revenueData == null
                                  ? const Text('Loading...')
                                  : Column(
                                      children: [
                                        _row('Total Orders',
                                            '${admin.revenueData!['grand_total']?['total_orders'] ?? 0}'),
                                        _row('Total Revenue',
                                            '₹${_asDouble(admin.revenueData!['grand_total']?['total_revenue']).toStringAsFixed(0)}'),
                                        _row('GST Collected',
                                            '₹${_asDouble(admin.revenueData!['grand_total']?['total_gst_collected']).toStringAsFixed(0)}'),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('📋 GST Report (This Month)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: gst == null
                                  ? const Text('Loading...')
                                  : Column(
                                      children: [
                                        _row('Restaurant', gst['restaurant']?['name'] ?? ''),
                                        _row('GSTIN', gst['restaurant']?['gst_number'] ?? ''),
                                        const Divider(),
                                        _row('Total Bills',
                                            '${gst['totals']?['total_bills'] ?? 0}'),
                                        _row('Taxable Value',
                                            '₹${_asDouble(gst['totals']?['taxable_value']).toStringAsFixed(2)}'),
                                        _row('CGST',
                                            '₹${_asDouble(gst['totals']?['cgst']).toStringAsFixed(2)}'),
                                        _row('SGST',
                                            '₹${_asDouble(gst['totals']?['sgst']).toStringAsFixed(2)}'),
                                        const Divider(thickness: 2),
                                        _row('Total Invoice',
                                            '₹${_asDouble(gst['totals']?['total_invoice_value']).toStringAsFixed(2)}',
                                            bold: true),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _dailyClosingCard(AdminProvider admin) {
    final data = admin.dailyClosingData;
    if (data == null) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Loading daily closing...')));
    final summary = data['summary'] ?? <String, dynamic>{};
    final closing = data['closing'];
    final expectedCash = _asDouble(summary['expected_cash']);
    final payments = summary['payment_breakdown'] as List? ?? [];
    final unpaidSessions = data['unpaid_sessions'] as List? ?? [];
    final variance = closing == null ? null : _asDouble(closing['cash_variance']);

    return Card(
      color: closing == null ? Colors.white : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(closing == null ? Icons.point_of_sale : Icons.verified, color: closing == null ? Colors.orange : Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(closing == null ? 'Daily Closing' : 'Day Closed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text(summary['date'] ?? ''),
              ],
            ),
            const Divider(),
            _row('Orders', '${summary['total_orders'] ?? 0}'),
            _row('Sales', '₹${_asDouble(summary['total_sales']).toStringAsFixed(2)}'),
            _row('Payment Collected', '₹${_asDouble(summary['payment_total']).toStringAsFixed(2)}'),
            _row('Expected Cash', '₹${expectedCash.toStringAsFixed(2)}', bold: true),
            if (payments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: payments.map((payment) => Chip(
                  label: Text('${payment['method']}: ₹${_asDouble(payment['amount']).toStringAsFixed(0)}'),
                )).toList(),
              ),
            ],
            if (unpaidSessions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.orange[50],
                child: Text('${unpaidSessions.length} unpaid table(s): ${unpaidSessions.map((session) => session['table_number']).join(', ')}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
              ),
            ],
            if (closing != null) ...[
              const Divider(),
              _row('Declared Cash', '₹${_asDouble(closing['actual_cash']).toStringAsFixed(2)}'),
              _row('Cash Variance', '${variance! >= 0 ? '+' : ''}₹${variance.toStringAsFixed(2)}', bold: true),
              if ((closing['notes'] ?? '').toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text('Note: ${closing['notes']}')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(onPressed: () => _showCsv(admin, summary['date']?.toString() ?? ''), icon: const Icon(Icons.download), label: const Text('CSV')),
                  OutlinedButton.icon(onPressed: () => _showReopenDialog(admin, summary['date']?.toString() ?? ''), icon: const Icon(Icons.lock_open), label: const Text('Reopen')),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCloseDayDialog(admin, expectedCash, summary['date']?.toString() ?? '', unpaidSessions.isNotEmpty),
                  icon: const Icon(Icons.lock_clock),
                  label: const Text('Close Day'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cashShiftCard(AdminProvider admin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF1A237E)),
                const SizedBox(width: 8),
                const Expanded(child: Text('Cash Shifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.add), tooltip: 'Open shift', onPressed: () => _showOpenShiftDialog(admin)),
              ],
            ),
            if (admin.cashShifts.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 8), child: Text('No cash shifts opened today'))
            else
              ...admin.cashShifts.map((shift) {
                final isOpen = shift['closed_at'] == null;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(shift['shift_name'] ?? 'Shift'),
                  subtitle: Text('Opening ₹${_asDouble(shift['opening_cash']).toStringAsFixed(2)}${isOpen ? ' • Open' : ' • Variance ₹${_asDouble(shift['cash_variance']).toStringAsFixed(2)}'}'),
                  trailing: isOpen ? TextButton(onPressed: () => _showCloseShiftDialog(admin, shift), child: const Text('Close')) : const Icon(Icons.verified, color: Colors.green),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _showCloseDayDialog(AdminProvider admin, double expectedCash, String date, bool hasUnpaidSessions) async {
    final cashCtrl = TextEditingController(text: expectedCash.toStringAsFixed(2));
    final notesCtrl = TextEditingController();
    bool allowUnpaid = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Confirm Daily Closing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Expected cash: ₹${expectedCash.toStringAsFixed(2)}'),
              TextField(controller: cashCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual cash counted')),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Closing note (optional)')),
              if (hasUnpaidSessions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: allowUnpaid,
                  onChanged: (value) => setDialogState(() => allowUnpaid = value ?? false),
                  title: const Text('Approve closing with unpaid tables'),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: hasUnpaidSessions && !allowUnpaid ? null : () => Navigator.pop(ctx, true), child: const Text('Confirm Close')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final ok = await admin.closeDay({
      'closing_date': date,
      'actual_cash': double.tryParse(cashCtrl.text) ?? 0,
      'notes': notesCtrl.text.trim(),
      'allow_unpaid': allowUnpaid,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Daily closing saved' : 'Unable to close day'), backgroundColor: ok ? Colors.green : Colors.red),
    );
    if (!ok) await admin.loadDailyClosing();
  }

  Future<void> _showOpenShiftDialog(AdminProvider admin) async {
    final nameCtrl = TextEditingController(text: 'Morning');
    final cashCtrl = TextEditingController(text: '0');
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Open Cash Shift'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Shift name')), TextField(controller: cashCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening cash'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open'))]));
    if (accepted != true) return;
    final ok = await admin.openCashShift({'shift_name': nameCtrl.text.trim(), 'opening_cash': double.tryParse(cashCtrl.text) ?? 0});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Shift opened' : 'Unable to open shift'), backgroundColor: ok ? Colors.green : Colors.red));
  }

  Future<void> _showCloseShiftDialog(AdminProvider admin, dynamic shift) async {
    final cashCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text('Close ${shift['shift_name']}'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: cashCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual cash counted')), TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Note'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close'))]));
    if (accepted != true) return;
    final ok = await admin.closeCashShift(shift['id'], {'actual_cash': double.tryParse(cashCtrl.text) ?? 0, 'notes': notesCtrl.text.trim()});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Shift closed' : 'Unable to close shift'), backgroundColor: ok ? Colors.green : Colors.red));
  }

  Future<void> _showReopenDialog(AdminProvider admin, String date) async {
    final reasonCtrl = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Reopen Daily Closing'), content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reopen'))]));
    if (accepted != true) return;
    final ok = await admin.reopenDay(date, reasonCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Day reopened' : 'Reason is required to reopen'), backgroundColor: ok ? Colors.green : Colors.red));
  }

  Future<void> _showCsv(AdminProvider admin, String date) async {
    final csv = await admin.downloadDailyClosingCsv(date);
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Daily Closing CSV'), content: SizedBox(width: 460, child: SingleChildScrollView(child: SelectableText(csv ?? 'Unable to create CSV export'))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]));
  }

  double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}
