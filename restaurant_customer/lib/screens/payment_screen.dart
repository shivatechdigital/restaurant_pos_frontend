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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Payment'),
        centerTitle: true,
      ),
      body: order.isLoading || bill == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  SizedBox(height: 12),
                  Text('Bill load ho raha hai...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- HEADER ----
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long,
                              size: 40, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Table ${widget.tableNumber}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Bill Summary',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---- ITEMS LIST ----
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Items Ordered',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          ...bill.items.map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.name} × ${item.quantity}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 24, thickness: 1.5),

                          // ---- BILL BREAKDOWN ----
                          _billRow('Subtotal', bill.subtotal),
                          _billRow('CGST (2.5%)', bill.cgst),
                          _billRow('SGST (2.5%)', bill.sgst),
                          _billRow('Service Charge', bill.serviceCharge),
                          const Divider(height: 20, thickness: 2),
                          _billRow('TOTAL', bill.finalAmount,
                              isBold: true, isGreen: true),
                          if (bill.paidAmount > 0)
                            _billRow('Paid', bill.paidAmount),
                          if (bill.outstandingAmount > 0)
                            _billRow('Balance', bill.outstandingAmount,
                                isBold: true, isGreen: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- PAYMENT OPTIONS ----
                  const Text(
                    'Choose Payment Method',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // UPI Payment
                  _paymentCard(
                    icon: Icons.qr_code_2,
                    title: 'Pay via UPI',
                    subtitle: 'GPay, PhonePe, Paytm, BHIM',
                    color: Colors.blue,
                    tag: 'Recommended',
                    onTap: () => _processUpi(context, order, bill.outstandingAmount),
                  ),
                  const SizedBox(height: 10),

                  // Card Payment
                  _paymentCard(
                    icon: Icons.credit_card,
                    title: 'Pay via Card',
                    subtitle: 'Debit / Credit Card',
                    color: Colors.purple,
                    tag: null,
                    onTap: () => _processUpi(context, order, bill.outstandingAmount),
                    // Razorpay card option bhi same checkout se hota hai
                  ),
                  const SizedBox(height: 10),

                  // Cash Payment
                  _paymentCard(
                    icon: Icons.money,
                    title: 'Pay Cash',
                    subtitle: 'Waiter ko cash do table par',
                    color: Colors.green,
                    tag: null,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Waiter cash amount record karega. Remaining balance yahin update hoga.')),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Error Message
                  if (order.paymentError.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.paymentError,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ---- PAYMENT CARD WIDGET ----
  Widget _paymentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? tag,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ---- BILL ROW ----
  Widget _billRow(String label, double amount,
      {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 20 : 14,
              color: isBold
                  ? (isGreen ? const Color(0xFF1B5E20) : Colors.black)
                  : Colors.grey[700],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 22 : 14,
              color: isBold
                  ? (isGreen ? const Color(0xFF1B5E20) : Colors.black)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---- UPI PAYMENT HANDLER ----
  Future<void> _processUpi(
      BuildContext context, OrderProvider order, double amount) async {
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
          const SnackBar(content: Text('Partial payment received. Remaining balance is shown above.')),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: const Text('Confirm & Pay',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
