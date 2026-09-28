import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';
// ⬇️ Apne project ke hisaab se sidebar import path theek kar lo
import '../widgets/app_sidebar.dart';
import '../widgets/admin_top_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeTab = 'all';
  final _searchCtrl = TextEditingController();
  final Set<int> _selectedIds = {};
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // -------- HELPERS --------
  double _toD(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  int _count(List list, {String? type, String? status}) {
    return list.where((o) {
      final t = (o['order_type'] ?? '').toString();
      final s = (o['status'] ?? '').toString();
      final tm = type == null || t == type;
      final sm = status == null || s == status;
      return tm && sm;
    }).length;
  }

  String _time(dynamic v) {
    try {
      if (v == null) return '--:--';
      return DateFormat('hh:mm a').format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return '--:--';
    }
  }

  String _ago(dynamic v) {
    try {
      if (v == null) return '';
      final d = DateTime.now().difference(DateTime.parse(v.toString()).toLocal());
      if (d.inMinutes < 60) return '${d.inMinutes} mins ago';
      if (d.inHours < 24) return '${d.inHours} hrs ago';
      return '${d.inDays} days ago';
    } catch (_) {
      return '';
    }
  }

  String _itemsText(dynamic order) {
    try {
      if (order['items_summary'] != null) return order['items_summary'].toString();
      if (order['items'] is List) {
        final items = order['items'] as List;
        if (items.isEmpty) return '—';
        final names = items.map((e) => (e['item_name'] ?? e['name'] ?? '').toString()).where((e) => e.isNotEmpty).toList();
        if (names.isEmpty) return '—';
        if (names.length <= 2) return names.join(', ');
        return '${names.take(2).join(', ')} +${names.length - 2} more';
      }
    } catch (_) {}
    return 'View details';
  }

  bool _isToday(dynamic placedAt) {
    try {
      if (placedAt == null) return false;
      final date = DateTime.parse(placedAt.toString()).toLocal();
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1100;
    final isMobile = w < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: const Color(0xFF1E1E1E),
              child: AppSidebar(activeLabel: 'Orders'),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              const CollapsibleSidebar(activeLabel: 'Orders'),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: !isDesktop ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Orders',
                  ),
                  Expanded(
                    child: admin.isOrdersLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)))
                        : _content(admin.orders, isMobile, isDesktop),
                  ),
                  _bottomBar(isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData? icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 6),
          ],
          Text(text, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // ================= CONTENT =================
  Widget _content(List<dynamic> orders, bool isMobile, bool isDesktop) {
    final todaysOrders = orders.where((o) => _isToday(o['placed_at'])).toList();
    final filtered = orders.where((o) {
      final type = (o['order_type'] ?? '').toString();
      final status = (o['status'] ?? '').toString();
      final tabOk = _activeTab == 'all' || type == _activeTab;
      final statusOk = _statusFilter.isEmpty || status == _statusFilter;
      return tabOk && statusOk;
    }).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _banner(todaysOrders.length),
                const SizedBox(height: 16),
                _statsRow(todaysOrders),
                const SizedBox(height: 16),
                _tabsAndFilters(orders, isMobile),
                const SizedBox(height: 0),
                _table(filtered, isMobile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Banner
  Widget _banner(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Orders', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Track and manage all your restaurant orders in real-time',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '"Good Food\nTakes Care\nof Everything"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade700,
                height: 1.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('TOTAL ORDERS TODAY',
                    style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.8)),
                Text('$total',
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stats
  Widget _statsRow(List orders) {
    final stats = [
      _Stat('New Orders', _count(orders, status: 'placed'), Icons.assignment_outlined, Colors.blue),
      _Stat('Preparing', _count(orders, status: 'preparing'), Icons.restaurant, Colors.orange),
      _Stat('Ready', _count(orders, status: 'ready'), Icons.room_service, Colors.green),
      _Stat('Served', _count(orders, status: 'served'), Icons.check_circle_outline, Colors.deepPurple),
      _Stat('Cancelled', _count(orders, status: 'cancelled'), Icons.cancel_outlined, Colors.red),
      _Stat('Avg. Prep Time', -1, Icons.timer_outlined, Colors.blueGrey, custom: '18 mins'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats.map((s) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.color.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: s.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s.icon, color: s.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      Text(
                        s.custom ?? '${s.value}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Tabs
  Widget _tabsAndFilters(List orders, bool isMobile) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _tab('All Orders', 'all', orders.length),
            _tab('Dine In', 'dine-in', _count(orders, type: 'dine-in')),
            _tab('Take Away', 'takeaway', _count(orders, type: 'takeaway')),
            _tab('Delivery', 'delivery', _count(orders, type: 'delivery')),
            _tab('Online', 'online', _count(orders, type: 'online')),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, String value, int count) {
    final active = _activeTab == value;
    return InkWell(
      onTap: () => setState(() => _activeTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFFE67E22) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFFE67E22) : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // Table
  Widget _table(List filtered, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: filtered.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('No orders found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('New orders will appear here', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - (MediaQuery.of(context).size.width >= 1100 ? 260 : 40),
                ),
                child: DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 72,
                  horizontalMargin: 12,
                  columnSpacing: 18,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FB)),
                  columns: const [
                    DataColumn(label: Text('')),
                    DataColumn(label: Text('Order ID', style: _h)),
                    DataColumn(label: Text('Type', style: _h)),
                    DataColumn(label: Text('Table / Customer', style: _h)),
                    DataColumn(label: Text('Items', style: _h)),
                    DataColumn(label: Text('Amount', style: _h)),
                    DataColumn(label: Text('Status', style: _h)),
                    DataColumn(label: Text('Payment', style: _h)),
                    DataColumn(label: Text('Time', style: _h)),
                    DataColumn(label: Text('Actions', style: _h)),
                  ],
                  rows: filtered.map((o) => _row(o)).toList(),
                ),
              ),
            ),
    );
  }

  static const _h = TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87);

  DataRow _row(dynamic o) {
    final id = o['id'];
    final selected = _selectedIds.contains(id);
    final type = (o['order_type'] ?? 'dine-in').toString();
    final status = (o['status'] ?? 'placed').toString();

    return DataRow(
      selected: selected,
      color: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return const Color(0xFFFFF3E0);
        return null;
      }),
      cells: [
        DataCell(
          Checkbox(
            value: selected,
            activeColor: const Color(0xFFE67E22),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedIds.add(id);
                } else {
                  _selectedIds.remove(id);
                }
              });
            },
          ),
        ),
        DataCell(Text('#${id ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        DataCell(_typeChip(type)),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'dine-in'
                    ? 'Table ${o['table_number'] ?? '—'}'
                    : (o['customer_name'] ?? o['customer'] ?? 'Walk-in').toString(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                type == 'dine-in'
                    ? '${o['guests'] ?? o['guest_count'] ?? '—'} Guests'
                    : (o['customer_phone'] ?? o['phone'] ?? '').toString(),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              _itemsText(o),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(
          Text(
            '₹ ${_toD(o['final_amount']).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        DataCell(_statusChip(status)),
        DataCell(_paymentChip(o)),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_time(o['placed_at']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(_ago(o['placed_at']), style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconAction(Icons.more_vert, () {}),
              _iconAction(Icons.print_outlined, () => _printSingleKot(o)),
              _iconAction(Icons.phone_outlined, () {}),
              const SizedBox(width: 4),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: () => _showDetails(o),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: BorderSide(color: Colors.blue.shade200),
                    foregroundColor: Colors.blue.shade700,
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentChip(dynamic order) {
    final paymentStatus = order['payment_status']?.toString();
    final paymentMethod = order['payment_method']?.toString();
    final isPaid = paymentStatus == 'success';
    final isCash = paymentMethod == 'cash';
    final isOffPremise = order['order_type'] == 'takeaway' || order['order_type'] == 'delivery';

    final label = isPaid
        ? (isCash ? 'CASH RECEIVED' : 'PAID ONLINE')
      : (isCash ? 'CASH PENDING' : (paymentStatus == 'pending' ? 'ONLINE PENDING' : (isOffPremise ? 'PAYMENT PENDING' : 'UNPAID')));
    final color = isPaid
        ? const Color(0xFF2E7D32)
      : (isCash ? const Color(0xFFE67E22) : Colors.grey.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _iconAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.grey.shade700),
      ),
    );
  }

  // ================= BOTTOM BAR =================
  Widget _bottomBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, -2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => context.read<AdminProvider>().loadOrders(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _printSelectedKot,
              icon: const Icon(Icons.receipt_long, size: 18),
              label: Text(
                _selectedIds.isEmpty ? 'Order KOT' : 'Order KOT (${_selectedIds.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEDE7F6),
                foregroundColor: const Color(0xFF6A1B9A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.library_add_check_outlined, size: 18),
              label: const Text('Bulk Actions'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Export Orders'),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFFF9A825), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Tip: Select orders with checkbox then press Order KOT',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================= CHIPS =================
  Widget _typeChip(String type) {
    late Color c;
    late IconData icon;
    late String label;
    switch (type) {
      case 'takeaway':
        c = Colors.green;
        icon = Icons.shopping_bag_outlined;
        label = 'Take Away';
        break;
      case 'delivery':
        c = Colors.redAccent;
        icon = Icons.delivery_dining;
        label = 'Delivery';
        break;
      case 'online':
        c = Colors.pink;
        icon = Icons.phone_android;
        label = 'Online';
        break;
      default:
        c = Colors.blue;
        icon = Icons.restaurant;
        label = 'Dine In';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    late Color c;
    late IconData icon;
    final s = status.toLowerCase();
    if (s == 'placed' || s == 'new' || s == 'accepted') {
      c = Colors.blue;
      icon = Icons.fiber_new;
    } else if (s == 'preparing') {
      c = Colors.orange;
      icon = Icons.soup_kitchen;
    } else if (s == 'ready') {
      c = Colors.green;
      icon = Icons.check_circle;
    } else if (s == 'served') {
      c = Colors.deepPurple;
      icon = Icons.done_all;
    } else if (s == 'cancelled') {
      c = Colors.red;
      icon = Icons.cancel;
    } else {
      c = Colors.grey;
      icon = Icons.circle;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(status.toUpperCase(), style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ================= KOT =================
  void _printSelectedKot() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle checkbox se order select karo'), backgroundColor: Colors.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('KOT print ho raha hai for ${_selectedIds.length} order(s)...'),
        backgroundColor: Colors.green,
      ),
    );
    // Yahan actual API: for (final id in _selectedIds) ApiService().getKot(id);
    setState(() => _selectedIds.clear());
  }

  void _printSingleKot(dynamic order) async {
    final id = order['id'];
    if (id == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('KOT print: Order #$id'), backgroundColor: Colors.deepPurple),
    );
    try {
      await ApiService().getKot(id);
    } catch (_) {}
  }

  // ================= DETAILS =================
  Future<void> _showDetails(dynamic order) async {
    final id = order['id'];
    if (id == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ApiService().getPosBill(id);
    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order details load nahi hue'), backgroundColor: Colors.red),
      );
      return;
    }

    final data = result['data'] as Map<String, dynamic>? ?? {};
    final printable = data['order'] as Map<String, dynamic>? ?? order;
    final items = data['items'] as List? ?? [];
    final summary = data['summary'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Order #${printable['id']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    _statusChip((printable['status'] ?? '').toString()),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${(printable['order_type'] ?? '').toString().toUpperCase()}  •  Table ${printable['table_number'] ?? '—'}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const Divider(height: 28),
                const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text('No items', style: TextStyle(color: Colors.grey))
                else
                  ...items.asMap().entries.map((e) {
                    final item = e.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.orange.shade50,
                        child: Text('${e.key + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      ),
                      title: Text('${item['item_name'] ?? item['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${item['quantity'] ?? 1} × ₹${_toD(item['unit_price']).toStringAsFixed(2)}'),
                      trailing: Text('₹${_toD(item['total_price']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    );
                  }),
                const Divider(height: 28),
                _sumRow('Subtotal', summary['subtotal'] ?? printable['final_amount']),
                _sumRow('GST', summary['gst']),
                if (_toD(summary['discount']) > 0) _sumRow('Discount', -_toD(summary['discount'])),
                const Divider(),
                _sumRow('Grand Total', summary['final_amount'] ?? printable['final_amount'], bold: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _printSingleKot(printable);
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Print KOT'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22), foregroundColor: Colors.white),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sumRow(String label, dynamic amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14)),
          Text(
            '₹${_toD(amount).toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 16 : 14),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? custom;
  _Stat(this.title, this.value, this.icon, this.color, {this.custom});
}