import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class InventoryRequestsScreen extends StatefulWidget {
  const InventoryRequestsScreen({super.key});

  @override
  State<InventoryRequestsScreen> createState() => _InventoryRequestsScreenState();
}

class _InventoryRequestsScreenState extends State<InventoryRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _requestFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadFullInventory();
      context.read<AdminProvider>().loadMenu();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        child: const SafeArea(child: AppSidebar(activeLabel: 'Inventory')),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              Container(
                width: 220,
                color: const Color(0xFF1E1E1E),
                child: const AppSidebar(activeLabel: 'Inventory'),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Inventory',
                  ),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: const Color(0xFF1A237E),
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Stock'),
                      Tab(text: 'Purchase'),
                      Tab(text: 'Vendors'),
                      Tab(text: 'Recipes'),
                      Tab(text: 'Ledger'),
                      Tab(text: 'Requests'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _stockTab(admin),
                        _purchaseTab(admin),
                        _vendorsTab(admin),
                        _recipesTab(admin),
                        _ledgerTab(admin),
                        _requestsTab(admin),
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

  Widget _stockTab(AdminProvider admin) {
    return Column(
      children: [
        if (admin.lowStock.isNotEmpty)
          Container(
            width: double.infinity,
            color: Colors.red[50],
            padding: const EdgeInsets.all(10),
            child: Text(
              '${admin.lowStock.length} low-stock materials need attention',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showMaterialDialog(admin),
              icon: const Icon(Icons.add),
              label: const Text('Add Material / Opening Stock'),
            ),
          ),
        ),
        Expanded(
          child: admin.materials.isEmpty
              ? const Center(child: Text('No raw materials yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: admin.materials.length,
                  itemBuilder: (context, index) {
                    final m = admin.materials[index];
                    final low = m['is_low_stock'] == true;
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.inventory_2,
                            color: low ? Colors.red : Colors.green),
                        title: Text(m['name'] ?? ''),
                        subtitle: Text(
                            'Stock: ${_fmt(m['current_stock'])} ${m['unit']} • Min: ${_fmt(m['min_stock'])}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showMaterialDialog(admin, material: m),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.orange),
                              onPressed: () => _showAdjustDialog(admin, m),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _purchaseTab(AdminProvider admin) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: admin.materials.isEmpty ? null : () => _showPurchaseDialog(admin),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add Purchase'),
            ),
          ),
        ),
        Expanded(
          child: admin.purchases.isEmpty
              ? const Center(child: Text('No purchases yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: admin.purchases.length,
                  itemBuilder: (context, index) {
                    final p = admin.purchases[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.green),
                        title: Text(p['material_name'] ?? ''),
                        subtitle: Text('${_fmt(p['quantity'])} • ${p['vendor_name'] ?? 'No vendor'}'),
                        trailing: Text('₹${_fmt(p['total_cost'])}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _vendorsTab(AdminProvider admin) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showVendorDialog(admin),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Vendor'),
            ),
          ),
        ),
        Expanded(
          child: admin.vendors.isEmpty
              ? const Center(child: Text('No vendors yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: admin.vendors.length,
                  itemBuilder: (context, index) {
                    final v = admin.vendors[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.store, color: Colors.blue),
                        title: Text(v['name'] ?? ''),
                        subtitle: Text('${v['phone'] ?? ''}\n${v['address'] ?? ''}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _recipesTab(AdminProvider admin) {
    final menuItems = <dynamic>[];
    for (final cat in admin.menuCategories) {
      menuItems.addAll(cat['items'] as List? ?? []);
    }

    return menuItems.isEmpty
        ? const Center(child: Text('Menu items load nahi hue'))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt, color: Colors.orange),
                  title: Text(item['name'] ?? ''),
                  subtitle: Text('₹${_fmt(item['price'])}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRecipeDialog(admin, item),
                ),
              );
            },
          );
  }

  Widget _ledgerTab(AdminProvider admin) {
    return admin.ledger.isEmpty
        ? const Center(child: Text('Ledger empty'))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: admin.ledger.length,
            itemBuilder: (context, index) {
              final l = admin.ledger[index];
              final qty = _asDouble(l['change_qty']);
              return Card(
                child: ListTile(
                  leading: Icon(qty >= 0 ? Icons.add_circle : Icons.remove_circle,
                      color: qty >= 0 ? Colors.green : Colors.red),
                  title: Text(l['material_name'] ?? ''),
                  subtitle: Text('${l['type']} • ${l['notes'] ?? ''}'),
                  trailing: Text('${qty >= 0 ? '+' : ''}${qty.toStringAsFixed(3)} ${l['unit'] ?? ''}'),
                ),
              );
            },
          );
  }

  Widget _requestsTab(AdminProvider admin) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _requestChip(admin, 'All', ''),
                _requestChip(admin, 'Pending', 'pending'),
                _requestChip(admin, 'Ordered', 'ordered'),
                _requestChip(admin, 'Received', 'received'),
                _requestChip(admin, 'Cancelled', 'cancelled'),
              ],
            ),
          ),
        ),
        Expanded(
          child: admin.inventoryRequests.isEmpty
              ? const Center(child: Text('Koi inventory request nahi hai'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: admin.inventoryRequests.length,
                  itemBuilder: (context, index) {
                    final request = admin.inventoryRequests[index];
                    return _requestCard(admin, request);
                  },
                ),
        ),
      ],
    );
  }

  Widget _requestChip(AdminProvider admin, String label, String value) {
    final selected = _requestFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _requestFilter = value);
          admin.loadInventoryRequests(status: value.isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _requestCard(AdminProvider admin, dynamic request) {
    final status = request['status'] ?? 'pending';
    final urgent = request['urgency'] == 'urgent';
    final createdAt = DateTime.tryParse(request['created_at'] ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: urgent ? Colors.red : Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request['item_name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Quantity: ${request['quantity']?.toString().isNotEmpty == true ? request['quantity'] : '-'}'),
            if ((request['notes'] ?? '').toString().isNotEmpty)
              Text('Notes: ${request['notes']}', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text(
              '${urgent ? 'URGENT' : 'Normal'} • ${createdAt != null ? '${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}' : ''}',
              style: TextStyle(color: urgent ? Colors.red : Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _requestAction(admin, request['id'], 'ordered', 'Mark Ordered', Colors.blue),
                _requestAction(admin, request['id'], 'received', 'Received', Colors.green),
                _requestAction(admin, request['id'], 'cancelled', 'Cancel', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestAction(AdminProvider admin, int id, String status, String label, Color color) {
    return OutlinedButton(
      onPressed: () => admin.updateInventoryStatus(id, status),
      style: OutlinedButton.styleFrom(foregroundColor: color),
      child: Text(label),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'ordered':
        color = Colors.blue;
        break;
      case 'received':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showMaterialDialog(AdminProvider admin, {dynamic material}) {
    final nameCtrl = TextEditingController(text: material?['name'] ?? '');
    final unitCtrl = TextEditingController(text: material?['unit'] ?? 'kg');
    final stockCtrl = TextEditingController(text: material == null ? '0' : _fmt(material['current_stock']));
    final minCtrl = TextEditingController(text: material == null ? '0' : _fmt(material['min_stock']));
    final costCtrl = TextEditingController(text: material == null ? '0' : _fmt(material['cost_per_unit']));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(material == null ? 'Add Material' : 'Edit Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (kg/litre/pcs)')),
              if (material == null)
                TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Stock')),
              TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low Stock Threshold')),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost per Unit')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await admin.saveMaterial({
                if (material != null) 'id': material['id'],
                'name': nameCtrl.text.trim(),
                'unit': unitCtrl.text.trim(),
                'current_stock': double.tryParse(stockCtrl.text) ?? 0,
                'min_stock': double.tryParse(minCtrl.text) ?? 0,
                'cost_per_unit': double.tryParse(costCtrl.text) ?? 0,
              });
              if (!mounted) return;
              _snack(ok ? 'Material saved' : 'Save failed', ok);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(AdminProvider admin, dynamic material) {
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'adjustment';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Adjust ${material['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'adjustment', label: Text('Adjustment')),
                  ButtonSegment(value: 'wastage', label: Text('Wastage')),
                ],
                selected: {type},
                onSelectionChanged: (v) => setDialogState(() => type = v.first),
              ),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Change Qty (+/-)')),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Reason')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await admin.adjustMaterial(
                  material['id'],
                  double.tryParse(qtyCtrl.text) ?? 0,
                  type,
                  notesCtrl.text,
                );
                if (!mounted) return;
                _snack(ok ? 'Stock updated' : 'Update failed', ok);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVendorDialog(AdminProvider admin) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Vendor Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await admin.createVendor({
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              });
              if (!mounted) return;
              _snack(ok ? 'Vendor added' : 'Vendor failed', ok);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(AdminProvider admin) {
    int? materialId = admin.materials.first['id'];
    int? vendorId = admin.vendors.isEmpty ? null : admin.vendors.first['id'];
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final invoiceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Purchase Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: materialId,
                  decoration: const InputDecoration(labelText: 'Material'),
                  items: admin.materials.map((m) => DropdownMenuItem<int>(value: m['id'], child: Text(m['name']))).toList(),
                  onChanged: (v) => setDialogState(() => materialId = v),
                ),
                DropdownButtonFormField<int>(
                  initialValue: vendorId,
                  decoration: const InputDecoration(labelText: 'Vendor (optional)'),
                  items: admin.vendors.map((v) => DropdownMenuItem<int>(value: v['id'], child: Text(v['name']))).toList(),
                  onChanged: (v) => setDialogState(() => vendorId = v),
                ),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
                TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Cost')),
                TextField(controller: invoiceCtrl, decoration: const InputDecoration(labelText: 'Invoice Number')),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await admin.createPurchase({
                  'material_id': materialId,
                  'vendor_id': vendorId,
                  'quantity': double.tryParse(qtyCtrl.text) ?? 0,
                  'unit_cost': double.tryParse(costCtrl.text) ?? 0,
                  'invoice_number': invoiceCtrl.text,
                  'notes': notesCtrl.text,
                });
                if (!mounted) return;
                _snack(ok ? 'Purchase added' : 'Purchase failed', ok);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecipeDialog(AdminProvider admin, dynamic menuItem) async {
    final existing = await admin.loadRecipe(menuItem['id']);
    if (!mounted) return;
    final rows = existing
        .map<Map<String, dynamic>>((r) => {
              'material_id': r['material_id'],
              'quantity_per_item': _asDouble(r['quantity_per_item']),
              'unit': r['unit'] ?? r['material_unit'],
            })
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Recipe: ${menuItem['name']}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...rows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButton<int>(
                            value: row['material_id'],
                            isExpanded: true,
                            items: admin.materials
                                .map((m) => DropdownMenuItem<int>(
                                      value: m['id'],
                                      child: Text(m['name']),
                                    ))
                                .toList(),
                            onChanged: (v) => setDialogState(() => row['material_id'] = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: '${row['quantity_per_item']}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                            onChanged: (v) => row['quantity_per_item'] = double.tryParse(v) ?? 0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setDialogState(() => rows.removeAt(i)),
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: admin.materials.isEmpty
                        ? null
                        : () => setDialogState(() => rows.add({
                              'material_id': admin.materials.first['id'],
                              'quantity_per_item': 0.1,
                              'unit': admin.materials.first['unit'],
                            })),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Ingredient'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await admin.saveRecipe(menuItem['id'], rows);
                if (!mounted) return;
                _snack(ok ? 'Recipe saved' : 'Recipe failed', ok);
              },
              child: const Text('Save Recipe'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  String _fmt(dynamic value) => _asDouble(value).toStringAsFixed(2);

  double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}
