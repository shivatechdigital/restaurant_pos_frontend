import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/debug_flags.dart';
import '../providers/order_provider.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class OffPremiseOrderScreen extends StatefulWidget {
  const OffPremiseOrderScreen({super.key});

  @override
  State<OffPremiseOrderScreen> createState() => _OffPremiseOrderScreenState();
}

class _OffPremiseOrderScreenState extends State<OffPremiseOrderScreen> {
  final _api = ApiService();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final List<Map<String, dynamic>> _cart = [];
  List<dynamic> _categories = [];
  bool _otpSent = false;
  bool _verified = false;
  bool _loading = false;
  String _mode = 'takeaway';
  String _paymentMode = 'prepaid';
  String _error = '';
  String? _testOtp;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    final result = await _api.sendOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _otpSent = result['success'] == true;
      _testOtp = result['data']?['otp']?.toString();
      _error = result['success'] == true ? '' : (result['message'] ?? 'Unable to send OTP');
    });
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = ''; });
    final result = await _api.verifyOtp(_phoneCtrl.text.trim(), _otpCtrl.text.trim());
    if (result['success'] == true) {
      final menu = await _api.getMenu('1');
      if (!mounted) return;
      setState(() { _categories = menu['success'] == true ? (menu['data']['menu'] ?? []) : []; _verified = true; _loading = false; });
    } else if (mounted) {
      setState(() { _loading = false; _error = result['message'] ?? 'Incorrect OTP'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_verified) return _authView();
    final subtotal = _cart.fold<double>(0, (sum, item) => sum + _amount(item['price']) * (item['qty'] as int));
    final deliveryFee = _mode == 'delivery' ? 40.0 : 0.0;
    final total = subtotal + (subtotal * .05) + (subtotal * .05) + deliveryFee;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, title: Text(_mode == 'delivery' ? 'Delivery Order' : 'Takeaway Order')),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'takeaway', icon: Icon(Icons.shopping_bag_outlined), label: Text('Takeaway')), ButtonSegment(value: 'delivery', icon: Icon(Icons.delivery_dining), label: Text('Delivery'))], selected: {_mode}, onSelectionChanged: (value) => setState(() => _mode = value.first)),
            if (_mode == 'delivery') ...[
              const SizedBox(height: 10),
              TextField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Delivery address', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _landmarkCtrl, decoration: const InputDecoration(labelText: 'Landmark (optional)', border: OutlineInputBorder())),
            ],
          ]),
        ),
        Expanded(child: _menuList()),
        if (_cart.isNotEmpty) Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: SafeArea(child: Column(children: [
            Text('${_cart.length} item types • ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(segments: const [ButtonSegment(value: 'prepaid', label: Text('Pay Online')), ButtonSegment(value: 'cod', label: Text('Cash on Delivery/Pickup'))], selected: {_paymentMode}, onSelectionChanged: (value) => setState(() => _paymentMode = value.first)),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _loading ? null : () => _placeOrder(total), icon: const Icon(Icons.arrow_forward), label: Text(_paymentMode == 'prepaid' ? 'Place & Pay ₹${total.toStringAsFixed(0)}' : 'Place Order ₹${total.toStringAsFixed(0)}'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white))),
          ])),
        ),
      ]),
    );
  }

  Widget _authView() => Scaffold(
    backgroundColor: const Color(0xFF1B5E20),
    appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: const Text('Order for Pickup or Delivery')),
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Container(
      constraints: const BoxConstraints(maxWidth: 420), padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.restaurant_menu, size: 48, color: Color(0xFF1B5E20)), const SizedBox(height: 12),
        Text(_otpSent ? 'Verify your number' : 'Start your order', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 18),
        TextField(controller: _phoneCtrl, enabled: !_otpSent, keyboardType: TextInputType.phone, maxLength: 10, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Mobile number', prefixText: '+91 ', border: OutlineInputBorder(), counterText: '')),
        if (_otpSent) ...[const SizedBox(height: 12), TextField(controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'OTP', border: OutlineInputBorder(), counterText: ''))],
        if (kShowTestOtp && _testOtp != null) Padding(padding: const EdgeInsets.only(top: 10), child: Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)), child: Text('Test OTP: $_testOtp', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)))),
        if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white), child: Text(_loading ? 'Please wait...' : (_otpSent ? 'Verify & continue' : 'Send OTP')))),
      ]),
    ))),
  );

  Widget _menuList() {
    final items = <dynamic>[];
    for (final category in _categories) { items.addAll(category['items'] as List? ?? []); }
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (_, index) {
      final item = items[index];
      final cartIndex = _cart.indexWhere((entry) => entry['id'] == item['id']);
      final quantity = cartIndex < 0 ? 0 : _cart[cartIndex]['qty'] as int;
      return Card(child: ListTile(title: Text(item['name'] ?? ''), subtitle: Text('₹${_amount(item['price']).toStringAsFixed(0)}'), trailing: quantity == 0 ? IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E20)), onPressed: () => _add(item)) : Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _change(cartIndex, -1)), Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.add_circle), color: const Color(0xFF1B5E20), onPressed: () => _change(cartIndex, 1))])));
    });
  }

  void _add(dynamic item) => setState(() => _cart.add({'id': item['id'], 'name': item['name'], 'price': _amount(item['price']), 'qty': 1}));
  void _change(int index, int delta) => setState(() { final quantity = (_cart[index]['qty'] as int) + delta; if (quantity == 0) { _cart.removeAt(index); } else { _cart[index]['qty'] = quantity; } });

  Future<void> _placeOrder(double total) async {
    if (_mode == 'delivery' && _addressCtrl.text.trim().isEmpty) { setState(() => _error = 'Enter delivery address'); return; }
    setState(() { _loading = true; _error = ''; });
    final result = await _api.placeOffPremiseOrder(restaurantId: 1, orderType: _mode, phone: _phoneCtrl.text.trim(), deliveryAddress: _addressCtrl.text.trim(), deliveryLandmark: _landmarkCtrl.text.trim(), deliveryCharge: _mode == 'delivery' ? 40 : 0, items: _cart.map((item) => {'menu_item_id': item['id'], 'quantity': item['qty'], 'modifiers': []}).toList());
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] != true) { setState(() => _error = result['message'] ?? 'Unable to place order'); return; }
    final data = result['data'];
    final sessionId = data['session_id'].toString();
    await SessionService.saveOffPremiseSession(
      sessionId: sessionId,
      orderType: _mode,
      pickupToken: data['pickup_token']?.toString(),
    );
    if (!mounted) return;
    context.read<OrderProvider>().setSessionId(sessionId);
    if (_paymentMode == 'prepaid') {
      final paid = await context.read<OrderProvider>().processUpiPayment(sessionId: sessionId, amount: total);
      if (!paid && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order is placed. Complete payment from tracking.'))); }
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OffPremiseTrackingScreen(sessionId: sessionId, orderType: _mode, pickupToken: data['pickup_token']?.toString())));
  }

  double _amount(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

class OffPremiseTrackingScreen extends StatefulWidget {
  final String sessionId;
  final String orderType;
  final String? pickupToken;
  const OffPremiseTrackingScreen({super.key, required this.sessionId, required this.orderType, this.pickupToken});
  @override State<OffPremiseTrackingScreen> createState() => _OffPremiseTrackingScreenState();
}

class _OffPremiseTrackingScreenState extends State<OffPremiseTrackingScreen> {
  final _api = ApiService();
  Timer? _timer;
  List<dynamic> _orders = [];
  @override void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 12), (_) => _load()); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  Future<void> _load() async { final result = await _api.getMyOrders(widget.sessionId); if (mounted && result['success'] == true) setState(() => _orders = result['data'] ?? []); }
  @override Widget build(BuildContext context) {
    final latest = _orders.isEmpty ? null : _orders.first;
    final deliveryStatus = latest?['delivery_status'] ?? 'new';
    final title = widget.orderType == 'delivery' ? 'Delivery tracking' : 'Pickup tracking';
    final status = widget.orderType == 'delivery' ? deliveryStatus : (latest?['status'] ?? 'placed');
    return Scaffold(appBar: AppBar(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, title: Text(title)), body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
      Icon(widget.orderType == 'delivery' ? Icons.delivery_dining : Icons.shopping_bag, size: 64, color: const Color(0xFF1B5E20)), const SizedBox(height: 14),
      Text(widget.orderType == 'delivery' ? 'Your order is $status' : 'Your order is ${latest?['status'] ?? 'placed'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      if (widget.pickupToken != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text('Pickup token: ${widget.pickupToken}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold))),
      const SizedBox(height: 24), ..._orders.map((order) => Card(child: ListTile(title: Text('Order #${order['id']}'), subtitle: Text('${order['status']} • ₹${order['final_amount']}')))),
    ])));
  }
}
