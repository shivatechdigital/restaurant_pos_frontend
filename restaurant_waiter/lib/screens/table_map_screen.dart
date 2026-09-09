import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_waiter/screens/active_orders_screen.dart';

import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/waiter_provider.dart';
import '../services/api_service.dart';
import '../widgets/waiter_shell.dart';
import 'bill_screen.dart';
import 'table_order_screen.dart';

const _ink = kInk;
const _red = kRed;

class TableMapScreen extends StatefulWidget {
  const TableMapScreen({super.key});

  @override
  State<TableMapScreen> createState() => _TableMapScreenState();
}

class _TableMapScreenState extends State<TableMapScreen> {
  TableModel? _selectedTable;
  String _floor = 'Main Hall';
  String _query = '';
  String _orderTab = 'current';

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
    final compact = width < 1000;
    final tables = waiter.tables
        .where(
          (table) =>
              _query.isEmpty ||
              table.tableNumber.toLowerCase().contains(_query),
        )
        .toList();

    return WaiterShell(
      route: WaiterRoute.floor,
      title: 'Hello, ${waiter.activeOrders.isNotEmpty ? 'Rahul' : 'Waiter'}! 👋',
      subtitle: 'Serve with a smile, make their day special!',
      searchHint: 'Search tables or orders...',
      onSearchChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      onRefresh: () {
        waiter.loadTables();
        waiter.loadActiveOrders();
      },
      body: _body(waiter, tables, compact),
    );
  }

  Widget _body(WaiterProvider waiter, List<TableModel> tables, bool compact) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stats(waiter),
          const SizedBox(height: 12),
          _floorTabs(),
          const SizedBox(height: 10),
          if (compact)
            _floorPlan(waiter, tables)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _floorPlan(waiter, tables)),
                const SizedBox(width: 12),
                SizedBox(width: 292, child: _selectedPanel(waiter)),
              ],
            ),
          const SizedBox(height: 12),
          if (!compact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _quickActions(waiter)),
                const SizedBox(width: 12),
                Expanded(child: _activeOrders(waiter)),
              ],
            )
          else
            Column(
              children: [
                _selectedPanel(waiter),
                const SizedBox(height: 12),
                _quickActions(waiter),
                const SizedBox(height: 12),
                _activeOrders(waiter),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stats(WaiterProvider waiter) {
    final cards = [
      (
        '${waiter.tables.length}',
        'Total Tables',
        Colors.blueGrey,
        Icons.table_restaurant,
      ),
      ('${waiter.availableCount}', 'Available', Colors.green, Icons.event_seat),
      ('${waiter.occupiedCount}', 'Occupied', Colors.red, Icons.people),
      (
        '${waiter.tables.where((table) => table.isReserved).length}',
        'Reserved',
        Colors.deepPurple,
        Icons.calendar_month,
      ),
      (
        '${waiter.cleaningCount}',
        'Cleaning',
        Colors.orange,
        Icons.cleaning_services,
      ),
    ];
    return LayoutBuilder(
      builder: (_, constraints) {
        final columns = constraints.maxWidth < 520
            ? 2
            : constraints.maxWidth < 900
            ? 3
            : 5;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: card.$3.withValues(alpha: .12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            color: card.$3.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(card.$4, color: card.$3, size: 17),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.$1,
                                style: TextStyle(
                                  color: card.$3,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                card.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: card.$3,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _floorTabs() {
    final tabs = ['Main Hall', 'Outdoor', 'Rooftop', 'Private Dining'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map(
              (tab) => Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  label: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 10,
                      color: _floor == tab ? Colors.white : _ink,
                    ),
                  ),
                  selected: _floor == tab,
                  selectedColor: _red,
                  backgroundColor: Colors.white,
                  onSelected: (_) => setState(() => _floor = tab),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _floorPlan(WaiterProvider waiter, List<TableModel> tables) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Main Hall Floor View',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _legend('Available', Colors.green),
                      _legend('Occupied', Colors.red),
                      _legend('Reserved', Colors.deepPurple),
                      _legend('Cleaning', Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 390,
            decoration: BoxDecoration(
              color: const Color(0xFFF4E7D2),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _FloorPainter())),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final columns = constraints.maxWidth < 420
                          ? 2
                          : constraints.maxWidth < 700
                          ? 3
                          : 4;
                      return GridView.builder(
                        physics: const ClampingScrollPhysics(),
                        itemCount: tables.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.18,
                        ),
                        itemBuilder: (_, index) => _floorTable(tables[index]),
                      );
                    },
                  ),
                ),
                const Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '▲ Entrance',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
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

  Widget _legend(String label, Color color) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 8),
        ),
      ],
    ),
  );

  Widget _floorTable(TableModel table) {
    final selected = _selectedTable?.id == table.id;
    final color = table.isAvailable
        ? Colors.green.shade500
        : table.isOccupied
        ? _red
        : table.isCleaning
        ? Colors.orange.shade500
        : Colors.deepPurple.shade500;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTable = table;
        _orderTab = 'current';
      }),
      onLongPress: table.isOccupied
          ? () => _showTableActions(
              context,
              table,
              context.read<WaiterProvider>(),
            )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? _ink : Colors.white,
            width: selected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .35), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.tableNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              table.isOccupied
                  ? 'Occupied'
                  : table.isCleaning
                  ? 'Cleaning'
                  : table.isReserved
                  ? 'Reserved'
                  : 'Available',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (table.isOccupied)
              Text(
                '${table.capacity} guests',
                style: const TextStyle(color: Colors.white70, fontSize: 7),
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectedPanel(WaiterProvider waiter) {
    final table = _selectedTable;
    if (table == null) {
      return _panel(
        const Icon(Icons.touch_app, color: Colors.blueGrey, size: 35),
        'Select a table',
        'Tap a table on the floor plan to see its order.',
      );
    }
    final tableOrders = table.activeSessionId == null
        ? <WaiterOrder>[]
        : waiter.activeOrders
              .where((item) => item.sessionId == table.activeSessionId)
              .toList();
    final currentOrders =
        tableOrders.where((item) => item.isActive).toList();
    final previousOrders =
        tableOrders.where((item) => item.isServed).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: table.isOccupied ? _red : Colors.green.shade600,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Table ${table.tableNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  table.isOccupied ? 'Occupied' : 'Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: tableOrders.isEmpty
                ? Column(
                    children: [
                      Icon(
                        Icons.event_seat,
                        color: Colors.green.shade500,
                        size: 35,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'No active order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _primaryButton(
                        'Take Order',
                        Icons.restaurant,
                        () => _openOrder(table),
                      ),
                    ],
                  )
                : _orderPanelBody(currentOrders, previousOrders, table),
          ),
        ],
      ),
    );
  }

  Widget _orderPanelBody(
    List<WaiterOrder> currentOrders,
    List<WaiterOrder> previousOrders,
    TableModel table,
  ) {
    final allOrders = [...currentOrders, ...previousOrders];
    final grandTotal =
        allOrders.fold<double>(0, (sum, item) => sum + item.totalAmount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _orderTabButton(
                'Current Order',
                _orderTab == 'current',
                () => setState(() => _orderTab = 'current'),
              ),
            ),
            Expanded(
              child: _orderTabButton(
                'Previous Orders (${previousOrders.length})',
                _orderTab == 'previous',
                () => setState(() => _orderTab = 'previous'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _orderTab == 'current'
            ? _currentOrderList(currentOrders)
            : _previousOrderList(previousOrders),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '₹${grandTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: _red),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (currentOrders.isNotEmpty) ...[
          _primaryButton(
            'Serve Order',
            Icons.room_service,
            () => _serveOrders(currentOrders),
          ),
          const SizedBox(height: 7),
        ],
        OutlinedButton.icon(
          onPressed: () => _requestBillForTable(allOrders, table),
          icon: const Icon(Icons.receipt, size: 15),
          label: const Text('Request Bill'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 38),
          ),
        ),
      ],
    );
  }

  Widget _orderTabButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? _red : Colors.blueGrey.shade400,
              ),
            ),
          ),
          Container(height: 2, color: selected ? _red : Colors.transparent),
        ],
      ),
    );
  }

  Widget _currentOrderList(List<WaiterOrder> orders) {
    if (orders.isEmpty) {
      return Column(
        children: [
          Icon(Icons.task_alt, color: Colors.green.shade400, size: 30),
          const SizedBox(height: 6),
          const Text(
            'All orders served',
            style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 3),
          Text(
            'Add a new order or request the bill.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500),
          ),
        ],
      );
    }
    final items = orders.expand((order) => order.items).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Order (${items.length})',
          style: const TextStyle(fontWeight: FontWeight.w900, color: _ink),
        ),
        const SizedBox(height: 8),
        ...items
            .take(4)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (items.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${items.length - 4} more items',
              style: TextStyle(fontSize: 9, color: Colors.blueGrey.shade400),
            ),
          ),
      ],
    );
  }

  Widget _previousOrderList(List<WaiterOrder> orders) {
    if (orders.isEmpty) {
      return Column(
        children: [
          Icon(Icons.history, color: Colors.blueGrey.shade300, size: 30),
          const SizedBox(height: 6),
          Text(
            'No previous orders yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade500,
            ),
          ),
        ],
      );
    }
    return Column(
      children: orders
          .map(
            (order) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.items.length} items',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _clock(order.placedAt),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blueGrey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _quickActions(WaiterProvider waiter) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _action(
                  'Take Order',
                  Icons.restaurant,
                  _red,
                  () => _openOrder(_selectedTable),
                ),
              ),
              Expanded(
                child: _action(
                  'Serve Order',
                  Icons.room_service,
                  Colors.blue,
                  () => _serveSelected(waiter),
                ),
              ),
              Expanded(
                child: _action(
                  'Request Bill',
                  Icons.receipt,
                  Colors.orange,
                  () => _requestSelectedBill(waiter),
                ),
              ),
              Expanded(
                child: _action('Refresh', Icons.refresh, Colors.deepPurple, () {
                  waiter.loadTables();
                  waiter.loadActiveOrders();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _activeOrders(WaiterProvider waiter) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'My Active Orders',
                style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _push(const ActiveOrdersScreen()),
                child: const Text('View All', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          ...waiter.activeOrders
              .take(4)
              .map(
                (order) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: _red.withValues(alpha: .1),
                    child: Text(
                      order.tableNumber,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _red,
                      ),
                    ),
                  ),
                  title: Text(
                    '${order.items.length} Items',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 9,
                      color: order.isServed ? Colors.green : Colors.orange,
                    ),
                  ),
                  trailing: Text(
                    _clock(order.placedAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blueGrey.shade500,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _panel(Widget icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  void _openOrder(TableModel? table) {
    if (table == null) {
      _showInfo('Please select a table first.');
      return;
    }
    _push(
      TableOrderScreen(
        table: table,
        restaurantId: context.read<WaiterProvider>().restaurantId.toString(),
      ),
    );
  }

  void _serveSelected(WaiterProvider waiter) {
    final table = _selectedTable;
    if (table == null) {
      _showInfo('Please select a table first.');
      return;
    }
    final currentOrders = table.activeSessionId == null
        ? <WaiterOrder>[]
        : waiter.activeOrders
              .where((item) =>
                  item.sessionId == table.activeSessionId && item.isActive)
              .toList();
    if (currentOrders.isEmpty) {
      _showInfo('All orders for this table are already served.');
      return;
    }
    _serveOrders(currentOrders);
  }

  void _serveOrders(List<WaiterOrder> orders) async {
    if (!await confirmServeIfNeeded(context, 'this order')) return;
    if (!mounted) return;
    final waiter = context.read<WaiterProvider>();
    var allOk = true;
    for (final order in orders) {
      final ok = await waiter.updateOrderStatus(order.orderId, 'served');
      allOk = allOk && ok;
    }
    if (mounted) {
      _showInfo(
        allOk ? 'Order marked as served.' : 'Unable to update some orders.',
      );
    }
  }

  void _requestSelectedBill(WaiterProvider waiter) {
    final table = _selectedTable;
    if (table == null) {
      _showInfo('Please select a table first.');
      return;
    }
    final tableOrders = table.activeSessionId == null
        ? <WaiterOrder>[]
        : waiter.activeOrders
              .where((item) => item.sessionId == table.activeSessionId)
              .toList();
    if (tableOrders.isEmpty) {
      _showInfo('No active order for this table.');
      return;
    }
    _requestBillForTable(tableOrders, table);
  }

  void _requestBillForTable(List<WaiterOrder> orders, TableModel table) {
    final withSession = orders.where((item) => item.sessionId != null);
    if (withSession.isEmpty) {
      _showInfo('Bill session is not available.');
      return;
    }
    _push(
      BillScreen(
        tableNumber: table.tableNumber,
        tableId: table.id,
        sessionId: withSession.first.sessionId!,
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showInfo(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _clock(DateTime date) =>
      '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';

  Future<void> _showTableActions(
    BuildContext context,
    TableModel table,
    WaiterProvider waiter,
  ) async {
    final sessionResult = await ApiService().getTableSessions(table.id);
    final session = sessionResult['data'];
    if (!context.mounted || sessionResult['success'] != true || session == null)
      return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Table ${table.tableNumber} actions')),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Transfer to available table'),
              onTap: () => Navigator.pop(ctx, 'transfer'),
            ),
            ListTile(
              leading: const Icon(Icons.call_merge),
              title: const Text('Merge with occupied table'),
              onTap: () => Navigator.pop(ctx, 'merge'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    final candidates = action == 'transfer'
        ? waiter.tables.where((item) => item.isAvailable).toList()
        : waiter.tables
              .where((item) => item.isOccupied && item.id != table.id)
              .toList();
    if (candidates.isEmpty) {
      _showInfo(
        action == 'transfer'
            ? 'Available table nahi hai'
            : 'Merge ke liye occupied table nahi hai',
      );
      return;
    }
    int targetTableId = candidates.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            action == 'transfer'
                ? 'Transfer ${table.tableNumber}'
                : 'Merge ${table.tableNumber}',
          ),
          content: DropdownButtonFormField<int>(
            value: targetTableId,
            decoration: InputDecoration(
              labelText: action == 'transfer'
                  ? 'Available table'
                  : 'Occupied table',
            ),
            items: candidates
                .map(
                  (candidate) => DropdownMenuItem(
                    value: candidate.id,
                    child: Text('Table ${candidate.tableNumber}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => targetTableId = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final sourceSessionId = int.tryParse(
      session['id']?.toString() ?? session['session_id']?.toString() ?? '',
    );
    if (sourceSessionId == null) {
      _showInfo('Active session id nahi mila.');
      return;
    }
    final result = action == 'transfer'
        ? await waiter.transferTable(sourceSessionId, targetTableId)
        : await _mergeWithTarget(waiter, sourceSessionId, targetTableId);
    if (!mounted) return;
    _showInfo(
      result['success'] == true
          ? '${action == 'transfer' ? 'Transfer' : 'Merge'} successful.'
          : (result['message']?.toString() ?? 'Action failed.'),
    );
  }

  Future<Map<String, dynamic>> _mergeWithTarget(
    WaiterProvider waiter,
    int sourceSessionId,
    int targetTableId,
  ) async {
    final targetResult = await ApiService().getTableSessions(targetTableId);
    final target = targetResult['data'];
    final targetSessionId = int.tryParse(
      target?['id']?.toString() ?? target?['session_id']?.toString() ?? '',
    );
    if (targetResult['success'] != true || targetSessionId == null) {
      return {'success': false, 'message': 'Target table session nahi mila.'};
    }
    return waiter.mergeTables(sourceSessionId, targetSessionId);
  }
}

class _FloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.brown.shade200
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    for (var y = 0.0; y < size.height; y += 32)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    final plant = Paint()..color = Colors.green.shade700;
    canvas.drawCircle(Offset(22, 22), 14, plant);
    canvas.drawCircle(Offset(size.width - 22, size.height - 22), 14, plant);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
