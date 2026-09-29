import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/kitchen_order_model.dart';
import '../models/waiter_request_model.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';
import '../config/socket_service.dart';

class KitchenProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SoundService _sound = SoundService();

  List<KitchenOrder> _orders = [];
  bool _isLoading = false;
  String _error = '';
  String _filterStatus = '';
  Timer? _refreshTimer;
  Timer? _urgentCheckTimer;
  bool _isGridView = false; // Grid vs List toggle
  int _restaurantId = 1;
  List<WaiterRequest> _waiterRequests = [];
  List<Map<String, dynamic>> _sections = [];
  String _activeSection = ''; // '' = All sections
  Map<String, dynamic>? _stats;

  // Track kiye hue order IDs (taaki naye orders pe sound baje)
  final Set<int> _knownOrderIds = {};

  List<KitchenOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get filterStatus => _filterStatus;
  bool get isGridView => _isGridView;
  int get restaurantId => _restaurantId;
  List<WaiterRequest> get waiterRequests => _waiterRequests;
  List<WaiterRequest> get unreadRequests =>
      _waiterRequests.where((r) => !r.isRead).toList();
  List<Map<String, dynamic>> get sections => _sections;
  String get activeSection => _activeSection;
  Map<String, dynamic>? get stats => _stats;

  // Stats
  int get newOrders => _orders
      .where((o) => o.status == 'placed' || o.status == 'pending')
      .length;
  int get preparingOrders => _orders
      .where((o) => o.status == 'accepted' || o.status == 'preparing')
      .length;
  int get readyOrders => _orders.where((o) => o.status == 'ready').length;
  int get urgentOrders => _orders.where((o) => o.isUrgent).length;
  int get totalActive => _orders.length;

  // ---- INIT ----

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _restaurantId = prefs.getInt('kitchen_restaurant_id') ?? 1;
    await _sound.init();
    await loadOrders();
    await loadSections();
    startAutoRefresh();
    setupSocketListeners();
    _startUrgentChecker();
  }

  // ---- LOAD SECTIONS ----

  Future<void> loadSections() async {
    try {
      final result = await _api.getKitchenSections();
      if (result['success'] == true) {
        _sections = List<Map<String, dynamic>>.from(result['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sections load error: $e');
    }
  }

  // ---- LOAD STATS ----

  Future<void> loadStats() async {
    try {
      final result = await _api.getKitchenStats();
      if (result['success'] == true) {
        _stats = result['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Stats load error: $e');
    }
  }

  // ---- LOAD ORDERS ----

  Future<void> loadOrders({bool isSocketRefresh = false}) async {
    _isLoading = _orders.isEmpty;
    _error = '';
    notifyListeners();

    try {
      final result = await _api.getKitchenOrders(includeServed: true);

      if (result['success'] == true) {
        final ordersList = result['data']['orders'] as List;
        final newOrders = ordersList
            .map((o) => KitchenOrder.fromJson(o))
            .toList();

        // Naye orders detect karo (sound ke liye)
        if (!isSocketRefresh) {
          for (final order in newOrders) {
            if (!_knownOrderIds.contains(order.orderId) &&
                order.status == 'placed') {
              // NAYA ORDER AAYA! 🔔
              _sound.playNewOrderAlert();
            }
            _knownOrderIds.add(order.orderId);
          }
        }

        _orders = _applySectionFilter(newOrders);
        _sortOrders();
      } else {
        _error = result['message'] ?? 'Orders load nahi hue';
      }
    } catch (e) {
      _error = 'Network error';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---- SORT ----

  void _sortOrders() {
    _orders.sort((a, b) {
      // Very Urgent sabse pehle
      if (a.isVeryUrgent && !b.isVeryUrgent) return -1;
      if (!a.isVeryUrgent && b.isVeryUrgent) return 1;
      // Urgent next
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      // Status order
      final statusOrder = {
        'placed': 0,
        'accepted': 1,
        'preparing': 2,
        'ready': 3,
        'served': 4,
      };
      final statusCompare = (statusOrder[a.status] ?? 5).compareTo(
        statusOrder[b.status] ?? 5,
      );
      if (statusCompare != 0) return statusCompare;
      // Same status mein purana order pehle
      return a.placedAt.compareTo(b.placedAt);
    });
  }

  List<KitchenOrder> _applySectionFilter(List<KitchenOrder> orders) {
    if (_activeSection.isEmpty) return orders;
    return orders.where((order) => order.section == _activeSection).toList();
  }

  // ---- UPDATE STATUS ----

  Future<bool> updateStatus(int orderId, String newStatus) async {
    try {
      final result = await _api.updateOrderStatus(orderId, newStatus);

      if (result['success'] == true) {
        final idx = _orders.indexWhere((o) => o.orderId == orderId);
        if (idx >= 0) {
          final old = _orders[idx];
          _orders[idx] = KitchenOrder(
            orderId: old.orderId,
            tableId: old.tableId,
            tableNumber: old.tableNumber,
            status: newStatus,
            orderedByName: old.orderedByName,
            orderedByPhone: old.orderedByPhone,
            notes: old.notes,
            placedAt: old.placedAt,
            acceptedAt: newStatus == 'accepted'
                ? DateTime.now()
                : old.acceptedAt,
            servedAt: old.servedAt,
            minutesAgo: old.minutesAgo,
            totalAmount: old.totalAmount,
            items: old.items,
            section: old.section,
          );

          // Ready hone par sound
          if (newStatus == 'ready') {
            _sound.playReadyAlert();
          }

          _sortOrders();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ---- SOCKET.IO REAL-TIME ----

  void setupSocketListeners() {
    final socket = SocketService();

    // Naya order aaya 🔔
    socket.on('new_order', (data) {
      _sound.playNewOrderAlert();
      loadOrders(isSocketRefresh: true);
    });

    // Order status update
    socket.on('order_status_update', (data) {
      loadOrders(isSocketRefresh: true);
    });

    // Order cancel hua
    socket.on('order_cancelled', (data) {
      final map = data is Map ? Map<String, dynamic>.from(data) : {};
      final orderId = map['order_id'];
      if (orderId != null) {
        _orders.removeWhere((o) => o.orderId == orderId);
        _knownOrderIds.remove(orderId);
        notifyListeners();
      }
    });

    // Kitchen order update
    socket.on('kitchen_order_update', (data) {
      loadOrders(isSocketRefresh: true);
    });

    // Waiter request (koi customer ne waiter bulaya)
    socket.on('waiter_called', (data) {
      final map = data is Map ? Map<String, dynamic>.from(data) : {};
      addWaiterRequest({
        'table_id': 0,
        'table_number': map['table_number'] ?? '?',
        'request_type': 'general',
        'message': map['message'] ?? '🛎️ Waiter needed',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Waiter detailed request (water, tissue, etc.)
    socket.on('waiter_request', (data) {
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      addWaiterRequest(map);
    });
  }

  // ---- WAITER REQUEST HANDLER ----

  void addWaiterRequest(Map<String, dynamic> data) {
    final request = WaiterRequest.fromSocket(data);
    _waiterRequests.insert(0, request);

    // Max 20 requests rakho
    if (_waiterRequests.length > 20) {
      _waiterRequests = _waiterRequests.take(20).toList();
    }

    _sound.playUrgentAlert();
    notifyListeners();
  }

  void markRequestRead(int index) {
    if (index >= 0 && index < _waiterRequests.length) {
      _waiterRequests[index].isRead = true;
      notifyListeners();
    }
  }

  void clearAllRequests() {
    _waiterRequests.clear();
    notifyListeners();
  }

  // ---- URGENT CHECKER (Har 30 second) ----

  void _startUrgentChecker() {
    _urgentCheckTimer?.cancel();
    _urgentCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      bool hasUrgent = _orders.any((o) => o.isVeryUrgent);
      if (hasUrgent) {
        _sound.playUrgentAlert();
      }
      // Minutes ago update karo
      _orders = _orders.map((o) {
        final mins = DateTime.now().difference(o.placedAt).inMinutes;
        return KitchenOrder(
          orderId: o.orderId,
          tableId: o.tableId,
          tableNumber: o.tableNumber,
          status: o.status,
          orderedByName: o.orderedByName,
          orderedByPhone: o.orderedByPhone,
          notes: o.notes,
          placedAt: o.placedAt,
          acceptedAt: o.acceptedAt,
          servedAt: o.servedAt,
          minutesAgo: mins,
          totalAmount: o.totalAmount,
          items: o.items,
          section: o.section,
        );
      }).toList();
      _sortOrders();
      notifyListeners();
    });
  }

  // ---- AUTO REFRESH ----

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadOrders(isSocketRefresh: true);
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _urgentCheckTimer?.cancel();
  }

  // ---- FILTER ----

  void setFilter(String status) {
    _filterStatus = status;
    loadOrders();
  }

  // ---- SECTION FILTER ----

  void setSection(String section) {
    _activeSection = section;
    loadOrders();
    notifyListeners();
  }

  // ---- VIEW TOGGLE ----

  void toggleView() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // ---- SOUND ----

  void toggleMute() {
    _sound.toggleMute();
    notifyListeners();
  }

  bool get isMuted => _sound.isMuted;

  @override
  void dispose() {
    stopAutoRefresh();
    _sound.dispose();
    super.dispose();
  }
}
