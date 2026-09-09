import 'package:shared_preferences/shared_preferences.dart';

/// Centralized, synchronous-after-init app preferences shared across screens.
/// Call [AppPreferences.load] once at startup (see main.dart) before reading
/// any getter. Setters persist to SharedPreferences and update the in-memory
/// cache immediately so other screens see the change without a reload.
class AppPreferences {
  AppPreferences._();

  static bool _loaded = false;
  static bool newOrderAlerts = true;
  static bool readyAlerts = true;
  static bool billReadyAlerts = true;
  static bool tableTransferAlerts = true;
  static bool vibration = true;
  static bool autoRefresh = false;
  static bool confirmBeforeServe = false;
  static bool showTableNumber = true;
  static String defaultView = 'floor'; // matches WaiterRoute.name

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    newOrderAlerts = prefs.getBool('notif_new_orders') ?? true;
    readyAlerts = prefs.getBool('notif_ready') ?? true;
    billReadyAlerts = prefs.getBool('notif_bill_ready') ?? true;
    tableTransferAlerts = prefs.getBool('notif_table_transfer') ?? true;
    vibration = prefs.getBool('notif_vibration') ?? true;
    autoRefresh = prefs.getBool('order_auto_refresh') ?? false;
    confirmBeforeServe = prefs.getBool('order_confirm_before_serve') ?? false;
    showTableNumber = prefs.getBool('display_show_table_number') ?? true;
    defaultView = prefs.getString('display_default_view') ?? 'floor';
    _loaded = true;
  }

  static bool get isLoaded => _loaded;

  static Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<void> setNewOrderAlerts(bool value) async {
    newOrderAlerts = value;
    await _setBool('notif_new_orders', value);
  }

  static Future<void> setReadyAlerts(bool value) async {
    readyAlerts = value;
    await _setBool('notif_ready', value);
  }

  static Future<void> setBillReadyAlerts(bool value) async {
    billReadyAlerts = value;
    await _setBool('notif_bill_ready', value);
  }

  static Future<void> setTableTransferAlerts(bool value) async {
    tableTransferAlerts = value;
    await _setBool('notif_table_transfer', value);
  }

  static Future<void> setVibration(bool value) async {
    vibration = value;
    await _setBool('notif_vibration', value);
  }

  static Future<void> setAutoRefresh(bool value) async {
    autoRefresh = value;
    await _setBool('order_auto_refresh', value);
  }

  static Future<void> setConfirmBeforeServe(bool value) async {
    confirmBeforeServe = value;
    await _setBool('order_confirm_before_serve', value);
  }

  static Future<void> setShowTableNumber(bool value) async {
    showTableNumber = value;
    await _setBool('display_show_table_number', value);
  }

  static Future<void> setDefaultView(String routeName) async {
    defaultView = routeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_default_view', routeName);
  }
}
