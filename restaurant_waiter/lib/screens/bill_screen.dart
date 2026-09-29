import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/waiter_provider.dart';
import '../models/order_model.dart';

import 'dart:async';

class BillScreen extends StatefulWidget {
  final String tableNumber;
  final int tableId;
  final int sessionId;

  const BillScreen({
    super.key,
    required this.tableNumber,
    required this.tableId,
    required this.sessionId,
  });

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  BillData? _bill;
  bool _isLoading = true;
  bool _isPaying = false;
  String? _qrImageUrl;
  bool _qrPaid = false;
  Timer? _qrPoller;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  @override
  void dispose() {
    _qrPoller?.cancel();
    super.dispose();
  }

  Future<void> _loadBill() async {
    final w = context.read<WaiterProvider>();
    final bill = await w.loadBill(widget.sessionId.toString());
    if (!mounted) return;
    setState(() {
      _bill = bill;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text('🧾 Bill — ${widget.tableNumber}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bill == null
          ? const Center(child: Text('Bill generate nahi hua'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Restaurant Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _bill!.restaurantName.isEmpty
                              ? 'RESTAURANT'
                              : _bill!.restaurantName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Table ${widget.tableNumber}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const Divider(height: 20),
                        Text(
                          'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Divider(),
                          // Header row
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Item',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Qty',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Amount',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_bill!.orders.isNotEmpty)
                            ..._bill!.orders.map(
                              (order) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${order.customerName}  ${order.customerPhone.isEmpty ? '' : '• ${order.customerPhone}'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blueGrey.shade600,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    ...order.items.map(_billItemRow),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._bill!.items.map(_billItemRow),
                          const Divider(thickness: 2),

                          // Totals
                          _totalRow('Subtotal', _bill!.subtotal),
                          _totalRow('CGST (2.5%)', _bill!.cgst),
                          _totalRow('SGST (2.5%)', _bill!.sgst),
                          _totalRow('Service Charge', _bill!.serviceCharge),
                          const Divider(thickness: 2),
                          _totalRow('TOTAL', _bill!.finalAmount, isBold: true),
                          if (_bill!.paidAmount > 0)
                            _totalRow('Paid', _bill!.paidAmount),
                          if (_bill!.outstandingAmount > 0)
                            _totalRow(
                              'Balance',
                              _bill!.outstandingAmount,
                              isBold: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Buttons
                  Row(
                    children: [
                      // Cash Payment
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isPaying || _bill!.outstandingAmount <= 0
                                ? null
                                : () => _processPayment(
                                    _bill!.outstandingAmount,
                                    'cash',
                                  ),
                            icon: const Icon(Icons.money, size: 18),
                            label: const Text(
                              'Cash',
                              style: TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Card payment must be confirmed by the separate card terminal.
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isPaying || _bill!.outstandingAmount <= 0
                                ? null
                                : () => _startMachinePayment(
                                    _bill!.outstandingAmount,
                                    'card',
                                  ),
                            icon: const Icon(Icons.credit_card, size: 18),
                            label: const Text(
                              'Card',
                              style: TextStyle(fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isPaying || _bill!.outstandingAmount <= 0
                          ? null
                          : _createOnlineQr,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Pay Online with Razorpay QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_qrImageUrl != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _qrPaid
                                ? 'Payment confirmed'
                                : 'Scan to pay ₹${_bill!.outstandingAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Image.network(
                            _qrImageUrl!,
                            width: 220,
                            height: 220,
                            errorBuilder: (_, _, _) =>
                                const Text('QR image could not be loaded'),
                          ),
                          const Text(
                            'Waiting for Razorpay confirmation',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _billItemRow(BillItem item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(item.name, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${item.quantity}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '₹${item.totalPrice.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Future<void> _createOnlineQr() async {
    setState(() => _isPaying = true);
    final result = await context.read<WaiterProvider>().createSessionQr(
      widget.sessionId.toString(),
    );
    if (!mounted) return;
    setState(() => _isPaying = false);
    if (result['success'] != true || result['data']?['image_url'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Razorpay QR could not be created',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _qrImageUrl = result['data']['image_url'].toString();
      _qrPaid = false;
    });
    _qrPoller?.cancel();
    _qrPoller = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkQrPayment(),
    );
  }

  Future<void> _checkQrPayment() async {
    final result = await context.read<WaiterProvider>().getPaymentStatus(
      widget.sessionId.toString(),
    );
    if (!mounted || result['success'] != true) return;
    final payments = result['data'] as List? ?? [];
    final paid = payments.any(
      (payment) =>
          payment['razorpay_qr_code_id'] != null &&
          payment['status'] == 'success',
    );
    if (!paid) return;
    _qrPoller?.cancel();
    await _loadBill();
    if (!mounted) return;
    final waiter = context.read<WaiterProvider>();
    await waiter.loadTables();
    if (!mounted) return;
    if (_bill != null && _bill!.outstandingAmount <= 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Razorpay payment received. Table is now available.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
      return;
    }
    setState(() => _qrPaid = true);
  }

  Widget _totalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
              color: isBold ? const Color(0xFF0D47A1) : Colors.grey[700],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 20 : 14,
              color: isBold ? const Color(0xFF0D47A1) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startMachinePayment(double amount, String method) async {
    const label = 'Card';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('$label Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'Process ₹${amount.toStringAsFixed(2)} on the $label terminal, then confirm its approval here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm terminal approval'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _processPayment(amount, method);
  }

  Future<void> _processPayment(double amount, String method) async {
    final w = context.read<WaiterProvider>();
    final settlesBill = amount >= _bill!.outstandingAmount - 0.01;

    if (method == 'cash') {
      // Confirm dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('💵 Cash Payment'),
          content: Text(
            '₹${amount.toStringAsFixed(2)} cash mein receive kiya?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nahi'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Haan, Cash Liya ✅',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isPaying = true);

    final success = await w.processCashPayment(
      widget.sessionId.toString(),
      amount,
      method: method,
    );

    if (!mounted) return;
    setState(() => _isPaying = false);

    if (success) {
      if (!settlesBill) {
        await _loadBill();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partial payment recorded'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      final label = method == 'cash' ? 'Cash' : 'Card';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $label payment recorded! Table free ho gayi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Bill screen close
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment record nahi hua'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
