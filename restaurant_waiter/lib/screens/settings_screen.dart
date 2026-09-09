import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waiter_provider.dart';
import '../services/api_service.dart';
import '../services/app_preferences.dart';
import '../widgets/waiter_shell.dart';
import 'login_screen.dart';

enum _SettingsSection { appPreferences, orderSettings, notifications, display, account, help, about }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection _section = _SettingsSection.appPreferences;
  String? _phone;
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final api = ApiService();
    final phone = await api.getSavedPhone();
    final name = await api.getSavedName();
    if (!mounted) return;
    setState(() {
      _phone = phone;
      _name = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    return WaiterShell(
      route: WaiterRoute.settings,
      title: 'Hello, Rahul! 👋',
      subtitle: 'Good service creates great experiences!',
      onRefresh: null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WaiterPageHeader(
              icon: Icons.settings_rounded,
              iconColor: kRed,
              title: 'Settings',
              subtitle: 'Customize your app experience',
            ),
            const SizedBox(height: 14),
            Expanded(
              child: compact
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _sectionRail(),
                          const SizedBox(height: 12),
                          _sectionContent(waiter),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 220, child: _sectionRail()),
                        const SizedBox(width: 12),
                        Expanded(child: SingleChildScrollView(child: _sectionContent(waiter))),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionRail() {
    final items = [
      (_SettingsSection.appPreferences, Icons.tune_rounded, 'App Preferences', 'Language, theme, sound'),
      (_SettingsSection.orderSettings, Icons.room_service_rounded, 'Order Settings', 'Order related options'),
      (_SettingsSection.notifications, Icons.notifications_rounded, 'Notifications', 'Alerts and updates'),
      (_SettingsSection.display, Icons.desktop_windows_rounded, 'Display', 'Screen and view settings'),
      (_SettingsSection.account, Icons.person_rounded, 'Account', 'Profile and security'),
      (_SettingsSection.help, Icons.help_outline_rounded, 'Help & Support', 'Get assistance'),
      (_SettingsSection.about, Icons.info_outline_rounded, 'About', 'App version and info'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items
            .map(
              (item) => ListTile(
                leading: Icon(item.$2, color: _section == item.$1 ? kRed : Colors.blueGrey, size: 20),
                title: Text(item.$3, style: TextStyle(fontSize: 13, fontWeight: _section == item.$1 ? FontWeight.bold : FontWeight.w600)),
                subtitle: Text(item.$4, style: const TextStyle(fontSize: 10.5)),
                selected: _section == item.$1,
                selectedTileColor: kRed.withValues(alpha: .06),
                onTap: () => setState(() => _section = item.$1),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _card(String title, String subtitle, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionContent(WaiterProvider waiter) {
    switch (_section) {
      case _SettingsSection.appPreferences:
        return _appPreferences();
      case _SettingsSection.orderSettings:
        return _orderSettings(waiter);
      case _SettingsSection.notifications:
        return _notificationSettings();
      case _SettingsSection.display:
        return _displaySettings();
      case _SettingsSection.account:
        return _accountSettings(waiter);
      case _SettingsSection.help:
        return _helpSettings();
      case _SettingsSection.about:
        return _aboutSettings();
    }
  }

  Widget _appPreferences() {
    return _card('App Preferences', 'Set up the app the way you like', [
      const Text('Language', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: 'en_IN',
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value: 'en_IN', child: Text('English (India)', style: TextStyle(fontSize: 12)))],
        onChanged: null,
      ),
      const SizedBox(height: 16),
      const Text('Theme', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: kPage, borderRadius: BorderRadius.circular(8)),
        child: const Row(
          children: [
            Icon(Icons.wb_sunny_rounded, size: 16, color: kRed),
            SizedBox(width: 6),
            Text('Light (default)', style: TextStyle(fontSize: 12)),
            Spacer(),
            Text('Dark mode coming soon', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
          ],
        ),
      ),
    ]);
  }

  Widget _orderSettings(WaiterProvider waiter) {
    return _card('Order Settings', 'Manage order related preferences', [
      _prefSwitch('Auto Refresh Orders', 'Automatically refresh tables and orders every 20s', AppPreferences.autoRefresh,
          (v) async {
        await AppPreferences.setAutoRefresh(v);
        if (v) {
          waiter.startAutoRefresh();
        } else {
          waiter.stopAutoRefresh();
        }
        setState(() {});
      }),
      _prefSwitch('Confirm Before Serve', 'Ask for confirmation before marking an order as served',
          AppPreferences.confirmBeforeServe, (v) async {
        await AppPreferences.setConfirmBeforeServe(v);
        setState(() {});
      }),
    ]);
  }

  Widget _notificationSettings() {
    return _card('Sound & Alerts', 'Manage sounds and in-app alerts', [
      _prefSwitch('New Order Alert', 'Play sound when a new order is assigned', AppPreferences.newOrderAlerts,
          (v) async {
        await AppPreferences.setNewOrderAlerts(v);
        setState(() {});
      }),
      _prefSwitch('Order Ready Alert', 'Notify when order is ready to serve', AppPreferences.readyAlerts, (v) async {
        await AppPreferences.setReadyAlerts(v);
        setState(() {});
      }),
      _prefSwitch('Bill Ready Alert', 'Notify when bill is generated', AppPreferences.billReadyAlerts, (v) async {
        await AppPreferences.setBillReadyAlerts(v);
        setState(() {});
      }),
      _prefSwitch('Table Transfer Alert', 'Notify when a table is transferred', AppPreferences.tableTransferAlerts,
          (v) async {
        await AppPreferences.setTableTransferAlerts(v);
        setState(() {});
      }),
      _prefSwitch('Vibration', 'Vibrate on new notifications', AppPreferences.vibration, (v) async {
        await AppPreferences.setVibration(v);
        setState(() {});
      }),
    ]);
  }

  Widget _displaySettings() {
    return _card('Display Settings', 'Customize how information is shown', [
      const Text('Default View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: AppPreferences.defaultView,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'floor', child: Text('Floor View', style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: 'orders', child: Text('My Orders', style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: 'serve', child: Text('Serve Order', style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: 'track', child: Text('Track Order', style: TextStyle(fontSize: 12))),
        ],
        onChanged: (value) async {
          if (value == null) return;
          await AppPreferences.setDefaultView(value);
          setState(() {});
        },
      ),
      const SizedBox(height: 16),
      _prefSwitch('Show Table Number', 'Display table number on order cards', AppPreferences.showTableNumber, (v) async {
        await AppPreferences.setShowTableNumber(v);
        setState(() {});
      }),
    ]);
  }

  Widget _accountSettings(WaiterProvider waiter) {
    return Column(
      children: [
        _card('Account', 'Your profile and security', [
          _detailRow('Name', _name ?? 'Waiter'),
          _detailRow('Phone Number', _phone ?? '\u2014'),
          _detailRow('Restaurant ID', '${waiter.restaurantId}'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This app uses OTP login \u2014 there is no password to change.')),
            ),
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('Change Password'),
          ),
        ]),
        _card('', '', [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await waiter.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _helpSettings() {
    return _card('Help & Support', 'Need help? Contact your manager', [
      const Text(
        'For login issues, order problems, or app bugs, please contact your restaurant admin or IT support.',
        style: TextStyle(fontSize: 12),
      ),
    ]);
  }

  Widget _aboutSettings() {
    return _card('App Information', 'Version details and support', [
      _detailRow('App Version', '1.0.0'),
      _detailRow('Last Updated', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
    ]);
  }

  Widget _prefSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeThumbColor: kRed,
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5)),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

