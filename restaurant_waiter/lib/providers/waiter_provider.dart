import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/table_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/app_preferences.dart';
import '../config/socket_service.dart';

class WaiterProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<TableModel> _tables = [];
  List<WaiterOrder> _activeOrders = [];
  BillData? _currentBill;
  bool _isLoading = false;
  bool _isOrdersLoading = false;
  String _error = '';
  int _restaurantId = 1;
  Timer? _refreshTimer;

  List<TableModel> get tables => _tables;
  List<WaiterOrder> get activeOrders => _activeOrders;
  BillData? get currentBill => _currentBill;
  bool get isLoading => _isLoading;
  bool get isOrdersLoading => _isOrdersLoading;
  String get error => _error;
  int get restaurantId => _restaurantId;

  int get availableCount => _tables.where((t) => t.isAvailable).length;
  int get occupiedCount => _tables.where((t) => t.isOccupied).length;
  int get cleaningCount => _tables.where((t) => t.isCleaning).length;
  int get totalActiveOrders => _activeOrders.length;
  int get servedOrders => _activeOrders.where((o) => o.isServed).length;

  void setRestaurantId(int id) {
    _restaurantId = id;
  }

  Future<bool> restoreSession() async {
    final hasLogin = await _api.hasSavedLogin();
    if (!hasLogin) return false;
    _restaurantId = await _api.getSavedRestaurantId();
    SocketService().connect(_restaurantId.toString());
    return true;
  }

  Future<void> logout() async {
    stopAutoRefresh();
    SocketService().disconnect();
    await _api.logout();
    _tables = [];
    _activeOrders = [];
    _currentBill = null;
    _error = '';
    notifyListeners();
  }

  Future<void> loadTables() async {
    _isLoading = _tables.isEmpty;
    _error = '';
    notifyListeners();

    try {
      final result = await _api.getTables();
      if (result['success'] == true) {
        _tables = (result['data'] as List)
            .map((t) => TableModel.fromJson(t))
            .toList();
      } else {
        _error = result['message'] ?? 'Tables load nahi hue';
      }
    } catch (e) {
      _error = 'Network error';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveOrders() async {
    _isOrdersLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await _api.getKitchenOrders();
      if (result['success'] == true) {
        final rawData = result['data'];
        final ordersList = rawData is Map && rawData['orders'] is List
            ? rawData['orders'] as List
            : (rawData is List ? rawData : const <dynamic>[]);

        _activeOrders = ordersList
            .whereType<Map<String, dynamic>>()
            .map((o) => WaiterOrder.fromJson(o))
            .toList();

        _activeOrders.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
      } else {
        _error = result['message']?.toString() ?? 'Active orders load nahi hue';
      }
    } catch (e) {
      _error = 'Network error';
      debugPrint('Orders load error: $e');
    } finally {
      _isOrdersLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final result = await _api.updateOrderStatus(orderId, newStatus);
      if (result['success'] == true) {
        // Local update
        final idx = _activeOrders.indexWhere((o) => o.orderId == orderId);
        if (idx >= 0) {
          final old = _activeOrders[idx];
          _activeOrders[idx] = WaiterOrder(
            orderId: old.orderId,
            sessionId: old.sessionId,
            tableId: old.tableId,
            tableNumber: old.tableNumber,
            status: newStatus,
            customerName: old.customerName,
            customerPhone: old.customerPhone,
            totalAmount: old.totalAmount,
            placedAt: old.placedAt,
            minutesAgo: old.minutesAgo,
            notes: old.notes,
            items: newStatus == 'served'
                ? old.items
                    .map((item) => WaiterOrderItem(
                          name: item.name,
                          quantity: item.quantity,
                          totalPrice: item.totalPrice,
                          status: 'served',
                        ))
                    .toList()
                : old.items,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> cancelOrderManually(int orderId, String reason) async {
    try {
      final result = await _api.cancelOrderManually(orderId, reason);
      if (result['success'] == true) {
        await loadActiveOrders();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Cancellation failed'};
    }
  }

  Future<BillData?> loadBill(String sessionId) async {
    try {
      final result = await _api.getBill(sessionId);
      if (result['success'] == true) {
        _currentBill = BillData.fromJson(result['data']);
        notifyListeners();
        return _currentBill;
      }
    } catch (e) {
      debugPrint('Bill load error: $e');
    }
    return null;
  }

  Future<bool> processCashPayment(String sessionId, double amount, {String method = 'cash'}) async {
    try {
      final result = await _api.cashPayment(sessionId, amount, method: method);
      if (result['success'] == true) {
        // Table refresh karo (status change hoga)
        await loadTables();
        await loadActiveOrders();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> transferTable(int sessionId, int targetTableId) async {
    try {
      final result = await _api.transferTable(sessionId, targetTableId);
      if (result['success'] == true) {
        await loadTables();
        await loadActiveOrders();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Transfer failed'};
    }
  }

  Future<Map<String, dynamic>> mergeTables(int sourceSessionId, int targetSessionId) async {
    try {
      final result = await _api.mergeTables(sourceSessionId, targetSessionId);
      if (result['success'] == true) {
        await loadTables();
        await loadActiveOrders();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Merge failed'};
    }
  }

  void startAutoRefresh() {
    // Opt-in only (see AppPreferences.autoRefresh / Settings > Order Settings)
    // to avoid the repeated loading loops that continuous polling caused before.
    _refreshTimer?.cancel();
    if (!AppPreferences.autoRefresh) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      loadTables();
      loadActiveOrders();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void setupSocketListeners() {
    // Intentionally disabled for the waiter table map to avoid repeated refresh cycles.
    // Real-time updates can be re-enabled later with explicit user intent.
  }

  // Mark table clean
  Future<void> markTableClean(int tableId) async {
    final socket = SocketService();
    socket.emit('mark_table_clean', {
      'table_id': tableId,
      'restaurant_id': _restaurantId,
    });
    // Local update
    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx >= 0) {
      final old = _tables[idx];
      _tables[idx] = TableModel(
        id: old.id,
        tableNumber: old.tableNumber,
        capacity: old.capacity,
        status: 'available',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
