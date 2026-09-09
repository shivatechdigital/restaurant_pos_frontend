class ApiConfig {
  // Development
  static const String baseUrl = 'https://petpooja.shivatechdigital.com/api';
  static const String socketUrl = 'https://petpooja.shivatechdigital.com';

  // Production (GCP)
  // static const String baseUrl = 'https://api.yourdomain.com/api';
  // static const String socketUrl = 'https://api.yourdomain.com';

  // Auth
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';

  // Kitchen Orders
  static const String kitchenOrders = '$baseUrl/orders/kitchen';
  static String updateStatus(int orderId) =>
      '$baseUrl/orders/$orderId/status';

  // Waiter Requests
  static const String waiterRequests = '$baseUrl/feedback/waiter-request';
}
