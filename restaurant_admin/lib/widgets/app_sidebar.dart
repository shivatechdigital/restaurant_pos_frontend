import 'package:flutter/material.dart';
import '../screens/main_dashboard.dart';
import '../screens/pos_counter_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/table_management_screen.dart';
import '../screens/menu_management_screen.dart';
import '../screens/inventory_requests_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/staff_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/coupons_screen.dart';
import '../screens/settings_screen.dart';

/// Shared left navigation used by MainDashboard and PosCounterScreen.
/// Wrap in a fixed-width Container for desktop, or in a Drawer for mobile/tablet.
class AppSidebar extends StatelessWidget {
  final String activeLabel;

  const AppSidebar({super.key, required this.activeLabel});

  static const List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.point_of_sale, 'label': 'POS Counter'},
    {'icon': Icons.receipt_long, 'label': 'Orders'},
    {'icon': Icons.table_restaurant, 'label': 'Table Management'},
    {'icon': Icons.restaurant_menu, 'label': 'Menu Management'},
    {'icon': Icons.inventory_2, 'label': 'Inventory'},
    {'icon': Icons.people, 'label': 'Customers'},
    {'icon': Icons.badge, 'label': 'Staff Management'},
    {'icon': Icons.bar_chart, 'label': 'Reports'},
    {'icon': Icons.local_offer, 'label': 'Offers & Promotions'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  void _onItemTap(BuildContext context, String label) {
    // Close the drawer first (no-op on desktop where there is no drawer).
    if (Scaffold.of(context).hasDrawer) {
      Navigator.of(context).maybePop();
    }
    if (label == activeLabel) return;

    final Widget? screen = switch (label) {
      'Dashboard' => const MainDashboard(),
      'POS Counter' => const PosCounterScreen(),
      'Orders' => const OrdersScreen(),
      'Table Management' => const TableManagementScreen(),
      'Menu Management' => const MenuManagementScreen(),
      'Inventory' => const InventoryRequestsScreen(),
      'Customers' => const CustomersScreen(),
      'Staff Management' => const StaffScreen(),
      'Reports' => const ReportsScreen(),
      'Offers & Promotions' => const CouponsScreen(),
      'Settings' => const SettingsScreen(),
      _ => null,
    };
    if (screen == null) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo Section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pet Pooja',
                style: TextStyle(
                  color: Color(0xFFE67E22),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                'Restaurant Management',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Good Food • Happy People',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        // Menu Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              final label = item['label'] as String;
              final isSelected = label == activeLabel;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: isSelected
                      ? const Color(0xFFE67E22)
                      : Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white60,
                      size: 20,
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () => _onItemTap(context, label),
                  ),
                ),
              );
            },
          ),
        ),
        // Version
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text(
                'Pet Pooja',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Text(
                'v1.0.0',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
