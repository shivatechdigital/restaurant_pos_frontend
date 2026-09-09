import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';
import '../services/razorpay_web_service.dart';
import '../config/socket_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // Current order state
  int? _currentOrderId;
  String _currentStatus = OrderStatus.placed;
  String _statusMessage = '';
  bool _isLoading = false;
  String _error = '';

  // Session
  String? _sessionId;

  // Bill
  BillData? _bill;

  // Order history (is session ke saare orders)
  List<OrderData> _orderHistory = [];
  bool _customerSelfCancelEnabled = false;

  // Getters
  int? get currentOrderId => _currentOrderId;
  String get currentStatus => _currentStatus;
  String get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;
  String get error => _error;
  String? get sessionId => _sessionId;
  BillData? get bill => _bill;
  List<OrderData> get orderHistory => _orderHistory;
  bool get customerSelfCancelEnabled => _customerSelfCancelEnabled;
  bool get isOrderActive =>
      _currentStatus != OrderStatus.served &&
      _currentStatus != OrderStatus.cancelled;

  // ---- SETUP ----

  void setSessionId(String id) {
    _sessionId = id;
    notifyListeners();
  }

  Future<void> loadCancellationPolicy() async {
    try {
      final result = await _api.getOrderPolicy();
      if (result['success'] == true) {
        _customerSelfCancelEnabled = result['data']?['kitchen_mode'] == 'kds' && result['data']?['customer_self_cancel'] == true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cancellation policy error: $e');
    }
  }

  // Socket.io listeners setup karo
  void setupSocketListeners() {
    final socket = SocketService();

    // Order status update (Kitchen se aayega)
    socket.on('order_status_update', (data) {
      final map = data is Map ? Map<String, dynamic>.from(data) : {};
      final orderId = map['order_id'];
      final status = map['status'] as String?;
      final message = map['message'] as String?;

      // Sirf current order ka update lo
      if (orderId == _currentOrderId && status != null) {
        _currentStatus = status;
        _statusMessage = message ?? OrderStatus.getMessage(status);
        notifyListeners();
      }
    });

    // Order placed confirmation
    socket.on('order_placed', (data) {
      final map = data is Map ? Map<String, dynamic>.from(data) : {};
      final message = map['message'] as String?;
      if (message != null) {
        _statusMessage = message;
        notifyListeners();
      }
    });

    // Bill generated (Waiter ne bill bheja)
    socket.on('bill_generated', (data) {
      final map = data is Map ? Map<String, dynamic>.from(data) : {};
      if (map['bill'] != null) {
        _bill = BillData.fromJson(map['bill']);
        notifyListeners();
      }
    });

    // Payment success
    socket.on('payment_success', (data) {
      // Phase 4 mein handle hoga
      notifyListeners();
    });
  }

  // ---- PLACE ORDER ----

  Future<bool> placeOrder({
    required int tableId,
    required int restaurantId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phone') ?? '';

      final result = await _api.placeOrder(
        tableId: tableId,
        restaurantId: restaurantId,
        phone: phone,
        items: items,
        notes: notes,
        sessionId: _sessionId != null ? int.tryParse(_sessionId!) : null,
      );

      _isLoading = false;

      if (result['success'] == true) {
        final data = result['data'];
        _currentOrderId = data['order_id'];
        _sessionId = data['session_id'].toString();
        _currentStatus = OrderStatus.placed;
        _statusMessage = OrderStatus.getMessage(OrderStatus.placed);

        // Socket listeners setup (agar nahi kiya)
        setupSocketListeners();

        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Order place nahi hua';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error. Try again.';
      notifyListeners();
      return false;
    }
  }

  // ---- CANCEL ORDER ----

  Future<bool> cancelOrder() async {
    if (_currentOrderId == null) return false;

    if (!_customerSelfCancelEnabled || _currentStatus != OrderStatus.placed) {
      _error = 'Order already kitchen mein hai. Waiter se baat karo.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.cancelOrder(_currentOrderId!);
      _isLoading = false;

      if (result['success'] == true) {
        _currentStatus = OrderStatus.cancelled;
        _statusMessage = OrderStatus.getMessage(OrderStatus.cancelled);
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Cancel nahi hua';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error';
      notifyListeners();
      return false;
    }
  }

  // ---- LOAD BILL ----

  Future<void> loadBill() async {
    if (_sessionId == null) return;

    try {
      final result = await _api.getBill(_sessionId!);
      if (result['success'] == true) {
        _bill = BillData.fromJson(result['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Bill load error: $e');
    }
  }

  // ---- LOAD ORDER HISTORY ----

  Future<void> loadOrderHistory() async {
    if (_sessionId == null) return;

    try {
      final result = await _api.getMyOrders(_sessionId!);
      if (result['success'] == true) {
        final orders = result['data'] as List;
        _orderHistory =
            orders.map((o) => OrderData.fromJson(o)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('History load error: $e');
    }
  }

  // ---- RESET (Naya order start karne ke liye) ----

  void resetForNewOrder() {
    _currentOrderId = null;
    _currentStatus = OrderStatus.placed;
    _statusMessage = '';
    _error = '';
    _bill = null;
    notifyListeners();
  }

  // ---- PAYMENT ----

  bool _isPaymentProcessing = false;
  String _paymentStatus = PaymentStatus.pending;
  String _paymentError = '';

  bool get isPaymentProcessing => _isPaymentProcessing;
  String get paymentStatus => _paymentStatus;
  String get paymentError => _paymentError;

  // UPI Payment (Razorpay)
  Future<bool> processUpiPayment({
    required String sessionId,
    required double amount,
  }) async {
    _isPaymentProcessing = true;
    _paymentError = '';
    _paymentStatus = PaymentStatus.pending;
    notifyListeners();

    try {
      // Step 1: Backend se Razorpay order create karo
      final createResult = await _api.createPayment(sessionId, amount);

      if (createResult['success'] != true) {
        _paymentError = createResult['message'] ?? 'Payment order create nahi hua';
        _isPaymentProcessing = false;
        notifyListeners();
        return false;
      }

      final paymentOrder = PaymentOrder.fromJson(createResult['data']);

      // Step 2: Razorpay Checkout open karo (Web)
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phone') ?? '';

      final paymentResult = await RazorpayWebService.openCheckout(
        keyId: paymentOrder.keyId,
        razorpayOrderId: paymentOrder.razorpayOrderId,
        amountInPaisa: paymentOrder.amountInPaisa,
        customerName: 'Customer',
        customerPhone: phone,
        description: 'Table Bill Payment',
      );

      if (paymentResult == null) {
        _paymentError = 'Payment cancelled ya failed';
        _isPaymentProcessing = false;
        notifyListeners();
        return false;
      }

      // Step 3: Payment verify karo (Backend signature check)
      final verifyResult = await _api.verifyPayment(
        razorpayOrderId: paymentResult.razorpayOrderId,
        razorpayPaymentId: paymentResult.razorpayPaymentId,
        razorpaySignature: paymentResult.razorpaySignature,
        sessionId: sessionId,
      );

      _isPaymentProcessing = false;

      if (verifyResult['success'] == true) {
        _paymentStatus = PaymentStatus.success;
        notifyListeners();
        return true;
      } else {
        _paymentError = verifyResult['message'] ?? 'Payment verification failed';
        _paymentStatus = PaymentStatus.failed;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isPaymentProcessing = false;
      _paymentError = 'Payment error: $e';
      _paymentStatus = PaymentStatus.failed;
      notifyListeners();
      return false;
    }
  }

  // Cash Payment
  Future<bool> processCashPayment({
    required String sessionId,
    required double amount,
  }) async {
    _isPaymentProcessing = true;
    _paymentError = '';
    notifyListeners();

    try {
      final result = await _api.cashPayment(sessionId, amount);
      _isPaymentProcessing = false;

      if (result['success'] == true) {
        _paymentStatus = PaymentStatus.cash;
        notifyListeners();
        return true;
      } else {
        _paymentError = result['message'] ?? 'Cash payment record nahi hua';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isPaymentProcessing = false;
      _paymentError = 'Network error';
      notifyListeners();
      return false;
    }
  }
}
