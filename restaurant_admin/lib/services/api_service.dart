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
    return prefs.getString('admin_token');
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
      await prefs.setString('admin_token', data['data']['token']);
      await prefs.setString('admin_phone', phone);
      await prefs.setString('admin_name', data['data']['user']['name']);
      await prefs.setInt(
          'restaurant_id', data['data']['user']['restaurant_id'] ?? 1);
    }
    return data;
  }

  // ---- DASHBOARD ----
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
        Uri.parse(ApiConfig.dashboard), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getOrderPolicy() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/settings/order-policy'), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getDeliveryPartners() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/fulfillment/partners'), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> createDeliveryPartner(Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/fulfillment/partners'), headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> getReservations() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/fulfillment/reservations'), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> createReservation(Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/fulfillment/reservations'), headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> checkInReservation(int id) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/fulfillment/reservations/$id/check-in'), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> assignDelivery(int orderId, int partnerId) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/fulfillment/delivery/$orderId/assign'), headers: await _headers(), body: jsonEncode({'partner_id': partnerId}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateDeliveryStatus(int orderId, String status) async {
    final res = await http.patch(Uri.parse('${ApiConfig.baseUrl}/fulfillment/delivery/$orderId/status'), headers: await _headers(), body: jsonEncode({'status': status}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateOrderPolicy(Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('${ApiConfig.baseUrl}/settings/order-policy'), headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> getDailyClosing({String? date}) async {
    final url = date == null ? ApiConfig.dailyClosing : '${ApiConfig.dailyClosing}?date=$date';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> closeDay(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(ApiConfig.dailyClosing),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getCashShifts({String? date}) async {
    final url = date == null ? '${ApiConfig.baseUrl}/reports/cash-shifts' : '${ApiConfig.baseUrl}/reports/cash-shifts?date=$date';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> openCashShift(Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/reports/cash-shifts'), headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> closeCashShift(int id, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/reports/cash-shifts/$id/close'), headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> reopenDay(String date, String reason) async {
    final res = await http.delete(Uri.parse('${ApiConfig.dailyClosing}/$date'), headers: await _headers(), body: jsonEncode({'reason': reason}));
    return _decode(res);
  }

  Future<String?> downloadDailyClosingCsv(String date) async {
    final res = await http.get(Uri.parse('${ApiConfig.dailyClosing}/export?date=$date'), headers: await _headers());
    return res.statusCode == 200 ? res.body : null;
  }

  Future<Map<String, dynamic>> getTopItems({int days = 7}) async {
    final res = await http.get(
        Uri.parse('${ApiConfig.topItems}?days=$days'),
        headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getRevenue(
      {String period = 'daily', String? start, String? end}) async {
    String url = '${ApiConfig.revenue}?period=$period';
    if (start != null) url += '&start_date=$start&end_date=$end';
    final res =
        await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getPeakHours() async {
    final res = await http.get(
        Uri.parse(ApiConfig.peakHours), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getStaffPerformance() async {
    final res = await http.get(
        Uri.parse(ApiConfig.staffPerf), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getStaffMembers() async {
    final res = await http.get(Uri.parse(ApiConfig.staffMembers), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getCoupons() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/discounts/coupons'), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getCustomers({String? search, String? segment}) async {
    final parameters = <String, String>{};
    if (search != null && search.isNotEmpty) parameters['search'] = search;
    if (segment != null && segment.isNotEmpty) parameters['segment'] = segment;
    final url = Uri.parse('${ApiConfig.baseUrl}/customers').replace(queryParameters: parameters.isEmpty ? null : parameters).toString();
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getCustomer(int id) async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/customers/$id'), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('${ApiConfig.baseUrl}/customers/$id'), headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/discounts/coupons'), headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  Future<Map<String, dynamic>> toggleCoupon(int id, bool isActive) async {
    final res = await http.patch(Uri.parse('${ApiConfig.baseUrl}/discounts/coupons/$id'), headers: await _headers(), body: jsonEncode({'is_active': isActive}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(ApiConfig.staffMembers),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateStaff(int id, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse(ApiConfig.updateStaff(id)),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getAuditLogs() async {
    final res = await http.get(Uri.parse(ApiConfig.auditLogs), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getGSTReport(
      String month, String year) async {
    final res = await http.get(
        Uri.parse(ApiConfig.gstReport(month, year)),
        headers: await _headers());
    return _decode(res);
  }

  // ---- MENU ----
  Future<Map<String, dynamic>> getMenu(String rId) async {
    final res = await http.get(
        Uri.parse(ApiConfig.menu(rId)), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> addCategory(
      String name, int order) async {
    final res = await http.post(
      Uri.parse(ApiConfig.addCategory),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'display_order': order}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> deleteCategory(int id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/menu/categories/$id'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> addMenuItem(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(ApiConfig.addItem),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateMenuItem(
      int id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/menu/items/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> deleteMenuItem(int id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/menu/items/$id'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> uploadMenuImage(List<int> bytes, String filename) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadMenuImage));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Future<Map<String, dynamic>> toggleItem(
      int id, bool available) async {
    final res = await http.patch(
      Uri.parse(ApiConfig.toggleItem(id)),
      headers: await _headers(),
      body: jsonEncode({'is_available': available}),
    );
    return _decode(res);
  }

  // ---- TABLES ----
  Future<Map<String, dynamic>> getTables() async {
    final res = await http.get(
        Uri.parse(ApiConfig.tables), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateTableStatus(int tableId, String status) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/tables/$tableId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> deleteTable(int tableId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/tables/$tableId'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> mergeTables(int sourceSessionId, int targetSessionId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/waiter/table/merge'),
      headers: await _headers(),
      body: jsonEncode({'source_session_id': sourceSessionId, 'target_session_id': targetSessionId}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> collectPayment(int sessionId, double amount, String method) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/cash'),
      headers: await _headers(),
      body: jsonEncode({'session_id': sessionId, 'amount': amount, 'payment_method': method}),
    );
    return _decode(res);
  }

  // ---- ORDERS ----
  Future<Map<String, dynamic>> getAllOrders(
      {String? date, String? status, int? orderId, int page = 1}) async {
    String url = '${ApiConfig.allOrders}?page=$page';
    if (date != null) url += '&date=$date';
    if (status != null && status.isNotEmpty) url += '&status=$status';
    if (orderId != null) url += '&order_id=$orderId';
    final res =
        await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getPaymentStatus(int sessionId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/payments/status/$sessionId'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ---- POS ----

  Future<Map<String, dynamic>> createPosOrder(Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/pos/orders'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));
    return _decode(res);
  }

  Future<Map<String, dynamic>> getKot(int orderId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pos/kot/$orderId'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getPosBill(int orderId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pos/bill/$orderId'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ---- INVENTORY ----

  Future<Map<String, dynamic>> getInventoryRequests({String? status}) async {
    String url = '${ApiConfig.baseUrl}/inventory/requests';
    if (status != null && status.isNotEmpty) url += '?status=$status';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> updateInventoryRequestStatus(
      int id, String status) async {
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/inventory/requests/$id/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getMaterials() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/inventory/materials'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> saveMaterial(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inventory/materials'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> adjustMaterial(
      int id, double changeQty, String type, String notes) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/inventory/materials/$id/adjust'),
      headers: await _headers(),
      body: jsonEncode({
        'change_qty': changeQty,
        'type': type,
        'notes': notes,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getVendors() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/inventory/vendors'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> createVendor(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inventory/vendors'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getPurchases() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/inventory/purchases'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inventory/purchases'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getLedger({int? materialId}) async {
    String url = '${ApiConfig.baseUrl}/inventory/ledger';
    if (materialId != null) url += '?material_id=$materialId';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> getLowStock() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/inventory/low-stock'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getRecipe(int menuItemId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/inventory/recipes/$menuItemId'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> saveRecipe(
      int menuItemId, List<Map<String, dynamic>> materials) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inventory/recipes/$menuItemId'),
      headers: await _headers(),
      body: jsonEncode({'materials': materials}),
    );
    return _decode(res);
  }
}
