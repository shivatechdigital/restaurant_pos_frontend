class ApiConfig {
  static const String baseUrl = 'http://48.217.50.135/api';
  static const String socketUrl = 'http://48.217.50.135';

  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String tables = '$baseUrl/tables/all';
  static String menu(String restaurantId) =>
      '$baseUrl/menu?restaurant_id=$restaurantId';
  static const String placeOrder = '$baseUrl/orders/place';
    static String kitchenOrders = '$baseUrl/orders/kitchen?include_served=true';
  static String updateStatus(int orderId) =>
      '$baseUrl/orders/$orderId/status';
  static String bill(String sessionId) =>
      '$baseUrl/orders/bill/$sessionId';
  static const String cashPayment = '$baseUrl/payments/cash';
}
