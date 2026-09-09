import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waiter_provider.dart';
import '../screens/login_screen.dart';
import '../services/app_preferences.dart';

const kNavy = Color(0xFF071522);
const kInk = Color(0xFF1D2939);
const kRed = Color(0xFFE82032);
const kPage = Color(0xFFF3F6FA);

/// Number of things needing the waiter's attention right now (new orders,
/// ready-to-serve orders, tables needing cleaning). Used for badges in the
/// sidebar and topbar; kept in sync with NotificationsScreen's own logic.
int _liveAlertCount(WaiterProvider waiter) =>
    waiter.activeOrders.where((o) => o.status == 'placed' || o.status == 'ready').length +
    waiter.tables.where((t) => t.isCleaning).length;

/// Identifies which sidebar entry (and screen) is currently active.
enum WaiterRoute { floor, orders, serve, track, transfer, notifications, settings }

/// Maps a persisted preference string (see AppPreferences.defaultView) back
/// to a [WaiterRoute], falling back to Floor View for unknown values.
WaiterRoute waiterRouteFromName(String name) => WaiterRoute.values
    .firstWhere((route) => route.name == name, orElse: () => WaiterRoute.floor);

/// Shared page shell: sidebar (or drawer on narrow screens) + topbar + body.
/// Every waiter screen should be built on top of this so navigation and
/// chrome stay consistent across the app.
class WaiterShell extends StatelessWidget {
  final WaiterRoute route;
  final String title;
  final String subtitle;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onRefresh;
  final Widget body;

  const WaiterShell({
    super.key,
    required this.route,
    required this.title,
    required this.subtitle,
    required this.body,
    this.searchHint = 'Search tables or orders...',
    this.onSearchChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1000;
    return Scaffold(
      backgroundColor: kPage,
      drawer: compact ? Drawer(child: WaiterSidebar(active: route)) : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!compact) SizedBox(width: 168, child: WaiterSidebar(active: route)),
            Expanded(
              child: Column(
                children: [
                  WaiterTopbar(
                    title: title,
                    subtitle: subtitle,
                    compact: compact,
                    searchHint: searchHint,
                    onSearchChanged: onSearchChanged,
                    onRefresh: onRefresh,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final WaiterRoute route;
  const _NavItem(this.icon, this.label, this.route);
}

class WaiterSidebar extends StatelessWidget {
  final WaiterRoute active;
  const WaiterSidebar({super.key, required this.active});

  static const _items = [
    _NavItem(Icons.home_rounded, 'Floor View', WaiterRoute.floor),
    _NavItem(Icons.receipt_long_rounded, 'My Orders', WaiterRoute.orders),
    _NavItem(Icons.room_service_rounded, 'Serve Order', WaiterRoute.serve),
    _NavItem(Icons.search_rounded, 'Track Order', WaiterRoute.track),
    _NavItem(Icons.compare_arrows_rounded, 'Table Transfer', WaiterRoute.transfer),
    _NavItem(Icons.notifications_rounded, 'Notifications', WaiterRoute.notifications),
    _NavItem(Icons.settings_rounded, 'Settings', WaiterRoute.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final alertCount = _liveAlertCount(waiter);
    return Container(
      color: kNavy,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: _SidebarHeader(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _items
                  .map(
                    (item) => _SideItem(
                      icon: item.icon,
                      label: item.label,
                      selected: active == item.route,
                      badge: switch (item.route) {
                        WaiterRoute.orders => waiter.totalActiveOrders,
                        WaiterRoute.notifications => alertCount,
                        _ => 0,
                      },
                      onTap: active == item.route
                          ? null
                          : () => _navigate(context, item.route),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(
            height: 110,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange.shade900, Colors.brown.shade900],
              ),
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Good Food\nHappier\nPeople',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.25,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, WaiterRoute route) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => routeScreen(route)),
    );
  }
}

/// Builds the destination screen for a given [WaiterRoute].
/// Kept as a top-level function (not a const map) since the target screens
/// are only imported lazily via `screen_registry.dart` to avoid import cycles.
Widget routeScreen(WaiterRoute route) => screenForRoute(route);

/// Overridden by `screen_registry.dart` at app start-up.
Widget Function(WaiterRoute route) screenForRoute = (route) =>
    const Scaffold(body: Center(child: Text('Screen not registered')));

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pet Pooja',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
        const Text(
          'Restaurant Management',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 9),
        ),
      ],
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback? onTap;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? kRed : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: selected ? Colors.white : Colors.white70, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge > 0) _CountBadge(count: badge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
    child: Text(
      '$count',
      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
    ),
  );
}

class WaiterTopbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool compact;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onRefresh;

  const WaiterTopbar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.compact,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final alertCount = _liveAlertCount(waiter);
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          if (compact)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: kInk),
              ),
            ),
          if (!compact)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: kInk, fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 10),
                  ),
                ],
              ),
            ),
          if (!compact)
            Container(
              width: 250,
              height: 36,
              decoration: BoxDecoration(color: kPage, borderRadius: BorderRadius.circular(7)),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: searchHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(top: 9),
                ),
              ),
            ),
          const SizedBox(width: 12),
          const _LiveClock(),
          const SizedBox(width: 12),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: kInk),
            ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screenForRoute(WaiterRoute.notifications)),
            ),
            icon: Badge(
              isLabelVisible: alertCount > 0,
              label: Text('$alertCount'),
              child: const Icon(Icons.notifications_none_rounded, color: kInk),
            ),
          ),
          if (!compact)
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: (value) async {
                if (value == 'logout') {
                  await waiter.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } else if (value == 'settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => screenForRoute(WaiterRoute.settings)),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'settings', child: Text('Settings')),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: kNavy,
                  child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small clock that ticks every minute; purely cosmetic chrome shared by all pages.
class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateText = '${days[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}';
    final hour12 = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final timeText = '$hour12:${_now.minute.toString().padLeft(2, '0')} ${_now.hour >= 12 ? 'PM' : 'AM'}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dateText, style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
            Text(timeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kInk)),
          ],
        ),
      ],
    );
  }
}

/// Small colored stat pill used at the top-right of each page header,
/// e.g. "5 My Active Orders".
class WaiterStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const WaiterStatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Big page heading used at the top of each screen's body: icon + title +
/// subtitle on the left, stat pills wrapped on the right.
class WaiterPageHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> pills;

  const WaiterPageHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.pills = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final heading = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade500),
                  ),
                ],
              ),
            ),
          ],
        );
        final pillsRow = Wrap(spacing: 10, runSpacing: 10, children: pills);
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 12), pillsRow],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 12),
            pillsRow,
          ],
        );
      },
    );
  }
}

/// Shows a confirmation dialog before serving if the user has enabled
/// "Confirm Before Serve" in Settings > Order Settings. Returns true when
/// the caller should proceed with the real serve API call.
Future<bool> confirmServeIfNeeded(BuildContext context, String label) async {
  if (!AppPreferences.confirmBeforeServe) return true;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Mark as Served?'),
      content: Text('Confirm that $label has been delivered to the table.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
