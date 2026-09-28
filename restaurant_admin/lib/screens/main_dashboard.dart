import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import 'menu_management_screen.dart';
import 'table_management_screen.dart';
import 'orders_screen.dart';
import 'staff_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'inventory_requests_screen.dart';
import 'pos_counter_screen.dart';
import 'coupons_screen.dart';
import 'customers_screen.dart';
import 'fulfillment_screen.dart';
import 'bill_management_screen.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/admin_top_bar.dart';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'dart:async';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  late Timer _timer;
  String currentTime = '';
  String currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final admin = context.read<AdminProvider>();
    await Future.wait([
      admin.loadDashboard(),
      admin.loadTables(),
      admin.loadOrders(),
      admin.loadLowStock(),
    ]);
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm a').format(now);
      currentDate = DateFormat('EEEE, d MMM yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static const double _tabletBreakpoint = 700;
  static const double _desktopBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < _tabletBreakpoint;
        return Scaffold(
          drawer: isMobile
              ? Drawer(
                  child: Container(
                    color: const Color(0xFF2D2D2D),
                    child: const SafeArea(
                      child: AppSidebar(activeLabel: 'Dashboard'),
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              // Sidebar becomes a Drawer on mobile instead
              if (!isMobile) _buildSidebar(),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(
                      isMobile: isMobile,
                      onMenuPressed: isMobile
                          ? () => Scaffold.of(context).openDrawer()
                          : null,
                      title: 'Dashboard',
                    ),
                    // Dashboard Content
                    Expanded(
                      child: Consumer<AdminProvider>(
                        builder: (context, admin, _) {
                          if (admin.isLoading && admin.dashboard == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: _loadAll,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(isMobile ? 12 : 20),
                              child: Column(
                                children: [
                                  // Welcome Banner
                                  _buildWelcomeBanner(isMobile: isMobile),
                                  SizedBox(height: isMobile ? 12 : 20),
                                  // Stats Cards
                                  _buildStatsCards(width, admin.dashboard),
                                  SizedBox(height: isMobile ? 12 : 20),
                                  // Middle Section - Table Status, Today's Sales, Popular Dishes
                                  _buildMiddleSection(width, admin),
                                  SizedBox(height: isMobile ? 12 : 20),
                                  // Bottom Section - Recent Orders, Inventory, Quick Actions
                                  _buildBottomSection(width, admin),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar() {
    return const CollapsibleSidebar(activeLabel: 'Dashboard');
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar({required bool isMobile}) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          // Search Bar
          Expanded(
            flex: 3,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: isMobile
                            ? 'Search...'
                            : 'Search dishes, orders, customers...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isMobile) const Spacer(flex: 2),
          // Branch Selector
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pet Pooja - Main Branch',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ),
          SizedBox(width: isMobile ? 8 : 15),
          // Notifications
          Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 26),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isMobile ? 8 : 15),
          // Profile
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE67E22),
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Restaurant Owner',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==================== WELCOME BANNER ====================
  Widget _buildWelcomeBanner({required bool isMobile}) {
    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Welcome Back, Admin! ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('👋', style: TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Good food. Better business. Let\'s make today amazing!',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          '"Serving Happiness Everyday"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green.shade300,
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );

    final dateTimeBlock = Container(
      width: isMobile ? double.infinity : 200,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isMobile
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            currentDate,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            currentTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('☀️ ', style: TextStyle(fontSize: 14)),
              const Text(
                '28°C, Noida, India',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFFA0522D), Color(0xFF6B3410)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textBlock,
                  const SizedBox(height: 16),
                  dateTimeBlock,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: textBlock),
                  dateTimeBlock,
                ],
              ),
      ),
    );
  }

  // ==================== STATS CARDS ====================
  Widget _buildStatsCards(double width, Map<String, dynamic>? dash) {
    final revenue = dash?['revenue'] as Map<String, dynamic>?;
    final totalOrders = revenue?['total_orders'] ?? 0;
    final totalRevenue = _asDouble(revenue?['total']);
    final activeOrders = dash?['active_orders'] ?? 0;
    final avgOrder = _asDouble(revenue?['avg_order_value']);

    final cards = [
      _buildStatCard(
        icon: Icons.shopping_bag,
        iconBgColor: const Color(0xFFFF6B35),
        title: 'Total Orders',
        value: '$totalOrders',
        change: 'Today',
        changeColor: Colors.green,
        subtitle: 'orders placed',
      ),
      _buildStatCard(
        icon: Icons.currency_rupee,
        iconBgColor: const Color(0xFF4CAF50),
        title: "Today's Revenue",
        value: '₹ ${totalRevenue.toStringAsFixed(0)}',
        change: 'Live',
        changeColor: Colors.green,
        subtitle: 'total sales',
      ),
      _buildStatCard(
        icon: Icons.local_fire_department,
        iconBgColor: const Color(0xFF2196F3),
        title: 'Active Orders',
        value: '$activeOrders',
        change: 'Now',
        changeColor: Colors.blue,
        subtitle: 'in progress',
      ),
      _buildStatCard(
        icon: Icons.receipt_long,
        iconBgColor: const Color(0xFFE67E22),
        title: 'Average Bill',
        value: '₹ ${avgOrder.toStringAsFixed(0)}',
        change: 'Today',
        changeColor: Colors.green,
        subtitle: 'per order',
      ),
    ];

    final columns = width < 700 ? 1 : (width < 1100 ? 2 : 4);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      childAspectRatio: columns == 1 ? 2.8 : (columns == 2 ? 2.4 : 1.7),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: cards,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconBgColor, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      change,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MIDDLE SECTION ====================
  Widget _buildMiddleSection(double width, AdminProvider admin) {
    final tableStatus = _buildTableStatus(admin.tables);
    final todaysSales = _buildTodaysSales(admin.dashboard);
    final popularDishes = _buildPopularDishes(admin.topItems);

    if (width < _desktopBreakpoint) {
      return Column(
        children: [
          tableStatus,
          const SizedBox(height: 15),
          todaysSales,
          const SizedBox(height: 15),
          popularDishes,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Status
        Expanded(flex: 2, child: tableStatus),
        const SizedBox(width: 15),
        // Today's Sales Chart
        Expanded(flex: 3, child: todaysSales),
        const SizedBox(width: 15),
        // Popular Dishes
        Expanded(flex: 2, child: popularDishes),
      ],
    );
  }

  Widget _buildTableStatus(List<dynamic> tables) {
    final occupied = tables.where((t) => t['status'] == 'occupied').length;
    final available = tables.where((t) => t['status'] == 'available').length;
    final reserved = tables.where((t) => t['status'] == 'reserved').length;
    final cleaning = tables.where((t) => t['status'] == 'cleaning').length;

    Color chipColor(String status) {
      switch (status) {
        case 'occupied':
          return const Color(0xFF4CAF50);
        case 'reserved':
          return const Color(0xFFE67E22);
        case 'cleaning':
          return Colors.grey.shade400;
        default:
          return Colors.grey.shade300;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Table Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TableManagementScreen(),
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Status summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTableStatusItem(
                '$occupied',
                'Occupied',
                const Color(0xFF4CAF50),
              ),
              _buildTableStatusItem('$available', 'Available', Colors.grey),
              _buildTableStatusItem(
                '$reserved',
                'Reserved',
                const Color(0xFFE67E22),
              ),
              _buildTableStatusItem(
                '$cleaning',
                'Cleaning',
                Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tables.isEmpty)
            const Text(
              'No tables configured yet',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tables.map((t) {
                final status = t['status']?.toString() ?? 'available';
                return _buildTableChip(
                  '${t['table_number']}',
                  chipColor(status),
                  isLight: status == 'available',
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTableStatusItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTableChip(String label, Color color, {bool isLight = false}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isLight ? Colors.grey.shade200 : color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isLight ? Colors.grey.shade700 : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysSales(Map<String, dynamic>? dash) {
    final hourly = (dash?['hourly_sales'] as List?) ?? [];
    final revenue = dash?['revenue'] as Map<String, dynamic>?;
    final totalRevenue = _asDouble(revenue?['total']);
    final totalOrders = revenue?['total_orders'] ?? 0;
    final avgOrder = _asDouble(revenue?['avg_order_value']);

    final spots = <FlSpot>[];
    double maxRevenue = 5000;
    for (final row in hourly) {
      final hour = (row['hour'] as num).toDouble();
      final rev = _asDouble(row['revenue']);
      spots.add(FlSpot(hour, rev));
      if (rev > maxRevenue) maxRevenue = rev;
    }
    spots.sort((a, b) => a.x.compareTo(b.x));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Sales",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Chart
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No sales recorded yet today',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(0)}K'
                                  : value.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            getTitlesWidget: (value, meta) {
                              final hour = value.toInt();
                              final label = hour == 0
                                  ? '12AM'
                                  : hour < 12
                                  ? '${hour}AM'
                                  : hour == 12
                                  ? '12PM'
                                  : '${hour - 12}PM';
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 23,
                      minY: 0,
                      maxY: maxRevenue * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFFE67E22),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFFE67E22),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFE67E22).withOpacity(0.3),
                                const Color(0xFFE67E22).withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 15),
          // Bottom stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSalesBottomStat(
                Icons.currency_rupee,
                const Color(0xFFE67E22),
                '₹ ${totalRevenue.toStringAsFixed(0)}',
                'Total Revenue',
              ),
              _buildSalesBottomStat(
                Icons.shopping_bag,
                const Color(0xFF4CAF50),
                '$totalOrders',
                'Total Orders',
              ),
              _buildSalesBottomStat(
                Icons.bar_chart,
                const Color(0xFF2196F3),
                '₹ ${avgOrder.toStringAsFixed(0)}',
                'Avg. Order Value',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesBottomStat(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPopularDishes(List<dynamic> topItems) {
    final palette = [
      const Color(0xFFE67E22),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
    ];
    final maxSold = topItems.isEmpty
        ? 1
        : topItems
              .map((d) => _asDouble(d['total_sold'] ?? d['quantity']))
              .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Dishes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (topItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No sales data yet',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            )
          else
            ...List.generate(topItems.length.clamp(0, 5), (index) {
              final dish = topItems[index];
              final sold = _asDouble(dish['total_sold'] ?? dish['quantity']);
              final color = palette[index % palette.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Rank number
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dish image placeholder
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.restaurant, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    // Dish details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (dish['name'] ?? dish['item_name'] ?? '')
                                .toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${sold.toStringAsFixed(0)} sold',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: maxSold == 0 ? 0 : sold / maxSold,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==================== BOTTOM SECTION ====================
  Widget _buildBottomSection(double width, AdminProvider admin) {
    final isMobile = width < _tabletBreakpoint;
    final recentOrders = _buildRecentOrders(isMobile, admin.orders);
    final lowInventory = _buildLowInventory(isMobile, admin.lowStock);
    final quickActions = _buildQuickActions();

    if (width < _desktopBreakpoint) {
      return Column(
        children: [
          recentOrders,
          const SizedBox(height: 15),
          lowInventory,
          const SizedBox(height: 15),
          quickActions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent Orders
        Expanded(flex: 3, child: recentOrders),
        const SizedBox(width: 15),
        // Low Inventory
        Expanded(flex: 2, child: lowInventory),
        const SizedBox(width: 15),
        // Quick Actions
        Expanded(flex: 2, child: quickActions),
      ],
    );
  }

  Widget _buildRecentOrders(bool isMobile, List<dynamic> orders) {
    Color statusColor(String status) {
      switch (status) {
        case 'served':
        case 'completed':
          return const Color(0xFF4CAF50);
        case 'preparing':
        case 'accepted':
        case 'ready':
          return const Color(0xFFE67E22);
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String timeLabel(dynamic placedAt) {
      final parsed = DateTime.tryParse(placedAt?.toString() ?? '');
      if (parsed == null) return '-';
      return DateFormat('hh:mm a').format(parsed.toLocal());
    }

    final recent = orders.take(6).toList();

    final table = Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildTableHeader('#', 1),
              _buildTableHeader('Table', 1),
              _buildTableHeader('Customer', 2),
              _buildTableHeader('Amount', 2),
              _buildTableHeader('Status', 2),
              _buildTableHeader('Time', 2),
            ],
          ),
        ),
        // Table Rows
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'No orders placed yet',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          )
        else
          ...recent.map((order) {
            final status = order['status']?.toString() ?? 'placed';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      '#${order['id']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${order['table_number'] ?? '-'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (order['ordered_by_name'] ?? 'Guest').toString(),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹ ${_asDouble(order['final_amount']).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          color: statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      timeLabel(order['placed_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: 560, child: table),
                )
              : table,
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildLowInventory(bool isMobile, List<dynamic> lowStock) {
    final table = Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Item',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Current Stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (lowStock.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'All materials sufficiently stocked',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          )
        else
          ...lowStock.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      (item['name'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_asDouble(item['current_stock']).toStringAsFixed(1)} ${item['unit'] ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'Low',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Low Inventory Alerts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryRequestsScreen(),
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: 420, child: table),
                )
              : table,
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          // Action buttons grid
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PosCounterScreen()),
                  ),
                  child: _buildActionButton(
                    Icons.add_shopping_cart,
                    'New Order',
                    const Color(0xFFE67E22),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MenuManagementScreen(),
                    ),
                  ),
                  child: _buildActionButton(
                    Icons.restaurant_menu,
                    'Manage Menu',
                    const Color(0xFF9C27B0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersScreen()),
                  ),
                  child: _buildActionButton(
                    Icons.person_add,
                    'Add Customer',
                    const Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  ),
                  child: _buildActionButton(
                    Icons.bar_chart,
                    'View Reports',
                    const Color(0xFFFF5722),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryRequestsScreen(),
                    ),
                  ),
                  child: _buildActionButton(
                    Icons.inventory,
                    'Manage Inventory',
                    const Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StaffScreen()),
                  ),
                  child: _buildActionButton(
                    Icons.people,
                    'Staff Management',
                    const Color(0xFF3F51B5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 220,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BillManagementScreen(),
                  ),
                ),
                child: _buildActionButton(
                  Icons.payments,
                  'Bill Management',
                  const Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Bottom motivational message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('😊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keep serving great food!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Happy customers build a successful restaurant.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.favorite, color: Colors.pink.shade300, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
