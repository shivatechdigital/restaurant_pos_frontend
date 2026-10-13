import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import 'thank_you_screen.dart';
import '../config/responsive.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderProvider>().loadBill();
    });
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
          'Bill & Payment',
          style: TextStyle(
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF1E2022)),
            tooltip: 'Share Bill',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bill summary ready to share'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: order.isLoading || bill == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF45B15)),
                  SizedBox(height: 14),
                  Text(
                    'Loading bill details...',
                    style: TextStyle(
                      color: Color(0xFF75787E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : CustomerPage(
              maxWidth: 600,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- TAX INVOICE HEADER CARD (Reference Card 05 UI) ----
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECECEC)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF2EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 26,
                              color: Color(0xFFF45B15),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sarjapur PetPooja',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2022),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Good Food, Good Mood',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF75787E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Text(
                              'TAX INVOICE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFECECEC)),
                          const SizedBox(height: 12),

                          _invoiceMetaRow('Table No', 'Table ${widget.tableNumber}'),
                          const SizedBox(height: 6),
                          _invoiceMetaRow('Order Type', 'Dine In'),
                          const SizedBox(height: 6),
                          _invoiceMetaRow(
                            'Date & Time',
                            '${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---- ORDERED ITEMS TABLE CARD ----
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECECEC)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Color(0xFF9EA1A8),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Qty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF9EA1A8),
                                    ),
                                  ),
                                  SizedBox(width: 28),
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF9EA1A8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFECECEC)),
                          const SizedBox(height: 8),
                          ...bill.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E2022),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
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
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF1E2022),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFECECEC)),
                          const SizedBox(height: 12),

                          // ---- BILL BREAKDOWN ----
                          _billRow('Items Total', bill.subtotal),
                          _billRow('CGST (2.5%)', bill.cgst),
                          _billRow('SGST (2.5%)', bill.sgst),
                          _billRow('Service Charge', bill.serviceCharge),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: Color(0xFFECECEC), thickness: 1),
                          ),
                          _billRow(
                            'Grand Total',
                            bill.finalAmount,
                            isBold: true,
                            isPrimary: true,
                          ),
                          if (bill.paidAmount > 0)
                            _billRow('Paid Amount', bill.paidAmount),
                          if (bill.outstandingAmount > 0)
                            _billRow(
                              'Outstanding Balance',
                              bill.outstandingAmount,
                              isBold: true,
                              isPrimary: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---- PAYMENT METHOD CARDS (Card 03 Reference) ----
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Pay at restaurant (Cash/Direct)
                    _paymentTile(
                      icon: Icons.storefront_rounded,
                      title: 'Pay at Restaurant',
                      subtitle: 'Pay at counter or to the waiter after meal',
                      badge: 'Counter',
                      iconBg: const Color(0xFFFFF2EB),
                      iconColor: const Color(0xFFF45B15),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please pay the amount to the waiter or cashier.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // UPI Payment
                    _paymentTile(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'UPI Payment',
                      subtitle: 'Pay instantly via GPay, PhonePe, Paytm',
                      badge: 'Instant',
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
                      subtitle: 'Credit / Debit Card online checkout',
                      badge: null,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      onTap: () =>
                          _processUpi(context, order, bill.outstandingAmount),
                    ),

                    const SizedBox(height: 20),

                    // Error Message
                    if (order.paymentError.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.paymentError,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _invoiceMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF75787E),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E2022),
            fontWeight: FontWeight.w700,
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

  // ---- PAYMENT TILE WIDGET (Card 03 Reference) ----
  Widget _paymentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? badge,
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E2022),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Color(0xFFF45B15),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
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
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9EA1A8),
            ),
          ],
        ),
      ),
    );
  }

  // ---- BILL ROW ----
  Widget _billRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              fontSize: isBold ? 16 : 13,
              color: isBold ? const Color(0xFF1E2022) : const Color(0xFF75787E),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              fontSize: isBold ? 18 : 14,
              color: isPrimary
                  ? const Color(0xFFF45B15)
                  : (isBold ? const Color(0xFF1E2022) : const Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- UPI PAYMENT HANDLER ----
  Future<void> _processUpi(
    BuildContext context,
    OrderProvider order,
    double amount,
  ) async {
    // Confirmation dialog
    final confirmed = await _showConfirmDialog(
      context,
      'UPI Payment',
      '₹${amount.toStringAsFixed(2)} UPI se pay karoge?',
      Icons.qr_code_2,
      Colors.blue,
    );

    if (!confirmed) return;

    final success = await order.processUpiPayment(
      sessionId: widget.sessionId,
      amount: amount,
    );

    if (success && context.mounted) {
      await order.loadBill();
      if (!context.mounted) return;
      final settled = order.bill?.outstandingAmount == 0;
      if (!settled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Partial payment received. Remaining balance is shown above.',
            ),
          ),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ThankYouScreen(
            tableNumber: widget.tableNumber,
            amount: amount,
            paymentMethod: 'UPI',
            sessionId: widget.sessionId,
          ),
        ),
      );
    }
  }

  // ---- CONFIRM DIALOG ----
  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text(
              'Confirm & Pay',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
