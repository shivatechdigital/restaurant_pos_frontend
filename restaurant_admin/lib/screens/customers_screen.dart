import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _segment = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isMobile = width < 700;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: const SafeArea(child: AppSidebar(activeLabel: 'Customers')),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              Container(
                width: 220,
                color: const Color(0xFF1E1E1E),
                child: const AppSidebar(activeLabel: 'Customers'),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Customers & Loyalty',
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (value) => admin.loadCustomers(search: value, segment: _segment),
                            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search name or phone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            children: [
                              _segmentChip(admin, 'All', ''),
                              _segmentChip(admin, 'VIP', 'vip'),
                              _segmentChip(admin, 'Repeat', 'repeat'),
                              _segmentChip(admin, 'At Risk', 'at_risk'),
                              _segmentChip(admin, 'Birthdays', 'birthday_month'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: admin.customers.isEmpty
                              ? const Center(child: Text('No loyalty customers yet'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: admin.customers.length,
                                  itemBuilder: (context, index) {
                                    final customer = admin.customers[index];
                                    return Card(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.cyan[50],
                                          child: Text((customer['name'] ?? customer['phone'] ?? '?').toString()[0].toUpperCase()),
                                        ),
                                        title: Text(customer['name'] ?? 'Customer'),
                                        subtitle: Text('${customer['phone'] ?? ''} • ${customer['total_visits'] ?? 0} visits • ₹${_number(customer['total_spend']).toStringAsFixed(0)} spent'),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('${customer['loyalty_points'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 18)),
                                            const Text('points', style: TextStyle(fontSize: 11)),
                                          ],
                                        ),
                                        onTap: () => _showProfile(admin, customer),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
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

  Future<void> _showProfile(AdminProvider admin, dynamic customer) async {
    final data = await admin.loadCustomer(customer['id']);
    if (!mounted || data == null) return;
    final profile = data['customer'];
    final ledger = data['loyalty_history'] as List? ?? [];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(profile['name'] ?? 'Customer Profile'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile['phone'] ?? ''),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _stat('Points', '${profile['loyalty_points'] ?? 0}')),
                Expanded(child: _stat('Visits', '${profile['total_visits'] ?? 0}')),
                Expanded(child: _stat('Spend', '₹${_number(profile['total_spend']).toStringAsFixed(0)}')),
              ]),
              const Divider(height: 24),
              const Text('Loyalty History', style: TextStyle(fontWeight: FontWeight.bold)),
              if (ledger.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No points activity')),
              ...ledger.take(8).map((entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_number(entry['points']) >= 0 ? Icons.add_circle : Icons.remove_circle, color: _number(entry['points']) >= 0 ? Colors.green : Colors.red),
                    title: Text('${entry['type']} ${_number(entry['points']).toStringAsFixed(0)} points'),
                    subtitle: Text(entry['notes'] ?? ''),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _editProfile(admin, profile); }, child: const Text('Edit')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _segmentChip(AdminProvider admin, String label, String value) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      selected: _segment == value,
      onSelected: (_) {
        setState(() => _segment = value);
        admin.loadCustomers(search: _searchCtrl.text, segment: value);
      },
    ),
  );

  Future<void> _editProfile(AdminProvider admin, dynamic profile) async {
    final nameCtrl = TextEditingController(text: profile['name'] ?? '');
    final birthdayCtrl = TextEditingController(text: profile['birthday']?.toString().split('T').first ?? '');
    final anniversaryCtrl = TextEditingController(text: profile['anniversary']?.toString().split('T').first ?? '');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: birthdayCtrl, decoration: const InputDecoration(labelText: 'Birthday (YYYY-MM-DD)')),
            TextField(controller: anniversaryCtrl, decoration: const InputDecoration(labelText: 'Anniversary (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (accepted != true) return;
    final ok = await admin.updateCustomer(profile['id'], {
      'name': nameCtrl.text.trim(),
      'birthday': birthdayCtrl.text.trim().isEmpty ? null : birthdayCtrl.text.trim(),
      'anniversary': anniversaryCtrl.text.trim().isEmpty ? null : anniversaryCtrl.text.trim(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Customer updated' : 'Unable to update customer'), backgroundColor: ok ? Colors.green : Colors.red));
  }

  Widget _stat(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))]);

  double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}
