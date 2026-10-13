import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/debug_flags.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../config/socket_service.dart';
import 'menu_screen.dart';

class OtpScreen extends StatefulWidget {
  final String tableNumber;
  final String restaurantId;

  const OtpScreen({
    super.key,
    required this.tableNumber,
    required this.restaurantId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _api = ApiService();

  bool otpSent = false;
  bool isSendingOtp = false;
  bool isProcessing = false;
  int? tableId;
  String localError = '';
  String? testOtp;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E2022)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Confirm Details',
          style: TextStyle(color: Color(0xFF1E2022), fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFFF2EB), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.table_restaurant_rounded, size: 16, color: Color(0xFFF45B15)),
                const SizedBox(width: 6),
                Text('Table ${widget.tableNumber}', style: const TextStyle(color: Color(0xFFF45B15), fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFECECEC), height: 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440), // Web Responsiveness
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFECECEC)),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: const BoxDecoration(color: Color(0xFFF45B15), shape: BoxShape.circle),
                    child: Icon(otpSent ? Icons.mark_email_read_rounded : Icons.restaurant_rounded, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    otpSent ? 'Enter OTP' : 'Start Your Order',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E2022)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    otpSent ? 'A 6-digit OTP has been sent to +91 ${_phoneCtrl.text}' : 'Enter your details to lock this table and start ordering.',
                    style: const TextStyle(color: Color(0xFF75787E), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ---- FORM SECTION ----
                  if (!otpSent) ...[
                    _buildFieldLabel('Full Name'),
                    _buildTextField(controller: _nameCtrl, hint: 'Enter your name', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Mobile Number'),
                    _buildTextField(
                      controller: _phoneCtrl,
                      hint: '9876543210',
                      icon: Icons.phone_iphone_rounded,
                      isPhone: true,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Email (Optional)'),
                    _buildTextField(controller: _emailCtrl, hint: 'name@example.com', icon: Icons.alternate_email_rounded),
                    
                    const SizedBox(height: 24),

                    if (localError.isNotEmpty) _buildErrorBanner(),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSendingOtp ? null : _handleSendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF45B15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSendingOtp
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],

                  // ---- OTP INPUT SECTION ----
                  if (otpSent) ...[
                    _buildFieldLabel('6-Digit OTP'),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w900, color: Color(0xFF1E2022)),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: const TextStyle(color: Color(0xFF9EA1A8), fontSize: 24, letterSpacing: 8),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFECECEC))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFF45B15))),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (localError.isNotEmpty) _buildErrorBanner(),

                    if (kShowTestOtp && testOtp != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _otpCtrl.text = testOtp!,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
                            child: Text('Test OTP: $testOtp (Tap to autofill)', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF92400E), fontSize: 13)),
                          ),
                        ),
                      ),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : _handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF45B15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isProcessing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Verify & Lock Table', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() { otpSent = false; localError = ''; }),
                      child: const Text('Edit Phone Number', style: TextStyle(color: Color(0xFF75787E), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E2022))),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLength: isPhone ? 10 : null,
      inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E2022)),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9EA1A8), fontSize: 14, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: const Color(0xFF9EA1A8), size: 20),
        prefixText: isPhone ? '+91  ' : null,
        prefixStyle: const TextStyle(color: Color(0xFF1E2022), fontWeight: FontWeight.w700, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFECECEC))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF45B15))),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(localError, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ---- SEND OTP HANDLER ----
  Future<void> _handleSendOtp() async {
    setState(() { localError = ''; isSendingOtp = true; });

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() { localError = 'Please enter your name'; isSendingOtp = false; });
      return;
    }
    if (_phoneCtrl.text.length != 10) {
      setState(() { localError = 'Please enter a valid 10-digit number'; isSendingOtp = false; });
      return;
    }

    try {
      final scanResult = await _api.scanTable(widget.tableNumber, widget.restaurantId, _phoneCtrl.text);

      if (scanResult['success'] != true) {
        setState(() => localError = scanResult['message'] ?? 'Table not found');
        return;
      }

      final data = scanResult['data'];

      if (data['requires_room_code'] == true) {
        _showRoomCodeDialog();
        return;
      }

      tableId = data['table_id'];
      setState(() { otpSent = true; testOtp = data['otp']?.toString(); });
    } catch (e) {
      setState(() => localError = 'Connection error. Please try again.');
    } finally {
      setState(() => isSendingOtp = false);
    }
  }

  // ---- VERIFY OTP + LOCK TABLE HANDLER ----
  Future<void> _handleVerifyOtp() async {
    setState(() { localError = ''; isProcessing = true; });

    if (_otpCtrl.text.length != 6) {
      setState(() { localError = 'Please enter the 6-digit OTP'; isProcessing = false; });
      return;
    }

    try {
      final lockResult = await _api.lockTable(tableId!, _phoneCtrl.text, _otpCtrl.text);

      if (lockResult['success'] == true) {
        final sessionId = lockResult['data']['session_id'].toString();
        final roomCode = lockResult['data']['room_code'];
        final token = lockResult['data']['token'] as String?;

        final prefs = await SharedPreferences.getInstance();
        if (token != null) await prefs.setString('token', token);
        await prefs.setString('phone', _phoneCtrl.text);
        await prefs.setString('customer_name', _nameCtrl.text.trim());

        await SessionService.saveSession(
          tableId: tableId!,
          restaurantId: widget.restaurantId,
          tableNumber: widget.tableNumber,
          sessionId: sessionId,
          roomCode: roomCode,
        );

        SocketService().connect(widget.restaurantId, tableId.toString());

        if (!mounted) return;
        _showSuccessDialog(sessionId, roomCode);
      } else {
        setState(() => localError = lockResult['message'] ?? 'Table lock failed');
      }
    } catch (e) {
      setState(() => localError = 'Verification error. Try again.');
    }
    setState(() => isProcessing = false);
  }

  void _showRoomCodeDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Table Occupied', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This table is currently occupied. Please enter the Room PIN from the host.', style: TextStyle(color: Color(0xFF75787E))),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFECECEC))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF45B15))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF75787E), fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room code verify — coming in Phase 2')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Join Table'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String sessionId, String roomCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Table Locked! 🔒', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E2022))),
            const SizedBox(height: 8),
            const Text('You have successfully secured this table for your order.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF75787E))),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECECEC))),
              child: Column(
                children: [
                  const Text('Share PIN with companions', style: TextStyle(fontSize: 12, color: Color(0xFF75787E), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(roomCode, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), letterSpacing: 8)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MenuScreen(restaurantId: widget.restaurantId, tableNumber: widget.tableNumber, tableId: tableId!, sessionId: sessionId, roomCode: roomCode)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF45B15), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('View Menu →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}