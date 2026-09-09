import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ReceptionSidebar extends StatelessWidget {
  final String activeLabel;
  final Function(String)? onItemTap;

  const ReceptionSidebar({
    super.key,
    required this.activeLabel,
    this.onItemTap,
  });

  static const List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.table_restaurant_rounded, 'label': 'Table Management'},
    {'icon': Icons.shopping_cart_rounded, 'label': 'POS / Orders'},
    {'icon': Icons.restaurant_menu_rounded, 'label': 'Menu Management'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Reports'},
    {'icon': Icons.settings_rounded, 'label': 'Settings'},
  ];

  void _handleTap(BuildContext context, String label) {
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
    if (label == activeLabel) return;
    if (onItemTap != null) {
      onItemTap!(label);
      return;
    }
    // Default navigation (will add routes later as pages are built)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label page coming soon...'),
        backgroundColor: AppTheme.brand,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.sidebarBg,
      child: Column(
        children: [
          // Logo section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 15),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pet Pooja',
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Text(
                  'Restaurant Management',
                  style: TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final label = item['label'] as String;
                final selected = label == activeLabel;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: selected ? AppTheme.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _handleTap(context, label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: selected ? Colors.white : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              label,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom promo card
          Container(
            height: 110,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8B4513), Color(0xFF5D2E0C)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good Food\nBetter\nMoments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.favorite, color: Colors.red.shade300, size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('Pet Pooja', style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text('v1.0.0', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}