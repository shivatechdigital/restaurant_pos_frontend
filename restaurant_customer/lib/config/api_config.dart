class ApiConfig {
  // Development
    static const String baseUrl = 'https://petpooja.shivatechdigital.com/api';
    static const String socketUrl = 'https://petpooja.shivatechdigital.com';

  // Production (jab GCP pe deploy karo)
  // static const String baseUrl = 'https://api.yourdomain.com/api';
  // static const String socketUrl = 'https://api.yourdomain.com';

  // Auth
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';

  // Tables
  static String scanTable(String table, String restaurant, String phone) =>
      '$baseUrl/tables/scan?table_number=$table&restaurant_id=$restaurant&phone=$phone';
  static const String lockTable = '$baseUrl/tables/lock';

  // Menu
  static String menu(String restaurantId) =>
      '$baseUrl/menu?restaurant_id=$restaurantId';
  static String searchMenu(String restaurantId, String keyword) =>
      '$baseUrl/menu/search?restaurant_id=$restaurantId&keyword=$keyword';
}
