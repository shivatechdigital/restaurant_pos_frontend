import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';
import '../widgets/reception_sidebar.dart';
import '../widgets/reception_topbar.dart';

class ReceptionSettingsScreen extends StatefulWidget {
  final String token;
  final String receptionistName;
  final VoidCallback onLogout;
  final ValueChanged<String>? onNavigate;

  const ReceptionSettingsScreen({
    super.key,
    required this.token,
    required this.receptionistName,
    required this.onLogout,
    this.onNavigate,
  });

  @override
  State<ReceptionSettingsScreen> createState() => _ReceptionSettingsScreenState();
}

class _ReceptionSettingsScreenState extends State<ReceptionSettingsScreen> {
  // Notification Settings
  bool _pushNotifs = true;
  bool _emailNotifs = false;
  bool _orderAlerts = true;
  bool _reservationAlerts = true;
  bool _billAlerts = true;

  // Display Settings
  bool _darkMode = false;
  bool _compactView = false;
  String _language = 'English';
  String _dateFormat = 'DD MMM YYYY';

  // Sound Settings
  bool _soundEnabled = true;
  bool _keyboardSound = false;
  double _volume = 0.7;

  // Privacy
  bool _autoLock = true;
  int _autoLockMinutes = 10;

  // Data
  bool _autoBackup = true;

