class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';

  // Auth
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';

  // Dashboard
  static const String dashboard = '$baseUrl/reports/dashboard';
  static const String dailyClosing = '$baseUrl/reports/daily-closing';
  static const String topItems = '$baseUrl/reports/top-items';
  static const String revenue = '$baseUrl/reports/revenue';
  static const String peakHours = '$baseUrl/reports/peak-hours';
  static const String staffPerf = '$baseUrl/reports/staff';
  static String gstReport(String m, String y) =>
      '$baseUrl/reports/gst?month=$m&year=$y';

  // Menu
  static String menu(String rId) => '$baseUrl/menu?restaurant_id=$rId';
  static const String addCategory = '$baseUrl/menu/categories';
  static const String addItem = '$baseUrl/menu/items';
  static String toggleItem(int id) => '$baseUrl/menu/items/$id/toggle';
  static const String uploadMenuImage = '$baseUrl/menu/upload-image';
  // e.g. http://localhost:3000 (baseUrl without the /api suffix), used to resolve relative image URLs
  static String get serverOrigin => baseUrl.replaceAll('/api', '');

  // Tables
  static const String tables = '$baseUrl/tables/all';

  // Orders
  static const String allOrders = '$baseUrl/orders/all';

  // Staff
  static const String staff = '$baseUrl/reports/staff';
  static const String staffMembers = '$baseUrl/staff';
  static const String auditLogs = '$baseUrl/staff/audit/logs';
  static String updateStaff(int id) => '$baseUrl/staff/$id';
}
