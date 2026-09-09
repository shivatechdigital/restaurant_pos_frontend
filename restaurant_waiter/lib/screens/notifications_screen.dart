import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waiter_provider.dart';
import '../services/app_preferences.dart';
import '../widgets/waiter_shell.dart';

enum _NotifFilter { all, orders, tables }

/// A single live alert derived from current provider state (not a persisted
/// backend notification log — the waiter API doesn't expose one for this role).
class _Alert {
  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final _NotifFilter category;
  const _Alert({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.category,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotifFilter _filter = _NotifFilter.all;
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final waiter = context.read<WaiterProvider>();
      waiter.loadTables();
      waiter.loadActiveOrders();
    });
  }

  List<_Alert> _buildAlerts(WaiterProvider waiter) {
    final alerts = <_Alert>[];
    for (final order in waiter.activeOrders.where((o) => o.status == 'placed')) {
      alerts.add(_Alert(
        key: 'order_new_${order.orderId}',
        icon: Icons.restaurant_rounded,
        color: kRed,
        title: 'New Order Received',
        message: 'Order #${order.orderId} placed for Table ${order.tableNumber} (${order.items.length} items) \u2022 ${order.minutesAgo}m ago',
        category: _NotifFilter.orders,
      ));
    }
    for (final order in waiter.activeOrders.where((o) => o.status == 'ready')) {
      alerts.add(_Alert(
        key: 'order_ready_${order.orderId}',
        icon: Icons.room_service_rounded,
        color: Colors.green,
        title: 'Order Ready',
        message: 'Order #${order.orderId} is ready to serve (Table ${order.tableNumber}) \u2022 ${order.minutesAgo}m ago',
        category: _NotifFilter.orders,
      ));
    }
    for (final table in waiter.tables.where((t) => t.isCleaning)) {
      alerts.add(_Alert(
        key: 'table_clean_${table.id}',
        icon: Icons.cleaning_services_rounded,
        color: Colors.orange,
        title: 'Table Needs Cleaning',
        message: 'Table ${table.tableNumber} is marked for cleaning before the next guest.',
        category: _NotifFilter.tables,
      ));
    }
    return alerts.where((a) => !_dismissed.contains(a.key)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1100;

    final alerts = _buildAlerts(waiter);
    final orderAlerts = alerts.where((a) => a.category == _NotifFilter.orders).length;
    final tableAlerts = alerts.where((a) => a.category == _NotifFilter.tables).length;
    final visible = switch (_filter) {
      _NotifFilter.orders => alerts.where((a) => a.category == _NotifFilter.orders).toList(),
      _NotifFilter.tables => alerts.where((a) => a.category == _NotifFilter.tables).toList(),
      _NotifFilter.all => alerts,
    };

    return WaiterShell(
      route: WaiterRoute.notifications,
      title: 'Hello, Rahul! 👋',
      subtitle: 'Stay updated, never miss a moment!',
      searchHint: 'Search notifications...',
      onRefresh: () {
        waiter.loadTables();
        waiter.loadActiveOrders();
      },
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: WaiterPageHeader(
                    icon: Icons.notifications_rounded,
                    iconColor: kRed,
                    title: 'Notifications',
                    subtitle: 'Get real-time updates about orders, tables, payments and more.',
                  ),
                ),
                if (alerts.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _dismissed.addAll(alerts.map((a) => a.key))),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark all as read'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kRed.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: kRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${alerts.length} Unread Notifications', style: const TextStyle(fontWeight: FontWeight.w900, color: kRed)),
                        const Text('Stay informed and keep service smooth!', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: compact
                  ? _list(visible, orderAlerts, tableAlerts, alerts.length)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _list(visible, orderAlerts, tableAlerts, alerts.length)),
                        const SizedBox(width: 12),
                        SizedBox(width: 300, child: _settingsPanel(orderAlerts, tableAlerts, alerts.length)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<_Alert> visible, int orderCount, int tableCount, int allCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tabsRow(allCount, orderCount, tableCount),
        const SizedBox(height: 12),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text('Sab kuch up to date hai!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) => _alertTile(visible[index]),
                ),
        ),
      ],
    );
  }

  Widget _tabsRow(int all, int orders, int tables) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChip('All ($all)', _NotifFilter.all),
          const SizedBox(width: 8),
          _tabChip('Orders ($orders)', _NotifFilter.orders),
          const SizedBox(width: 8),
          _tabChip('Tables ($tables)', _NotifFilter.tables),
        ],
      ),
    );
  }

  Widget _tabChip(String label, _NotifFilter filter) {
    final selected = _filter == filter;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.5, color: selected ? Colors.white : kInk)),
      selected: selected,
      selectedColor: kRed,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? kRed : Colors.grey.shade300),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _alertTile(_Alert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: alert.color.withValues(alpha: .12), child: Icon(alert.icon, color: alert.color, size: 18)),
        title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(alert.message, style: const TextStyle(fontSize: 11.5)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16),
          tooltip: 'Dismiss',
          onPressed: () => setState(() => _dismissed.add(alert.key)),
        ),
      ),
    );
  }

  Widget _settingsPanel(int orderCount, int tableCount, int allCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 6),
          _prefSwitch('New Orders', 'Get notified when a new order is placed', AppPreferences.newOrderAlerts,
              (v) => setState(() => AppPreferences.setNewOrderAlerts(v))),
          _prefSwitch('Order Ready', 'Get notified when an order is ready to serve', AppPreferences.readyAlerts,
              (v) => setState(() => AppPreferences.setReadyAlerts(v))),
          _prefSwitch('Bill Ready', 'Get notified when a bill is generated', AppPreferences.billReadyAlerts,
              (v) => setState(() => AppPreferences.setBillReadyAlerts(v))),
          _prefSwitch('Table Transfer', 'Get notified when a table is transferred', AppPreferences.tableTransferAlerts,
              (v) => setState(() => AppPreferences.setTableTransferAlerts(v))),
          _prefSwitch('Vibration', 'Vibrate on new notifications', AppPreferences.vibration,
              (v) => setState(() => AppPreferences.setVibration(v))),
        ],
      ),
    );
  }

  Widget _prefSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeThumbColor: kRed,
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5)),
    );
  }
}
