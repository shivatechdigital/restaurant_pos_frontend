import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_theme.dart';
import '../services/reception_api.dart';
import '../widgets/reception_sidebar.dart';
import '../widgets/reception_topbar.dart';
import 'reception_pos_screen.dart';

class ReceptionTableMgmt extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;
  final VoidCallback? onNavigateToDashboard;
  final void Function(dynamic table)? onNavigateToPos;
  final VoidCallback? onNavigateToReports;
  final VoidCallback? onNavigateToMenu;
  final VoidCallback? onNavigateToSettings;

  const ReceptionTableMgmt({
    super.key,
    required this.token,
    required this.receptionistName,
    required this.onLogout,
    this.onNavigateToDashboard,
    this.onNavigateToPos,
    this.onNavigateToReports,
    this.onNavigateToMenu,
    this.onNavigateToSettings,
  });

  @override
  State<ReceptionTableMgmt> createState() => _ReceptionTableMgmtState();
}

class _ReceptionTableMgmtState extends State<ReceptionTableMgmt>
    with SingleTickerProviderStateMixin {
  late ReceptionApi _api;
  List<dynamic> _tables = [];
  bool _loading = true;
  String _statusFilter = 'all';
  String _viewMode = 'grid'; // grid or list
  String _floorFilter = 'All Floors';
  String _searchQuery = '';

  Timer? _refreshTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _api = ReceptionApi(widget.token);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadTables();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadTables(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadTables({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final tables = await _api.getTables();
    if (!mounted) return;
    setState(() {
      _tables = tables.isNotEmpty ? tables : _demoTables();
      _loading = false;
    });
  }

  // ===================== HELPERS =====================
  double _amount(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  int _countByStatus(String status) {
    if (status == 'active')
      return _tables.where((t) => t['active_session_id'] != null).length;
    return _tables
        .where((t) => (t['status'] ?? '').toString().toLowerCase() == status)
        .length;
  }

  Color _statusColor(String status, bool isActive, bool hasKot) {
    if (isActive && hasKot)
      return const Color(0xFFFBC02D); // Yellow/Orange for running KOT
    if (isActive)
      return const Color(0xFF29B6F6); // Light Blue for active but no new KOT

    switch (status.toLowerCase()) {
      case 'occupied':
        return AppTheme.statusOccupied;
      case 'reserved':
        return AppTheme.statusReserved;
      case 'available':
        return AppTheme.statusAvailable;
      case 'cleaning':
        return AppTheme.statusCleaning;
      default:
        return AppTheme.statusOutOfService;
    }
  }

  // Fallback Data
  List<Map<String, dynamic>> _demoTables() => [
    {'id': 1, 'table_number': 'T1', 'capacity': 4, 'status': 'available'},
    {
      'id': 2,
      'table_number': 'T2',
      'capacity': 4,
      'status': 'occupied',
      'active_session_id': 's1',
      'has_running_kot': true,
      'running_amount': 850,
    },
    {'id': 3, 'table_number': 'T3', 'capacity': 4, 'status': 'available'},
  ];

  // ===================== MAIN BUILD =====================
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1100;
    final isMobile = w < 720;

    final filteredTables = _tables.where((t) {
      final s = (t['status'] ?? '').toString().toLowerCase();
      final isActive = t['active_session_id'] != null;

      bool statusMatch =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && isActive) ||
          (!isActive && s == _statusFilter);

      bool searchMatch =
          _searchQuery.isEmpty ||
          (t['table_number']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      return statusMatch && searchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.sidebarBg,
              child: ReceptionSidebar(
                activeLabel: 'Table Management',
                onItemTap: (label) {
                  if (label == 'Dashboard') {
                    widget.onNavigateToDashboard?.call();
                  } else if (label == 'POS / Orders') {
                    widget.onNavigateToPos?.call(null);
                  } else if (label == 'Reports') {
                    widget.onNavigateToReports?.call();
                  } else if (label == 'Menu Management') {
                    widget.onNavigateToMenu?.call();
                  } else if (label == 'Settings') {
                    widget.onNavigateToSettings?.call();
                  }
                },
              ),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              SizedBox(
                width: 230,
                child: ReceptionSidebar(
                  activeLabel: 'Table Management',
                  onItemTap: (label) {
                    if (label == 'Dashboard') {
                      widget.onNavigateToDashboard?.call();
                    } else if (label == 'POS / Orders') {
                      widget.onNavigateToPos?.call(null);
                    } else if (label == 'Reports') {
                      widget.onNavigateToReports?.call();
                    } else if (label == 'Menu Management') {
                      widget.onNavigateToMenu?.call();
                    } else if (label == 'Settings') {
                      widget.onNavigateToSettings?.call();
                    }
                  },
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  ReceptionTopBar(
                    receptionistName: widget.receptionistName,
                    onLogout: widget.onLogout,
                    searchHint: 'Search table number...',
                    onSearch: (v) => setState(() => _searchQuery = v),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.brand,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 12 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _heroBanner(),
                                const SizedBox(height: 20),
                                _quickStats(),
                                const SizedBox(height: 20),
                                _controlsRow(isMobile),
                                const SizedBox(height: 16),
                                _floorTabs(),
                                const SizedBox(height: 16),
                                _viewMode == 'grid'
                                    ? _tablesGrid(filteredTables, w)
                                    : _tablesList(filteredTables),
                                const SizedBox(height: 20),
                              ],
                            ),
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

  // ===================== WIDGETS =====================
  Widget _heroBanner() {
    final total = _tables.length;
    final active = _countByStatus('active');
    final available = total - active;
    final rate = total == 0 ? 0.0 : (active / total * 100);

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
          BoxShadow(
            color: const Color(0xFF8B4513).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
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
                      child: const Icon(
                        Icons.table_restaurant,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Live Floor Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage tables, view running orders and settle bills in real-time.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _heroChip('$available Free', Colors.greenAccent),
                    const SizedBox(width: 8),
                    _heroChip('$active Running', Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
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
                      CircularProgressIndicator(
                        value: rate / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.greenAccent,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${rate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Occupied',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$total Total Tables',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _quickStats() {
    final stats = [
      (
        'Available',
        _countByStatus('available'),
        Icons.check_circle,
        AppTheme.statusAvailable,
      ),
      (
        'Running',
        _countByStatus('active'),
        Icons.receipt_long,
        const Color(0xFFFBC02D),
      ),
      (
        'Reserved',
        _countByStatus('reserved'),
        Icons.event_seat,
        AppTheme.statusReserved,
      ),
      (
        'Cleaning',
        _countByStatus('cleaning'),
        Icons.cleaning_services,
        AppTheme.statusCleaning,
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats
            .map(
              (s) => Container(
                width: 155,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: s.$4.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: s.$4.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(s.$3, color: s.$4, size: 20),
                        ),
                        const Spacer(),
                        Text(
                          '${s.$2}',
                          style: TextStyle(
                            color: s.$4,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.$1,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _controlsRow(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
              _filterChip('Available', 'available'),
              _filterChip('Running', 'active'),
              _filterChip('Reserved', 'reserved'),
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
            color: active ? AppTheme.brand : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade700,
              fontSize: 11,
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
          color: active ? AppTheme.brand : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.grey.shade700,
          size: 16,
        ),
      ),
    );
  }

  Widget _floorTabs() {
    final floors = ['All Floors', 'Ground Floor', 'First Floor', 'Rooftop'];
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? Colors.black : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tablesGrid(List tables, double w) {
    if (tables.isEmpty) return _emptyState();
    int cols = w >= 1400
        ? 6
        : w >= 1100
        ? 5
        : w >= 800
        ? 4
        : w >= 500
        ? 3
        : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tables.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) => _tableCard(tables[i]),
    );
  }

  Widget _tablesList(List tables) {
    if (tables.isEmpty) return _emptyState();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tables.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final t = tables[i];
          final isActive = t['active_session_id'] != null;
          final hasKot = t['has_running_kot'] == true;
          final color = _statusColor(
            t['status']?.toString() ?? '',
            isActive,
            hasKot,
          );
          return ListTile(
            onTap: () => _handleTableClick(t),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                isActive ? Icons.receipt_long : Icons.table_restaurant,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              'Table ${t['table_number']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isActive
                  ? 'Running Bill: ₹${_amount(t['running_amount']).toStringAsFixed(0)}'
                  : 'Available',
              style: TextStyle(
                color: isActive ? Colors.orange.shade700 : Colors.green,
                fontSize: 12,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.table_bar, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No tables found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'Try changing your filters',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _tableCard(dynamic table) {
    final isActive = table['active_session_id'] != null;
    final hasKot = table['has_running_kot'] == true;
    final status = (table['status'] ?? 'available').toString().toLowerCase();
    final color = _statusColor(status, isActive, hasKot);

    final started = DateTime.tryParse(
      table['session_started_at']?.toString() ?? '',
    );
    final minutes = started == null
        ? 0
        : DateTime.now().difference(started.toLocal()).inMinutes.clamp(0, 999);

    return InkWell(
      onTap: () => _handleTableClick(table),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(isActive ? 0.5 : 0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'T${table['table_number']}',
                    style: TextStyle(
                      color: color.withOpacity(0.8).withBlue(50).withRed(50),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  if (isActive)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(
                            0.5 + _pulseController.value * 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive && hasKot
                          ? Icons.room_service
                          : (isActive
                                ? Icons.receipt_long
                                : Icons.check_circle_outline),
                      color: color,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    if (isActive) ...[
                      Text(
                        '₹${_amount(table['running_amount']).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hasKot ? 'KOT' : 'Served'} • ${minutes}m',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cap: ${table['capacity']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
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

  // ===================== LOGIC =====================

  void _handleTableClick(dynamic table) {
    final isActive = table['active_session_id'] != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.brandLight,
                  child: const Icon(
                    Icons.table_restaurant,
                    color: AppTheme.brand,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table ${table['table_number']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isActive ? 'Running Order' : 'Available',
                      style: TextStyle(
                        color: isActive ? Colors.orange.shade700 : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (isActive) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showBill(table); // Purana View Bill Logic
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('View Bill'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.brand),
                        foregroundColor: AppTheme.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (widget.onNavigateToPos != null) {
                        widget.onNavigateToPos!(table);
                        return;
                      }
                      if (mounted) _loadTables();
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text(
                      isActive ? 'Add More Items' : 'Open POS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tumhara original Bill Settle wala Logic yahan integrate kiya gaya hai
  Future<void> _showBill(dynamic table) async {
    final sessionId = table['active_session_id'];
    if (sessionId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: AppTheme.brand)),
    );

    final billData = await _api.getBill(sessionId);
    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (billData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill load nahi hua'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final items = billData['items'] as List? ?? [];
    final summary = billData['summary'] as Map<String, dynamic>;
    final outstanding = _amount(summary['outstanding_amount']);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: .8,
        minChildSize: .45,
        maxChildSize: .95,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table ${table['table_number']} Bill',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '₹${outstanding.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brand,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            if ((billData['orders'] as List? ?? []).isNotEmpty)
              ...(billData['orders'] as List).expand(
                (order) => [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(
                      '${order['customer_name'] ?? 'Customer'}  ${order['customer_phone'] ?? ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...(order['items'] as List? ?? []).map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['item_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item['quantity']} × ₹${_amount(item['unit_price']).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '₹${_amount(item['total_price']).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['item_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${item['quantity']} × ₹${_amount(item['unit_price']).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '₹${_amount(item['total_price']).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 30),
            _billRow('Subtotal', summary['subtotal']),
            _billRow('GST', summary['total_gst']),
            if (_amount(summary['paid_amount']) > 0)
              _billRow('Already paid', -_amount(summary['paid_amount'])),
            const Divider(),
            _billRow('Outstanding', outstanding, bold: true),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: outstanding <= 0
                      ? null
                      : () => _settleCash(ctx, sessionId, outstanding),
                  icon: const Icon(Icons.payments, color: Colors.white),
                  label: Text(
                    'Cash ₹${outstanding.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: outstanding <= 0
                      ? null
                      : () => _settleCash(
                          ctx,
                          sessionId,
                          outstanding,
                          method: 'card',
                        ),
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Card terminal'),
                ),
                OutlinedButton.icon(
                  onPressed: outstanding <= 0
                      ? null
                      : () => _showRazorpayQr(ctx, sessionId, outstanding),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Pay online QR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            '₹${_amount(value).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _settleCash(
    BuildContext sheetContext,
    dynamic sessionId,
    double amount, {
    String method = 'cash',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          method == 'cash' ? 'Confirm Cash Payment' : 'Confirm Card Payment',
        ),
        content: Text(
          method == 'cash'
              ? 'Receive ₹${amount.toStringAsFixed(2)} cash for this table?'
              : 'Confirm ₹${amount.toStringAsFixed(2)} was approved on the card terminal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brand),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: AppTheme.brand)),
    );

    final result = await _api.cashPayment(sessionId, amount, method: method);
    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (result['success'] == true) {
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      await _loadTables();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              method == 'cash'
                  ? 'Cash received. Table is now available.'
                  : 'Card payment recorded. Table is now available.',
            ),
            backgroundColor: Colors.green,
          ),
        );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRazorpayQr(
    BuildContext sheetContext,
    dynamic sessionId,
    double amount,
  ) async {
    final result = await _api.createSessionQr(sessionId);
    if (!mounted) return;
    if (result['success'] != true || result['data']?['image_url'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Razorpay QR could not be created',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final settled = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReceptionQrPaymentDialog(
        api: _api,
        sessionId: sessionId,
        imageUrl: result['data']['image_url'].toString(),
        amount: amount,
      ),
    );
    if (settled == true && sheetContext.mounted) {
      Navigator.pop(sheetContext);
      await _loadTables();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Razorpay payment confirmed. Table is now available.',
            ),
            backgroundColor: Colors.green,
          ),
        );
    }
  }
}

class ReceptionQrPaymentDialog extends StatefulWidget {
  final ReceptionApi api;
  final dynamic sessionId;
  final String imageUrl;
  final double amount;

  const ReceptionQrPaymentDialog({
    super.key,
    required this.api,
    required this.sessionId,
    required this.imageUrl,
    required this.amount,
  });

  @override
  State<ReceptionQrPaymentDialog> createState() =>
      _ReceptionQrPaymentDialogState();
}

class _ReceptionQrPaymentDialogState extends State<ReceptionQrPaymentDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkPayment());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkPayment() async {
    final result = await widget.api.getPaymentStatus(widget.sessionId);
    if (!mounted || result['success'] != true) return;
    final payments = result['data'] as List? ?? [];
    final paid = payments.any(
      (payment) =>
          payment['razorpay_qr_code_id'] != null &&
          payment['status'] == 'success',
    );
    if (paid) {
      _timer?.cancel();
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pay with Razorpay'),
    content: SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Scan to pay ₹${widget.amount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          Image.network(
            widget.imageUrl,
            width: 240,
            height: 240,
            errorBuilder: (_, _, _) => const Text('QR could not be displayed'),
          ),
          const Text(
            'Waiting for payment confirmation',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Close'),
      ),
    ],
  );
}
