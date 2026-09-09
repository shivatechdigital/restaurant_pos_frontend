import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../providers/admin_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../utils/print_helper_stub.dart'
    if (dart.library.html) '../utils/print_helper_web.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen>
    with SingleTickerProviderStateMixin {
  String _statusFilter = 'all';
  String _viewMode = 'grid'; // grid or list
  String _floorFilter = 'all';
  String _qrBaseUrl = '';
  static const _qrBaseUrlPrefKey = 'customer_app_qr_base_url';
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  final _api = ApiService();
  bool _mergeMode = false;
  final Set<int> _mergeSelectedTableIds = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadQrBaseUrl();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadTables();
    });

    // Auto refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<AdminProvider>().loadTables();
    });
  }

  Future<void> _loadQrBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _qrBaseUrl = prefs.getString(_qrBaseUrlPrefKey) ?? '');
  }

  Future<void> _saveQrBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qrBaseUrlPrefKey, value);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ===================== HELPERS =====================
  int _countByStatus(List tables, String status) {
    return tables.where((t) => (t['status'] ?? '').toString().toLowerCase() == status).length;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'occupied':
        return const Color(0xFF4CAF50);
      case 'reserved':
        return const Color(0xFFE67E22);
      case 'available':
        return const Color(0xFF2196F3);
      case 'cleaning':
        return const Color(0xFF9C27B0);
      case 'out_of_service':
      case 'out-of-service':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'occupied':
        return Icons.people;
      case 'reserved':
        return Icons.event_seat;
      case 'available':
        return Icons.check_circle;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'out_of_service':
      case 'out-of-service':
        return Icons.block;
      default:
        return Icons.help_outline;
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
              child: AppSidebar(activeLabel: 'Table Management'),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              Container(
                width: 220,
                color: const Color(0xFF1E1E1E),
                child: AppSidebar(activeLabel: 'Table Management'),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: isMobile ? () => Scaffold.of(context).openDrawer() : null,
                    title: 'Table Management',
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroBanner(admin.tables),
                          const SizedBox(height: 20),
                          _quickStats(admin.tables),
                          const SizedBox(height: 20),
                          _controlsRow(isMobile),
                          const SizedBox(height: 16),
                          _floorTabs(),
                          const SizedBox(height: 16),
                          _viewMode == 'grid'
                              ? _tablesGrid(admin.tables, isMobile)
                              : _tablesList(admin.tables),
                          const SizedBox(height: 20),
                          _legendCard(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  _bottomActionBar(isMobile, admin.tables),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTableDialog(),
        backgroundColor: const Color(0xFFE67E22),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _liveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.5 + _pulseController.value * 0.5),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Live', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ===================== HERO BANNER =====================
  Widget _heroBanner(List tables) {
    final total = tables.length;
    final occupied = _countByStatus(tables, 'occupied');
    final available = _countByStatus(tables, 'available');
    final occupancyRate = total == 0 ? 0.0 : (occupied / total * 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B3410), Color(0xFF8B4513), Color(0xFFA0522D)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B4513).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.table_restaurant, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Table Management',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage floor tables, reservations and seating in real-time',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _heroChip('$available Free', Colors.greenAccent),
                    const SizedBox(width: 8),
                    _heroChip('$occupied Busy', Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _heroChip('${DateFormat('EEE, d MMM').format(DateTime.now())}', Colors.white),
                  ],
                ),
              ],
            ),
          ),
          // Occupancy Circle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: occupancyRate / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${occupancyRate.toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const Text('Occupied', style: TextStyle(color: Colors.white60, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('$total Total Tables', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ===================== QUICK STATS =====================
  Widget _quickStats(List tables) {
    final stats = [
      _StatCard('Occupied', _countByStatus(tables, 'occupied'), Icons.people, const Color(0xFF4CAF50)),
      _StatCard('Available', _countByStatus(tables, 'available'), Icons.check_circle, const Color(0xFF2196F3)),
      _StatCard('Reserved', _countByStatus(tables, 'reserved'), Icons.event_seat, const Color(0xFFE67E22)),
      _StatCard('Cleaning', _countByStatus(tables, 'cleaning'), Icons.cleaning_services, const Color(0xFF9C27B0)),
      _StatCard('Out of Service', _countByStatus(tables, 'out_of_service'), Icons.block, Colors.red),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats.map((s) {
          return Container(
            width: 165,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: s.color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: s.color.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [s.color, s.color.withOpacity(0.7)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${s.value}',
                        style: TextStyle(color: s.color, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${s.value}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                Text(s.title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===================== CONTROLS =====================
  Widget _controlsRow(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterChip('All', 'all'),
              _filterChip('Occupied', 'occupied'),
              _filterChip('Available', 'available'),
              _filterChip('Reserved', 'reserved'),
              _filterChip('Cleaning', 'cleaning'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewModeBtn(Icons.grid_view_rounded, 'grid'),
              _viewModeBtn(Icons.view_list_rounded, 'list'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _statusFilter = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE67E22) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewModeBtn(IconData icon, String mode) {
    final active = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE67E22) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: active ? Colors.white : Colors.grey.shade700, size: 18),
      ),
    );
  }

  // ===================== FLOOR TABS =====================
  Widget _floorTabs() {
    final floors = ['all', 'Ground Floor', 'First Floor', 'Rooftop', 'Outdoor'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: floors.map((f) {
          final active = _floorFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _floorFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: active ? Colors.black : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      f == 'all' ? Icons.apps : Icons.layers,
                      size: 14,
                      color: active ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f == 'all' ? 'All Floors' : f,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===================== TABLES GRID =====================
  Widget _tablesGrid(List tables, bool isMobile) {
    // Show demo data if API returns empty
    final displayTables = tables.isEmpty ? _demoTables() : tables;
    final filtered = displayTables.where((t) {
      final s = (t['status'] ?? '').toString().toLowerCase();
      return _statusFilter == 'all' || s == _statusFilter;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.table_restaurant, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No tables found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Try changing the filter', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    int crossCount;
    if (w >= 1400) {
      crossCount = 6;
    } else if (w >= 1100) {
      crossCount = 5;
    } else if (w >= 800) {
      crossCount = 4;
    } else if (w >= 500) {
      crossCount = 3;
    } else {
      crossCount = 2;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) => _tableCard(filtered[i]),
    );
  }

  Widget _tableCard(dynamic table) {
    final status = (table['status'] ?? 'available').toString().toLowerCase();
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final number = table['table_number'] ?? table['number'] ?? '—';
    final capacity = table['capacity'] ?? 4;
    final guests = table['current_guests'] ?? table['guests'] ?? 0;
    final amount = table['current_amount'];
    final duration = table['occupied_since'];
    final tableId = table['id'] as int?;
    final isSelectedForMerge = tableId != null && _mergeSelectedTableIds.contains(tableId);

    return InkWell(
      onTap: _mergeMode ? () => _onMergeTableTap(table) : () => _showTableDetails(table),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(
            color: isSelectedForMerge ? Colors.blue : color.withOpacity(0.3),
            width: isSelectedForMerge ? 3 : 1.5,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_restaurant, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'T$number',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!_mergeMode && (status == 'occupied' || status == 'cleaning') && tableId != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _cleanTable(table),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.cleaning_services, color: Colors.white, size: 16),
                          ),
                        ),
                      if (!_mergeMode) const SizedBox(width: 8),
                      if (!_mergeMode)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showQrDialog(table),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                          ),
                        ),
                      if (!_mergeMode && status == 'available' && tableId != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _deleteTable(table),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.delete_outline, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                      if (_mergeMode)
                        Icon(
                          isSelectedForMerge ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: Colors.white,
                          size: 18,
                        ),
                      if (status == 'occupied' && !_mergeMode) ...[
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.5 + _pulseController.value * 0.5),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Details
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          status == 'occupied' ? '$guests/$capacity Guests' : 'Cap: $capacity',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    if (status == 'occupied' && duration != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('$duration', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                        ],
                      ),
                    ],
                    if (amount != null && amount != 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.currency_rupee, size: 12, color: Colors.green.shade700),
                          Text(
                            '$amount',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TABLES LIST =====================
  Widget _tablesList(List tables) {
    final displayTables = tables.isEmpty ? _demoTables() : tables;
    final filtered = displayTables.where((t) {
      final s = (t['status'] ?? '').toString().toLowerCase();
      return _statusFilter == 'all' || s == _statusFilter;
    }).toList();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final t = filtered[i];
          final status = (t['status'] ?? 'available').toString().toLowerCase();
          final color = _statusColor(status);
          return ListTile(
            onTap: () => _showTableDetails(t),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'T${t['table_number'] ?? t['number'] ?? '?'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            title: Text('Table ${t['table_number'] ?? t['number'] ?? '—'}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Capacity: ${t['capacity'] ?? 4} • ${status.toUpperCase()}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            trailing: Icon(_statusIcon(status), color: color),
          );
        },
      ),
    );
  }

  // ===================== LEGEND =====================
  Widget _legendCard() {
    final legends = [
      ('Occupied', const Color(0xFF4CAF50), Icons.people),
      ('Available', const Color(0xFF2196F3), Icons.check_circle),
      ('Reserved', const Color(0xFFE67E22), Icons.event_seat),
      ('Cleaning', const Color(0xFF9C27B0), Icons.cleaning_services),
      ('Out of Service', Colors.red, Icons.block),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE67E22), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: legends.map((l) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: l.$2.withOpacity(0.15), shape: BoxShape.circle),
                          child: Icon(l.$3, size: 12, color: l.$2),
                        ),
                        const SizedBox(width: 6),
                        Text(l.$1, style: const TextStyle(fontSize: 11)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BOTTOM ACTION BAR =====================
  Widget _bottomActionBar(bool isMobile, List tables) {
    final occupiedCount = tables
        .where((t) => (t['status'] ?? '') == 'occupied' && t['active_session_id'] != null)
        .length;
    final hasOutstanding = tables.any((t) => (t['status'] ?? '') == 'occupied' && _asD(t['running_amount']) > 0);
    final canClean = tables.any((t) => (t['status'] ?? '') != 'available' && t['id'] != null);

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
            _bottomBtn(Icons.event_available, 'New Reservation', Colors.orange, _showReservationDialog),
            const SizedBox(width: 10),
            _bottomBtn(
              Icons.swap_horiz,
              _mergeMode ? 'Selecting ${_mergeSelectedTableIds.length}/2' : 'Merge Tables',
              Colors.blue,
              occupiedCount >= 2 ? _toggleMergeMode : null,
            ),
            const SizedBox(width: 10),
            _bottomBtn(Icons.call_split, 'Split Bill', Colors.purple, hasOutstanding ? _showSplitBillDialog : null),
            const SizedBox(width: 10),
            _bottomBtn(Icons.cleaning_services, 'Mark Cleaning', Colors.deepPurple, canClean ? _showMarkCleaningDialog : null),
            const SizedBox(width: 10),
            _bottomBtn(Icons.print, 'Print Layout', Colors.green, _showPrintLayoutDialog),
          ],
        ),
      ),
    );
  }

  Widget _bottomBtn(IconData icon, String label, Color color, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? color.withOpacity(0.3) : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? color : Colors.grey.shade400, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: enabled ? color : Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ===================== DETAILS BOTTOM SHEET =====================
  void _showTableDetails(dynamic table) {
    final status = (table['status'] ?? 'available').toString().toLowerCase();
    final color = _statusColor(status);
    final number = table['table_number'] ?? table['number'] ?? '—';
    final capacity = table['capacity'] ?? 4;
    final guests = table['current_guests'] ?? table['guests'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'T$number',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Table $number', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'available' && table['id'] != null)
                  IconButton(
                    tooltip: 'Delete table',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteTable(table);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
            const Divider(height: 32),
            _detailRow(Icons.people, 'Capacity', '$capacity Guests'),
            if (status == 'occupied') ...[
              _detailRow(Icons.person, 'Currently Seated', '$guests Guests'),
              _detailRow(Icons.access_time, 'Occupied Since', '${table['occupied_since'] ?? '45 mins ago'}'),
              _detailRow(Icons.receipt, 'Current Bill', '₹ ${table['current_amount'] ?? 850}'),
              _detailRow(Icons.person_outline, 'Server', '${table['server_name'] ?? 'Rahul'}'),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showQrDialog(table);
                    },
                    icon: Icon(Icons.qr_code_2, color: color),
                    label: Text('QR Code', style: TextStyle(color: color)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Managing Table $number'), backgroundColor: color),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Manage', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  // ===================== DELETE TABLE =====================
  Future<void> _deleteTable(dynamic table) async {
    final tableId = table['id'] as int?;
    if (tableId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Table ${table['table_number']} delete karna hai? Ye action undo nahi ho sakta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _api.deleteTable(tableId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true ? 'Table delete ho gayi' : (result['message']?.toString() ?? 'Delete fail ho gaya')),
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
    ));
    if (result['success'] == true) await context.read<AdminProvider>().loadTables();
  }

  // ===================== QR CODE DIALOG =====================
  String _qrValueFor(dynamic table) {
    final number = table['table_number'] ?? table['number'] ?? '';
    final restaurantId = context.read<AdminProvider>().restaurantId;
    final base = _qrBaseUrl.trim().isEmpty ? 'http://localhost:PORT' : _qrBaseUrl.trim();
    final separator = base.contains('?') ? '&' : '?';
    return '$base$separator' 'table=$number&restaurant=$restaurantId';
  }

  void _showQrDialog(dynamic table) {
    final number = table['table_number'] ?? table['number'] ?? '—';
    final urlCtrl = TextEditingController(text: _qrBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final qrValue = _qrBaseUrl.trim().isEmpty
              ? null
              : _qrValueFor(table);
          return AlertDialog(
            title: Text('Table $number ka QR Code'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ye QR sirf Table $number ka apna hai \u2014 customer scan karke seedha isi table par order karega.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ordering app link (ek baar set karo, sab tables ke liye)',
                      hintText: 'https://order.yourrestaurant.com',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) async {
                      setDialogState(() => _qrBaseUrl = value);
                      await _saveQrBaseUrl(value);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (qrValue == null)
                    Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Text(
                        'Ordering app ka link ek baar daalo, phir har table ka apna QR yahan ban jayega',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  else ...[
                    QrImageView(
                      data: qrValue,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(qrValue, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              if (qrValue != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: qrValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Link'),
                ),
            ],
          );
        },
      ),
    );
  }

  // ===================== RESERVATIONS (with table merge suggestion) =====================
  double _asD(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  /// Best combination of AVAILABLE tables covering [guestCount] seats with minimal wasted capacity.
  /// Prefers a single table if one fits; otherwise searches combos (capped at 5 tables) and returns
  /// null if no combination can seat the party.
  List<dynamic>? _bestTableCombo(List<dynamic> tables, int guestCount) {
    if (guestCount <= 0) return null;
    final available = tables.where((t) => (t['status'] ?? '') == 'available' && t['id'] != null).toList();
    if (available.isEmpty) return null;

    int cap(dynamic t) => (t['capacity'] as num?)?.toInt() ?? 0;

    final singleFits = available.where((t) => cap(t) >= guestCount).toList()
      ..sort((a, b) => cap(a).compareTo(cap(b)));
    if (singleFits.isNotEmpty) return [singleFits.first];

    final maxCombo = available.length < 5 ? available.length : 5;
    List<dynamic>? best;
    var bestWaste = 1 << 30;

    void search(int start, List<dynamic> chosen, int sum) {
      if (chosen.isNotEmpty && sum >= guestCount) {
        final waste = sum - guestCount;
        if (waste < bestWaste || (waste == bestWaste && chosen.length < (best?.length ?? 1 << 30))) {
          bestWaste = waste;
          best = List.of(chosen);
        }
        return; // adding more tables only increases waste once target is met
      }
      if (chosen.length >= maxCombo) return;
      for (var i = start; i < available.length; i++) {
        chosen.add(available[i]);
        search(i + 1, chosen, sum + cap(available[i]));
        chosen.removeLast();
      }
    }

    search(0, [], 0);
    return best;
  }

  void _showReservationDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final guestsCtrl = TextEditingController(text: '2');
    final notesCtrl = TextEditingController();
    var selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    var submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final admin = context.read<AdminProvider>();
          final guestCount = int.tryParse(guestsCtrl.text.trim()) ?? 0;
          final combo = _bestTableCombo(admin.tables, guestCount);

          return AlertDialog(
            title: const Text('New Reservation'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Customer name', border: OutlineInputBorder(), isDense: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone', prefixText: '+91 ', border: OutlineInputBorder(), isDense: true),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: guestsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Number of guests', border: OutlineInputBorder(), isDense: true),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (date == null || !ctx.mounted) return;
                        final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(selectedDateTime));
                        if (time == null) return;
                        setDialogState(() => selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                      },
                      icon: const Icon(Icons.event),
                      label: Text(DateFormat('d MMM yyyy, hh:mm a').format(selectedDateTime)),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: combo == null ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: combo == null ? Colors.red.shade200 : Colors.green.shade200),
                      ),
                      child: Text(
                        guestCount <= 0
                            ? 'Guests ki sahi sankhya daalo'
                            : combo == null
                                ? 'Seats available nahi hain $guestCount guests ke liye'
                                : combo.length == 1
                                    ? 'Table ${combo.first['table_number']} assign hoga (capacity ${combo.first['capacity']})'
                                    : 'Tables ${combo.map((t) => t['table_number']).join(' + ')} merge honge (total capacity ${combo.fold<int>(0, (s, t) => s + ((t['capacity'] as num?)?.toInt() ?? 0))})',
                        style: TextStyle(
                          color: combo == null ? Colors.red.shade700 : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: submitting || combo == null || nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length != 10
                    ? null
                    : () async {
                        setDialogState(() => submitting = true);
                        final note = combo.length > 1
                            ? 'Merged: ${combo.map((t) => 'T${t['table_number']}').join(' + ')}. ${notesCtrl.text.trim()}'.trim()
                            : notesCtrl.text.trim();
                        var allOk = true;
                        for (final table in combo) {
                          final ok = await admin.createReservation({
                            'table_id': table['id'],
                            'customer_name': nameCtrl.text.trim(),
                            'phone': '+91${phoneCtrl.text.trim()}',
                            'guest_count': guestCount,
                            'reservation_at': selectedDateTime.toUtc().toIso8601String(),
                            'notes': note,
                          });
                          if (!ok) allOk = false;
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(allOk
                              ? 'Reservation booked for ${combo.map((t) => 'T${t['table_number']}').join(', ')}'
                              : 'Reservation partially failed, Reservations list check karo'),
                          backgroundColor: allOk ? Colors.green : Colors.red,
                        ));
                      },
                child: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Book Reservation'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===================== MERGE TABLES =====================
  void _toggleMergeMode() {
    setState(() {
      _mergeMode = !_mergeMode;
      _mergeSelectedTableIds.clear();
    });
    if (_mergeMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2 occupied tables select karo merge karne ke liye')),
      );
    }
  }

  void _onMergeTableTap(dynamic table) {
    final status = (table['status'] ?? '').toString();
    final sessionId = table['active_session_id'];
    final id = table['id'] as int?;
    if (status != 'occupied' || sessionId == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sirf active bill wali occupied tables select karo'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      if (_mergeSelectedTableIds.contains(id)) {
        _mergeSelectedTableIds.remove(id);
      } else if (_mergeSelectedTableIds.length < 2) {
        _mergeSelectedTableIds.add(id);
      }
    });
    if (_mergeSelectedTableIds.length == 2) _confirmMerge();
  }

  Future<void> _confirmMerge() async {
    final admin = context.read<AdminProvider>();
    final selected = admin.tables.where((t) => _mergeSelectedTableIds.contains(t['id'])).toList();
    if (selected.length != 2) return;
    final source = selected[0];
    final target = selected[1];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge Tables'),
        content: Text(
          'Table ${source['table_number']} ka bill Table ${target['table_number']} mein merge ho jayega. '
          'Table ${source['table_number']} available ho jayega. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Merge')),
        ],
      ),
    );
    if (confirmed != true) {
      setState(() => _mergeSelectedTableIds.clear());
      return;
    }

    final result = await _api.mergeTables(source['active_session_id'] as int, target['active_session_id'] as int);
    if (!mounted) return;
    setState(() {
      _mergeMode = false;
      _mergeSelectedTableIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true ? 'Tables merged successfully' : (result['message']?.toString() ?? 'Merge fail ho gaya')),
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
    ));
    if (result['success'] == true) await admin.loadTables();
  }

  // ===================== SPLIT BILL =====================
  void _showSplitBillDialog() {
    final admin = context.read<AdminProvider>();
    final occupiedWithBill = admin.tables
        .where((t) => (t['status'] ?? '') == 'occupied' && _asD(t['running_amount']) > 0 && t['active_session_id'] != null)
        .toList();
    if (occupiedWithBill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koi outstanding bill wali table nahi hai'), backgroundColor: Colors.red),
      );
      return;
    }

    dynamic selectedTable = occupiedWithBill.first;
    var ways = 2;
    var method = 'cash';
    var collecting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final outstanding = _asD(selectedTable['running_amount']);
          final share = outstanding <= 0 ? 0.0 : (outstanding / ways);
          return AlertDialog(
            title: const Text('Split Bill'),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<dynamic>(
                    initialValue: selectedTable,
                    decoration: const InputDecoration(labelText: 'Table', border: OutlineInputBorder(), isDense: true),
                    items: occupiedWithBill
                        .map((t) => DropdownMenuItem(value: t, child: Text('T${t['table_number']} \u2022 \u20b9${_asD(t['running_amount']).toStringAsFixed(0)} due')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedTable = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Split into: '),
                      IconButton(onPressed: ways > 2 ? () => setDialogState(() => ways--) : null, icon: const Icon(Icons.remove_circle_outline)),
                      Text('$ways ways', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(onPressed: ways < 8 ? () => setDialogState(() => ways++) : null, icon: const Icon(Icons.add_circle_outline)),
                    ],
                  ),
                  Text('Outstanding: \u20b9${outstanding.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('Har share: \u20b9${share.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'card', child: Text('Card')),
                    ],
                    onChanged: (v) => setDialogState(() => method = v ?? 'cash'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: collecting ? null : () => Navigator.pop(ctx), child: const Text('Close')),
              ElevatedButton(
                onPressed: collecting || outstanding <= 0
                    ? null
                    : () async {
                        setDialogState(() => collecting = true);
                        final sessionId = selectedTable['active_session_id'] as int;
                        final result = await _api.collectPayment(sessionId, share, method);
                        if (!ctx.mounted) return;
                        setDialogState(() => collecting = false);
                        if (result['success'] == true) {
                          await context.read<AdminProvider>().loadTables();
                          final refreshed = context.read<AdminProvider>().tables.firstWhere(
                                (t) => t['id'] == selectedTable['id'],
                                orElse: () => selectedTable,
                              );
                          if (_asD(refreshed['running_amount']) <= 0.01) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bill fully paid, table available ho gayi'), backgroundColor: Colors.green),
                            );
                          } else {
                            setDialogState(() => selectedTable = refreshed);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share collect ho gaya'), backgroundColor: Colors.green),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message']?.toString() ?? 'Payment fail ho gaya'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: collecting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Collect Share'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===================== CLEAN TABLE (pays outstanding bill first) =====================
  void _showMarkCleaningDialog() {
    final admin = context.read<AdminProvider>();
    final candidates = admin.tables.where((t) => (t['status'] ?? '') != 'available' && t['id'] != null).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saari tables already available hain')));
      return;
    }
    dynamic selected = candidates.first;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Mark Table Clean'),
            content: SizedBox(
              width: 320,
              child: DropdownButtonFormField<dynamic>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Table', border: OutlineInputBorder(), isDense: true),
                items: candidates.map((t) => DropdownMenuItem(value: t, child: Text('T${t['table_number']} \u2022 ${t['status']}'))).toList(),
                onChanged: (v) => setDialogState(() => selected = v),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _cleanTable(selected);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cleanTable(dynamic table) async {
    final outstanding = _asD(table['running_amount']);
    final sessionId = table['active_session_id'];
    final tableId = table['id'] as int?;
    if (tableId == null) return;

    if (sessionId != null && outstanding > 0.01) {
      _showPaymentDialog(table, onSettled: () async {
        await _api.updateTableStatus(tableId, 'available');
        await context.read<AdminProvider>().loadTables();
      });
      return;
    }

    final result = await _api.updateTableStatus(tableId, 'available');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true ? 'Table clean ho gayi' : (result['message']?.toString() ?? 'Update fail ho gaya')),
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
    ));
    if (result['success'] == true) await context.read<AdminProvider>().loadTables();
  }

  void _showPaymentDialog(dynamic table, {required Future<void> Function() onSettled}) {
    var method = 'cash';
    var paying = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final outstanding = _asD(table['running_amount']);
          return AlertDialog(
            title: Text('Settle Bill \u2014 Table ${table['table_number']}'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outstanding: \u20b9${outstanding.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: const InputDecoration(labelText: 'Payment method', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'card', child: Text('Card')),
                    ],
                    onChanged: (v) => setDialogState(() => method = v ?? 'cash'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: paying ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: paying
                    ? null
                    : () async {
                        setDialogState(() => paying = true);
                        final result = await _api.collectPayment(table['active_session_id'] as int, outstanding, method);
                        if (!ctx.mounted) return;
                        if (result['success'] == true) {
                          Navigator.pop(ctx);
                          await onSettled();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bill paid, table clean ho gayi'), backgroundColor: Colors.green),
                          );
                        } else {
                          setDialogState(() => paying = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message']?.toString() ?? 'Payment fail ho gaya'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: paying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Collect & Clean'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===================== PRINT LAYOUT =====================
  void _showPrintLayoutDialog() {
    final admin = context.read<AdminProvider>();
    final tables = admin.tables.isEmpty ? _demoTables() : admin.tables;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Table Layout \u2014 Print Preview'),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: tables.map<Widget>((t) {
                final status = (t['status'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('Table ${t['table_number']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      Text('Cap: ${t['capacity'] ?? '-'}'),
                      const SizedBox(width: 12),
                      Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: triggerBrowserPrint,
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  // ===================== ADD TABLE DIALOG =====================
  void _showAddTableDialog() {
    final numCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    String selectedFloor = 'Ground Floor';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.table_restaurant, color: Color(0xFFE67E22)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Add New Table', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: numCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Table Number',
                  prefixIcon: const Icon(Icons.tag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Capacity (Seats)',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedFloor,
                items: ['Ground Floor', 'First Floor', 'Rooftop', 'Outdoor']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => selectedFloor = v ?? 'Ground Floor',
                decoration: InputDecoration(
                  labelText: 'Floor',
                  prefixIcon: const Icon(Icons.layers),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Table added successfully'), backgroundColor: Colors.green),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22), foregroundColor: Colors.white),
                      child: const Text('Add Table'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== DEMO DATA (Fallback) =====================
  List<Map<String, dynamic>> _demoTables() {
    return [
      {'table_number': 1, 'status': 'occupied', 'capacity': 4, 'current_guests': 3, 'current_amount': 850, 'occupied_since': '45 mins'},
      {'table_number': 2, 'status': 'available', 'capacity': 2},
      {'table_number': 3, 'status': 'occupied', 'capacity': 6, 'current_guests': 5, 'current_amount': 1250, 'occupied_since': '1 hr 20 mins'},
      {'table_number': 4, 'status': 'reserved', 'capacity': 4},
      {'table_number': 5, 'status': 'cleaning', 'capacity': 2},
      {'table_number': 6, 'status': 'available', 'capacity': 8},
      {'table_number': 7, 'status': 'occupied', 'capacity': 4, 'current_guests': 4, 'current_amount': 620, 'occupied_since': '25 mins'},
      {'table_number': 8, 'status': 'available', 'capacity': 4},
      {'table_number': 9, 'status': 'occupied', 'capacity': 2, 'current_guests': 2, 'current_amount': 340, 'occupied_since': '15 mins'},
      {'table_number': 10, 'status': 'reserved', 'capacity': 6},
      {'table_number': 11, 'status': 'available', 'capacity': 4},
      {'table_number': 12, 'status': 'out_of_service', 'capacity': 4},
    ];
  }
}

class _StatCard {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  _StatCard(this.title, this.value, this.icon, this.color);
}