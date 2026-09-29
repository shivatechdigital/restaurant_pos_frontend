import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/auth_provider.dart';
import '../config/socket_service.dart';
import '../models/kitchen_order_model.dart';
import '../providers/kitchen_provider.dart';
import '../widgets/waiter_alert_banner.dart';
import 'kds_tv_mode.dart';
import 'login_screen.dart';
import 'kitchen_stats_screen.dart';
import 'kitchen_settings_screen.dart';
import 'order_detail_screen.dart';
import 'order_history_screen.dart';
import 'stock_request_screen.dart';
import 'trends_report_screen.dart';

const _navy = Color(0xFF101C29);
const _ink = Color(0xFF172235);
const _red = Color(0xFFE52235);
const _bg = Color(0xFFF3F6FA);

class KDSDashboard extends StatefulWidget {
  const KDSDashboard({super.key});
  @override
  State<KDSDashboard> createState() => _KDSDashboardState();
}

class _KDSDashboardState extends State<KDSDashboard> {
  KitchenProvider? provider;
  String searchQuery = '';
  final Set<String> _visibleStages = {'new', 'preparing', 'ready'};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider ??= context.read<KitchenProvider>();
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final kitchen = provider;
      if (!mounted || kitchen == null) return;
      await kitchen.initialize();
      await kitchen.loadStats();
      if (mounted) SocketService().connect(kitchen.restaurantId.toString());
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    provider?.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitchen = context.watch<KitchenProvider>();
    final compact = MediaQuery.sizeOf(context).width < 850;
    return Scaffold(
      backgroundColor: _bg,
      drawer: compact ? Drawer(child: _rail()) : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!compact) SizedBox(width: 214, child: _rail()),
            Expanded(child: _main(kitchen, compact)),
          ],
        ),
      ),
    );
  }

  Widget _rail() {
    return Container(
      color: _navy,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pet Pooja\nKITCHEN DISPLAY SYSTEM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          _nav(Icons.dashboard_rounded, 'All Orders', true, () {}),
          _nav(
            Icons.inventory_2_rounded,
            'Stock Requests',
            false,
            () => _push(const StockRequestScreen()),
          ),
          _nav(
            Icons.bar_chart_rounded,
            'Kitchen Stats',
            false,
            () => _push(const KitchenStatsScreen()),
          ),
          _nav(
            Icons.trending_up_rounded,
            'Trends Report',
            false,
            () => _push(const TrendsReportScreen()),
          ),
          _nav(
            Icons.history_rounded,
            'Order History',
            false,
            () => _push(const KitchenHistoryScreen()),
          ),
          const Spacer(),
          _nav(
            Icons.settings_rounded,
            'Kitchen Settings',
            false,
            () => _push(const KitchenSettingsScreen()),
          ),
          _nav(Icons.logout_rounded, 'Logout', false, _logout),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 9),
                SizedBox(width: 7),
                Text(
                  'Kitchen Online',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(IconData icon, String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: active ? _red : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? Colors.white : Colors.white60,
                  size: 19,
                ),
                const SizedBox(width: 11),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _main(KitchenProvider kitchen, bool compact) {
    return Column(
      children: [
        _topBar(kitchen, compact),
        _tabs(kitchen),
        if (kitchen.unreadRequests.isNotEmpty)
          WaiterAlertBanner(
            requests: kitchen.waiterRequests,
            onDismiss: kitchen.markRequestRead,
            onClearAll: kitchen.clearAllRequests,
          ),
        Expanded(
          child: kitchen.isLoading && kitchen.orders.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _red))
              : _visibleOrders(kitchen).isEmpty
              ? _empty()
              : compact
              ? _mobile(kitchen)
              : _desktop(kitchen),
        ),
      ],
    );
  }

  Widget _topBar(KitchenProvider kitchen, bool compact) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: _navy,
      child: Row(
        children: [
          if (compact)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
          if (!compact)
            const Text(
              'KITCHEN DISPLAY SYSTEM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
          const SizedBox(width: 18),
          Expanded(
            child: Container(
              height: 38,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (value) =>
                    setState(() => searchQuery = value.trim().toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white54,
                    size: 18,
                  ),
                  hintText: 'Search by Table, Order ID or item...',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 10),
                ),
              ),
            ),
          ),
          if (!compact)
            Text(
              _time(),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          IconButton(
            onPressed: kitchen.loadOrders,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: kitchen.toggleMute,
            icon: Icon(
              kitchen.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white70,
            ),
            tooltip: 'Sound',
          ),
          IconButton(
            onPressed: () => _push(const KDSTvMode()),
            icon: const Icon(Icons.tv_rounded, color: Colors.white70),
            tooltip: 'TV mode',
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _time() {
    final time = TimeOfDay.now();
    return '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Widget _tabs(KitchenProvider kitchen) {
    final tabs = [
      ('New', 'new', kitchen.newOrders, Icons.fiber_new_rounded, _red),
      (
        'Cooking',
        'preparing',
        kitchen.preparingOrders,
        Icons.restaurant_rounded,
        Colors.orange.shade700,
      ),
      (
        'Ready',
        'ready',
        kitchen.readyOrders,
        Icons.room_service_rounded,
        Colors.green.shade700,
      ),
      (
        'Completed',
        'completed',
        kitchen.orders.where((order) => order.status == 'served').length,
        Icons.check_circle_rounded,
        Colors.blue.shade700,
      ),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final selected = _visibleStages.contains(tab.$2);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                avatar: Icon(
                  tab.$4,
                  size: 16,
                  color: selected ? Colors.white : tab.$5,
                ),
                label: Text('${tab.$1} (${tab.$3})'),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: tab.$5,
                backgroundColor: tab.$5.withValues(alpha: .08),
                checkmarkColor: Colors.white,
                onSelected: (enabled) => setState(() {
                  if (enabled) {
                    _visibleStages.add(tab.$2);
                  } else {
                    _visibleStages.remove(tab.$2);
                  }
                }),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _desktop(KitchenProvider kitchen) {
    final orders = _visibleOrders(kitchen);
    final columns = <_ColumnData>[
      if (_visibleStages.contains('new'))
        _ColumnData(
          'New Orders',
          Colors.red.shade50,
          Colors.red.shade700,
          orders
              .where(
                (order) =>
                    order.status == 'placed' || order.status == 'pending',
              )
              .toList(),
        ),
      if (_visibleStages.contains('preparing'))
        _ColumnData(
          'Cooking',
          Colors.orange.shade50,
          Colors.orange.shade700,
          orders
              .where(
                (order) =>
                    order.status == 'accepted' || order.status == 'preparing',
              )
              .toList(),
        ),
      if (_visibleStages.contains('ready'))
        _ColumnData(
          'Ready to Serve',
          Colors.green.shade50,
          Colors.green.shade700,
          orders.where((order) => order.status == 'ready').toList(),
        ),
      if (_visibleStages.contains('completed'))
        _ColumnData(
          'Completed',
          Colors.blue.shade50,
          Colors.blue.shade700,
          orders.where((order) => order.status == 'served').toList(),
        ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...columns.map((column) => Expanded(child: _column(column, kitchen))),
        SizedBox(width: 230, child: _overview(kitchen)),
      ],
    );
  }

  Widget _mobile(KitchenProvider kitchen) {
    final orders = _visibleOrders(kitchen);
    return RefreshIndicator(
      onRefresh: kitchen.loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, index) => _card(orders[index], kitchen),
      ),
    );
  }

  List<KitchenOrder> _visibleOrders(KitchenProvider kitchen) {
    return kitchen.orders.where((order) {
      final stage = order.status == 'placed' || order.status == 'pending'
          ? 'new'
          : order.status == 'accepted' || order.status == 'preparing'
          ? 'preparing'
          : order.status == 'ready'
          ? 'ready'
          : order.status == 'served'
          ? 'completed'
          : '';
      if (!_visibleStages.contains(stage)) return false;
      if (searchQuery.isEmpty) return true;
      final itemMatch = order.items.any(
        (item) => item.name.toLowerCase().contains(searchQuery),
      );
      return order.tableNumber.toLowerCase().contains(searchQuery) ||
          order.orderId.toString().contains(searchQuery) ||
          itemMatch;
    }).toList();
  }

  Widget _column(_ColumnData data, KitchenProvider kitchen) {
    return Container(
      margin: const EdgeInsets.fromLTRB(7, 8, 0, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: data.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '${data.orders.length}',
                  style: TextStyle(
                    color: data.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: data.orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: kitchen.loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: data.orders.length,
                      itemBuilder: (_, index) =>
                          _card(data.orders[index], kitchen),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(KitchenOrder order, KitchenProvider kitchen) {
    final urgent = order.isUrgent;
    final header = order.status == 'placed'
        ? _red
        : order.status == 'ready'
        ? Colors.green.shade600
        : order.status == 'served'
        ? Colors.blue.shade600
        : Colors.orange.shade600;
    return InkWell(
      onTap: () => _push(OrderDetailScreen(order: order)),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: order.isVeryUrgent
                ? Colors.red
                : urgent
                ? Colors.orange
                : Colors.grey.shade200,
            width: urgent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: header.withValues(alpha: .08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '#KOT${order.orderId}',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _clock(order.placedAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                  if (order.status == 'placed' ||
                      order.status == 'pending') ...[
                    const SizedBox(width: 7),
                    _badge('NEW', _red),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_restaurant, size: 14, color: _ink),
                      const SizedBox(width: 5),
                      Text(
                        order.tableNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        order.section ?? 'Dine In',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      if (urgent)
                        Text(
                          '${order.minutesAgo} min',
                          style: TextStyle(
                            color: order.isVeryUrgent
                                ? Colors.red
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...order.items
                      .take(5)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '${item.quantity} × ${item.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  if (order.items.length > 5)
                    Text(
                      '+ ${order.items.length - 5} more items',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: header.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Note: ${order.notes}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: header, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            if (order.status != 'served')
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => kitchen.updateStatus(
                      order.orderId,
                      _next(order.status),
                    ),
                    icon: Icon(_nextIcon(order.status), size: 14),
                    label: Text(
                      _nextLabel(order.status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: header,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            if (order.status == 'served')
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Served at ${_clock(order.servedAt ?? order.placedAt)}',
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _overview(KitchenProvider kitchen) {
    final stats = kitchen.stats ?? {};
    final completed = kitchen.orders
        .where((order) => order.status == 'served')
        .length;
    final prepStats = stats['avg_prep_time'] is Map
        ? Map<String, dynamic>.from(stats['avg_prep_time'])
        : <String, dynamic>{};
    final averagePrep = prepStats['avg_minutes'];
    final fastestPrep = prepStats['fastest'];
    final slowestPrep = prepStats['slowest'];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: ListView(
        children: [
          _title(Icons.bar_chart, 'Kitchen Overview'),
          Row(
            children: [
              _metric('New Orders', kitchen.newOrders, Colors.red),
              _metric('Preparing', kitchen.preparingOrders, Colors.orange),
            ],
          ),
          Row(
            children: [
              _metric('Ready', kitchen.readyOrders, Colors.green),
              _metric('Completed', completed, Colors.blue),
            ],
          ),
          const SizedBox(height: 14),
          _title(Icons.assessment_rounded, 'Order Stats (Today)'),
          _row(
            Icons.receipt_long,
            'Total Orders',
            '${stats['total_orders'] ?? kitchen.totalActive}',
          ),
          _row(
            Icons.restaurant,
            'In Preparation',
            '${kitchen.preparingOrders}',
          ),
          _row(Icons.room_service, 'Ready to Serve', '${kitchen.readyOrders}'),
          _row(
            Icons.takeout_dining,
            'Takeaway',
            '${kitchen.orders.where((order) => order.tableNumber.toLowerCase().contains('take')).length}',
          ),
          const SizedBox(height: 14),
          _title(Icons.timer_outlined, 'Average Preparation Time'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              averagePrep == null
                  ? '--'
                  : '$averagePrep mins\nFastest: ${fastestPrep ?? '--'} mins\nSlowest: ${slowestPrep ?? '--'} mins',
              style: const TextStyle(
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
          ),
          if (kitchen.unreadRequests.isNotEmpty) ...[
            const SizedBox(height: 14),
            _title(Icons.notifications_active, 'Alerts & Notes'),
            ...kitchen.unreadRequests
                .take(3)
                .map(
                  (request) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Table ${request.tableNumber} - ${request.message}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _title(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Icon(icon, size: 17, color: _ink),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
  Widget _metric(String label, int value, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color.withValues(alpha: .85),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey.shade500),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 10),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
  String _next(String status) => status == 'placed' || status == 'pending'
      ? 'preparing'
      : status == 'accepted' || status == 'preparing'
      ? 'ready'
      : 'served';
  IconData _nextIcon(String status) => status == 'placed' || status == 'pending'
      ? Icons.restaurant
      : status == 'accepted' || status == 'preparing'
      ? Icons.check
      : Icons.room_service;
  String _nextLabel(String status) => status == 'placed' || status == 'pending'
      ? 'Start Preparing'
      : status == 'accepted' || status == 'preparing'
      ? 'Mark as Ready'
      : 'Mark as Served';
  String _clock(DateTime date) =>
      '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.restaurant_menu, size: 60, color: Colors.blueGrey.shade200),
        const SizedBox(height: 12),
        Text(
          'No orders in this view',
          style: TextStyle(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'New orders will appear here automatically',
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ColumnData {
  final String title;
  final Color background;
  final Color foreground;
  final List<KitchenOrder> orders;
  _ColumnData(this.title, this.background, this.foreground, this.orders);
}
