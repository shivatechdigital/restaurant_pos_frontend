import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../services/reception_api.dart';
import '../widgets/reception_sidebar.dart';
import '../widgets/reception_topbar.dart';

class ReceptionDashboard extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;
  final VoidCallback? onNavigateToTableMgmt;
  final void Function(dynamic table)? onNavigateToPos;
  final VoidCallback? onNavigateToReports;
  final VoidCallback? onNavigateToMenu;
  final VoidCallback? onNavigateToSettings;

  const ReceptionDashboard({
    super.key,
    required this.token,
    required this.receptionistName,
    required this.onLogout,
    this.onNavigateToTableMgmt,
    this.onNavigateToPos,
    this.onNavigateToReports,
    this.onNavigateToMenu,
    this.onNavigateToSettings,
  });

  @override
  State<ReceptionDashboard> createState() => _ReceptionDashboardState();
}

class _ReceptionDashboardState extends State<ReceptionDashboard> {
  late ReceptionApi _api;
  List<dynamic> _tables = [];
  bool _loading = true;
  String _activeFloor = 'First Floor';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _api = ReceptionApi(widget.token);
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final tables = await _api.getTables();
    if (!mounted) return;
    setState(() {
      _tables = tables.isNotEmpty ? tables : _demoTables();
      _loading = false;
    });
  }

  // Fallback demo data (image me jaisi)
  List<Map<String, dynamic>> _demoTables() {
    return [
      {'id': 1, 'table_number': 'T1', 'capacity': 4, 'status': 'available'},
      {'id': 2, 'table_number': 'T2', 'capacity': 4, 'status': 'occupied', 'guests': 4},
      {'id': 3, 'table_number': 'T3', 'capacity': 4, 'status': 'available'},
      {'id': 4, 'table_number': 'T4', 'capacity': 2, 'status': 'reserved'},
      {'id': 5, 'table_number': 'T5', 'capacity': 6, 'status': 'occupied', 'guests': 3},
      {'id': 6, 'table_number': 'T6', 'capacity': 4, 'status': 'available'},
      {'id': 7, 'table_number': 'T7', 'capacity': 4, 'status': 'available'},
      {'id': 8, 'table_number': 'T8', 'capacity': 4, 'status': 'cleaning'},
      {'id': 9, 'table_number': 'T9', 'capacity': 2, 'status': 'available'},
      {'id': 10, 'table_number': 'T10', 'capacity': 4, 'status': 'out_of_service'},
      {'id': 11, 'table_number': 'T11', 'capacity': 4, 'status': 'available'},
      {'id': 12, 'table_number': 'T12', 'capacity': 6, 'status': 'reserved'},
    ];
  }

  int _countByStatus(String status) => _tables
      .where((t) => (t['status'] ?? '').toString().toLowerCase() == status)
      .length;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1100;
    final isTablet = w >= 720 && w < 1100;
    final isMobile = w < 720;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.sidebarBg,
              child: ReceptionSidebar(
                activeLabel: 'Dashboard',
                onItemTap: (label) {
                  if (label == 'Table Management') {
                    widget.onNavigateToTableMgmt?.call();
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
                  activeLabel: 'Dashboard',
                  onItemTap: (label) {
                    if (label == 'Table Management') {
                      widget.onNavigateToTableMgmt?.call();
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
                    searchHint: 'Search tables, reservations, guests...',
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppTheme.brand),
                          )
                        : _buildBody(isMobile, isTablet, isDesktop),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _greetingHeader(isMobile),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _leftColumn(isMobile)),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: _rightColumn()),
                  ],
                )
              : Column(children: [
                  _leftColumn(isMobile),
                  const SizedBox(height: 16),
                  _rightColumn(),
                ]),
        ],
      ),
    );
  }

  Widget _greetingHeader(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '$_greeting, ${widget.receptionistName.split(' ').first}!',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 26)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Manage tables, reservations and walk-in guests smoothly.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // LEFT COLUMN
  Widget _leftColumn(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statsRow(),
        const SizedBox(height: 16),
        _floorTabsRow(),
        const SizedBox(height: 14),
        _floorPlanCard(isMobile),
      ],
    );
  }

  Widget _statsRow() {
    final total = _tables.length;
    final available = _countByStatus('available');
    final occupied = _countByStatus('occupied');
    final reserved = _countByStatus('reserved');

    final stats = [
      _StatData('Total Tables', '$total', _activeFloor, Icons.table_bar_rounded, AppTheme.brand, null),
      _StatData('Available', '$available', total == 0 ? '' : '${(available / total * 100).round()}%', Icons.chair_rounded, AppTheme.statusAvailable, null),
      _StatData('Occupied', '$occupied', total == 0 ? '' : '${(occupied / total * 100).round()}%', Icons.people_rounded, AppTheme.statusOccupied, null),
      _StatData('Reserved', '$reserved', total == 0 ? '' : '${(reserved / total * 100).round()}%', Icons.event_seat_rounded, AppTheme.statusReserved, null),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w < 500 ? 2 : 4;
      final itemWidth = (w - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: stats
            .map((s) => SizedBox(width: itemWidth, child: _statCard(s)))
            .toList(),
      );
    });
  }

  Widget _statCard(_StatData s) {
    return Container(
        height: 80,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(s.icon, color: s.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        s.value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (s.subtitle != null && s.subtitle!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          s.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: s.color,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                if (s.title == 'Total Tables')
                  Text(_activeFloor,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorTabsRow() {
    final floors = ['First Floor', 'Ground Floor', 'Rooftop'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...floors.map((f) {
            final active = _activeFloor == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _activeFloor = f),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.brand : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: AppTheme.brand.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.grid_view_rounded,
                          size: 15,
                          color: active ? Colors.white : Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text(f,
                          style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : Colors.grey.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Opening Table Management...'),
                    backgroundColor: AppTheme.brand,
                    duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: const [
                  Icon(Icons.list_alt_rounded, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('View Table List',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorPlanCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E9D3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Floor header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_activeFloor (${_tables.length} Tables)',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          // Tables grid
          LayoutBuilder(builder: (context, cons) {
            final cols = cons.maxWidth < 500 ? 3 : cons.maxWidth < 800 ? 4 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 1.15,
              ),
              itemCount: _tables.length,
              itemBuilder: (_, i) => _tableTile(_tables[i]),
            );
          }),
          const SizedBox(height: 20),
          // Entrance
          Column(
            children: [
              const Icon(Icons.arrow_upward_rounded,
                  color: AppTheme.brand, size: 20),
              Text('Entrance',
                  style: TextStyle(
                      color: AppTheme.brand,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableTile(dynamic table) {
    final status = (table['status'] ?? 'available').toString().toLowerCase();
    final number = table['table_number']?.toString() ?? '?';
    final capacity = table['capacity'] ?? 4;
    final guests = table['guests'];

    Color color;
    IconData? topIcon;
    switch (status) {
      case 'occupied':
        color = AppTheme.statusOccupied;
        topIcon = Icons.people;
        break;
      case 'reserved':
        color = AppTheme.statusReserved;
        topIcon = Icons.access_time;
        break;
      case 'cleaning':
        color = AppTheme.statusCleaning;
        topIcon = Icons.cleaning_services;
        break;
      case 'out_of_service':
      case 'out-of-service':
        color = AppTheme.statusOutOfService;
        topIcon = Icons.build;
        break;
      default:
        color = AppTheme.statusAvailable;
    }

    return InkWell(
      onTap: () => _showTableInfo(table),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(number.replaceAll('T', 'T'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('$capacity Seats',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (topIcon != null && status != 'available')
            Positioned(
              top: -6,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(topIcon, color: Colors.white, size: 12),
                    if (guests != null) ...[
                      const SizedBox(width: 3),
                      Text('$guests',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTableInfo(dynamic table) {
    final status = (table['status'] ?? 'available').toString();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_restaurant,
                      color: AppTheme.brand, size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Table ${table['table_number']}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                        'Capacity: ${table['capacity']} • ${status.toUpperCase()}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNavigateToPos?.call(table);
                },
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text('Open POS / Take Order',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // RIGHT COLUMN
  Widget _rightColumn() {
    return Column(
      children: [
        _newReservationBtn(),
        const SizedBox(height: 14),
        _tableStatusList(),
        const SizedBox(height: 14),
        _quickActionsCard(),
        const SizedBox(height: 14),
        _todaysActivity(),
      ],
    );
  }

  Widget _newReservationBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('New Reservation dialog coming soon...'),
                backgroundColor: AppTheme.brand),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text('New Reservation',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brand,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _tableStatusList() {
    final items = [
      ('Available', _countByStatus('available'), AppTheme.statusAvailable),
      ('Occupied', _countByStatus('occupied'), AppTheme.statusOccupied),
      ('Reserved', _countByStatus('reserved'), AppTheme.statusReserved),
      ('Cleaning', _countByStatus('cleaning'), AppTheme.statusCleaning),
      ('Out of Service', _countByStatus('out_of_service'), AppTheme.statusOutOfService),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Table Status',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: item.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item.$1,
                            style: const TextStyle(fontSize: 13))),
                    Text('${item.$2}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _quickActionsCard() {
    final actions = [
      ('Walk-in Guest', Icons.person_add, Colors.blue),
      ('New Reservation', Icons.event_available, Colors.green),
      ('Merge Tables', Icons.merge, Colors.orange),
      ('Block Table', Icons.block, Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
            ),
            itemCount: actions.length,
            itemBuilder: (_, i) {
              final a = actions[i];
              return InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${a.$1} feature coming soon'),
                        backgroundColor: a.$3,
                        duration: const Duration(seconds: 1)),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: a.$3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a.$2, color: a.$3, size: 22),
                      const SizedBox(height: 4),
                      Text(a.$1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: a.$3,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _todaysActivity() {
    final activities = [
      ('12:30 PM', 'Walk-in seated at Table T2', '(4 Guests)',
          Icons.person_add, Colors.blue),
      ('11:45 AM', 'Table T4 reserved by Rahul Sharma', '(2 Guests)',
          Icons.event_available, Colors.purple),
      ('11:20 AM', 'Table T8 marked for cleaning', '',
          Icons.cleaning_services, Colors.orange),
      ('10:15 AM', 'Table T5 new order added', '(3 Items)',
          Icons.shopping_cart, AppTheme.brand),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Activity",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {},
                child: const Text('View All',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activities.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text(a.$1,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: a.$5.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: Icon(a.$4, size: 14, color: a.$5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.$2,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          if (a.$3.isNotEmpty)
                            Text(a.$3,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _StatData {
  final String title, value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  _StatData(this.title, this.value, this.subtitle, this.icon, this.color, this.onTap);
}