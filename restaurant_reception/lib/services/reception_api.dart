import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_theme.dart';

class ReceptionApi {
  final String token;
  ReceptionApi(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('${AppTheme.apiBaseUrl}$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.body.isEmpty) return {'success': false};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('${AppTheme.apiBaseUrl}$path'),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.body.isEmpty) return {'success': false};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getTables() async {
    final r = await _get('/tables/all');
    return r['success'] == true && r['data'] is List ? r['data'] : [];
  }

  Future<Map<String, dynamic>?> getBill(dynamic sessionId) async {
    final r = await _get('/orders/bill/$sessionId');
    return r['success'] == true ? r['data'] as Map<String, dynamic> : null;
  }

  Future<Map<String, dynamic>> getMenu() async {
    return _get('/menu?restaurant_id=1');
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async {
    return _post('/pos/orders', body);
  }

  Future<Map<String, dynamic>> cashPayment(dynamic sessionId, double amount) async {
    return _post('/payments/cash', {'session_id': sessionId, 'amount': amount});
  }

  Future<Map<String, dynamic>> toggleItemAvailability(int itemId, bool available) async {
    return _post('/menu/items/$itemId/toggle', {'is_available': available});
  }

  Future<Map<String, dynamic>> updateMenuItem(int itemId, Map<String, dynamic> body) async {
    try {
      final res = await http
          .put(Uri.parse('${AppTheme.apiBaseUrl}/menu/items/$itemId'),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.body.isEmpty) return {'success': false};
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRevenue({String period = 'daily', String? startDate, String? endDate}) async {
    final query = StringBuffer('?period=$period');
    if (startDate != null && endDate != null) {
      query.write('&start_date=$startDate&end_date=$endDate');
    }
    return _get('/reports/revenue$query');
  }

  Future<Map<String, dynamic>> getTopItems({int days = 7}) async {
    return _get('/reports/top-items?days=$days');
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    return _get('/reports/dashboard');
  }

  Future<Map<String, dynamic>> getDailyClosing({String? date}) async {
    final query = date != null ? '?date=$date' : '';
    return _get('/reports/daily-closing$query');
  }

  Future<String?> exportDailyClosing({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final res = await http
          .get(Uri.parse('${AppTheme.apiBaseUrl}/reports/daily-closing/export$query'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300 && res.body.isNotEmpty) {
        return res.body;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>?> exportReport({required String format, String? date}) async {
    try {
      final query = date == null ? '' : '&date=$date&start_date=$date&end_date=$date';
      final res = await http
          .get(Uri.parse('${AppTheme.apiBaseUrl}/reports/export?format=$format$query'), headers: _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode >= 200 && res.statusCode < 300 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}