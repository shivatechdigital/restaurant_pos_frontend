import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/debug_flags.dart';
import '../providers/waiter_provider.dart';
import '../services/api_service.dart';
import '../config/socket_service.dart';
import 'table_map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _api = ApiService();
  bool otpSent = false;
  bool isLoading = false;
  String error = '';
  String? testOtp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.room_service, size: 70, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Waiter App',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              prefixText: '+91 ',
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.phone),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (_phoneCtrl.text.length == 10) {
                                        setState(() => isLoading = true);
                                        final r = await _api.sendOtp(
                                          _phoneCtrl.text,
                                        );
                                        if (!mounted) return;
                                        setState(() => isLoading = false);
                                        if (r['success'] == true) {
                                          setState(() {
                                            otpSent = true;
                                            testOtp = r['data']?['otp']
                                                ?.toString();
                                          });
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Send OTP',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              letterSpacing: 10,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'OTP',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              counterText: '',
                            ),
                          ),
                          if (error.isNotEmpty)
                            Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          if (kShowTestOtp && testOtp != null)
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
                                  'Test OTP: $testOtp',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        isLoading = true;
                                        error = '';
                                      });
                                      final r = await _api.verifyOtp(
                                        _phoneCtrl.text,
                                        _otpCtrl.text,
                                      );
                                      if (!mounted) return;
                                      setState(() => isLoading = false);

                                      if (r['success'] == true) {
                                        final role = r['data']['user']['role'];
                                        if (role != 'waiter' &&
                                            role != 'admin') {
                                          setState(
                                            () => error = 'This number is not registered as an active waiter or admin. Ask your admin to add it under Staff.',
                                          );
                                          return;
                                        }
                                        final restaurantId =
                                            r['data']['user']['restaurant_id'] ??
                                            1;
                                        if (!context.mounted) return;
                                        final waiter = context
                                            .read<WaiterProvider>();
                                        waiter.setRestaurantId(restaurantId);
                                        SocketService().connect(
                                          restaurantId.toString(),
                                        );

                                        if (!context.mounted) return;
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const TableMapScreen(),
                                          ),
                                        );
                                      } else {
                                        setState(
                                          () => error = r['message'] ?? 'Error',
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16),
                                    ),
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
