import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/menu_provider.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rId = _qrRestaurantId ?? (_offPremiseRestaurantId?.toString()) ?? '1';
      context.read<MenuProvider>().loadMenu(rId);
    });
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
        builder: (_) => OtpScreen(tableNumber: tableNumber, restaurantId: restaurantId),
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
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SizedBox(
            width: double.infinity,
            child: _entryCard(context, isQrScanned),
          ),
        ),
      ),
    );
  }

  Widget _entryCard(BuildContext context, bool isQrScanned) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo/Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF45B15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          
          // Welcome Text
          Text(
            context.watch<MenuProvider>().restaurantName,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E2022), letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(
            context.watch<MenuProvider>().restaurantTagline,
            style: const TextStyle(color: Color(0xFF75787E), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: Color(0xFFECECEC), height: 1),
          ),

          if (isQrScanned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFFFF2EB), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_restaurant_rounded, color: Color(0xFFF45B15), size: 20),
                  const SizedBox(width: 8),
                  Text('Table $_qrTableNumber', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFF45B15), fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _goToOtp(_qrTableNumber!, _qrRestaurantId!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B15),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Start Ordering', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ] else ...[
            const Text(
              'How would you like to order?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E2022)),
            ),
            const SizedBox(height: 16),
            _modeButton(
              icon: Icons.restaurant_rounded,
              title: 'Dine in',
              subtitle: 'Scan table QR or enter manually',
              onTap: () => _showTableInput(context),
            ),
            const SizedBox(height: 12),
            _modeButton(
              icon: Icons.shopping_bag_outlined,
              title: 'Takeaway',
              subtitle: 'Pick up your order',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OffPremiseOrderScreen())),
            ),
            const SizedBox(height: 12),
            _modeButton(
              icon: Icons.delivery_dining_rounded,
              title: 'Delivery',
              subtitle: 'Get food delivered to you',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OffPremiseOrderScreen())),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeButton({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFECECEC)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF2EB), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFFF45B15), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E2022))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF75787E))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9EA1A8)),
          ],
        ),
      ),
    );
  }

  void _showTableInput(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Table Number', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: _tableCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'e.g. 5',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFECECEC))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF45B15))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF75787E), fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () {
              final table = _tableCtrl.text.trim();
              if (table.isEmpty) return;
              Navigator.pop(ctx);
              _goToOtp(table, '1');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF45B15), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}