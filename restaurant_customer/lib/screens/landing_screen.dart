import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'off_premise_order_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _tableCtrl = TextEditingController();

  // QR scan se aaya table/restaurant (URL query params: ?table=T1&restaurant=1)
  String? _qrTableNumber;
  String? _qrRestaurantId;

  @override
  void initState() {
    super.initState();
    final params = Uri.base.queryParameters;
    if (params['table'] != null && params['restaurant'] != null) {
      _qrTableNumber = params['table'];
      _qrRestaurantId = params['restaurant'];
    }
  }

  @override
  void dispose() {
    _tableCtrl.dispose();
    super.dispose();
  }

  void _goToOtp(String tableNumber, String restaurantId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          tableNumber: tableNumber,
          restaurantId: restaurantId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isQrScanned = _qrTableNumber != null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Logo / Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Welcome Text
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan. Order. Enjoy.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              // ---- QR SE MILA TABLE (Badge + seedha Start) ----
              if (isQrScanned) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.table_restaurant,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Table $_qrTableNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          _goToOtp(_qrTableNumber!, _qrRestaurantId!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Start Ordering  →',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ]
              // ---- QR NAHI MILA (manual table number entry) ----
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _tableCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'Table Number',
                                hintText: 'e.g. T1',
                                prefixIcon: const Icon(Icons.table_restaurant),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  final table = _tableCtrl.text.trim();
                                  if (table.isEmpty) return;
                                  _goToOtp(table, '1');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Continue  →',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ya table par lage QR code ko scan karo',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              if (!isQrScanned)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OffPremiseOrderScreen())),
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    label: const Text('Order Takeaway or Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              const Text(
                'Phone verify hoga — koi spam nahi 🤞',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
