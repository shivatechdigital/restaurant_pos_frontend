import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import 'thank_you_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String sessionId;
  final String tableNumber;

  const PaymentScreen({
    super.key,
    required this.sessionId,
    required this.tableNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<OrderProvider>().loadBill();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrderProvider>();
    final bill = order.bill;

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
          'Bill Details',
          style: TextStyle(
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: Color(0xFF1E2022),
            ),
            tooltip: 'Download Invoice',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading bill...')),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: _loading || order.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF45B15)),
            )
          : (bill == null || bill.items.isEmpty)
          ? _buildEmptyBillState()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ), // Web Responsiveness
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- RECEIPT CARD (Screen 05 Replica) ----
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          children: [
                            // Header Logo & Address (Dynamic for each restaurant)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF45B15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bill.restaurantName.isNotEmpty ? bill.restaurantName : 'Food Plaza',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E2022),
                                      ),
                                    ),
                                    if (bill.restaurantTagline.isNotEmpty)
                                      Text(
                                        bill.restaurantTagline,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF75787E),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (bill.restaurantAddress.isNotEmpty || bill.restaurantPhone.isNotEmpty)
                              const SizedBox(height: 12),
                            if (bill.restaurantAddress.isNotEmpty)
                              Text(
                                bill.restaurantAddress,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF75787E),
                                ),
                              ),
                            if (bill.restaurantPhone.isNotEmpty)
                              Text(
                                'Phone: ${bill.restaurantPhone}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF75787E),
                                ),
                              ),
                            if (bill.restaurantGst.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'GSTIN: ${bill.restaurantGst}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF75787E),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),
                            const Text(
                              'TAX INVOICE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: Color(0xFF1E2022),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Meta Data
                            _invoiceMetaRow(
                              'Order No',
                              ' :  #${order.currentOrderId ?? "ORD12345"}',
                            ),
                            const SizedBox(height: 4),
                            _invoiceMetaRow(
                              'Date',
                              ' :  ${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                            ),
                            const SizedBox(height: 4),
                            _invoiceMetaRow(
                              'Time',
                              ' :  ${TimeOfDay.now().format(context)}',
                            ),
                            const SizedBox(height: 4),
                            _invoiceMetaRow(
                              'Table No',
                              ' :  ${widget.tableNumber}',
                            ),
                            const SizedBox(height: 4),
                            _invoiceMetaRow('Type', ' :  Dine In'),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                color: Color(0xFFECECEC),
                                height: 1,
                              ),
                            ),

                            // Items Header
                            const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Item',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF75787E),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Qty',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF75787E),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Price',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF75787E),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Amount',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF75787E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Items List
                            ...bill.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E2022),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF75787E),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '₹${(item.totalPrice / item.quantity).toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF75787E),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '₹${item.totalPrice.toStringAsFixed(0)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E2022),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                color: Color(0xFFECECEC),
                                height: 1,
                              ),
                            ),

                            // Bill Totals
                            _billRow('Items Total', bill.subtotal),
                            const SizedBox(height: 6),
                            _billRow(
                              'Discount',
                              0,
                              isDiscount: true,
                            ), // Placeholder for discount
                            const SizedBox(height: 6),
                            _billRow('CGST (2.5%)', bill.cgst),
                            const SizedBox(height: 6),
                            _billRow('SGST (2.5%)', bill.sgst),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: Color(0xFF1E2022),
                                height: 1,
                                thickness: 1.5,
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Color(0xFF1E2022),
                                  ),
                                ),
                                Text(
                                  '₹${bill.finalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Color(0xFF1E2022),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                            const Icon(
                              Icons.card_giftcard_rounded,
                              color: Color(0xFF9EA1A8),
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Thank You!',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF1E2022),
                              ),
                            ),
                            const Text(
                              'Visit Again for More Delicious Food',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF75787E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pay at restaurant
                      _paymentTile(
                        icon: Icons.storefront_rounded,
                        title: 'Pay at Restaurant',
                        subtitle: 'Pay at counter after your meal',
                        iconBg: const Color(0xFFFFF2EB),
                        iconColor: const Color(0xFFF45B15),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please pay at the counter.'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // UPI Payment
                      _paymentTile(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'UPI Payment',
                        subtitle: 'Pay using any UPI app',
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        onTap: () =>
                            _processUpi(context, order, bill.outstandingAmount),
                      ),
                      const SizedBox(height: 10),

                      // Card Payment
                      _paymentTile(
                        icon: Icons.credit_card_rounded,
                        title: 'Card Payment',
                        subtitle: 'Credit/Debit Card',
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        onTap: () =>
                            _processUpi(context, order, bill.outstandingAmount),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

      bottomNavigationBar: (bill == null || bill.items.isEmpty)
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
                child: Center(
                  heightFactor: 1.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bill shared successfully!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text(
                          'Share Bill',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF45B15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyBillState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: Color(0xFFF45B15),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Bill Generated Yet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1E2022),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add items from menu to place an order and generate a bill.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF75787E), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: const Text('Explore Menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF45B15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceMetaRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF75787E)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E2022),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  Widget _billRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF75787E),
          ),
        ),
        Text(
          isDiscount
              ? '- ₹${amount.toStringAsFixed(0)}'
              : '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isDiscount
                ? const Color(0xFF16A34A)
                : const Color(0xFF1E2022),
          ),
        ),
      ],
    );
  }

  Widget _paymentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECECEC)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF75787E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.circle_outlined,
              size: 20,
              color: Color(0xFFECECEC),
            ), // Radio button look alike
          ],
        ),
      ),
    );
  }

  Future<void> _processUpi(
    BuildContext context,
    OrderProvider order,
    double amount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Payment'),
        content: Text('Pay ₹${amount.toStringAsFixed(0)} via UPI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF75787E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF45B15),
            ),
            child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await order.processUpiPayment(
      sessionId: widget.sessionId,
      amount: amount,
    );

    if (success && context.mounted) {
      await order.loadBill();
      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ThankYouScreen(
            tableNumber: widget.tableNumber,
            amount: amount,
            paymentMethod: 'UPI / Online',
            sessionId: widget.sessionId,
          ),
        ),
      );
    }
  }
}
