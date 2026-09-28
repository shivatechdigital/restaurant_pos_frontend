import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/app_sidebar.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = context.read<AdminProvider>();
      admin.loadStaffMembers();
      admin.loadStaff();
      admin.loadAuditLogs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isMobile = width < 700;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: const Color(0xFF1E1E1E),
              child: const SafeArea(
                child: AppSidebar(activeLabel: 'Staff Management'),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              const CollapsibleSidebar(activeLabel: 'Staff Management'),
            Expanded(
              child: Column(
                children: [
                  AdminTopBar(
                    isMobile: isMobile,
                    onMenuPressed: !isDesktop
                        ? () => Scaffold.of(context).openDrawer()
                        : null,
                    title: 'Staff & Audit',
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF1A237E),
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Staff'),
                      Tab(text: 'Performance'),
                      Tab(text: 'Audit Log'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _staffTab(admin),
                        _performanceTab(admin),
                        _auditTab(admin),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              tooltip: 'Add staff',
              onPressed: () => _showStaffDialog(admin),
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Widget _staffTab(AdminProvider admin) {
    if (admin.staffMembers.isEmpty) {
      return const Center(child: Text('No staff accounts yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: admin.staffMembers.length,
      itemBuilder: (context, index) {
        final member = admin.staffMembers[index];
        final active = member['is_active'] == true;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _roleColor(member['role'])
                  .withValues(alpha: 0.14),
              child: Icon(
                _roleIcon(member['role']),
                color: _roleColor(member['role']),
              ),
            ),
            title: Text(member['name'] ?? 'Unknown'),
            subtitle: Text(
              '${member['phone'] ?? ''} • ${(member['role'] ?? '').toString().toUpperCase()}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: active,
                  onChanged: (value) =>
                      _updateMember(admin, member, isActive: value),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Staff actions',
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showStaffDialog(admin, member: member);
                    } else if (action == 'delete') {
                      _confirmDeleteStaff(admin, member);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit details')),
                    PopupMenuItem(value: 'delete', child: Text('Delete staff')),
                  ],
                ),
              ],
            ),
            onTap: () => _showStaffDialog(admin, member: member),
          ),
        );
      },
    );
  }

  Widget _performanceTab(AdminProvider admin) {
    if (admin.staff.isEmpty)
      return const Center(child: Text('No staff performance data'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: admin.staff.length,
      itemBuilder: (context, index) {
        final staff = admin.staff[index];
        final name = staff['name'] ?? staff['ordered_by_name'] ?? 'Unknown';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(name.toString()[0].toUpperCase()),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${staff['orders'] ?? staff['total_orders'] ?? 0} orders • Avg ${staff['avg_serve_time'] ?? staff['avg_prep_time'] ?? '?'} min',
            ),
            trailing: Text(
              '₹${_asDouble(staff['revenue'] ?? staff['total_revenue']).toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _auditTab(AdminProvider admin) {
    if (admin.auditLogs.isEmpty)
      return const Center(child: Text('No audit events yet'));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: admin.auditLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final log = admin.auditLogs[index];
        final timestamp = DateTime.tryParse(
          log['created_at']?.toString() ?? '',
        );
        return ListTile(
          leading: Icon(
            _auditIcon(log['action']),
            color: const Color(0xFF1A237E),
          ),
          title: Text(_auditLabel(log['action'])),
          subtitle: Text(
            '${log['actor_name'] ?? 'System'} • ${timestamp == null ? '' : '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'}',
          ),
        );
      },
    );
  }

  Future<void> _showStaffDialog(AdminProvider admin, {dynamic member}) async {
    final nameCtrl = TextEditingController(text: member?['name'] ?? '');
    final savedPhone = (member?['phone'] ?? '').toString().replaceAll(
      RegExp(r'\D'),
      '',
    );
    final phoneCtrl = TextEditingController(
      text: savedPhone.length == 12 && savedPhone.startsWith('91')
          ? savedPhone.substring(2)
          : savedPhone,
    );
    String role = member?['role'] ?? 'waiter';
    String? formError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            member == null ? 'Add Staff Member' : 'Edit Staff Member',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixText: '+91 ',
                  counterText: '',
                ),
              ),
              if (formError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'waiter', child: Text('Waiter')),
                  DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                  DropdownMenuItem(
                    value: 'reception',
                    child: Text('Reception'),
                  ),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => setDialogState(() => role = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setDialogState(() => formError = 'Name is required');
                  return;
                }
                if (phoneCtrl.text.length != 10) {
                  setDialogState(() => formError = 'Enter all 10 phone digits');
                  return;
                }
                Navigator.pop(ctx);
                final ok = member == null
                    ? await admin.createStaff({
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'role': role,
                      })
                    : await admin.updateStaffMember(member['id'] as int, {
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'role': role,
                      });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Staff member saved'
                          : (admin.staffError ?? 'Unable to save staff member'),
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteStaff(AdminProvider admin, dynamic member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete staff member?'),
        content: Text(
          '${member['name']} (${member['phone']}) will be removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await admin.deleteStaffMember(member['id'] as int);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Staff member deleted' : (admin.staffError ?? 'Delete failed'),
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _updateMember(
    AdminProvider admin,
    dynamic member, {
    required bool isActive,
  }) async {
    final ok = await admin.updateStaffMember(member['id'], {
      'is_active': isActive,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Staff status updated' : 'Unable to update staff'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Color _roleColor(dynamic role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'kitchen':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _roleIcon(dynamic role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'kitchen':
        return Icons.restaurant;
      default:
        return Icons.room_service;
    }
  }

  IconData _auditIcon(dynamic action) {
    final text = action?.toString() ?? '';
    if (text.contains('payment')) return Icons.payments;
    if (text.contains('merge')) return Icons.call_merge;
    if (text.contains('transfer')) return Icons.swap_horiz;
    return Icons.manage_accounts;
  }

  String _auditLabel(dynamic action) =>
      (action?.toString() ?? 'system_event').replaceAll('_', ' ').toUpperCase();

  double _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}
