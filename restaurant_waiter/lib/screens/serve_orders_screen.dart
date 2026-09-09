import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/waiter_provider.dart';
import '../widgets/waiter_shell.dart';

/// Orders for a single table, grouped so the waiter can serve everything at once.
class _TableOrders {
  final TableModel table;
  final List<WaiterOrder> orders;
  _TableOrders(this.table, this.orders);

  List<WaiterOrderItem> get items => orders.expand((o) => o.items).toList();
  double get total => orders.fold<double>(0, (sum, o) => sum + o.totalAmount);
  int get minutesAgo => orders.map((o) => o.minutesAgo).reduce((a, b) => a > b ? a : b);
  String get orderIds => orders.map((o) => '#${o.orderId}').join(', ');
}

class ServeOrdersScreen extends StatefulWidget {
  const ServeOrdersScreen({super.key});

  @override
  State<ServeOrdersScreen> createState() => _ServeOrdersScreenState();
}

class _ServeOrdersScreenState extends State<ServeOrdersScreen> {
  int _tab = 0; // 0 = pending, 1 = all, 2 = served today
  int? _selectedTableId;
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

  List<_TableOrders> _groupByTable(List<WaiterOrder> orders, List<TableModel> tables) {
    final byTable = <int, List<WaiterOrder>>{};
    for (final order in orders) {
      byTable.putIfAbsent(order.tableId, () => []).add(order);
    }
    return byTable.entries
        .map((entry) {
          final table = tables.firstWhere(
            (t) => t.id == entry.key,
            orElse: () => TableModel(
              id: entry.key,
              tableNumber: entry.value.first.tableNumber,
              capacity: 0,
              status: 'occupied',
            ),
          );
          return _TableOrders(table, entry.value);
        })
        .where((group) =>
            _query.isEmpty || group.table.tableNumber.toLowerCase().contains(_query))
        .toList()
      ..sort((a, b) => a.minutesAgo.compareTo(b.minutesAgo) * -1);
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1100;

    final pendingOrders = waiter.activeOrders.where((o) => o.isActive).toList();
    final servedOrders = waiter.activeOrders.where((o) => o.isServed).toList();

    final pendingGroups = _groupByTable(pendingOrders, waiter.tables);
    final allGroups = _groupByTable(waiter.activeOrders, waiter.tables);
    final servedGroups = _groupByTable(servedOrders, waiter.tables);

    final visibleGroups = switch (_tab) {
      1 => allGroups,
      2 => servedGroups,
      _ => pendingGroups,
    };

    final selected = visibleGroups.where((g) => g.table.id == _selectedTableId).firstOrNull;

    return WaiterShell(
      route: WaiterRoute.serve,
      title: 'Serve Orders',
      subtitle: 'Deliver happiness, one table at a time! \u2764\ufe0f',
      searchHint: 'Search by table, order id or item...',
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
              icon: Icons.room_service_rounded,
              iconColor: kRed,
              title: 'Serve Orders',
              subtitle: 'Mark items as served when delivered to the table',
              pills: [
                WaiterStatPill(
                  icon: Icons.room_service_rounded,
                  value: '${pendingGroups.length}',
                  label: 'Pending to Serve',
                  color: kRed,
                ),
                WaiterStatPill(
                  icon: Icons.check_circle_rounded,
                  value: '${servedOrders.length}',
                  label: 'Served Today',
                  color: Colors.green,
                ),
                WaiterStatPill(
                  icon: Icons.table_bar_rounded,
                  value: '${allGroups.length}',
                  label: 'My Tables',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _tabsRow(pendingGroups.length, servedOrders.length),
            const SizedBox(height: 12),
            Expanded(
              child: compact
                  ? _grid(visibleGroups, crossAxisCount: width < 700 ? 1 : 2)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _grid(visibleGroups, crossAxisCount: 3)),
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

  Widget _tabsRow(int pending, int served) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChip('\ud83d\udecE Pending to Serve ($pending)', 0),
          const SizedBox(width: 8),
          _tabChip('All Orders', 1),
          const SizedBox(width: 8),
          _tabChip("Today's Served ($served)", 2),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int tab) {
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

  Widget _grid(List<_TableOrders> groups, {required int crossAxisCount}) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text('Koi table nahi hai is tab mein', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisExtent: 240,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) => _tableCard(groups[index]),
    );
  }

  Widget _tableCard(_TableOrders group) {
    const palette = [kRed, Colors.orange, Colors.blue, Colors.purple, Colors.teal, Colors.pink];
    final color = palette[group.table.tableNumber.hashCode.abs() % palette.length];
    final selected = _selectedTableId == group.table.id;
    final allServed = group.orders.every((o) => o.isServed);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedTableId = group.table.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : color.withValues(alpha: .25), width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Table ${group.table.tableNumber}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14),
                  ),
                ),
                Text(group.orderIds, style: TextStyle(fontSize: 10, color: color)),
              ],
            ),
            Text(
              '${group.minutesAgo}m ago \u2022 ${group.items.length} items',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: group.items
                    .take(4)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                            Text('x${item.quantity}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: allServed ? null : () => _markAllServed(group),
                icon: const Icon(Icons.check, size: 16),
                label: Text(allServed ? 'All Served' : 'Mark All as Served', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allServed ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailPanel(_TableOrders? group) {
    if (group == null) {
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
            Text('Select a table', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 3),
            Text(
              'Tap a table card to review its order before serving.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
      );
    }
    final allServed = group.orders.every((o) => o.isServed);
    final notes = group.orders.map((o) => o.notes).whereType<String>().where((n) => n.trim().isNotEmpty).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Text(
                        'Table ${group.table.tableNumber}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${group.minutesAgo}m ago \u2022 ${group.orderIds}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Items (${group.items.length})', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  ...group.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                Text('x${item.quantity}', style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500)),
                              ],
                            ),
                          ),
                          Icon(
                            item.status == 'served' ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: item.status == 'served' ? Colors.green : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kRed.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Special Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kRed)),
                          Text(notes.join(' \u2022 '), style: const TextStyle(fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: allServed ? null : () => _markAllServed(group),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark All as Served'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: allServed ? null : () => _markAllServed(group),
                    icon: const Icon(Icons.room_service_rounded, size: 16),
                    label: Text(allServed ? 'Already Served' : 'Update Serve Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allServed ? Colors.grey : kRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllServed(_TableOrders group) async {
    if (!await confirmServeIfNeeded(context, 'Table ${group.table.tableNumber}')) return;
    if (!mounted) return;
    final waiter = context.read<WaiterProvider>();
    var allOk = true;
    for (final order in group.orders.where((o) => o.isActive)) {
      final ok = await waiter.updateOrderStatus(order.orderId, 'served');
      allOk = allOk && ok;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(allOk ? '✅ Table ${group.table.tableNumber} served!' : 'Unable to update some orders.'),
        backgroundColor: allOk ? Colors.green : Colors.red,
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
