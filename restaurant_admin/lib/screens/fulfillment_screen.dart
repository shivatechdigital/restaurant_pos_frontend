import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class FulfillmentScreen extends StatefulWidget {
  const FulfillmentScreen({super.key});

  @override
  State<FulfillmentScreen> createState() => _FulfillmentScreenState();
}

class _FulfillmentScreenState extends State<FulfillmentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = context.read<AdminProvider>();
      admin.loadDeliveryPartners();
      admin.loadReservations();
      admin.loadTables();
      admin.loadOrders();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Fulfillment'),
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Deliveries'), Tab(text: 'Partners'), Tab(text: 'Reservations')]),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { admin.loadOrders(); admin.loadDeliveryPartners(); admin.loadReservations(); })],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: _tabs.index == 1 ? 'Add delivery partner' : 'Add reservation',
        onPressed: () => _tabs.index == 1 ? _addPartner(admin) : _addReservation(admin),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(controller: _tabs, children: [_deliveries(admin), _partners(admin), _reservations(admin)]),
    );
  }

  Widget _partners(AdminProvider admin) => admin.deliveryPartners.isEmpty
      ? const Center(child: Text('No delivery partners added'))
      : ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: admin.deliveryPartners.length,
          itemBuilder: (_, index) { final partner = admin.deliveryPartners[index]; return Card(child: ListTile(leading: const Icon(Icons.delivery_dining, color: Colors.orange), title: Text(partner['name'] ?? ''), subtitle: Text(partner['phone'] ?? ''), trailing: Icon(partner['is_active'] == true ? Icons.verified : Icons.block, color: partner['is_active'] == true ? Colors.green : Colors.grey))); },
        );

  Widget _reservations(AdminProvider admin) => admin.reservations.isEmpty
      ? const Center(child: Text('No reservations'))
      : ListView.builder(
          padding: const EdgeInsets.all(12), itemCount: admin.reservations.length,
          itemBuilder: (_, index) {
            final reservation = admin.reservations[index];
            final date = DateTime.tryParse(reservation['reservation_at']?.toString() ?? '');
            final booked = reservation['status'] == 'booked';
            return Card(child: ListTile(
              leading: const Icon(Icons.event_seat, color: Colors.indigo),
              title: Text('${reservation['customer_name']} • ${reservation['guest_count']} guests'),
              subtitle: Text('${reservation['table_number'] ?? 'Table not assigned'}\n${date == null ? '' : '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'} • ${reservation['phone']}'),
              isThreeLine: true,
              trailing: booked ? TextButton(onPressed: () => _checkIn(admin, reservation), child: const Text('Check in')) : Chip(label: Text((reservation['status'] ?? '').toString().toUpperCase())),
            ));
          },
        );

  Widget _deliveries(AdminProvider admin) {
    final deliveries = admin.orders.where((order) => order['order_type'] == 'delivery' && order['delivery_status'] != 'delivered').toList();
    if (deliveries.isEmpty) return const Center(child: Text('No active delivery orders'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: deliveries.length, itemBuilder: (_, index) {
      final order = deliveries[index];
      return Card(child: ListTile(
        leading: const Icon(Icons.delivery_dining, color: Colors.deepOrange),
        title: Text('Order #${order['id']} • ₹${order['final_amount']}'),
        subtitle: Text('${order['delivery_status'] ?? 'new'}\n${order['delivery_address'] ?? 'Address not recorded'}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => value == 'assign' ? _assignPartner(admin, order) : admin.updateDeliveryStatus(order['id'], value),
          itemBuilder: (_) => const [PopupMenuItem(value: 'assign', child: Text('Assign partner')), PopupMenuItem(value: 'out_for_delivery', child: Text('Out for delivery')), PopupMenuItem(value: 'delivered', child: Text('Delivered')), PopupMenuItem(value: 'failed', child: Text('Failed'))],
        ),
      ));
    });
  }

  Future<void> _addPartner(AdminProvider admin) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Add Delivery Partner'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone'))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))]));
    if (ok != true) return;
    final saved = await admin.createDeliveryPartner({'name': name.text.trim(), 'phone': phone.text.trim()});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'Partner added' : 'Unable to add partner'), backgroundColor: saved ? Colors.green : Colors.red));
  }

  Future<void> _addReservation(AdminProvider admin) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final guests = TextEditingController(text: '2');
    int? tableId;
    DateTime time = DateTime.now().add(const Duration(hours: 1));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(title: const Text('New Reservation'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Customer name')), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')), TextField(controller: guests, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Guests')), DropdownButtonFormField<int>(decoration: const InputDecoration(labelText: 'Table'), items: admin.tables.map((table) => DropdownMenuItem(value: table['id'] as int, child: Text('${table['table_number']} (${table['capacity']} seats)'))).toList(), onChanged: (value) => setState(() => tableId = value)), TextButton.icon(icon: const Icon(Icons.schedule), label: Text('${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}'), onPressed: () async { final selected = await showDatePicker(context: ctx, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: time); if (selected != null) setState(() => time = DateTime(selected.year, selected.month, selected.day, time.hour, time.minute)); })])), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create'))])));
    if (ok != true) return;
    final saved = await admin.createReservation({'table_id': tableId, 'customer_name': name.text.trim(), 'phone': phone.text.trim(), 'guest_count': int.tryParse(guests.text) ?? 0, 'reservation_at': time.toUtc().toIso8601String()});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'Reservation created' : 'Unable to create reservation'), backgroundColor: saved ? Colors.green : Colors.red));
  }

  Future<void> _checkIn(AdminProvider admin, dynamic reservation) async {
    final ok = await admin.checkInReservation(reservation['id']);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Reservation checked in' : 'Unable to check in'), backgroundColor: ok ? Colors.green : Colors.red));
  }

  Future<void> _assignPartner(AdminProvider admin, dynamic order) async {
    if (admin.deliveryPartners.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a delivery partner first'))); return; }
    int selected = admin.deliveryPartners.first['id'];
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(title: Text('Assign Order #${order['id']}'), content: DropdownButtonFormField<int>(initialValue: selected, items: admin.deliveryPartners.where((partner) => partner['is_active'] == true).map((partner) => DropdownMenuItem(value: partner['id'] as int, child: Text(partner['name']))).toList(), onChanged: (value) => setState(() => selected = value!)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign'))])));
    if (ok != true) return;
    final assigned = await admin.assignDelivery(order['id'], selected);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(assigned ? 'Partner assigned' : 'Unable to assign partner'), backgroundColor: assigned ? Colors.green : Colors.red));
  }
}
