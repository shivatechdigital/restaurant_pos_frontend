import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/address_service.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'order_tracking_screen.dart';
import 'off_premise_order_screen.dart';
import 'settled_session_screen.dart';

class CartScreen extends StatefulWidget {
  final int? tableId;
  final String restaurantId;
  final String? sessionId;
  final String tableNumber;
  final bool isOffPremise;

  const CartScreen({
    super.key,
    this.tableId,
    this.restaurantId = '1',
    this.sessionId,
    this.tableNumber = '',
    this.isOffPremise = false,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacing = false;
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _instructionsCtrl = TextEditingController();

  // Off-Premise (Takeaway & Delivery) states
  late bool _isOffPremiseOrder;
  String _offPremiseMode = 'takeaway'; // 'takeaway' or 'delivery'
  String _paymentMode = 'prepaid'; // 'prepaid' or 'cod'

  // Phone controller for off-premise
  final TextEditingController _phoneCtrl = TextEditingController();

  // Delivery Address states
  final TextEditingController _addressLineCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  String _selectedAddressTag = 'Home'; // 'Home', 'Office', 'Other'
  List<SavedAddress> _savedAddresses = [];
  SavedAddress? _selectedSavedAddress;
  bool _isAddingNewAddress = false;

  @override
  void initState() {
    super.initState();
    _isOffPremiseOrder =
        widget.isOffPremise || widget.tableId == null || widget.tableId == 0;
    _initCustomerData();
  }

  Future<void> _initCustomerData() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone') ?? '';
    if (phone.isNotEmpty) {
      _phoneCtrl.text = phone;
      final list = await AddressService.getAddresses(phone);
      if (mounted) {
        setState(() {
          _savedAddresses = list;
          if (list.isNotEmpty) {
            _selectedSavedAddress = list.first;
            _isAddingNewAddress = false;
          } else {
            _isAddingNewAddress = true;
          }
        });
      }
    } else {
      _isAddingNewAddress = true;
    }
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    _instructionsCtrl.dispose();
    _phoneCtrl.dispose();
    _addressLineCtrl.dispose();
    _landmarkCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final order = context.watch<OrderProvider>();
    if (order.isSessionSettled && !_isOffPremiseOrder) {
      return SettledSessionScreen(
        sessionId: widget.sessionId ?? '',
        tableNumber: widget.tableNumber,
      );
    }

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
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _confirmClearCart(cart),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Color(0xFFF45B15),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Order Items + Add More Items button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Items (${cart.totalItems})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2022),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 18,
                            color: Color(0xFFF45B15),
                          ),
                          label: const Text(
                            'Add More Items',
                            style: TextStyle(
                              color: Color(0xFFF45B15),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Cart Items List
                    ...List.generate(cart.items.length, (index) {
                      final item = cart.items[index];
                      return _buildCartItemTile(context, cart, item, index);
                    }),

                    const SizedBox(height: 16),

                    // Special Instructions (Combined for entire order as per Screen 03 design)
                    const Text(
                      'Special Instructions (Optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _instructionsCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'E.g. less spicy, no onion, extra cheese etc.',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9EA1A8),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFECECEC),
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

                    // ---- OFF-PREMISE (TAKEAWAY VS DELIVERY) OPTIONS (Requirement 8 & 9) ----
                    if (_isOffPremiseOrder) ...[
                      const SizedBox(height: 24),
                      _buildDeliveryTakeawaySection(),
                    ],

                    const SizedBox(height: 24),

                    // Apply Coupon Section
                    Row(
                      children: [
                        const Icon(
                          Icons.percent_rounded,
                          size: 20,
                          color: Color(0xFFF45B15),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Apply Coupon',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF1E2022),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFECECEC),
                              ),
                            ),
                            child: TextField(
                              controller: _couponCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter coupon code',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9EA1A8),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No active coupons available right now.',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF45B15),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bill Summary
                    const Text(
                      'Bill Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECECEC)),
                      ),
                      child: Column(
                        children: [
                          _buildBillLine('Items Total', cart.subtotal),
                          const SizedBox(height: 10),
                          _buildBillLine('Taxes (5%)', cart.gst),
                          const SizedBox(height: 10),
                          _buildBillLine('Service Charge', cart.serviceCharge),
                          if (_isOffPremiseOrder &&
                              _offPremiseMode == 'delivery') ...[
                            const SizedBox(height: 10),
                            _buildBillLine('Delivery Charge', 40.0),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFECECEC)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E2022),
                                ),
                              ),
                              Text(
                                '₹${(cart.totalAmount + ((_isOffPremiseOrder && _offPremiseMode == 'delivery') ? 40.0 : 0.0)).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E2022),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

      // Bottom Action Button (Proceed to Order)
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isPlacing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isPlacing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isOffPremiseOrder
                                    ? (_paymentMode == 'prepaid'
                                          ? 'Proceed to Pay ₹${(cart.totalAmount + (_offPremiseMode == 'delivery' ? 40.0 : 0.0)).toStringAsFixed(0)}'
                                          : 'Confirm Order (₹${(cart.totalAmount + (_offPremiseMode == 'delivery' ? 40.0 : 0.0)).toStringAsFixed(0)})')
                                    : 'Proceed to Order',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCartItemTile(
    BuildContext context,
    CartProvider cart,
    dynamic item,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 70,
              height: 70,
              color: const Color(0xFFFFF2EB),
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImg(),
                    )
                  : _placeholderImg(),
            ),
          ),
          const SizedBox(width: 12),

          // Item Details & Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _vegBadge(item.isVeg),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF1E2022),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item.unitPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF75787E),
                            ),
                          ),
                          if (item.modifiers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.modifiers.map((m) => m.name).join(', '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF45B15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => cart.removeItem(index),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Control
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF45B15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => cart.decreaseQty(index),
                            child: const SizedBox(
                              width: 28,
                              child: Center(
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: Color(0xFFF45B15),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            color: const Color(0xFFFFF2EB),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: Color(0xFFF45B15),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => cart.increaseQty(index),
                            child: const SizedBox(
                              width: 28,
                              child: Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFFF45B15),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total Item Price
                    Text(
                      '₹${item.itemTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImg() => const Center(
    child: Icon(Icons.restaurant_rounded, color: Color(0xFFF45B15), size: 24),
  );

  Widget _vegBadge(bool isVeg) {
    final color = isVeg ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildBillLine(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF75787E),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2022),
          ),
        ),
      ],
    );
  }

  void _confirmClearCart(CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart?'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF75787E)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF2EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: Color(0xFFF45B15),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2022),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Looks like you haven\'t added\nanything yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF75787E)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF45B15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Browse Menu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---- OFF-PREMISE (TAKEAWAY & DELIVERY) SECTION ----
  Widget _buildDeliveryTakeawaySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2022),
            ),
          ),
          const SizedBox(height: 12),
          // Toggle: Takeaway vs Delivery (Requirement 8)
          Row(
            children: [
              Expanded(
                child: _orderTypeCard(
                  title: 'Takeaway',
                  subtitle: 'Pickup at restaurant',
                  icon: Icons.shopping_bag_outlined,
                  isSelected: _offPremiseMode == 'takeaway',
                  onTap: () => setState(() => _offPremiseMode = 'takeaway'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _orderTypeCard(
                  title: 'Delivery',
                  subtitle: 'Deliver to doorstep (₹40)',
                  icon: Icons.delivery_dining_rounded,
                  isSelected: _offPremiseMode == 'delivery',
                  onTap: () => setState(() => _offPremiseMode = 'delivery'),
                ),
              ),
            ],
          ),

          // Contact Mobile Number
          const SizedBox(height: 18),
          const Text(
            'Contact Mobile Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2022),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            onChanged: (phone) {
              if (phone.length == 10) {
                _initCustomerData();
              }
            },
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter 10-digit number',
              prefixText: '+91 ',
              prefixIcon: const Icon(
                Icons.phone_iphone_rounded,
                color: Color(0xFFF45B15),
                size: 18,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFECECEC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF45B15)),
              ),
            ),
          ),

          // If Delivery: Address Selector / Form (Requirement 9)
          if (_offPremiseMode == 'delivery') ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2022),
                  ),
                ),
                if (_savedAddresses.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(
                      () => _isAddingNewAddress = !_isAddingNewAddress,
                    ),
                    child: Text(
                      _isAddingNewAddress ? 'Choose Saved' : '+ New Address',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF45B15),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // If user has saved address and not adding new:
            if (_savedAddresses.isNotEmpty && !_isAddingNewAddress) ...[
              ..._savedAddresses.map((saved) {
                final isSelected = _selectedSavedAddress?.id == saved.id;
                return InkWell(
                  onTap: () => setState(() => _selectedSavedAddress = saved),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF2EB)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF45B15)
                            : const Color(0xFFECECEC),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF45B15)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            saved.tag.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                saved.address,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1E2022),
                                ),
                              ),
                              if (saved.landmark.isNotEmpty)
                                Text(
                                  'Landmark: ${saved.landmark}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF75787E),
                                  ),
                                ),
                              Text(
                                'PIN: ${saved.pincode}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF75787E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? const Color(0xFFF45B15)
                              : const Color(0xFF9EA1A8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              // New Address Form (Default: Home)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFECECEC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _addressLineCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Address (House / Flat No., Street, Area) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _landmarkCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Landmark (Optional)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _pincodeCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              counterText: '',
                              labelText: 'Pincode *',
                              border: OutlineInputBorder(),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Address Tag Chips: Home (Default), Office, Other (Requirement 9)
                    Row(
                      children: [
                        const Text(
                          'Save as:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF75787E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...['Home', 'Office', 'Other'].map((tag) {
                          final isSelected = _selectedAddressTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(tag),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFFF2EB),
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? const Color(0xFFF45B15)
                                    : const Color(0xFF75787E),
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedAddressTag = tag),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Payment Mode Toggle: Online vs COD / Pickup
          const SizedBox(height: 18),
          const Text(
            'Payment Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2022),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _paymentModeCard(
                  title: 'Pay Online',
                  subtitle: 'UPI, Cards, NetBanking',
                  icon: Icons.qr_code_scanner_rounded,
                  isSelected: _paymentMode == 'prepaid',
                  onTap: () => setState(() => _paymentMode = 'prepaid'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _paymentModeCard(
                  title: _offPremiseMode == 'delivery'
                      ? 'Cash on Delivery'
                      : 'Pay at Pickup',
                  subtitle: 'Pay when receiving food',
                  icon: Icons.payments_outlined,
                  isSelected: _paymentMode == 'cod',
                  onTap: () => setState(() => _paymentMode = 'cod'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF2EB) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF45B15)
                : const Color(0xFFECECEC),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFF45B15)
                  : const Color(0xFF75787E),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isSelected
                    ? const Color(0xFFF45B15)
                    : const Color(0xFF1E2022),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF75787E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF2EB) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF45B15)
                : const Color(0xFFECECEC),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFF45B15)
                  : const Color(0xFF75787E),
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFFF45B15)
                    : const Color(0xFF1E2022),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF75787E)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final order = context.read<OrderProvider>();

    // Applying overall special instructions to the first item as fallback, since API format asks per item
    if (_instructionsCtrl.text.isNotEmpty && cart.items.isNotEmpty) {
      cart.updateInstructions(0, _instructionsCtrl.text);
    }

    // ---- OFF-PREMISE (TAKEAWAY / DELIVERY) FLOW ----
    if (_isOffPremiseOrder) {
      final phone = _phoneCtrl.text.trim();
      if (phone.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 10-digit mobile number'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      String finalAddress = '';
      String finalLandmark = '';
      final deliveryCharge = _offPremiseMode == 'delivery' ? 40.0 : 0.0;

      if (_offPremiseMode == 'delivery') {
        if (_isAddingNewAddress || _selectedSavedAddress == null) {
          final addr = _addressLineCtrl.text.trim();
          final pin = _pincodeCtrl.text.trim();
          if (addr.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter delivery address'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
            return;
          }
          if (pin.length < 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter valid pincode'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
            return;
          }

          finalLandmark = _landmarkCtrl.text.trim();
          finalAddress =
              '$addr${finalLandmark.isNotEmpty ? ' (Near $finalLandmark)' : ''} - $pin';

          // Save address in SharedPreferences for this phone! (Requirement 9)
          final newSaved = SavedAddress(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            address: addr,
            landmark: finalLandmark,
            pincode: pin,
            tag: _selectedAddressTag,
          );
          await AddressService.saveAddress(phone, newSaved);
        } else {
          final s = _selectedSavedAddress!;
          finalLandmark = s.landmark;
          finalAddress =
              '${s.address}${s.landmark.isNotEmpty ? ' (Near ${s.landmark})' : ''} - ${s.pincode}';
        }
      }

      setState(() => _isPlacing = true);

      final total = cart.totalAmount + deliveryCharge;

      final result = await ApiService().placeOffPremiseOrder(
        restaurantId: int.tryParse(widget.restaurantId) ?? 1,
        orderType: _offPremiseMode,
        paymentMode: _paymentMode,
        phone: phone,
        deliveryAddress: finalAddress,
        deliveryLandmark: finalLandmark,
        deliveryCharge: deliveryCharge,
        items: cart.toApiFormat(),
      );

      if (!mounted) return;
      setState(() => _isPlacing = false);

      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Unable to place order. Try again.',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }

      final data = result['data'];
      final sessionId = data['session_id'].toString();
      final pickupToken = data['pickup_token']?.toString();

      await SessionService.saveOffPremiseSession(
        sessionId: sessionId,
        orderType: _offPremiseMode,
        pickupToken: pickupToken,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', phone);

      order.setSessionId(sessionId);

      if (_paymentMode == 'prepaid') {
        await order.processUpiPayment(sessionId: sessionId, amount: total);
      }

      cart.clear();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OffPremiseTrackingScreen(
            sessionId: sessionId,
            orderType: _offPremiseMode,
            pickupToken: pickupToken,
          ),
        ),
      );
      return;
    }

    // ---- DINE-IN TABLE FLOW ----
    setState(() => _isPlacing = true);
    order.setSessionId(widget.sessionId ?? '');
    final success = await order.placeOrder(
      tableId: widget.tableId ?? 0,
      restaurantId: int.parse(widget.restaurantId),
      items: cart.toApiFormat(),
    );

    if (!mounted) return;
    if (success) {
      cart.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            sessionId: widget.sessionId ?? '',
            tableNumber: widget.tableNumber,
            restaurantId: widget.restaurantId,
            tableId: widget.tableId ?? 0,
          ),
        ),
      );
      return;
    }

    setState(() => _isPlacing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          order.error.isNotEmpty ? order.error : 'Order not placed. Try again.',
        ),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }
}
