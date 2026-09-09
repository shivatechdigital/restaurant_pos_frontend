import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json', 'Cache-Control': 'no-cache'};
    if (auth) {
      final token = await _getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // 304/empty body ki wajah se crash na ho, isliye safe decode
  Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }
    return jsonDecode(res.body);
  }

  // ---- AUTH ----

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse(ApiConfig.sendOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse(ApiConfig.verifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    final data = jsonDecode(res.body);

    if (data['success'] == true && data['data']?['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['data']['token']);
      await prefs.setString('phone', phone);
    }
    return data;
  }

  // ---- TABLE ----

  Future<Map<String, dynamic>> scanTable(
      String tableNumber, String restaurantId, String phone) async {
    final res = await http.get(
      Uri.parse(ApiConfig.scanTable(tableNumber, restaurantId, phone)),
      headers: await _headers(auth: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> lockTable(
      int tableId, String phone, String otp) async {
    final res = await http.post(
      Uri.parse(ApiConfig.lockTable),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'table_id': tableId,
        'phone': phone,
        'otp': otp,
      }),
    );
    return jsonDecode(res.body);
  }

  // ---- MENU ----

  Future<Map<String, dynamic>> getMenu(String restaurantId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/menu?restaurant_id=$restaurantId'),
      headers: await _headers(auth: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> searchMenu(
      String restaurantId, String keyword) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/menu/search?restaurant_id=$restaurantId&keyword=$keyword'),
      headers: await _headers(auth: false),
    );
    return _decode(res);
  }

  // ---- ORDERS ----

  Future<Map<String, dynamic>> placeOrder({
    required int tableId,
    required int restaurantId,
    required String phone,
    required List<Map<String, dynamic>> items,
    String? notes,
    int? sessionId,
  }) async {
    final body = {
      'table_id': tableId,
      'restaurant_id': restaurantId,
      'phone': phone,
      'items': items,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'session_id': ?sessionId,
    };

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/place'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> placeOffPremiseOrder({
    required int restaurantId,
    required String orderType,
    required List<Map<String, dynamic>> items,
    required String phone,
    String? deliveryAddress,
    String? deliveryLandmark,
    double deliveryCharge = 0,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/place'),
      headers: await _headers(),
      body: jsonEncode({
        'restaurant_id': restaurantId,
        'order_type': orderType,
        'phone': phone,
        'items': items,
        'delivery_address': deliveryAddress,
        'delivery_landmark': deliveryLandmark,
        'delivery_charge': deliveryCharge,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getMyOrders(String sessionId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/my-orders?session_id=$sessionId'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/cancel'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getOrderPolicy() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/settings/order-policy'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getBill(String sessionId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/bill/$sessionId'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ---- PAYMENTS ----

  Future<Map<String, dynamic>> createPayment(
      String sessionId, double amount) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/create'),
      headers: await _headers(),
      body: jsonEncode({
        'session_id': int.parse(sessionId),
        'amount': amount,
        'payment_method': 'upi',
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String sessionId,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/verify'),
      headers: await _headers(),
      body: jsonEncode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'session_id': int.parse(sessionId),
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> cashPayment(
      String sessionId, double amount) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/cash'),
      headers: await _headers(),
      body: jsonEncode({
        'session_id': int.parse(sessionId),
        'amount': amount,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getPaymentStatus(String sessionId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/status/$sessionId'),
      headers: await _headers(),
    );
    return _decode(res);
  }
}
