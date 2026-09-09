import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../services/reception_api.dart';
import '../widgets/reception_sidebar.dart';
import '../widgets/reception_topbar.dart';
import '../utils/download_helper.dart';
import '../utils/print_helper.dart';

class ReceptionReportsScreen extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;
  final ValueChanged<String>? onNavigate;

  const ReceptionReportsScreen({
    super.key,
    required this.token,
    required this.receptionistName,
    required this.onLogout,
    this.onNavigate,
  });

  @override
  State<ReceptionReportsScreen> createState() => _ReceptionReportsScreenState();
}

class _ReceptionReportsScreenState extends State<ReceptionReportsScreen> {
  late ReceptionApi _api;
  bool _loading = true;
  String _period = 'today'; // today, week, month
  DateTime _selectedDate = DateTime.now();

  // Data
  Map<String, dynamic> _stats = {};
  List<dynamic> _topItems = [];
  List<Map<String, dynamic>> _revenueTrend = [];
  Map<String, double> _paymentBreakdown = {};
  Map<String, double> _orderTypeBreakdown = {};

  @override
  void initState() {
    super.initState();
    _api = ReceptionApi(widget.token);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final reportPeriod = _period == 'today' ? 'daily' : _period == 'week' ? 'weekly' : 'monthly';
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final nextDate = DateFormat('yyyy-MM-dd').format(_selectedDate.add(const Duration(days: 1)));
    final revResult = await _api.getRevenue(
      period: reportPeriod,
      startDate: _period == 'today' ? selectedDate : null,
      endDate: _period == 'today' ? nextDate : null,
    );
    final topResult = await _api.getTopItems(days: _period == 'month' ? 30 : 7);
    final isCurrentDate = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dashboardResult = _period == 'today' && isCurrentDate ? await _api.getDashboardStats() : null;

    if (!mounted) return;

    final revenueData = revResult['success'] == true && revResult['data'] is Map
        ? Map<String, dynamic>.from(revResult['data'])
        : <String, dynamic>{};
    final grandTotal = revenueData['grand_total'] is Map
        ? Map<String, dynamic>.from(revenueData['grand_total'])
        : <String, dynamic>{};
    final dashboardData = dashboardResult?['success'] == true && dashboardResult?['data'] is Map
        ? Map<String, dynamic>.from(dashboardResult!['data'])
        : <String, dynamic>{};
    final revenue = dashboardData['revenue'] is Map
        ? Map<String, dynamic>.from(dashboardData['revenue'])
        : grandTotal;
    final topItems = topResult['success'] == true && topResult['data']?['top_items'] is List
        ? List<dynamic>.from(topResult['data']['top_items'])
        : <dynamic>[];
    final breakdown = revenueData['breakdown'] is List
        ? List<dynamic>.from(revenueData['breakdown'])
        : <dynamic>[];
    final hourlySales = dashboardData['hourly_sales'] is List
        ? List<dynamic>.from(dashboardData['hourly_sales'])
        : <dynamic>[];
    final payments = dashboardData['payment_methods'] is List
        ? List<dynamic>.from(dashboardData['payment_methods'])
        : <dynamic>[];
    final orderTypes = dashboardData['order_types'] is List
        ? List<dynamic>.from(dashboardData['order_types'])
        : <dynamic>[];

    setState(() {
      _stats = {
        'total_revenue': revenue['total_revenue'] ?? revenue['total'],
        'total_orders': revenue['total_orders'] ?? revenue['orders'],
        'avg_order_value': revenue['avg_order_value'] ??
            (_asD(revenue['total_orders']) == 0 ? 0 : _asD(revenue['total_revenue']) / _asD(revenue['total_orders'])),
        'total_customers': revenue['total_sessions'] ?? 0,
        'revenue_change': 0,
        'orders_change': 0,
        'customers_change': 0,
        'aov_change': 0,
      };
      _topItems = topItems.map((item) => {
        ...Map<String, dynamic>.from(item as Map),
        'quantity_sold': item['quantity_sold'] ?? item['total_sold'] ?? 0,
      }).toList();
      _revenueTrend = _period == 'today'
          ? hourlySales.map((item) => {'label': '${item['hour']}:00', 'value': _asD(item['revenue'])}).toList()
          : breakdown.map((item) => {'label': item['period'] ?? '', 'value': _asD(item['revenue'])}).toList();
      _paymentBreakdown = {
        for (final item in payments)
          _prettyLabel(item['payment_method'] ?? item['method']): _asD(item['total'] ?? item['amount']),
      };
      _orderTypeBreakdown = {
        for (final item in orderTypes)
          _prettyLabel(item['order_type']): _asD(item['count']),
      };
      _loading = false;
    });
  }

