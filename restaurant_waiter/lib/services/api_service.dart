import 'dart:async';
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
    return prefs.getString('waiter_token');
  }

  Future<bool> hasSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('waiter_token') != null;
  }

  Future<int> getSavedRestaurantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('restaurant_id') ?? 1;
  }

  Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('waiter_name');
  }

  Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('waiter_phone');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('waiter_token');
    await prefs.remove('waiter_phone');
    await prefs.remove('waiter_name');
    await prefs.remove('restaurant_id');
  }

  Future<Map<String, String>> _headers() async {
    final h = {'Content-Type': 'application/json', 'Cache-Control': 'no-cache'};
    final token = await _getToken();
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }
    return jsonDecode(res.body);
  }

  // Auth
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await http.post(
      Uri.parse(ApiConfig.sendOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse(ApiConfig.verifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    final data = _decode(res);
    if (data['success'] == true && data['data']?['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('waiter_token', data['data']['token']);
      await prefs.setString('waiter_phone', phone);
      await prefs.setString('waiter_name', data['data']['user']['name']);
      await prefs.setInt(
          'restaurant_id', data['data']['user']['restaurant_id'] ?? 1);
    }
    return data;
  }

  // Tables
  Future<Map<String, dynamic>> getTables() async {
    final res = await http.get(
      Uri.parse(ApiConfig.tables),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // Menu
  Future<Map<String, dynamic>> getMenu(String restaurantId) async {
    final res = await http.get(
      Uri.parse(ApiConfig.menu(restaurantId)),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // Orders
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(ApiConfig.placeOrder),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getKitchenOrders() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.kitchenOrders),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      return _decode(res);
    } on TimeoutException {
      return {'success': false, 'message': 'Server did not respond in time'};
    } on http.ClientException {
      return {'success': false, 'message': 'Network connection failed'};
    }
  }

  Future<Map<String, dynamic>> getTableSessions(int tableId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/waiter/table/$tableId/sessions'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> transferTable(
      int sessionId, int targetTableId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/waiter/table/transfer'),
      headers: await _headers(),
      body: jsonEncode({
        'session_id': sessionId,
        'target_table_id': targetTableId,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> mergeTables(
      int sourceSessionId, int targetSessionId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/waiter/table/merge'),
      headers: await _headers(),
      body: jsonEncode({
        'source_session_id': sourceSessionId,
        'target_session_id': targetSessionId,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      int orderId, String status) async {
    final res = await http.patch(
      Uri.parse(ApiConfig.updateStatus(orderId)),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> cancelOrderManually(int orderId, String reason) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/cancel/manual'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    return _decode(res);
  }

  // Bill + Payment
  Future<Map<String, dynamic>> getBill(String sessionId) async {
    final res = await http.get(
      Uri.parse(ApiConfig.bill(sessionId)),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> cashPayment(
      String sessionId, double amount, {String method = 'cash'}) async {
    final res = await http.post(
      Uri.parse(ApiConfig.cashPayment),
      headers: await _headers(),
      body: jsonEncode({
        'session_id': int.parse(sessionId),
        'amount': amount,
        'payment_method': method,
      }),
    );
    return _decode(res);
  }
}