  String _phone = '';
  String _restaurantName = 'Pet Pooja';
  String _branchName = 'Main Branch';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifs = prefs.getBool('setting_push') ?? true;
      _emailNotifs = prefs.getBool('setting_email') ?? false;
      _orderAlerts = prefs.getBool('setting_order_alerts') ?? true;
      _reservationAlerts = prefs.getBool('setting_reservation_alerts') ?? true;
      _billAlerts = prefs.getBool('setting_bill_alerts') ?? true;
      _darkMode = prefs.getBool('setting_dark_mode') ?? false;
      _compactView = prefs.getBool('setting_compact') ?? false;
      _language = prefs.getString('setting_language') ?? 'English';
      _dateFormat = prefs.getString('setting_date_format') ?? 'DD MMM YYYY';
      _soundEnabled = prefs.getBool('setting_sound') ?? true;
      _keyboardSound = prefs.getBool('setting_kb_sound') ?? false;
      _volume = prefs.getDouble('setting_volume') ?? 0.7;
      _autoLock = prefs.getBool('setting_auto_lock') ?? true;
      _autoLockMinutes = prefs.getInt('setting_lock_minutes') ?? 10;
      _autoBackup = prefs.getBool('setting_backup') ?? true;
      _phone = prefs.getString('reception_phone') ?? '';
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is double) await prefs.setDouble(key, value);
  }

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
              child: ReceptionSidebar(activeLabel: 'Settings', onItemTap: widget.onNavigate),
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              SizedBox(
                width: 230,
                child: ReceptionSidebar(activeLabel: 'Settings', onItemTap: widget.onNavigate),
              ),
            Expanded(
              child: Column(
                children: [
                  ReceptionTopBar(
                    receptionistName: widget.receptionistName,
                    onLogout: widget.onLogout,
                    searchHint: 'Search settings...',
                  ),
                  Expanded(child: _body(isMobile, isDesktop)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool isMobile, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroBanner(),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _profileCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _restaurantCard()),
                  ],
                )
              : Column(children: [
                  _profileCard(),
                  const SizedBox(height: 16),
                  _restaurantCard(),
                ]),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _notificationsCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _displayCard()),
                  ],
                )
              : Column(children: [
                  _notificationsCard(),
                  const SizedBox(height: 16),
                  _displayCard(),
                ]),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _soundCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _privacyCard()),
                  ],
                )
              : Column(children: [
                  _soundCard(),
                  const SizedBox(height: 16),
                  _privacyCard(),
                ]),
          const SizedBox(height: 20),
          _dataBackupCard(),
          const SizedBox(height: 20),
          _aboutCard(),
          const SizedBox(height: 20),
          _dangerZone(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============ HERO BANNER ============
  Widget _heroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF78909C)],
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF546E7A).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.settings, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings',
                    style: TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Manage your account, preferences and application settings',
                    style:
                        TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 700)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 6),
                  Text('v1.0.0',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============ SECTION CARD WRAPPER ============
  Widget _sectionCard(String title, IconData icon, Color color, List<Widget> children) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  // ============ PROFILE CARD ============
  Widget _profileCard() {
    return _sectionCard('My Profile', Icons.person, AppTheme.brand, [
      const SizedBox(height: 8),
      Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppTheme.brand,
              child: Text(
                widget.receptionistName.isNotEmpty
                    ? widget.receptionistName[0].toUpperCase()
                    : 'R',
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ]),
                child: const Icon(Icons.camera_alt, color: AppTheme.brand, size: 16),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(widget.receptionistName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      Center(
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppTheme.brandLight, borderRadius: BorderRadius.circular(20)),
          child: const Text('Receptionist',
              style: TextStyle(
                  color: AppTheme.brand, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 16),
      _infoRow(Icons.phone, 'Phone', _phone.isEmpty ? 'Not set' : '+91 $_phone'),
      _infoRow(Icons.badge, 'Role', 'Reception Staff'),
      _infoRow(Icons.access_time, 'Shift', 'Morning (9AM - 6PM)'),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Edit profile coming soon'),
                backgroundColor: AppTheme.brand,
                duration: Duration(seconds: 1)));
          },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit Profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.brand,
            side: const BorderSide(color: AppTheme.brand),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text('$label:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ============ RESTAURANT CARD ============
  Widget _restaurantCard() {
    return _sectionCard('Restaurant Info', Icons.storefront, Colors.orange, [
      const SizedBox(height: 4),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade700]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_restaurantName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_branchName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text('Online',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            _detailInline('GST Number', '29AABCU9603R1ZM'),
            const SizedBox(height: 8),
            _detailInline('Address', '123 MG Road, Bangalore'),
            const SizedBox(height: 8),
            _detailInline('Contact', '+91 98765 43210'),
            const SizedBox(height: 8),
            _detailInline('Timings', '9:00 AM - 11:00 PM'),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('View full details coming soon'),
                    backgroundColor: AppTheme.brand,
                    duration: Duration(seconds: 1)));
              },
              icon: const Icon(Icons.info_outline, size: 14),
              label: const Text('View Details', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Switch branch feature coming soon'),
                    backgroundColor: AppTheme.brand,
                    duration: Duration(seconds: 1)));
              },
              icon: const Icon(Icons.swap_horiz, size: 14),
              label: const Text('Switch Branch', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _detailInline(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ============ NOTIFICATIONS ============
  Widget _notificationsCard() {
    return _sectionCard('Notifications', Icons.notifications, Colors.blue, [
      _switchTile('Push Notifications', 'Receive updates on your device',
          Icons.phone_iphone, _pushNotifs, (v) {
        setState(() => _pushNotifs = v);
        _savePref('setting_push', v);
      }),
      _switchTile('Email Notifications', 'Get daily reports on email',
          Icons.email_outlined, _emailNotifs, (v) {
        setState(() => _emailNotifs = v);
        _savePref('setting_email', v);
      }),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(),
      ),
      _switchTile('Order Alerts', 'New orders and status updates',
          Icons.receipt_long, _orderAlerts, (v) {
        setState(() => _orderAlerts = v);
        _savePref('setting_order_alerts', v);
      }),
      _switchTile('Reservation Alerts', 'New table reservations',
          Icons.event_available, _reservationAlerts, (v) {
        setState(() => _reservationAlerts = v);
        _savePref('setting_reservation_alerts', v);
      }),
      _switchTile('Bill Alerts', 'Bill payment reminders',
          Icons.payment, _billAlerts, (v) {
        setState(() => _billAlerts = v);
        _savePref('setting_bill_alerts', v);
      }),
    ]);
  }

  // ============ DISPLAY ============
  Widget _displayCard() {
    return _sectionCard('Display & Language', Icons.palette, Colors.purple, [
      _switchTile('Dark Mode', 'Easy on eyes at night', Icons.dark_mode, _darkMode,
          (v) {
        setState(() => _darkMode = v);
        _savePref('setting_dark_mode', v);
        _snack('Dark mode ${v ? "enabled" : "disabled"} (restart needed)');
      }),
      _switchTile('Compact View', 'Show more items per screen', Icons.view_compact,
          _compactView, (v) {
        setState(() => _compactView = v);
        _savePref('setting_compact', v);
      }),
      const SizedBox(height: 8),
      _dropdownTile('Language', Icons.language, _language,
          ['English', 'Hindi', 'Marathi', 'Kannada'], (v) {
        setState(() => _language = v);
        _savePref('setting_language', v);
      }),
      _dropdownTile('Date Format', Icons.date_range, _dateFormat,
          ['DD MMM YYYY', 'DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'], (v) {
        setState(() => _dateFormat = v);
        _savePref('setting_date_format', v);
      }),
    ]);
  }

  // ============ SOUND ============
  Widget _soundCard() {
    return _sectionCard('Sound & Vibration', Icons.volume_up, Colors.green, [
      _switchTile('Sound Enabled', 'Play sounds for actions', Icons.volume_up,
          _soundEnabled, (v) {
        setState(() => _soundEnabled = v);
        _savePref('setting_sound', v);
      }),
      _switchTile('Keyboard Sound', 'Sound on typing', Icons.keyboard, _keyboardSound,
          (v) {
        setState(() => _keyboardSound = v);
        _savePref('setting_kb_sound', v);
      }),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                const Text('Notification Volume',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Text('${(_volume * 100).toInt()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.brand, fontSize: 13)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.brand,
                inactiveTrackColor: AppTheme.brandLight,
                thumbColor: AppTheme.brand,
                overlayColor: AppTheme.brand.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _volume,
                onChanged: _soundEnabled
                    ? (v) {
                        setState(() => _volume = v);
                        _savePref('setting_volume', v);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ============ PRIVACY ============
  Widget _privacyCard() {
    return _sectionCard('Privacy & Security', Icons.lock, Colors.red, [
      _switchTile('Auto Lock', 'Lock screen when inactive', Icons.lock_clock, _autoLock,
          (v) {
        setState(() => _autoLock = v);
        _savePref('setting_auto_lock', v);
      }),
      if (_autoLock) ...[
        const SizedBox(height: 8),
        _dropdownTile(
            'Auto Lock Time',
            Icons.timer,
            '$_autoLockMinutes minutes',
            ['5 minutes', '10 minutes', '15 minutes', '30 minutes', '60 minutes'], (v) {
          final n = int.tryParse(v.split(' ').first) ?? 10;
          setState(() => _autoLockMinutes = n);
          _savePref('setting_lock_minutes', n);
        }),
      ],
      const SizedBox(height: 8),
      _actionTile('Change PIN', 'Update your login PIN', Icons.pin, Colors.orange, () {
        _snack('Change PIN feature coming soon');
      }),
      _actionTile('Session Log', 'View recent login activity', Icons.history, Colors.blue,
          () {
        _showSessionLog();
      }),
    ]);
  }

  // ============ DATA & BACKUP ============
  Widget _dataBackupCard() {
    return _sectionCard('Data & Backup', Icons.backup, Colors.teal, [
      _switchTile('Auto Backup', 'Backup data daily to cloud', Icons.cloud_upload,
          _autoBackup, (v) {
        setState(() => _autoBackup = v);
        _savePref('setting_backup', v);
      }),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.teal, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Backup',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Today, 2:30 AM • 45 MB',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _snack('Backup started...'),
              child:
                  const Text('Backup Now', style: TextStyle(color: Colors.teal, fontSize: 12)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _miniActionCard(
                Icons.download, 'Export Data', 'Download all data', Colors.blue, () {
              _snack('Export data feature coming soon');
            }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _miniActionCard(
                Icons.cleaning_services, 'Clear Cache', 'Free up storage', Colors.orange,
                () {
              _confirmClearCache();
            }),
          ),
        ],
      ),
    ]);
  }

  Widget _miniActionCard(
      IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ABOUT ============
  Widget _aboutCard() {
    return _sectionCard('About & Support', Icons.info, Colors.indigo, [
      _actionTile('Help Center', 'Get help and support articles', Icons.help_outline,
          Colors.blue, () => _snack('Opening Help Center...')),
      _actionTile('Contact Support', 'Chat with our support team', Icons.support_agent,
          Colors.green, () => _snack('Opening chat...')),
      _actionTile('Send Feedback', 'Help us improve', Icons.feedback, Colors.orange,
          () => _showFeedbackDialog()),
      _actionTile('Rate Us', 'Rate the app on store', Icons.star, Colors.amber,
          () => _snack('Redirecting to app store...')),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
      _actionTile('Privacy Policy', 'How we handle your data', Icons.privacy_tip,
          Colors.grey, () => _snack('Opening privacy policy...')),
      _actionTile('Terms of Service', 'Terms and conditions', Icons.description,
          Colors.grey, () => _snack('Opening terms...')),
      const SizedBox(height: 8),
      Center(
        child: Column(
          children: [
            Text('Pet Pooja - Reception',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            Text('Version 1.0.0 (Build 100)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            const SizedBox(height: 4),
            Text('© 2026 Pet Pooja. All rights reserved.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          ],
        ),
      ),
    ]);
  }

  // ============ DANGER ZONE ============
  Widget _dangerZone() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Danger Zone',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Text('These actions are irreversible. Please proceed with caution.',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout, size: 16, color: Colors.red),
                  label: const Text('Logout',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmResetSettings,
                  icon: const Icon(Icons.restore, size: 16, color: Colors.white),
                  label: const Text('Reset Settings',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ TILE WIDGETS ============
  Widget _switchTile(String title, String subtitle, IconData icon, bool value,
      Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.brand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile(String title, IconData icon, String current, List<String> options,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.brandLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: options.contains(current) ? current : options.first,
              underline: const SizedBox(),
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppTheme.brand, size: 16),
              style: const TextStyle(
                  color: AppTheme.brand, fontSize: 12, fontWeight: FontWeight.bold),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ============ HELPERS ============
  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.brand,
        duration: const Duration(seconds: 1)));
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cleaning_services, color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Clear Cache?', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
            'This will clear temporary files. Your data will not be affected. Continue?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack('Cache cleared successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Logout?', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text('You will be logged out from this device.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmResetSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.red, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Reset All Settings?', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
            'All your preferences will be reset to default. Your account and data will remain safe. Continue?',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final keys = prefs.getKeys().where((k) => k.startsWith('setting_')).toList();
              for (final k in keys) {
                await prefs.remove(k);
              }
              if (!mounted) return;
              Navigator.pop(ctx);
              await _loadPrefs();
              _snack('All settings reset to default');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSessionLog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 10),
                Text('Recent Sessions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            _sessionItem('Today, 9:00 AM', 'Chrome on Windows', 'Active now', true),
            _sessionItem('Yesterday, 6:00 PM', 'Chrome on Windows', 'Ended', false),
            _sessionItem('2 days ago', 'Firefox on Mac', 'Ended', false),
          ],
        ),
      ),
    );
  }

  Widget _sessionItem(String time, String device, String status, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? Colors.green.shade50 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.computer,
                color: active ? Colors.green : Colors.grey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: active ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                    color: active ? Colors.green : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final ctrl = TextEditingController();
    int rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Send Feedback', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How was your experience?', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    onPressed: () => setSt(() => rating = i + 1),
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us more...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _snack('Thanks for your feedback! ⭐');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brand),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }
}