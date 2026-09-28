import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/session_service.dart';
import 'landing_screen.dart';
import '../config/responsive.dart';

class ThankYouScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE5092F), Color(0xFFC1082A), Color(0xFF8E1028)],
          ),
        ),
        child: SafeArea(
          child: CustomerPage(
            child: SingleChildScrollView(
              padding: CustomerResponsive.pagePadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Animation (Static for now)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Thank You! 🎉',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Payment Successful',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Payment Details Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Table', tableNumber),
                        const Divider(color: Colors.white24),
                        _detailRow(
                          'Amount Paid',
                          '₹${amount.toStringAsFixed(2)}',
                        ),
                        const Divider(color: Colors.white24),
                        _detailRow('Payment Method', paymentMethod),
                        const Divider(color: Colors.white24),
                        _detailRow('Receipt ID', sessionId),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Feedback prompt
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Aapka experience kaisa raha?',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                Icons.star,
                                color: Colors.yellow[300],
                                size: 32,
                              ),
                              onPressed: () {
                                // Phase 5 mein feedback save hoga
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${index + 1} star diya! Thank you!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Done Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
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
                            MaterialPageRoute(
                              builder: (_) => const LandingScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE5092F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          'Done ✓',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
