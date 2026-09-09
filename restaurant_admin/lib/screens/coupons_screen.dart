import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().loadCoupons();
    });
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
        child: const SafeArea(child: AppSidebar(activeLabel: 'Offers & Promotions')),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              Container(
                width: 220,
                color: const Color(0xFF1E1E1E),
                child: const AppSidebar(activeLabel: 'Offers & Promotions'),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Coupons & Offers',
                  ),
                  Expanded(
                    child: admin.coupons.isEmpty
                        ? const Center(child: Text('No coupons created'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: admin.coupons.length,
                            itemBuilder: (context, index) {
                              final coupon = admin.coupons[index];
                              final active = coupon['is_active'] == true;
                              final type = coupon['discount_type'] == 'percent' ? '%' : '₹';
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: active ? Colors.green[50] : Colors.grey[200],
                                    child: const Icon(Icons.sell, color: Color(0xFF1A237E)),
                                  ),
                                  title: Text(coupon['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${_value(coupon['discount_value'])}$type off • Min order ₹${_value(coupon['min_order_amount'])}\nUsed ${coupon['usage_count'] ?? 0}${coupon['usage_limit'] == null ? '' : ' / ${coupon['usage_limit']}'}'),
                                  isThreeLine: true,
                                  trailing: Switch(
                                    value: active,
                                    onChanged: (value) => admin.toggleCoupon(coupon['id'], value),
                                  ),
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
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create coupon',
        onPressed: () => _showCouponDialog(admin),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCouponDialog(AdminProvider admin) async {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minimumCtrl = TextEditingController(text: '0');
    final limitCtrl = TextEditingController();
    String type = 'percent';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Coupon'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: codeCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Coupon code')),
              SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'percent', label: Text('% Percent')), ButtonSegment(value: 'fixed', label: Text('₹ Fixed'))],
                selected: {type},
                onSelectionChanged: (value) => setDialogState(() => type = value.first),
              ),
              TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount value')),
              TextField(controller: minimumCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum order amount')),
              TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Usage limit (optional)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    final ok = await admin.createCoupon({
      'code': codeCtrl.text.trim(),
      'discount_type': type,
      'discount_value': double.tryParse(valueCtrl.text) ?? 0,
      'min_order_amount': double.tryParse(minimumCtrl.text) ?? 0,
      if (limitCtrl.text.trim().isNotEmpty) 'usage_limit': int.tryParse(limitCtrl.text),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Coupon created' : 'Unable to create coupon'), backgroundColor: ok ? Colors.green : Colors.red));
  }

  String _value(dynamic value) => (value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0).toStringAsFixed(0);
}
