import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  int restaurantId = 1;
  String adminName = 'Admin';
  bool isLoading = false;

  // Dashboard
  Map<String, dynamic>? dashboard;
  List<dynamic> topItems = [];
  Map<String, dynamic>? revenueData;
  Map<String, dynamic>? dailyClosingData;
  List<dynamic> cashShifts = [];
  List<dynamic> coupons = [];
  List<dynamic> customers = [];
  List<dynamic> deliveryPartners = [];
  List<dynamic> reservations = [];

  // Menu
  List<dynamic> menuCategories = [];

  // Tables
  List<dynamic> tables = [];

  // Orders
  List<dynamic> orders = [];
  int totalOrders = 0;
  bool isOrdersLoading = false;

  // Staff
  List<dynamic> staff = [];
  List<dynamic> staffMembers = [];
  List<dynamic> auditLogs = [];

  // GST
  Map<String, dynamic>? gstData;

  // Inventory
  List<dynamic> inventoryRequests = [];
  List<dynamic> materials = [];
  List<dynamic> vendors = [];
  List<dynamic> purchases = [];
  List<dynamic> ledger = [];
  List<dynamic> lowStock = [];

  // ---- INIT ----
  void setRestaurant(int id, String name) {
    restaurantId = id;
    adminName = name;
    notifyListeners();
  }

  String? staffError; // Added to hold the error message for staff creation
  // ---- DASHBOARD ----
  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();
    try {
      final r = await _api.getDashboard();
      if (r['success'] == true) dashboard = r['data'];

      final t = await _api.getTopItems();
      if (t['success'] == true) topItems = t['data']['top_items'] ?? [];

      final rev = await _api.getRevenue();
      if (rev['success'] == true) revenueData = rev['data'];
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadDailyClosing({String? date}) async {
    try {
      final r = await _api.getDailyClosing(date: date);
      if (r['success'] == true) {
        dailyClosingData = r['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Daily closing error: $e');
    }
  }

  Future<void> loadCashShifts({String? date}) async {
    try {
      final r = await _api.getCashShifts(date: date);
      if (r['success'] == true) {
        cashShifts = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cash shifts error: $e');
    }
  }

  Future<void> loadCoupons() async {
    try {
      final r = await _api.getCoupons();
      if (r['success'] == true) {
        coupons = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Coupons error: $e');
    }
  }

  Future<void> loadDeliveryPartners() async {
    try {
      final r = await _api.getDeliveryPartners();
      if (r['success'] == true) {
        deliveryPartners = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Delivery partners error: $e');
    }
  }

  Future<bool> createDeliveryPartner(Map<String, dynamic> body) async {
    try {
      final r = await _api.createDeliveryPartner(body);
      if (r['success'] == true) {
        await loadDeliveryPartners();
        return true;
      }
    } catch (e) {
      debugPrint('Create partner error: $e');
    }
    return false;
  }

  Future<void> loadReservations() async {
    try {
      final r = await _api.getReservations();
      if (r['success'] == true) {
        reservations = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Reservations error: $e');
    }
  }

  Future<bool> createReservation(Map<String, dynamic> body) async {
    try {
      final r = await _api.createReservation(body);
      if (r['success'] == true) {
        await loadReservations();
        await loadTables();
        return true;
      }
    } catch (e) {
      debugPrint('Create reservation error: $e');
    }
    return false;
  }

  Future<bool> checkInReservation(int id) async {
    try {
      final r = await _api.checkInReservation(id);
      if (r['success'] == true) {
        await loadReservations();
        await loadTables();
        return true;
      }
    } catch (e) {
      debugPrint('Reservation check-in error: $e');
    }
    return false;
  }

  Future<bool> assignDelivery(int orderId, int partnerId) async {
    try {
      final r = await _api.assignDelivery(orderId, partnerId);
      if (r['success'] == true) {
        await loadOrders();
        return true;
      }
    } catch (e) {
      debugPrint('Assign delivery error: $e');
    }
    return false;
  }

  Future<bool> updateDeliveryStatus(int orderId, String status) async {
    try {
      final r = await _api.updateDeliveryStatus(orderId, status);
      if (r['success'] == true) {
        await loadOrders();
        return true;
      }
    } catch (e) {
      debugPrint('Delivery status error: $e');
    }
    return false;
  }

  Future<void> loadCustomers({String? search, String? segment}) async {
    try {
      final r = await _api.getCustomers(search: search, segment: segment);
      if (r['success'] == true) {
        customers = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Customers error: $e');
    }
  }

  Future<Map<String, dynamic>?> loadCustomer(int id) async {
    try {
      final r = await _api.getCustomer(id);
      return r['success'] == true ? r['data'] : null;
    } catch (e) {
      debugPrint('Customer profile error: $e');
    }
    return null;
  }

  Future<bool> updateCustomer(int id, Map<String, dynamic> body) async {
    try {
      final r = await _api.updateCustomer(id, body);
      if (r['success'] == true) {
        await loadCustomers();
        return true;
      }
    } catch (e) {
      debugPrint('Customer update error: $e');
    }
    return false;
  }

  Future<bool> createCoupon(Map<String, dynamic> body) async {
    try {
      final r = await _api.createCoupon(body);
      if (r['success'] == true) {
        await loadCoupons();
        return true;
      }
    } catch (e) {
      debugPrint('Coupon create error: $e');
    }
    return false;
  }

  Future<bool> toggleCoupon(int id, bool isActive) async {
    try {
      final r = await _api.toggleCoupon(id, isActive);
      if (r['success'] == true) {
        await loadCoupons();
        return true;
      }
    } catch (e) {
      debugPrint('Coupon toggle error: $e');
    }
    return false;
  }

  Future<bool> openCashShift(Map<String, dynamic> body) async {
    try {
      final r = await _api.openCashShift(body);
      if (r['success'] == true) {
        await loadCashShifts();
        return true;
      }
    } catch (e) {
      debugPrint('Open shift error: $e');
    }
    return false;
  }

  Future<bool> closeCashShift(int id, Map<String, dynamic> body) async {
    try {
      final r = await _api.closeCashShift(id, body);
      if (r['success'] == true) {
        await loadCashShifts();
        return true;
      }
    } catch (e) {
      debugPrint('Close shift error: $e');
    }
    return false;
  }

  Future<bool> reopenDay(String date, String reason) async {
    try {
      final r = await _api.reopenDay(date, reason);
      if (r['success'] == true) {
        await loadDailyClosing(date: date);
        return true;
      }
    } catch (e) {
      debugPrint('Reopen day error: $e');
    }
    return false;
  }

  Future<String?> downloadDailyClosingCsv(String date) =>
      _api.downloadDailyClosingCsv(date);

  Future<bool> closeDay(Map<String, dynamic> body) async {
    try {
      final r = await _api.closeDay(body);
      if (r['success'] == true) {
        dailyClosingData = r['data'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Close day error: $e');
    }
    return false;
  }

  // ---- MENU ----
  Future<void> loadMenu() async {
    try {
      final r = await _api.getMenu(restaurantId.toString());
      if (r['success'] == true) {
        menuCategories = r['data']['menu'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Menu error: $e');
    }
  }

  Future<bool> toggleItemAvailability(int id, bool available) async {
    try {
      final r = await _api.toggleItem(id, available);
      if (r['success'] == true) {
        await loadMenu();
        return true;
      }
    } catch (e) {
      debugPrint('Toggle item error: $e');
    }
    return false;
  }

  Future<bool> createMenuItem(Map<String, dynamic> body) async {
    try {
      final r = await _api.addMenuItem(body);
      if (r['success'] == true) {
        await loadMenu();
        return true;
      }
    } catch (e) {
      debugPrint('Create item error: $e');
    }
    return false;
  }

  Future<String?> uploadMenuImage(List<int> bytes, String filename) async {
    try {
      final r = await _api.uploadMenuImage(bytes, filename);
      if (r['success'] == true) return r['data']['url'];
    } catch (e) {
      debugPrint('Upload image error: $e');
    }
    return null;
  }

  Future<bool> createCategory(String name) async {
    try {
      final r = await _api.addCategory(name, menuCategories.length);
      if (r['success'] == true) {
        await loadMenu();
        return true;
      }
    } catch (e) {
      debugPrint('Create category error: $e');
    }
    return false;
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final r = await _api.deleteCategory(id);
      if (r['success'] == true) {
        await loadMenu();
        return true;
      }
    } catch (e) {
      debugPrint('Delete category error: $e');
    }
    return false;
  }

  Future<bool> updateMenuItem(int id, Map<String, dynamic> body) async {
    try {
      final r = await _api.updateMenuItem(id, body);
      if (r['success'] == true) {
        await loadMenu();
        return true;
      }
    } catch (e) {
      debugPrint('Update item error: $e');
    }
    return false;
  }

  Future<bool> deleteMenuItem(int id) async {
    try {
      final r = await _api.deleteMenuItem(id);
      if (r['success'] == true) {
        await loadMenu();
        return true;
      }
    } catch (e) {
      debugPrint('Delete item error: $e');
    }
    return false;
  }

  // ---- TABLES ----
  Future<void> loadTables() async {
    try {
      final r = await _api.getTables();
      if (r['success'] == true) {
        tables = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Tables error: $e');
    }
  }

  // ---- ORDERS ----
  String? ordersError;

  Future<void> loadOrders({String? date, String? status, int? orderId}) async {
    isOrdersLoading = true;
    ordersError = null;
    notifyListeners();
    try {
      final r = await _api.getAllOrders(
        date: date,
        status: status,
        orderId: orderId,
      );
      if (r['success'] == true) {
        final loadedOrders = List<dynamic>.from(r['data']['orders'] ?? []);
        orders = await _enrichOrderPayments(loadedOrders);
        totalOrders = r['data']['total'] ?? 0;
      } else {
        ordersError = r['message']?.toString() ?? 'Orders load nahi ho paaye';
      }
    } catch (e) {
      debugPrint('Orders error: $e');
      ordersError = 'Backend se connect nahi ho pa raha';
    }
    isOrdersLoading = false;
    notifyListeners();
  }

  Future<List<dynamic>> _enrichOrderPayments(List<dynamic> loadedOrders) async {
    final enriched = loadedOrders
        .map((order) => Map<String, dynamic>.from(order as Map))
        .toList();
    final missing = enriched
        .where(
          (order) =>
              order['payment_status'] == null && order['session_id'] != null,
        )
        .toList();

    for (var start = 0; start < missing.length; start += 5) {
      final end = (start + 5 < missing.length) ? start + 5 : missing.length;
      await Future.wait(
        missing.sublist(start, end).map((order) async {
          final sessionId = int.tryParse(order['session_id'].toString());
          if (sessionId == null) return;

          try {
            final response = await _api.getPaymentStatus(sessionId);
            if (response['success'] != true || response['data'] is! List)
              return;
            final payments = List<dynamic>.from(response['data']);
            if (payments.isEmpty) return;

            final successful = payments
                .where((payment) => payment['status'] == 'success')
                .toList();
            final paidAmount = successful.fold<double>(
              0,
              (sum, payment) =>
                  sum +
                  (double.tryParse(payment['amount']?.toString() ?? '') ?? 0),
            );
            final orderAmount =
                double.tryParse(order['final_amount']?.toString() ?? '') ?? 0;
            final selected = successful.isNotEmpty
                ? successful.first
                : payments.first;

            order['payment_method'] = selected['payment_method'];
            order['payment_status'] = paidAmount + 0.01 >= orderAmount
                ? 'success'
                : selected['status'];
          } catch (error) {
            debugPrint('Payment status error for session $sessionId: $error');
          }
        }),
      );
    }

    return enriched;
  }

  // ---- STAFF ----
  Future<void> loadStaff() async {
    try {
      final r = await _api.getStaffPerformance();
      if (r['success'] == true) {
        staff = r['data'] is List
            ? r['data']
            : (r['data']['staff'] ?? r['data']['performance'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Staff error: $e');
    }
  }

  Future<void> loadStaffMembers() async {
    try {
      final r = await _api.getStaffMembers();
      if (r['success'] == true) {
        staffMembers = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Staff members error: $e');
    }
  }

  Future<bool> createStaff(Map<String, dynamic> body) async {
    staffError = null;
    try {
      final r = await _api.createStaff(body);
      if (r['success'] == true) {
        await loadStaffMembers();
        await loadAuditLogs();
        return true;
      }
      staffError = r['message']?.toString() ?? 'Staff member could not be saved';
    } catch (e) {
      debugPrint('Create staff error: $e');
      staffError = e.toString();
    }
    return false;
  }

  Future<bool> updateStaffMember(int id, Map<String, dynamic> body) async {
    try {
      final r = await _api.updateStaff(id, body);
      if (r['success'] == true) {
        await loadStaffMembers();
        await loadAuditLogs();
        return true;
      }
    } catch (e) {
      debugPrint('Update staff error: $e');
    }
    return false;
  }

  Future<void> loadAuditLogs() async {
    try {
      final r = await _api.getAuditLogs();
      if (r['success'] == true) {
        auditLogs = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Audit logs error: $e');
    }
  }

  // ---- GST ----
  Future<void> loadGST(String month, String year) async {
    try {
      final r = await _api.getGSTReport(month, year);
      if (r['success'] == true) {
        gstData = r['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('GST error: $e');
    }
  }

  Future<void> loadInventoryRequests({String? status}) async {
    try {
      final r = await _api.getInventoryRequests(status: status);
      if (r['success'] == true) {
        inventoryRequests = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Inventory error: $e');
    }
  }

  Future<bool> updateInventoryStatus(int id, String status) async {
    try {
      final r = await _api.updateInventoryRequestStatus(id, status);
      if (r['success'] == true) {
        await loadInventoryRequests();
        return true;
      }
    } catch (e) {
      debugPrint('Inventory update error: $e');
    }
    return false;
  }

  Future<void> loadFullInventory() async {
    await Future.wait([
      loadMaterials(),
      loadVendors(),
      loadPurchases(),
      loadLedger(),
      loadLowStock(),
      loadInventoryRequests(),
    ]);
  }

  Future<void> loadMaterials() async {
    try {
      final r = await _api.getMaterials();
      if (r['success'] == true) {
        materials = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Materials error: $e');
    }
  }

  Future<bool> saveMaterial(Map<String, dynamic> body) async {
    try {
      final r = await _api.saveMaterial(body);
      if (r['success'] == true) {
        await loadMaterials();
        await loadLedger();
        await loadLowStock();
        return true;
      }
    } catch (e) {
      debugPrint('Save material error: $e');
    }
    return false;
  }

  Future<bool> adjustMaterial(
    int id,
    double changeQty,
    String type,
    String notes,
  ) async {
    try {
      final r = await _api.adjustMaterial(id, changeQty, type, notes);
      if (r['success'] == true) {
        await loadMaterials();
        await loadLedger();
        await loadLowStock();
        return true;
      }
    } catch (e) {
      debugPrint('Adjust material error: $e');
    }
    return false;
  }

  Future<void> loadVendors() async {
    try {
      final r = await _api.getVendors();
      if (r['success'] == true) {
        vendors = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Vendors error: $e');
    }
  }

  Future<bool> createVendor(Map<String, dynamic> body) async {
    try {
      final r = await _api.createVendor(body);
      if (r['success'] == true) {
        await loadVendors();
        return true;
      }
    } catch (e) {
      debugPrint('Create vendor error: $e');
    }
    return false;
  }

  Future<void> loadPurchases() async {
    try {
      final r = await _api.getPurchases();
      if (r['success'] == true) {
        purchases = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Purchases error: $e');
    }
  }

  Future<bool> createPurchase(Map<String, dynamic> body) async {
    try {
      final r = await _api.createPurchase(body);
      if (r['success'] == true) {
        await loadPurchases();
        await loadMaterials();
        await loadLedger();
        await loadLowStock();
        return true;
      }
    } catch (e) {
      debugPrint('Create purchase error: $e');
    }
    return false;
  }

  Future<void> loadLedger({int? materialId}) async {
    try {
      final r = await _api.getLedger(materialId: materialId);
      if (r['success'] == true) {
        ledger = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ledger error: $e');
    }
  }

  Future<void> loadLowStock() async {
    try {
      final r = await _api.getLowStock();
      if (r['success'] == true) {
        lowStock = r['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Low stock error: $e');
    }
  }

  Future<List<dynamic>> loadRecipe(int menuItemId) async {
    try {
      final r = await _api.getRecipe(menuItemId);
      if (r['success'] == true) return r['data'] ?? [];
    } catch (e) {
      debugPrint('Recipe error: $e');
    }
    return [];
  }

  Future<bool> saveRecipe(
    int menuItemId,
    List<Map<String, dynamic>> materials,
  ) async {
    try {
      final r = await _api.saveRecipe(menuItemId, materials);
      return r['success'] == true;
    } catch (e) {
      debugPrint('Save recipe error: $e');
    }
    return false;
  }
}
