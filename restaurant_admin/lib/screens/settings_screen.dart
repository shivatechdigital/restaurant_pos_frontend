import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  String _kitchenMode = 'printer_only';
  bool _selfCancel = false;
  bool _cancelAfterAccepted = false;
  bool _printCancelledKot = true;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    final result = await _api.getOrderPolicy();
    if (!mounted) return;
    if (result['success'] == true) {
      final policy = result['data'];
      setState(() {
        _kitchenMode = policy['kitchen_mode'] ?? 'printer_only';
        _selfCancel = policy['customer_self_cancel'] == true;
        _cancelAfterAccepted = policy['allow_cancel_after_accepted'] == true;
        _printCancelledKot = policy['print_cancelled_kot'] != false;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePolicy() async {
    setState(() => _saving = true);
    final result = await _api.updateOrderPolicy({
      'kitchen_mode': _kitchenMode,
      'customer_self_cancel': _selfCancel,
      'allow_cancel_after_accepted': _cancelAfterAccepted,
      'print_cancelled_kot': _printCancelledKot,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['success'] == true ? 'Order policy saved' : result['message'] ?? 'Unable to save settings'), backgroundColor: result['success'] == true ? Colors.green : Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isMobile = width < 700;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: const SafeArea(child: AppSidebar(activeLabel: 'Settings')),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              Container(
                width: 220,
                color: const Color(0xFF1E1E1E),
                child: const AppSidebar(activeLabel: 'Settings'),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Settings',
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              const Text('Kitchen & Cancellation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                              const SizedBox(height: 8),
                              Card(
                                child: RadioGroup<String>(
                                  groupValue: _kitchenMode,
                                  onChanged: (value) => setState(() {
                                    _kitchenMode = value!;
                                    if (value == 'printer_only') _selfCancel = false;
                                  }),
                                  child: Column(children: [
                                    RadioListTile<String>(
                                      value: 'printer_only',
                                      title: const Text('Printer only'),
                                      subtitle: const Text('Chef receives printed KOTs. Waiter confirms cancellation verbally.'),
                                    ),
                                    const Divider(height: 1),
                                    RadioListTile<String>(
                                      value: 'kds',
                                      title: const Text('Kitchen display (KDS)'),
                                      subtitle: const Text('Kitchen staff updates order progress on a screen.'),
                                    ),
                                    const Divider(height: 1),
                                    SwitchListTile(
                                      value: _selfCancel,
                                      onChanged: _kitchenMode == 'kds' ? (value) => setState(() => _selfCancel = value) : null,
                                      title: const Text('Allow customer self-cancellation'),
                                      subtitle: Text(_kitchenMode == 'kds' ? 'Customers can cancel while the order is eligible.' : 'Available only when Kitchen display mode is selected.'),
                                    ),
                                    SwitchListTile(
                                      value: _cancelAfterAccepted,
                                      onChanged: (value) => setState(() => _cancelAfterAccepted = value),
                                      title: const Text('Allow cancellation after accepted'),
                                      subtitle: const Text('Never allows cancellation after preparation begins.'),
                                    ),
                                    SwitchListTile(
                                      value: _printCancelledKot,
                                      onChanged: _kitchenMode == 'printer_only' ? (value) => setState(() => _printCancelledKot = value) : null,
                                      title: const Text('Print cancellation slip'),
                                      subtitle: const Text('Print a CANCELLED KOT for paper-ticket kitchens.'),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Restaurant', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                              const SizedBox(height: 8),
                              const Card(child: Column(children: [
                                ListTile(leading: Icon(Icons.receipt), title: Text('GST'), subtitle: Text('5% (2.5% CGST + 2.5% SGST)')),
                                Divider(height: 1),
                                ListTile(leading: Icon(Icons.public), title: Text('Business timezone'), subtitle: Text('Asia/Kolkata by default')),
                              ])),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _loading ? null : SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(height: 48, child: ElevatedButton.icon(onPressed: _saving ? null : _savePolicy, icon: const Icon(Icons.save), label: Text(_saving ? 'Saving...' : 'Save order policy'))),
      ),
    );
  }
}
