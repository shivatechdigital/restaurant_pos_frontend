import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/session_service.dart';
import 'landing_screen.dart';

class ThankYouScreen extends StatefulWidget {
  final String tableNumber;
  final double amount;
  final String paymentMethod;
  final String sessionId;

  const ThankYouScreen({
    super.key,
    required this.tableNumber,
    required this.amount,
    required this.paymentMethod,
    required this.sessionId,
  });

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Payment Successful',
          style: TextStyle(color: Color(0xFF1E2022), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // Web Responsiveness
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success Animation / Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF16A34A)),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Thank You! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E2022)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your payment has been received successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF75787E), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),

                // Payment Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECECEC)),
                    boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _detailRow('Table Number', 'Table ${widget.tableNumber}'),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFECECEC), height: 1)),
                      _detailRow('Amount Paid', '₹${widget.amount.toStringAsFixed(0)}', isBold: true),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFECECEC), height: 1)),
                      _detailRow('Payment Method', widget.paymentMethod),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFECECEC), height: 1)),
                      _detailRow('Receipt ID', widget.sessionId),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Feedback prompt
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECECEC)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'How was your food & experience?',
                        style: TextStyle(color: Color(0xFF1E2022), fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: index < _rating ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() => _rating = index + 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you for your feedback!'),
                                  backgroundColor: Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Done Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Payment ho chuka hai, table free hai - purana session/cart clear karo
                      await SessionService.clearSession();
                      if (context.mounted) {
                        context.read<CartProvider>().clear();
                        context.read<OrderProvider>().resetForNewOrder();
                      }
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LandingScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF75787E), fontSize: 14, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            color: isBold ? const Color(0xFFF45B15) : const Color(0xFF1E2022),
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}