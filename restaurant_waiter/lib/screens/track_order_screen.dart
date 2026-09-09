import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/waiter_provider.dart';
import '../widgets/waiter_shell.dart';

enum _TrackTab { all, myTables, inKitchen, readyToServe, completed }

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  _TrackTab _tab = _TrackTab.all;
  WaiterOrder? _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final waiter = context.read<WaiterProvider>();
      waiter.loadTables();
      waiter.loadActiveOrders();
      waiter.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    context.read<WaiterProvider>().stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1100;

    final all = waiter.activeOrders
        .where((order) =>
            _query.isEmpty ||
            order.tableNumber.toLowerCase().contains(_query) ||
            '#${order.orderId}'.contains(_query))
        .toList();
    final myTables = all.where((o) => o.tableId != 0).map((o) => o.tableId).toSet();
    final inKitchen = all.where((o) => o.status == 'accepted' || o.status == 'preparing').toList();
    final readyToServe = all.where((o) => o.status == 'ready').toList();
    final completed = all.where((o) => o.isServed).toList();
    final newOrders = all.where((o) => o.status == 'placed').toList();

    final visible = switch (_tab) {
      _TrackTab.myTables => all,
      _TrackTab.inKitchen => inKitchen,
      _TrackTab.readyToServe => readyToServe,
      _TrackTab.completed => completed,
      _TrackTab.all => all,
    };

    if (_selected != null && !all.any((o) => o.orderId == _selected!.orderId)) {
      _selected = null;
    }
    final selected = _selected ?? (visible.isNotEmpty ? visible.first : null);

    return WaiterShell(
      route: WaiterRoute.track,
      title: 'Hello, Rahul! 👋',
      subtitle: 'Track your orders in real-time',
      searchHint: 'Search by table, order or customer...',
      onSearchChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      onRefresh: () {
        waiter.loadTables();
        waiter.loadActiveOrders();
      },
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaiterPageHeader(
              icon: Icons.search_rounded,
              iconColor: kRed,
              title: 'Track Orders',
              subtitle: 'Check live status of all orders from kitchen to table',
              pills: [
                WaiterStatPill(icon: Icons.fiber_new_rounded, value: '${newOrders.length}', label: 'New Orders', color: kRed),
                WaiterStatPill(icon: Icons.soup_kitchen_rounded, value: '${inKitchen.length}', label: 'In Kitchen', color: Colors.orange),
                WaiterStatPill(icon: Icons.room_service_rounded, value: '${readyToServe.length}', label: 'Ready to Serve', color: Colors.deepPurple),
                WaiterStatPill(icon: Icons.done_all_rounded, value: '${completed.length}', label: 'Served Today', color: Colors.green),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _tabsRow(all.length, myTables.length, inKitchen.length, readyToServe.length, completed.length)),
                const SizedBox(width: 8),
                _todayChip(),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: compact
                  ? _table(visible, fullWidth: true)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _table(visible, fullWidth: false)),
                        const SizedBox(width: 12),
                        SizedBox(width: 320, child: _detailPanel(selected)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Today', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
        SizedBox(width: 4),
        Icon(Icons.expand_more, size: 16),
      ],
    ),
  );

  Widget _tabsRow(int all, int myTables, int inKitchen, int readyToServe, int completed) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChip('All Orders ($all)', _TrackTab.all),
          const SizedBox(width: 8),
          _tabChip('My Tables ($myTables)', _TrackTab.myTables),
          const SizedBox(width: 8),
          _tabChip('In Kitchen ($inKitchen)', _TrackTab.inKitchen),
          const SizedBox(width: 8),
          _tabChip('Ready to Serve ($readyToServe)', _TrackTab.readyToServe),
          const SizedBox(width: 8),
          _tabChip('Completed ($completed)', _TrackTab.completed),
        ],
      ),
    );
  }

  Widget _tabChip(String label, _TrackTab tab) {
    final selected = _tab == tab;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, color: selected ? Colors.white : kInk)),
      selected: selected,
      selectedColor: kRed,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? kRed : Colors.grey.shade300),
      onSelected: (_) => setState(() => _tab = tab),
    );
  }

  Widget _table(List<WaiterOrder> orders, {required bool fullWidth}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text('Koi order nahi hai is tab mein', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 18,
          headingRowHeight: 40,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 62,
          columns: const [
            DataColumn(label: Text('Order ID')),
            DataColumn(label: Text('Table')),
            DataColumn(label: Text('Items')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: orders
              .map(
                (order) => DataRow(
                  onSelectChanged: (_) => _openDetail(order, fullWidth),
                  cells: [
                    DataCell(Text('#${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(_tableChip(order.tableNumber)),
                    DataCell(SizedBox(
                      width: 180,
                      child: Text(
                        order.items.isEmpty
                            ? '\u2014'
                            : '${order.items.length} items \u2022 ${order.items.take(2).map((i) => i.name).join(', ')}${order.items.length > 2 ? '...' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    )),
                    DataCell(Text('${order.minutesAgo}m ago', style: const TextStyle(fontSize: 11.5, color: Colors.grey))),
                    DataCell(_statusBadge(order.status)),
                    DataCell(
                      TextButton.icon(
                        onPressed: () => _openDetail(order, fullWidth),
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text('View', style: TextStyle(fontSize: 11.5)),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _openDetail(WaiterOrder order, bool fullWidth) {
    if (fullWidth) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: .75,
          minChildSize: .4,
          maxChildSize: .95,
          expand: false,
          builder: (context, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: _detailContent(order),
          ),
        ),
      );
      return;
    }
    setState(() => _selected = order);
  }

  Widget _tableChip(String tableNumber) {
    const palette = [kRed, Colors.orange, Colors.blue, Colors.purple, Colors.teal, Colors.pink];
    final color = palette[tableNumber.hashCode.abs() % palette.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
      child: Text(tableNumber, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5)),
    );
  }

  Widget _statusBadge(String status) {
    final map = {
      'placed': ('New', Colors.red, Icons.fiber_new_rounded),
      'accepted': ('In Kitchen', Colors.orange, Icons.soup_kitchen_rounded),
      'preparing': ('Preparing', Colors.orange, Icons.soup_kitchen_rounded),
      'ready': ('Ready to Serve', Colors.deepPurple, Icons.room_service_rounded),
      'served': ('Served', Colors.green, Icons.check_circle_rounded),
      'cancelled': ('Cancelled', Colors.grey, Icons.cancel_rounded),
    };
    final entry = map[status] ?? (status, Colors.grey, Icons.help_outline);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: entry.$2.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(entry.$3, size: 12, color: entry.$2),
          const SizedBox(width: 4),
          Text(entry.$1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: entry.$2)),
        ],
      ),
    );
  }

  Widget _detailPanel(WaiterOrder? order) {
    if (order == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, color: Colors.blueGrey, size: 32),
            SizedBox(height: 8),
            Text('Select an order', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(child: _detailContent(order)),
    );
  }

  Widget _detailContent(WaiterOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: kRed,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.orderId}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('Table ${order.tableNumber} \u2022 ${order.minutesAgo}m ago', style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                  ],
                ),
              ),
              _statusBadge(order.status),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Items (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontSize: 12.5))),
                      Text('x${item.quantity}', style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 11)),
                      const SizedBox(width: 8),
                      Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Order Progress', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              _progress(order),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kRed.withValues(alpha: .06), borderRadius: BorderRadius.circular(8)),
                child: Text(_statusMessage(order.status), style: const TextStyle(fontSize: 11.5)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<WaiterProvider>().loadActiveOrders(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh Status'),
                ),
              ),
              if (order.status == 'ready') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markServed(order),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark as Served'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _progress(WaiterOrder order) {
    const stages = ['Order Received', 'In Kitchen', 'Ready to Serve', 'Served to Table'];
    final stageIndex = switch (order.status) {
      'placed' => 0,
      'accepted' || 'preparing' => 1,
      'ready' => 2,
      'served' => 3,
      _ => 0,
    };
    return Row(
      children: List.generate(stages.length, (index) {
        final done = index <= stageIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(child: Container(height: 2, color: index <= stageIndex ? kRed : Colors.grey.shade300)),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? kRed : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  if (index < stages.length - 1)
                    Expanded(child: Container(height: 2, color: index < stageIndex ? kRed : Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stages[index],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8.5, color: done ? kInk : Colors.grey, fontWeight: done ? FontWeight.w700 : FontWeight.w400),
              ),
              if (index == 0)
                Text(_clock(order.placedAt), style: TextStyle(fontSize: 8, color: Colors.blueGrey.shade400)),
            ],
          ),
        );
      }),
    );
  }

  String _clock(DateTime date) =>
      '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';

  String _statusMessage(String status) {
    const messages = {
      'placed': 'Your order has been received and is waiting to be accepted by the kitchen.',
      'accepted': 'The kitchen has accepted this order and will start preparing soon.',
      'preparing': 'Your order is being prepared in the kitchen. We\'ll notify you when it\'s ready.',
      'ready': 'Order is ready! Please serve it to the table as soon as possible.',
      'served': 'This order has already been served to the table.',
      'cancelled': 'This order was cancelled.',
    };
    return messages[status] ?? 'Tracking order status...';
  }

  Future<void> _markServed(WaiterOrder order) async {
    if (!await confirmServeIfNeeded(context, 'Order #${order.orderId}')) return;
    if (!mounted) return;
    final ok = await context.read<WaiterProvider>().updateOrderStatus(order.orderId, 'served');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✅ ${order.tableNumber} order served!' : 'Unable to update order.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }
}
