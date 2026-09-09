class ApiConfig {
  static const String baseUrl = 'https://petpooja.shivatechdigital.com/api';
  static const String socketUrl = 'https://petpooja.shivatechdigital.com';

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
