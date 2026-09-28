import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class BillManagementScreen extends StatefulWidget {
  const BillManagementScreen({super.key});

  @override
  State<BillManagementScreen> createState() => _BillManagementScreenState();
}

class _BillManagementScreenState extends State<BillManagementScreen> {
  late DateTime _selectedDate;

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        context.read<AdminProvider>().loadDailyClosing(
          date: _dateKey(_selectedDate),
        );
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
    await context.read<AdminProvider>().loadDailyClosing(
      date: _dateKey(selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AdminProvider>().dailyClosingData;
    final summary = data?['summary'] as Map<String, dynamic>? ?? const {};
    final payments = summary['payment_breakdown'] as List? ?? const [];
    final unpaid = data?['unpaid_sessions'] as List? ?? const [];
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final isMobile = width < 700;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: const Color(0xFF1E1E1E),
              child: const SafeArea(
                child: AppSidebar(activeLabel: 'Bill Management'),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              const CollapsibleSidebar(activeLabel: 'Bill Management'),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: !isDesktop
                        ? () => Scaffold.of(context).openDrawer()
                        : null,
                    title: 'Bill Management',
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => context
                          .read<AdminProvider>()
                          .loadDailyClosing(date: _dateKey(_selectedDate)),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Payment collection',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                label: Text(_dateKey(_selectedDate)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (data == null)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else ...[
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _metric(
                                  'Sales',
                                  _money(summary['total_sales']),
                                  Icons.receipt_long,
                                  const Color(0xFF1976D2),
                                ),
                                _metric(
                                  'Collected',
                                  _money(summary['payment_total']),
                                  Icons.payments,
                                  const Color(0xFF2E7D32),
                                ),
                                _metric(
                                  'Orders',
                                  '${summary['total_orders'] ?? 0}',
                                  Icons.shopping_bag,
                                  const Color(0xFFEF6C00),
                                ),
                                _metric(
                                  'Open bills',
                                  '${unpaid.length}',
                                  Icons.pending_actions,
                                  const Color(0xFFC62828),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Collected by payment method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (payments.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                    'No completed payments for this date',
                                  ),
                                ),
                              )
                            else
                              ...payments.map(
                                (payment) => Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFE8F5E9),
                                      child: Icon(
                                        _paymentIcon(payment['method']),
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                    title: Text(
                                      _label(payment['method']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${payment['count'] ?? 0} successful payment(s)',
                                    ),
                                    trailing: Text(
                                      _money(payment['amount']),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            const Text(
                              'Outstanding table bills',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (unpaid.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text('No outstanding table bills'),
                                ),
                              )
                            else
                              ...unpaid.map(
                                (bill) => Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.table_restaurant,
                                      color: Color(0xFFC62828),
                                    ),
                                    title: Text(
                                      'Table ${bill['table_number'] ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Session ${bill['session_id']} • Paid ${_money(bill['paid_amount'])}',
                                    ),
                                    trailing: Text(
                                      _money(bill['outstanding_amount']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

  Widget _metric(String label, String value, IconData icon, Color color) =>
      SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _money(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _label(dynamic method) => switch (method?.toString()) {
    'cash' => 'Cash',
    'upi' => 'Online / UPI',
    'card' => 'Card',
    _ => method?.toString().toUpperCase() ?? 'Other',
  };

  IconData _paymentIcon(dynamic method) => switch (method?.toString()) {
    'cash' => Icons.currency_rupee,
    'upi' => Icons.qr_code_2,
    'card' => Icons.credit_card,
    _ => Icons.payments,
  };
}
