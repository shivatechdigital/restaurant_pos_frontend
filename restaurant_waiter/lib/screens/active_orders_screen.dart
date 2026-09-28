import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/waiter_provider.dart';
import '../widgets/waiter_shell.dart';
import 'bill_screen.dart';

enum _OrdersTab { active, served, pendingBill, all }

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  _OrdersTab _tab = _OrdersTab.active;
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

  /// A session is still "pending bill" only while its table still points to
  /// this exact session as the active one (i.e. it hasn't been paid/closed yet).
  bool _isPendingBill(WaiterOrder order, List<TableModel> tables) {
    if (!order.isServed || order.sessionId == null) return false;
    return tables.any((t) => t.activeSessionId == order.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1100;

    final all = waiter.activeOrders
        .where(
          (order) =>
              _query.isEmpty ||
              order.tableNumber.toLowerCase().contains(_query) ||
              '#${order.orderId}'.contains(_query),
        )
        .toList();
    final active = all.where((o) => o.isActive).toList();
    final served = all.where((o) => o.isServed).toList();
    final pendingBill = all
        .where((o) => _isPendingBill(o, waiter.tables))
        .toList();
    final pendingTables = waiter.tables
        .where(
          (table) =>
              table.activeSessionId != null && table.runningAmount > 0.01,
        )
        .toList();

    final visible = switch (_tab) {
      _OrdersTab.active => active,
      _OrdersTab.served => served,
      _OrdersTab.pendingBill => pendingBill,
      _OrdersTab.all => all,
    };

    if (_selected != null && !all.any((o) => o.orderId == _selected!.orderId)) {
      _selected = null;
    }

    return WaiterShell(
      route: WaiterRoute.orders,
      title: 'Hello, Rahul! 👋',
      subtitle: 'Great service creates great memories!',
      searchHint: 'Search by table or order id...',
      onSearchChanged: (value) =>
          setState(() => _query = value.trim().toLowerCase()),
      onRefresh: () {
        waiter.loadTables();
        waiter.loadActiveOrders();
      },
      body: waiter.isOrdersLoading && waiter.activeOrders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : waiter.error.isNotEmpty && waiter.activeOrders.isEmpty
          ? _errorState(waiter)
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WaiterPageHeader(
                    icon: Icons.receipt_long_rounded,
                    iconColor: kRed,
                    title: 'My Orders',
                    subtitle: 'Manage your table orders, track status and serve with smile!',
                    pills: [
                      WaiterStatPill(
                        icon: Icons.groups_2_rounded,
                        value: '${active.length}',
                        label: 'My Active Orders',
                        color: Colors.green,
                      ),
                      WaiterStatPill(
                        icon: Icons.check_circle_rounded,
                        value: '${served.length}',
                        label: 'Completed Today',
                        color: Colors.blue,
                      ),
                      WaiterStatPill(
                        icon: Icons.hourglass_bottom_rounded,
                        value: _avgWaitMinutes(active),
                        label: 'Avg Wait Time',
                        color: Colors.orange,
                      ),
                      WaiterStatPill(
                        icon: Icons.receipt_rounded,
                        value: '${pendingTables.length}',
                        label: 'Pending Bill',
                        color: kRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _tabsRow(
                    active.length,
                    served.length,
                    pendingTables.length,
                    all.length,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: compact
                        ? _list(visible, waiter.tables, fullWidth: true)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _list(
                                  visible,
                                  waiter.tables,
                                  fullWidth: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 300,
                                child: _detailPanel(_selected, waiter),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _avgWaitMinutes(List<WaiterOrder> active) {
    if (active.isEmpty) return '0m';
    final total = active.fold<int>(0, (sum, o) => sum + o.minutesAgo);
    return '${(total / active.length).round()}m';
  }

  Widget _errorState(WaiterProvider waiter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 56, color: Colors.red[300]),
            const SizedBox(height: 10),
            Text(waiter.error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => waiter.loadActiveOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabsRow(int active, int served, int pendingBill, int all) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChip('Active Orders ($active)', _OrdersTab.active),
          const SizedBox(width: 8),
          _tabChip('Served ($served)', _OrdersTab.served),
          const SizedBox(width: 8),
          _tabChip('Pending Bill ($pendingBill)', _OrdersTab.pendingBill),
          const SizedBox(width: 8),
          _tabChip('All Orders ($all)', _OrdersTab.all),
        ],
      ),
    );
  }

  Widget _tabChip(String label, _OrdersTab tab) {
    final selected = _tab == tab;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 11.5, color: selected ? Colors.white : kInk),
      ),
      selected: selected,
      selectedColor: kRed,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? kRed : Colors.grey.shade300),
      onSelected: (_) => setState(() => _tab = tab),
    );
  }

  Widget _list(
    List<WaiterOrder> orders,
    List<TableModel> tables, {
    required bool fullWidth,
  }) {
    if (_tab == _OrdersTab.pendingBill) return _pendingBills(tables);
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text(
              'Koi order nahi hai is tab mein',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<WaiterProvider>().loadActiveOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _orderRow(orders[index], tables, fullWidth),
      ),
    );
  }

  Widget _pendingBills(List<TableModel> tables) {
    final pendingTables = tables
        .where(
          (table) =>
              table.activeSessionId != null && table.runningAmount > 0.01,
        )
        .toList();
    if (pendingTables.isEmpty) {
      return const Center(child: Text('No tables have an outstanding bill'));
    }
    return RefreshIndicator(
      onRefresh: () async {
        final waiter = context.read<WaiterProvider>();
        await waiter.loadTables();
        await waiter.loadActiveOrders();
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: pendingTables.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final table = pendingTables[index];
          return Card(
            child: ListTile(
              leading: _tableBadge(table.tableNumber),
              title: Text(
                'Table ${table.tableNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Combined bill for all customers at this table',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${table.runningAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kRed,
                    ),
                  ),
                  const Text('View bill', style: TextStyle(fontSize: 11)),
                ],
              ),
              onTap: () => _openTableBill(table),
            ),
          );
        },
      ),
    );
  }

  void _openTableBill(TableModel table) {
    final sessionId = table.activeSessionId;
    if (sessionId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillScreen(
          tableNumber: table.tableNumber,
          tableId: table.id,
          sessionId: sessionId,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      final waiter = context.read<WaiterProvider>();
      waiter.loadTables();
      waiter.loadActiveOrders();
    });
  }

  Widget _orderRow(WaiterOrder order, List<TableModel> tables, bool fullWidth) {
    final pendingBill = _isPendingBill(order, tables);
    final selected = _selected?.orderId == order.orderId;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? kRed.withValues(alpha: .04) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? kRed.withValues(alpha: .4) : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDetail(order, fullWidth),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tableBadge(order.tableNumber),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '#${order.orderId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        _statusBadge(order.status, pendingBill: pendingBill),
                        Text(
                          '${order.minutesAgo}m ago',
                          style: TextStyle(
                            fontSize: 11,
                            color: order.minutesAgo > 15 ? kRed : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.items.isEmpty
                          ? 'No items'
                          : order.items
                                .take(3)
                                .map((i) => '${i.name} x${i.quantity}')
                                .join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: kInk,
                          ),
                        ),
                        const Spacer(),
                        if (order.status == 'ready')
                          _smallButton(
                            'Mark as Served',
                            Colors.green,
                            () => _markServed(order),
                          ),
                        TextButton(
                          onPressed: () => _openDetail(order, fullWidth),
                          child: const Text(
                            'View',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(WaiterOrder order, bool fullWidth) {
    if (fullWidth) {
      // narrow layout has no side panel, so show details in a bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: .7,
          minChildSize: .4,
          maxChildSize: .95,
          expand: false,
          builder: (context, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: _detailContent(order, context.read<WaiterProvider>()),
          ),
        ),
      );
      return;
    }
    setState(() => _selected = order);
  }

  Widget _tableBadge(String tableNumber) {
    const palette = [
      kRed,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final color = palette[tableNumber.hashCode.abs() % palette.length];
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tableNumber,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _smallButton(String label, Color color, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 11),
      ),
      child: Text(label),
    ),
  );

  Widget _statusBadge(String status, {bool pendingBill = false}) {
    if (pendingBill) {
      return _badge('Pending Bill', Colors.deepOrange);
    }
    final map = {
      'placed': ('Placed', Colors.blue),
      'accepted': ('Accepted', Colors.indigo),
      'preparing': ('Preparing', Colors.orange),
      'ready': ('Ready to Serve', Colors.teal),
      'served': ('Served', Colors.green),
      'cancelled': ('Cancelled', Colors.grey),
    };
    final entry = map[status] ?? (status, Colors.grey);
    return _badge(entry.$1, entry.$2);
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _detailPanel(WaiterOrder? order, WaiterProvider waiter) {
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
            Text(
              'Select an order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3),
            Text(
              'Tap View on any order to see its details here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
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
        padding: const EdgeInsets.all(14),
        child: _detailContent(order, waiter),
      ),
    );
  }

  Widget _detailContent(WaiterOrder order, WaiterProvider waiter) {
    final pendingBill = _isPendingBill(order, waiter.tables);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Table ${order.tableNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _statusBadge(order.status, pendingBill: pendingBill),
          ],
        ),
        Text(
          '#${order.orderId} \u2022 ${order.minutesAgo}m ago',
          style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 11),
        ),
        const Divider(height: 20),
        Text(
          'Order Items (${order.items.length})',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'x${item.quantity}',
                  style: TextStyle(
                    color: Colors.blueGrey.shade500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '₹${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '₹${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: kRed),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (order.status == 'ready' || order.isActive)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: order.isServed ? null : () => _markServed(order),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Mark as Served'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _markServed(WaiterOrder order) async {
    if (!await confirmServeIfNeeded(context, 'Order #${order.orderId}')) return;
    if (!mounted) return;
    final ok = await context.read<WaiterProvider>().updateOrderStatus(
      order.orderId,
      'served',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '✅ ${order.tableNumber} order served!'
              : 'Unable to update order.',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }
}
