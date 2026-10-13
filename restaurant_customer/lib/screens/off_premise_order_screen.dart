import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/debug_flags.dart';
import '../providers/order_provider.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../config/responsive.dart';

class OffPremiseOrderScreen extends StatefulWidget {
  final int restaurantId;

  const OffPremiseOrderScreen({super.key, this.restaurantId = 1});

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
    setState(() {
      _loading = true;
      _error = '';
    });
    final result = await _api.sendOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _otpSent = result['success'] == true;
      _testOtp = result['data']?['otp']?.toString();
      _error = result['success'] == true
          ? ''
          : (result['message'] ?? 'Unable to send OTP');
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final result = await _api.verifyOtp(
      _phoneCtrl.text.trim(),
      _otpCtrl.text.trim(),
    );
    if (result['success'] == true) {
      final menu = await _api.getMenu(widget.restaurantId.toString());
      if (!mounted) return;
      setState(() {
        _categories = menu['success'] == true
            ? (menu['data']['menu'] ?? [])
            : [];
        _verified = true;
        _loading = false;
      });
    } else if (mounted) {
      setState(() {
        _loading = false;
        _error = result['message'] ?? 'Incorrect OTP';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_verified) return _authView();
    final subtotal = _cart.fold<double>(
      0,
      (sum, item) => sum + _amount(item['price']) * (item['qty'] as int),
    );
    final deliveryFee = _mode == 'delivery' ? 40.0 : 0.0;
    final total = subtotal + (subtotal * .05) + (subtotal * .05) + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1E2022),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _mode == 'delivery' ? 'Delivery Order' : 'Takeaway Order',
          style: const TextStyle(
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _mode == 'delivery'
                      ? Icons.delivery_dining_rounded
                      : Icons.shopping_bag_rounded,
                  size: 14,
                  color: const Color(0xFFF45B15),
                ),
                const SizedBox(width: 4),
                Text(
                  _mode == 'delivery' ? 'Delivery' : 'Takeaway',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF45B15),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: CustomerPage(
        maxWidth: 620,
        child: Column(
          children: [
            // Mode switcher capsule + Delivery details
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFECECEC)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _modeTab(
                          label: 'Takeaway',
                          icon: Icons.shopping_bag_outlined,
                          isSelected: _mode == 'takeaway',
                          onTap: () => setState(() => _mode = 'takeaway'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _modeTab(
                          label: 'Delivery',
                          icon: Icons.delivery_dining_rounded,
                          isSelected: _mode == 'delivery',
                          onTap: () => setState(() => _mode = 'delivery'),
                        ),
                      ),
                    ],
                  ),
                  if (_mode == 'delivery') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Delivery Address',
                        hintText: 'House/Flat no, building, street',
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFF45B15),
                          size: 20,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF45B15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _landmarkCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Landmark (optional)',
                        prefixIcon: const Icon(
                          Icons.near_me_outlined,
                          color: Color(0xFF9EA1A8),
                          size: 18,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF45B15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: _menuList()),
            if (_cart.isNotEmpty)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_cart.length} item${_cart.length > 1 ? 's' : ''} in cart',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF75787E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E2022),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Row(
                              children: [
                                _paymentChip('Online', 'prepaid'),
                                _paymentChip('Cash/Pay on Pickup', 'cod'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : () => _placeOrder(total),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF45B15),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _paymentMode == 'prepaid'
                                          ? 'Proceed to Pay ₹${total.toStringAsFixed(0)}'
                                          : 'Confirm Order (₹${total.toStringAsFixed(0)})',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF45B15) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF45B15)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF75787E),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF1E2022),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentChip(String label, String value) {
    final selected = _paymentMode == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? const Color(0xFFF45B15) : const Color(0xFF75787E),
          ),
        ),
      ),
    );
  }

  Widget _authView() => Scaffold(
    backgroundColor: const Color(0xFFF9F9FB),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF1E2022),
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Order Online',
        style: TextStyle(
          color: Color(0xFF1E2022),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFECECEC), height: 1),
      ),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFECECEC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF7A3D), Color(0xFFF45B15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x35F45B15),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _otpSent ? 'Verify Phone' : 'Start Your Order',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2022),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _otpSent
                    ? 'Enter the 6-digit OTP sent to your phone'
                    : 'Enter your mobile number for takeaway or delivery',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF75787E)),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _phoneCtrl,
                enabled: !_otpSent,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91 ',
                  counterText: '',
                  prefixIcon: const Icon(
                    Icons.phone_iphone_rounded,
                    color: Color(0xFFF45B15),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFF45B15)),
                  ),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w800,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '6-Digit OTP',
                    counterText: '',
                    hintText: '• • • • • •',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFF45B15)),
                    ),
                  ),
                ),
              ],
              if (kShowTestOtp && _testOtp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: InkWell(
                    onTap: () => _otpCtrl.text = _testOtp!,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        'Test OTP: $_testOtp (Tap to copy)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_otpSent ? _verifyOtp : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF45B15),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _otpSent ? 'Verify & Continue' : 'Send OTP',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _menuList() {
    final items = <dynamic>[];
    for (final category in _categories) {
      items.addAll(category['items'] as List? ?? []);
    }
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items found',
          style: TextStyle(color: Color(0xFF75787E)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        final cartIndex = _cart.indexWhere(
          (entry) => entry['id'] == item['id'],
        );
        final quantity = cartIndex < 0 ? 0 : _cart[cartIndex]['qty'] as int;
        final isVeg = item['is_veg'] == true || item['is_veg'] == 1;
        final price = _amount(item['price']);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Food image or styled avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFFFFF2EB),
                  child:
                      item['image_url'] != null &&
                          (item['image_url'] as String).isNotEmpty
                      ? Image.network(
                          item['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFFF45B15),
                            size: 26,
                          ),
                        )
                      : const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFFF45B15),
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isVeg
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                              width: 1.3,
                            ),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isVeg
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1E2022),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFFF45B15),
                      ),
                    ),
                  ],
                ),
              ),

              // Add / Quantity Controls
              if (quantity == 0)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF45B15),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30F45B15),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => _add(item),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD4C2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _change(cartIndex, -1),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Icon(
                            Icons.remove_rounded,
                            size: 16,
                            color: Color(0xFFF45B15),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFFF45B15),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _change(cartIndex, 1),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Color(0xFFF45B15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _add(dynamic item) => setState(
    () => _cart.add({
      'id': item['id'],
      'name': item['name'],
      'price': _amount(item['price']),
      'qty': 1,
    }),
  );
  void _change(int index, int delta) => setState(() {
    final quantity = (_cart[index]['qty'] as int) + delta;
    if (quantity == 0) {
      _cart.removeAt(index);
    } else {
      _cart[index]['qty'] = quantity;
    }
  });

  Future<void> _placeOrder(double total) async {
    if (_mode == 'delivery' && _addressCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter delivery address');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    final result = await _api.placeOffPremiseOrder(
      restaurantId: widget.restaurantId,
      orderType: _mode,
      paymentMode: _paymentMode,
      phone: _phoneCtrl.text.trim(),
      deliveryAddress: _addressCtrl.text.trim(),
      deliveryLandmark: _landmarkCtrl.text.trim(),
      deliveryCharge: _mode == 'delivery' ? 40 : 0,
      items: _cart
          .map(
            (item) => {
              'menu_item_id': item['id'],
              'quantity': item['qty'],
              'modifiers': [],
            },
          )
          .toList(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] != true) {
      setState(() => _error = result['message'] ?? 'Unable to place order');
      return;
    }
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
      final paid = await context.read<OrderProvider>().processUpiPayment(
        sessionId: sessionId,
        amount: total,
      );
      if (!paid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order is placed. Complete payment from tracking.'),
          ),
        );
      }
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OffPremiseTrackingScreen(
          sessionId: sessionId,
          orderType: _mode,
          pickupToken: data['pickup_token']?.toString(),
        ),
      ),
    );
  }

  double _amount(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
}

