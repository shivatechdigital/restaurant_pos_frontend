import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kitchen_provider.dart';
import 'kds_tv_mode.dart';

class KitchenSettingsScreen extends StatelessWidget {
  const KitchenSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kitchen = context.watch<KitchenProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        title: const Text('⚙️ Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- SOUND SECTION ----
          _sectionHeader('🔊 Sound & Alerts'),
          Card(
            color: Colors.grey[850],
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sound Alerts',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    kitchen.isMuted
                        ? 'Muted — No sound on new orders'
                        : 'Active — Beep on new orders',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  value: !kitchen.isMuted,
                  activeThumbColor: Colors.green,
                  onChanged: (_) => kitchen.toggleMute(),
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.vibration,
                      color: Colors.orange),
                  title: const Text('Vibration',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Mobile par vibration bhi hogi',
                      style: TextStyle(color: Colors.grey[400])),
                  trailing: const Icon(Icons.check_circle,
                      color: Colors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- DISPLAY SECTION ----
          _sectionHeader('🖥️ Display'),
          Card(
            color: Colors.grey[850],
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Grid View (Tablet)',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    kitchen.isGridView
                        ? 'Grid layout active'
                        : 'List layout active',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  value: kitchen.isGridView,
                  activeThumbColor: Colors.blue,
                  onChanged: (_) => kitchen.toggleView(),
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading:
                      const Icon(Icons.tv, color: Colors.purple),
                  title: const Text('TV Mode',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Full screen — Auto scroll — No touch',
                      style: TextStyle(color: Colors.grey[400])),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KDSTvMode(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- KITCHEN SECTIONS ----
          _sectionHeader('🏪 Kitchen Sections'),
          Card(
            color: Colors.grey[850],
            child: Column(
              children: kitchen.sections.isEmpty
                  ? [
                      const ListTile(
                        title: Text('No sections configured',
                            style: TextStyle(color: Colors.grey)),
                      )
                    ]
                  : kitchen.sections.map((section) {
                      return ListTile(
                        leading: Icon(
                          _getSectionIcon(section['name'] ?? ''),
                          color: Colors.orange,
                        ),
                        title: Text(
                          section['name'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          section['description'] ?? '',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        trailing: const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ---- DATA SECTION ----
          _sectionHeader('📡 Data & Sync'),
          Card(
            color: Colors.grey[850],
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.sync, color: Colors.blue),
                  title: const Text('Auto Refresh',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Every 15 seconds',
                      style: TextStyle(color: Colors.grey[400])),
                  trailing: const Icon(Icons.check_circle,
                      color: Colors.green, size: 20),
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.wifi,
                      color: Colors.green),
                  title: const Text('Socket.io Connection',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Real-time updates active',
                      style: TextStyle(color: Colors.grey[400])),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.refresh,
                      color: Colors.orange),
                  title: const Text('Force Refresh',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    kitchen.loadOrders();
                    kitchen.loadStats();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 Refreshing...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- ABOUT ----
          _sectionHeader('ℹ️ About'),
          Card(
            color: Colors.grey[850],
            child: const ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('Restaurant POS Kitchen',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text('Version 1.0.0 • Phase 4 Complete',
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getSectionIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tandoor')) return Icons.local_fire_department;
    if (lower.contains('bar')) return Icons.local_bar;
    if (lower.contains('chinese')) return Icons.ramen_dining;
    if (lower.contains('dessert')) return Icons.cake;
    return Icons.restaurant;
  }
}
