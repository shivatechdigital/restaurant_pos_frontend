import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/debug_flags.dart';
import '../config/socket_service.dart';
import '../providers/auth_provider.dart';
import 'kds_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool otpSent = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFE53935)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department,
                      size: 70, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Kitchen Display',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text(
                    'Staff Login',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),

                  // White Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        if (!otpSent) ...[
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              prefixText: '+91 ',
                              labelText: 'Staff Phone Number',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.phone),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      if (_phoneCtrl.text.length == 10) {
                                        final ok = await auth
                                            .sendOtp(_phoneCtrl.text);
                                        if (ok) {
                                          setState(() => otpSent = true);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: auth.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Send OTP',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24, letterSpacing: 10),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              labelText: 'OTP',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              counterText: '',
                            ),
                          ),
                          if (auth.error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(auth.error,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          if (kShowTestOtp && auth.testOtp != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Text(
                                  'Test OTP: ${auth.testOtp}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      final ok = await auth
                                          .verifyOtp(_otpCtrl.text);
                                      if (ok && context.mounted) {
                                        // Socket connect karo restaurant ke saath
                                        SocketService().connect(
                                          auth.restaurantId.toString());

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const KDSDashboard(),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: auth.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Login 🔥',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ],
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
