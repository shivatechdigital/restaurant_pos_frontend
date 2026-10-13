import 'package:flutter/material.dart';

import 'payment_screen.dart';

class SettledSessionScreen extends StatelessWidget {
  final String sessionId;
  final String tableNumber;

  const SettledSessionScreen({
    super.key,
    required this.sessionId,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          title: const Text(
            'Session Settled',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Table $tableNumber bill is paid',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1E2022),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can view this bill. To order again, close this page and scan the table QR code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF75787E), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            sessionId: sessionId,
                            tableNumber: tableNumber,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('View Paid Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF45B15),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
}
