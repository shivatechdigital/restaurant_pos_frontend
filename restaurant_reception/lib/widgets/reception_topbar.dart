import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';

class ReceptionTopBar extends StatefulWidget {
  final String receptionistName;
  final VoidCallback onLogout;
  final VoidCallback? onMenuTap;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  const ReceptionTopBar({
    super.key,
    required this.receptionistName,
    required this.onLogout,
    this.onMenuTap,
    this.searchHint,
    this.onSearch,
  });

  @override
  State<ReceptionTopBar> createState() => _ReceptionTopBarState();
}

class _ReceptionTopBarState extends State<ReceptionTopBar> {
  Timer? _clock;
  DateTime _now = DateTime.now();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _initial => widget.receptionistName.isNotEmpty
      ? widget.receptionistName[0].toUpperCase()
      : 'R';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 720;
    final isTablet = w >= 720 && w < 1100;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (isMobile || isTablet)
            IconButton(
              icon: const Icon(Icons.menu, size: 26),
              onPressed: widget.onMenuTap ??
                  () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            ),
          if (!isMobile)
            Expanded(
              flex: 3,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: widget.onSearch,
                        decoration: InputDecoration(
                          hintText: widget.searchHint ??
                              'Search tables, orders, guests...',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          if (!isMobile) ...[
            // Date + Time compact display
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE, d MMM yyyy').format(_now),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade700),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(_now),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Notifications
          _iconButton(
            icon: Icons.notifications_none_rounded,
            badge: '3',
            onTap: () => _showNotifications(context),
          ),
          const SizedBox(width: 8),
          // Profile
          _profileMenu(context),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Icon(icon, size: 26, color: AppTheme.textDark),
            if (badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.brand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileMenu(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    return PopupMenuButton<String>(
      offset: const Offset(0, 55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        if (value == 'logout') widget.onLogout();
        if (value == 'profile') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile page coming soon...'),
                backgroundColor: AppTheme.brand),
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(children: const [
            Icon(Icons.person, size: 18, color: Colors.grey),
            SizedBox(width: 10),
            Text('My Profile'),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(children: const [
            Icon(Icons.logout, size: 18, color: AppTheme.brand),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(color: AppTheme.brand)),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.brand,
              child: Text(
                _initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receptionistName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Text(
                    'Receptionist',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications,
                      color: AppTheme.brand, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            _notifTile(Icons.table_restaurant, 'Table T5 requesting bill',
                '2 min ago', AppTheme.brand),
            _notifTile(Icons.event_available, 'New reservation: Rahul Sharma',
                '15 min ago', Colors.purple),
            _notifTile(Icons.check_circle, 'Order #124 completed', '30 min ago',
                Colors.green),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(IconData icon, String title, String time, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(time,
          style: const TextStyle(color: Colors.grey, fontSize: 11)),
    );
  }
}