import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waiter_provider.dart';
import '../models/order_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadBill();
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
                            const Text(
                              'RESTAURANT NAME',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2),
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
                              const Text('Items',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Divider(),
                              // Header row
                              Row(
                                children: [
                                  Expanded(
                                      flex: 4,
                                      child: Text('Item',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12))),
                                  Expanded(
                                      flex: 1,
                                      child: Text('Qty',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Amount',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12))),
                                ],
                              ),
                              const Divider(),
                              ..._bill!.items.map((item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Text(item.name,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text('${item.quantity}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                              '₹${item.totalPrice.toStringAsFixed(2)}',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Divider(thickness: 2),

                              // Totals
                              _totalRow('Subtotal', _bill!.subtotal),
                              _totalRow('CGST (2.5%)', _bill!.cgst),
                              _totalRow('SGST (2.5%)', _bill!.sgst),
                              _totalRow(
                                  'Service Charge', _bill!.serviceCharge),
                              const Divider(thickness: 2),
                              _totalRow('TOTAL', _bill!.finalAmount,
                                  isBold: true),
                              if (_bill!.paidAmount > 0)
                                _totalRow('Paid', _bill!.paidAmount),
                              if (_bill!.outstandingAmount > 0)
                                _totalRow('Balance', _bill!.outstandingAmount,
                                    isBold: true),
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
                                onPressed: _isPaying
                                    ? null
                                    : () => _processPayment(_bill!.outstandingAmount, 'cash'),
                                icon: const Icon(Icons.money, size: 18),
                                label: const Text('Cash',
                                    style: TextStyle(fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // UPI Payment (machine ke status par settle hoga)
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _isPaying
                                    ? null
                                    : () => _startMachinePayment(_bill!.outstandingAmount, 'upi'),
                                icon: const Icon(Icons.qr_code_2, size: 18),
                                label: const Text('UPI',
                                    style: TextStyle(fontSize: 14)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Card Payment (machine ke status par settle hoga)
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _isPaying
                                    ? null
                                    : () => _startMachinePayment(_bill!.outstandingAmount, 'card'),
                                icon: const Icon(Icons.credit_card, size: 18),
                                label: const Text('Card',
                                    style: TextStyle(fontSize: 14)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.deepPurple,
                                  side: const BorderSide(color: Colors.deepPurple),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
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
                        child: OutlinedButton.icon(
                          onPressed: _isPaying ? null : _showSplitPaymentDialog,
                          icon: const Icon(Icons.call_split),
                          label: const Text('Split Cash Payment'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _isPaying ? null : _showItemSplitDialog,
                          icon: const Icon(Icons.checklist),
                          label: const Text('Split by Selected Items'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 18 : 14,
                color: isBold ? const Color(0xFF0D47A1) : Colors.grey[700],
              )),
          Text('₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 20 : 14,
                color: isBold ? const Color(0xFF0D47A1) : Colors.black87,
              )),
        ],
      ),
    );
  }

  Future<void> _startMachinePayment(double amount, String method) async {
    final label = method == 'upi' ? 'UPI' : 'Card';
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
              'Waiting for $label machine...\nAmount: ₹${amount.toStringAsFixed(2)}',
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
            child: const Text('Payment Successful'),
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
              '₹${amount.toStringAsFixed(2)} cash mein receive kiya?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nahi'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Haan, Cash Liya ✅',
                  style: TextStyle(color: Colors.white)),
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
          const SnackBar(content: Text('Partial payment recorded'), backgroundColor: Colors.green),
        );
        return;
      }
      final label = method == 'cash' ? 'Cash' : method == 'upi' ? 'UPI' : 'Card';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ $label payment recorded! Table free ho gayi.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Bill screen close
      Navigator.pop(context); // Orders screen par wapas
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment record nahi hua'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processCashPayment(double amount) => _processPayment(amount, 'cash');

  Future<void> _showSplitPaymentDialog() async {
    int people = 2;
    final customCtrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Split Cash Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: people,
                decoration: const InputDecoration(labelText: 'Equal split between'),
                items: List.generate(9, (index) => index + 2)
                    .map((value) => DropdownMenuItem(value: value, child: Text('$value people')))
                    .toList(),
                onChanged: (value) => setDialogState(() => people = value!),
              ),
              const SizedBox(height: 8),
              Text('Each share: ₹${(_bill!.outstandingAmount / people).toStringAsFixed(2)}'),
              TextField(
                controller: customCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Or enter custom amount'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                ctx,
                double.tryParse(customCtrl.text) ?? _bill!.outstandingAmount / people,
              ),
              child: const Text('Record Cash'),
            ),
          ],
        ),
      ),
    );
    if (amount != null && amount > 0 && mounted) await _processCashPayment(amount);
  }

  Future<void> _showItemSplitDialog() async {
    final selectedItemIds = <int>{};
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final items = _bill!.items;
          final selectedSubtotal = items
              .where((item) => selectedItemIds.contains(item.id))
              .fold<double>(0, (total, item) => total + item.totalPrice);
          final billSubtotal = items.fold<double>(0, (total, item) => total + item.totalPrice);
          final calculatedAmount = billSubtotal == 0
              ? 0.0
              : selectedSubtotal * _bill!.finalAmount / billSubtotal;
          final amountToPay = calculatedAmount.clamp(0.0, _bill!.outstandingAmount);

          return AlertDialog(
            title: const Text('Select Items for Cash Split'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: items.map((item) => CheckboxListTile(
                            value: selectedItemIds.contains(item.id),
                            title: Text('${item.name} x${item.quantity}'),
                            subtitle: Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                            onChanged: (selected) => setDialogState(() {
                              if (selected == true) {
                                selectedItemIds.add(item.id);
                              } else {
                                selectedItemIds.remove(item.id);
                              }
                            }),
                          )).toList(),
                    ),
                  ),
                  const Divider(),
                  Text('Share including tax/charges: ₹${amountToPay.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: selectedItemIds.isEmpty ? null : () => Navigator.pop(ctx, amountToPay),
                child: const Text('Record Cash'),
              ),
            ],
          );
        },
      ),
    );
    if (amount != null && amount > 0 && mounted) await _processCashPayment(amount);
  }
}
