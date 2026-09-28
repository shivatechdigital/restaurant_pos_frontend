import 'package:flutter/material.dart';

import 'otp_screen.dart';
import 'off_premise_order_screen.dart';
import '../config/responsive.dart';

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
  int? _offPremiseRestaurantId;

  @override
  void initState() {
    super.initState();
    final params = Uri.base.queryParameters;
    if (params['table'] != null && params['restaurant'] != null) {
      _qrTableNumber = params['table'];
      _qrRestaurantId = params['restaurant'];
    } else if (params['order'] == 'off-premise') {
      _offPremiseRestaurantId = int.tryParse(params['restaurant'] ?? '');
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
        builder: (_) =>
            OtpScreen(tableNumber: tableNumber, restaurantId: restaurantId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_offPremiseRestaurantId != null) {
      return OffPremiseOrderScreen(restaurantId: _offPremiseRestaurantId!);
    }

    final isQrScanned = _qrTableNumber != null;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7F3), Color(0xFFF4DDD5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: CustomerResponsive.pagePadding(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: CustomerResponsive(
                  mobile: _entryCard(context, isQrScanned, compact: true),
                  tablet: _entryCard(context, isQrScanned),
                  desktop: Row(
                    children: [
                      Expanded(child: _heroCopy()),
                      const SizedBox(width: 60),
                      Expanded(child: _entryCard(context, isQrScanned)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCopy() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'PetPooja',
        style: TextStyle(
          fontSize: 62,
          fontWeight: FontWeight.w900,
          color: Color(0xFFF45B15),
          fontStyle: FontStyle.italic,
        ),
      ),
      SizedBox(height: 20),
      Text(
        'Great Food\nBetter Experiences',
        style: TextStyle(
          fontSize: 42,
          height: 1.05,
          fontWeight: FontWeight.w800,
          color: Color(0xFF242124),
        ),
      ),
      SizedBox(height: 16),
      Text(
        'Order from this restaurant, your way.',
        style: TextStyle(fontSize: 18, color: Color(0xFF665D5A)),
      ),
    ],
  );

  Widget _entryCard(
    BuildContext context,
    bool isQrScanned, {
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sarjapur PetPooja',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Good food, made for your table.',
            style: TextStyle(color: Color(0xFF756B68)),
          ),
          const SizedBox(height: 24),
          if (isQrScanned) ...[
            _pill(Icons.table_restaurant, 'Table $_qrTableNumber'),
            const SizedBox(height: 22),
            _primaryButton(
              'Start ordering',
              () => _goToOtp(_qrTableNumber!, _qrRestaurantId!),
            ),
          ] else ...[
            const Text(
              'How would you like to order?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            const SizedBox(height: 14),
            _modeButton(
              Icons.restaurant,
              'Dine in',
              'Scan a table QR to start ordering',
              () => _showTableInput(context),
            ),
            const SizedBox(height: 10),
            _modeButton(
              Icons.shopping_bag_outlined,
              'Takeaway',
              'Pick up your order at the restaurant',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OffPremiseOrderScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _modeButton(
              Icons.delivery_dining,
              'Delivery',
              'Get your food delivered to your door',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OffPremiseOrderScreen(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Secure phone verification at checkout',
              style: TextStyle(fontSize: 12, color: Color(0xFF9B9290)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9DD),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFF45B15), size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _primaryButton(String label, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF45B15),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );

  Widget _modeButton(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onPressed,
  ) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9E1DE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9DD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFF45B15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF807673),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );

  void _showTableInput(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter table number'),
        content: TextField(
          controller: _tableCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'e.g. T1'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final table = _tableCtrl.text.trim();
              if (table.isEmpty) return;
              Navigator.pop(ctx);
              _goToOtp(table, '1');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