  String _prettyLabel(dynamic value) {
    final text = value?.toString().replaceAll('_', ' ') ?? '';
    return text.isEmpty ? 'Unknown' : '${text[0].toUpperCase()}${text.substring(1)}';
  }

  double _asD(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1100;
    final isMobile = w < 720;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppTheme.sidebarBg,
              child: ReceptionSidebar(activeLabel: 'Reports', onItemTap: widget.onNavigate),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              SizedBox(
                width: 230,
                child: ReceptionSidebar(activeLabel: 'Reports', onItemTap: widget.onNavigate),
              ),
            Expanded(
              child: Column(
                children: [
                  ReceptionTopBar(
                    receptionistName: widget.receptionistName,
                    onLogout: widget.onLogout,
                    searchHint: 'Search reports...',
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                        : _body(isMobile, isDesktop),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool isMobile, bool isDesktop) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.brand,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroBanner(),
            const SizedBox(height: 20),
            _periodTabs(),
            const SizedBox(height: 20),
            _kpiCards(),
            const SizedBox(height: 20),
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _revenueChart()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _paymentBreakdownCard()),
                    ],
                  )
                : Column(children: [
                    _revenueChart(),
                    const SizedBox(height: 16),
                    _paymentBreakdownCard(),
                  ]),
            const SizedBox(height: 20),
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _topItemsCard()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _orderTypeCard()),
                    ],
                  )
                : Column(children: [
                    _topItemsCard(),
                    const SizedBox(height: 16),
                    _orderTypeCard(),
                  ]),
            const SizedBox(height: 20),
            _quickInsightsCard(),
            const SizedBox(height: 20),
            _exportSection(),
          ],
        ),
      ),
    );
  }

  // ============ HERO BANNER ============
  Widget _heroBanner() {
    final revenue = _asD(_stats['total_revenue']);
    final change = _asD(_stats['revenue_change']);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF3949AB).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
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
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Business Reports',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Track revenue, orders and performance metrics in real-time',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _bannerChip(Icons.calendar_today,
                        DateFormat('EEE, d MMM yyyy').format(_selectedDate)),
                    const SizedBox(width: 8),
                    _bannerChip(Icons.trending_up, '+${change.toStringAsFixed(1)}% Growth',
                        color: Colors.greenAccent),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('TOTAL REVENUE',
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('₹${_format(revenue)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: change >= 0 ? Colors.greenAccent : Colors.redAccent, size: 14),
                    Text(' ${change.abs().toStringAsFixed(1)}% vs yesterday',
                        style: TextStyle(
                            color: change >= 0 ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? Colors.white).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============ PERIOD TABS ============
  Widget _periodTabs() {
    final periods = [
      ('today', 'Today', Icons.today),
      ('week', 'This Week', Icons.date_range),
      ('month', 'This Month', Icons.calendar_month),
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ...periods.map((p) => Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _period = p.$1);
                    _loadData();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _period == p.$1 ? AppTheme.brand : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.$3,
                            color: _period == p.$1 ? Colors.white : Colors.grey.shade600,
                            size: 15),
                        const SizedBox(width: 6),
                        Text(p.$2,
                            style: TextStyle(
                                color: _period == p.$1 ? Colors.white : Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(primary: AppTheme.brand),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadData();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.calendar_today, size: 14, color: Colors.black87),
                  SizedBox(width: 6),
                  Text('Custom',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ KPI CARDS ============
  Widget _kpiCards() {
    final kpis = [
      _KpiData('Total Orders', '${_stats['total_orders']}', _asD(_stats['orders_change']),
          Icons.receipt_long, const Color(0xFFFF6B35)),
      _KpiData('Revenue', '₹${_format(_asD(_stats['total_revenue']))}',
          _asD(_stats['revenue_change']), Icons.currency_rupee, const Color(0xFF4CAF50)),
      _KpiData('Sessions', '${_stats['total_customers']}',
          _asD(_stats['customers_change']), Icons.people, const Color(0xFF2196F3)),
      _KpiData('Avg Order Value', '₹${_asD(_stats['avg_order_value']).toStringAsFixed(0)}',
          _asD(_stats['aov_change']), Icons.trending_up, const Color(0xFF9C27B0)),
    ];

    return LayoutBuilder(builder: (ctx, cons) {
      final w = cons.maxWidth;
      final cols = w < 600 ? 2 : 4;
      final itemW = (w - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: kpis.map((k) => SizedBox(width: itemW, child: _kpiCard(k))).toList(),
      );
    });
  }

  Widget _kpiCard(_KpiData k) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: k.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(k.icon, color: k.color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (k.change >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(k.change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10, color: k.change >= 0 ? Colors.green : Colors.red),
                    const SizedBox(width: 2),
                    Text('${k.change.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: k.change >= 0 ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(k.value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(k.title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============ REVENUE CHART ============
  Widget _revenueChart() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppTheme.brand, size: 20),
              const SizedBox(width: 8),
              const Text('Revenue Trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.trending_up, color: Colors.green, size: 12),
                    SizedBox(width: 4),
                    Text('+18.5%',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 220, child: _buildLineChart()),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = _revenueTrend
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['value'] as double))
        .toList();

    final maxY = _revenueTrend
        .map((e) => e['value'] as double)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Text('₹${(v / 1000).toStringAsFixed(0)}K',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= _revenueTrend.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_revenueTrend[i]['label'],
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem('₹${_format(s.y)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [AppTheme.brand, Colors.orange.shade400]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppTheme.brand),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.brand.withOpacity(0.3), AppTheme.brand.withOpacity(0.02)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ PAYMENT BREAKDOWN ============
  Widget _paymentBreakdownCard() {
    final total = _paymentBreakdown.values.fold(0.0, (s, v) => s + v);
    final colors = {'Cash': const Color(0xFF4CAF50), 'UPI': const Color(0xFF9C27B0), 'Card': const Color(0xFF2196F3)};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.payments, color: AppTheme.brand, size: 20),
              SizedBox(width: 8),
              Text('Payment Modes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: _paymentBreakdown.entries.map((e) {
                        final pct = total == 0 ? 0.0 : (e.value / total * 100);
                        return PieChartSectionData(
                          value: e.value,
                          color: colors[e.key] ?? Colors.grey,
                          title: '${pct.toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _paymentBreakdown.entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: colors[e.key] ?? Colors.grey,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.key,
                                          style: const TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w600)),
                                      Text('₹${_format(e.value)}',
                                          style: TextStyle(
                                              fontSize: 10, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Collected', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text('₹${_format(total)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.brand)),
            ],
          ),
        ],
      ),
    );
  }

  // ============ TOP ITEMS ============
  Widget _topItemsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('Top Selling Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_topItems.length} items',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          ..._topItems.take(6).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final qty = _asD(item['quantity_sold']);
            final rev = _asD(item['revenue']);
            final maxQty = _topItems.isEmpty ? 1.0 : _asD(_topItems.first['quantity_sold']);
            final progress = maxQty == 0 ? 0.0 : (qty / maxQty);
            final rankColors = [Colors.amber, Colors.blueGrey.shade400, Colors.orange.shade700];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: i < 3 ? rankColors[i] : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: i < 3 ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(item['name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('₹${_format(rev)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.brand)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      i < 3 ? rankColors[i] : Colors.grey.shade400),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${qty.toInt()} sold',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
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

  // ============ ORDER TYPE CARD ============
  Widget _orderTypeCard() {
    final total = _orderTypeBreakdown.values.fold(0.0, (s, v) => s + v);
    final data = [
      ('Dine In', _orderTypeBreakdown['Dine In'] ?? 0, const Color(0xFF4CAF50), Icons.restaurant),
      ('Takeaway', _orderTypeBreakdown['Takeaway'] ?? 0, const Color(0xFFFF9800), Icons.shopping_bag),
      ('Delivery', _orderTypeBreakdown['Delivery'] ?? 0, const Color(0xFF9C27B0), Icons.delivery_dining),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart, color: AppTheme.brand, size: 20),
              SizedBox(width: 8),
              Text('Order Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...data.map((d) {
            final pct = total == 0 ? 0.0 : (d.$2 / total * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: d.$3.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(d.$4, color: d.$3, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(d.$1,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Text('${d.$2.toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(width: 6),
                      Text('(${pct.toStringAsFixed(0)}%)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(d.$3),
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

  // ============ INSIGHTS ============
  Widget _quickInsightsCard() {
    Map<String, dynamic>? peakHour;
    for (final entry in _revenueTrend) {
      if (peakHour == null || _asD(entry['value']) > _asD(peakHour['value'])) {
        peakHour = entry;
      }
    }
    final bestItem = _topItems.isEmpty ? null : _topItems.first;
    final orderCount = _asD(_stats['total_orders']);
    final insights = [
      _Insight(
        'Peak Hour',
        peakHour == null ? 'No data' : peakHour['label'].toString(),
        peakHour == null ? 'No sales recorded for this period' : 'Highest revenue period',
        Icons.access_time,
        Colors.orange,
      ),
      _Insight(
        'Best Seller',
        bestItem == null ? 'No data' : (bestItem['name'] ?? 'Unknown').toString(),
        bestItem == null ? 'No items sold for this period' : '${bestItem['quantity_sold']} units sold',
        Icons.star,
        Colors.amber,
      ),
      _Insight(
        'Order Volume',
        orderCount.toInt().toString(),
        'Orders in selected period',
        Icons.receipt_long,
        Colors.blue,
      ),
      _Insight(
        'Payment Methods',
        _paymentBreakdown.isEmpty ? 'No data' : _paymentBreakdown.length.toString(),
        _paymentBreakdown.isEmpty ? 'No payments recorded' : 'Methods used in selected period',
        Icons.payments,
        Colors.green,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Quick Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (ctx, cons) {
            final w = cons.maxWidth;
            final cols = w < 500 ? 1 : w < 900 ? 2 : 4;
            final itemW = (w - (cols - 1) * 12) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: insights
                  .map((i) => SizedBox(
                        width: itemW,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: i.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: i.color.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(i.icon, color: i.color, size: 18),
                                  const SizedBox(width: 6),
                                  Text(i.title,
                                      style: TextStyle(
                                          color: i.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(i.value,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(i.subtitle,
                                  style: TextStyle(
                                      fontSize: 10.5, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  // ============ EXPORT SECTION ============
  Widget _exportSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.brandLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.download, color: AppTheme.brand, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Export Reports',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Download reports in different formats',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          _exportBtn(Icons.picture_as_pdf, 'PDF', Colors.red),
          const SizedBox(width: 8),
          _exportBtn(Icons.table_chart, 'CSV', Colors.green),
          const SizedBox(width: 8),
          _exportBtn(Icons.print, 'Print', Colors.blue),
        ],
      ),
    );
  }

  Widget _exportBtn(IconData icon, String label, Color color) {
    return OutlinedButton.icon(
      onPressed: () => _handleExport(label, color),
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Future<void> _handleExport(String label, Color color) async {
    if (label == 'Print') {
      triggerBrowserPrint();
      return;
    }

    _showExportMessage('Preparing $label report...', color);
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final format = label.toLowerCase();
    final bytes = await _api.exportReport(format: format, date: date);
    if (!mounted) return;
    if (bytes == null) {
      _showExportMessage('$label export failed. Please try again.', Colors.red);
      return;
    }

    final extension = format == 'pdf' ? 'pdf' : 'csv';
    final mimeType = format == 'pdf' ? 'application/pdf' : 'text/csv';
    final downloaded = await downloadBytesFile('restaurant-report-$date.$extension', bytes, mimeType);
    if (!mounted) return;
    _showExportMessage(
      downloaded ? '$label downloaded successfully' : '$label download is available only in the web app',
      downloaded ? Colors.green : Colors.orange,
    );
  }

  void _showExportMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ));
  }

  String _format(double n) {
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

class _KpiData {
  final String title, value;
  final double change;
  final IconData icon;
  final Color color;
  _KpiData(this.title, this.value, this.change, this.icon, this.color);
}

class _Insight {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  _Insight(this.title, this.value, this.subtitle, this.icon, this.color);
}