class OffPremiseTrackingScreen extends StatefulWidget {
  final String sessionId;
  final String orderType;
  final String? pickupToken;
  const OffPremiseTrackingScreen({
    super.key,
    required this.sessionId,
    required this.orderType,
    this.pickupToken,
  });
  @override
  State<OffPremiseTrackingScreen> createState() =>
      _OffPremiseTrackingScreenState();
}

class _OffPremiseTrackingScreenState extends State<OffPremiseTrackingScreen> {
  final _api = ApiService();
  Timer? _timer;
  List<dynamic> _orders = [];
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _api.getMyOrders(widget.sessionId);
    if (mounted && result['success'] == true) {
      setState(() => _orders = result['data'] ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _orders.isEmpty ? null : _orders.first;
    final deliveryStatus = latest?['delivery_status'] ?? 'new';
    final title = widget.orderType == 'delivery'
        ? 'Delivery tracking'
        : 'Pickup tracking';
    final status = widget.orderType == 'delivery'
        ? deliveryStatus
        : (latest?['status'] ?? 'placed');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF45B15),
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: CustomerPage(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(
                widget.orderType == 'delivery'
                    ? Icons.delivery_dining
                    : Icons.shopping_bag,
                size: 64,
                color: const Color(0xFFF45B15),
              ),
              const SizedBox(height: 14),
              Text(
                widget.orderType == 'delivery'
                    ? 'Your order is $status'
                    : 'Your order is ${latest?['status'] ?? 'placed'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.pickupToken != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Pickup token: ${widget.pickupToken}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ..._orders.map(
                (order) => Card(
                  child: ListTile(
                    title: Text('Order #${order['id']}'),
                    subtitle: Text(
                      '${order['status']} • ₹${order['final_amount']}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
