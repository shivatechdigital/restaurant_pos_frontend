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
    return prefs.getString('kitchen_token');
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

  // ---- AUTH ----

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
      await prefs.setString('kitchen_token', data['data']['token']);
      await prefs.setString('kitchen_phone', phone);
      await prefs.setString('kitchen_role', data['data']['user']['role']);
      await prefs.setInt(
          'kitchen_restaurant_id', data['data']['user']['restaurant_id'] ?? 1);
    }
    return data;
  }

  // ---- KITCHEN ORDERS ----

  Future<Map<String, dynamic>> getKitchenOrders({String? status, bool includeServed = false}) async {
    String url = ApiConfig.kitchenOrders;
    final query = <String>[];
    if (status != null) query.add('status=$status');
    if (includeServed) query.add('include_served=true');
    if (query.isNotEmpty) url += '?${query.join('&')}';

    final res = await http.get(
      Uri.parse(url),
      headers: await _headers(),
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

  // ---- KITCHEN ----

  Future<Map<String, dynamic>> getKitchenStats() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kitchen/stats'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getKitchenHistory({
    String? date,
    String? status,
    int page = 1,
  }) async {
    String url = '${ApiConfig.baseUrl}/kitchen/history?page=$page';
    if (date != null) url += '&date=$date';
    if (status != null) url += '&status=$status';

    final res = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getKitchenSections() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kitchen/sections'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ---- RECALL ----

  Future<Map<String, dynamic>> recallOrder(
      int orderId, String reason) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/kitchen/recall/$orderId'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    return _decode(res);
  }

  // ---- TRENDS ----

  Future<Map<String, dynamic>> getTrends(String period) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kitchen/trends?period=$period'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ---- INVENTORY ----

  Future<Map<String, dynamic>> createInventoryRequest({
    required String itemName,
    required String quantity,
    required String urgency,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inventory/requests'),
      headers: await _headers(),
      body: jsonEncode({
        'item_name': itemName,
        'quantity': quantity,
        'urgency': urgency,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    return _decode(res);
  }
}
