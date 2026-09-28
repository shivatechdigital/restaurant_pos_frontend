import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/admin_provider.dart';
import '../screens/login_screen.dart';

class AdminTopBar extends StatelessWidget {
  final bool isMobile;
  final VoidCallback? onMenuPressed;
  final bool showSearch;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? title;

  const AdminTopBar({
    super.key,
    required this.isMobile,
    this.onMenuPressed,
    this.showSearch = true,
    this.searchHint = 'Search...',
    this.searchController,
    this.onSearchChanged,
    this.title,
  });

  Future<void> _editProfile(BuildContext context) async {
    final provider = context.read<AdminProvider>();
    final nameController = TextEditingController(text: provider.adminName);
    final prefs = await SharedPreferences.getInstance();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Admin Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = nameController.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await prefs.setString('admin_name', result);
      provider.setRestaurant(provider.restaurantId, result);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    await prefs.remove('restaurant_id');
    await prefs.remove('admin_name');

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminName = context.watch<AdminProvider>().adminName;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onMenuPressed != null)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu, color: Colors.black87),
            ),
          if (title != null && !isMobile)
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            )
          else if (showSearch)
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        controller: searchController,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          if (isMobile && title != null)
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 12),
          const Icon(Icons.notifications_none_rounded, size: 24, color: Colors.black87),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Admin menu',
            onSelected: (value) async {
              if (value == 'profile') {
                await _editProfile(context);
              } else if (value == 'logout') {
                await _logout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 10),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF6D4C41),
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const Text(
                        'Main Branch',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
