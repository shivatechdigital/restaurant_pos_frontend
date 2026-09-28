import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/debug_flags.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../config/socket_service.dart';
import 'menu_screen.dart';
import '../config/responsive.dart';

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
  String? _birthday;
  bool _acceptPrivacy = false;
  bool _receiveUpdates = false;

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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF191919),
        elevation: 0,
        title: Text('Table ${widget.tableNumber}'),
        centerTitle: true,
      ),
      body: CustomerPage(
        child: SingleChildScrollView(
          padding: CustomerResponsive.pagePadding(context),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  otpSent ? Icons.sms_outlined : Icons.phone_android,
                  size: 50,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                otpSent ? 'Enter your OTP' : 'Confirm your details',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                otpSent
                    ? '${_phoneCtrl.text} par OTP bheja gaya hai'
                    : 'Add your details to start ordering at the table.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ---- PHONE INPUT ----
              if (!otpSent) ...[
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+91 ',
                    labelText: 'Mobile Number',
                    hintText: '9876543210',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectBirthday,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth (optional)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _birthday ?? 'YYYY-MM-DD',
                      style: TextStyle(
                        color: _birthday == null
                            ? const Color(0xFF777777)
                            : const Color(0xFF222222),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _acceptPrivacy,
                  activeColor: const Color(0xFFF45B15),
                  onChanged: (value) =>
                      setState(() => _acceptPrivacy = value ?? false),
                  title: const Text('I accept the privacy policy.'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _receiveUpdates,
                  activeColor: const Color(0xFFF45B15),
                  onChanged: (value) =>
                      setState(() => _receiveUpdates = value ?? false),
                  title: const Text(
                    'Send me important updates on WhatsApp, RCS or email.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),

                // Error Message
                if (localError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      localError,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSendingOtp || !_acceptPrivacy
                        ? null
                        : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isSendingOtp
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Continue with OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              // ---- OTP INPUT ----
              if (otpSent) ...[
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '6-Digit OTP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),

                // Error Message
                if (localError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      localError,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                if (kShowTestOtp && testOtp != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Text(
                        'Test OTP: $testOtp',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : _handleVerifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF45B15),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Verify & Lock Table 🔒',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend OTP
                TextButton(
                  onPressed: () async {
                    final resendResult = await _api.scanTable(
                      widget.tableNumber,
                      widget.restaurantId,
                      _phoneCtrl.text,
                    );
                    if (!context.mounted) return;
                    setState(
                      () => testOtp = resendResult['data']?['otp']?.toString(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('OTP dobara bhej diya gaya!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('OTP nahi aaya? Resend karo'),
                ),
              ],

              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OTP verify hone par yeh table aapke liye lock ho jayegi. Koi aur is table se order nahi kar payega.',
                        style: TextStyle(color: Colors.blue[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectBirthday() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthday =
          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    });
  }

  // ---- SEND OTP HANDLER ----
  Future<void> _handleSendOtp() async {
    setState(() {
      localError = '';
      isSendingOtp = true;
    });

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() {
        localError = 'Enter your name';
        isSendingOtp = false;
      });
      return;
    }
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      setState(() {
        localError = 'Enter a valid email address';
        isSendingOtp = false;
      });
      return;
    }
    if (!_acceptPrivacy) {
      setState(() {
        localError = 'Accept the privacy policy to continue';
        isSendingOtp = false;
      });
      return;
    }
    if (_phoneCtrl.text.length != 10) {
      setState(() {
        localError = '10 digit phone number daalo';
        isSendingOtp = false;
      });
      return;
    }

    // Table scan karo — yahi table_lock OTP bhi bhej deta hai
    try {
      final scanResult = await _api.scanTable(
        widget.tableNumber,
        widget.restaurantId,
        _phoneCtrl.text,
      );

      if (scanResult['success'] != true) {
        setState(() => localError = scanResult['message'] ?? 'Table nahi mili');
        return;
      }

      final data = scanResult['data'];

      // Agar table already occupied hai
      if (data['requires_room_code'] == true) {
        _showRoomCodeDialog();
        return;
      }

      tableId = data['table_id'];
      setState(() {
        otpSent = true;
        testOtp = data['otp']?.toString();
      });
    } catch (e) {
      setState(
        () =>
            localError = 'Server se connect nahi ho raha. Backend check karo.',
      );
    } finally {
      setState(() => isSendingOtp = false);
    }
  }

  // ---- VERIFY OTP + LOCK TABLE HANDLER ----
  Future<void> _handleVerifyOtp() async {
    setState(() {
      localError = '';
      isProcessing = true;
    });

    if (_otpCtrl.text.length != 6) {
      setState(() {
        localError = '6 digit OTP daalo';
        isProcessing = false;
      });
      return;
    }

    // OTP verify + table lock ek hi call mein hota hai (backend table_lock purpose se OTP verify karta hai)
    try {
      final lockResult = await _api.lockTable(
        tableId!,
        _phoneCtrl.text,
        _otpCtrl.text,
      );

      if (lockResult['success'] == true) {
        final sessionId = lockResult['data']['session_id'].toString();
        final roomCode = lockResult['data']['room_code'];
        final token = lockResult['data']['token'] as String?;

        // Orders jaise authenticated API calls ke liye token save karo
        final prefs = await SharedPreferences.getInstance();
        if (token != null) await prefs.setString('token', token);
        await prefs.setString('phone', _phoneCtrl.text);
        await prefs.setString('customer_name', _nameCtrl.text.trim());
        await prefs.setString('customer_email', _emailCtrl.text.trim());
        await prefs.setString('customer_birthday', _birthday ?? '');
        await prefs.setBool('customer_updates_opt_in', _receiveUpdates);

        // Refresh ke baad bhi session yaad rahe, isliye save karo
        await SessionService.saveSession(
          tableId: tableId!,
          restaurantId: widget.restaurantId,
          tableNumber: widget.tableNumber,
          sessionId: sessionId,
          roomCode: roomCode,
        );

        // Step 3: Socket.io connect karo
        SocketService().connect(widget.restaurantId, tableId.toString());

        if (!mounted) return;

        // ✅ SUCCESS — Phase 2 mein yahan MenuScreen par jayenge
        // Abhi ke liye success dialog dikhao
        _showSuccessDialog(sessionId, roomCode);
      } else {
        setState(
          () => localError = lockResult['message'] ?? 'Table lock failed',
        );
      }
    } catch (e) {
      setState(() => localError = 'Table lock error. Try again.');
    }

    setState(() => isProcessing = false);
  }

  // ---- ROOM CODE DIALOG (Group Ordering) ----
  void _showRoomCodeDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.group, color: Colors.orange),
            SizedBox(width: 8),
            Text('Table Occupied'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yeh table pehle se occupied hai. Host se Room Code lo aur yahan daalo.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Room Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Phase 2 mein room code verify implement hoga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room code verify — coming in Phase 2'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Join', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---- SUCCESS DIALOG ----
  void _showSuccessDialog(String sessionId, String roomCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Table Locked! 🔒',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ab koi aur is table se order nahi kar sakta',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Doston ke saath share karo:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Room Code: $roomCode',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuScreen(
                        restaurantId: widget.restaurantId,
                        tableNumber: widget.tableNumber,
                        tableId: tableId!,
                        sessionId: sessionId,
                        roomCode: roomCode,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF45B15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Menu →',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
