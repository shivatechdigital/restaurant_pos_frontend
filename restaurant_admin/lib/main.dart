import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/admin_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_dashboard.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: MaterialApp(
        title: 'Admin Panel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1A237E),
        ),
        home: const AdminSessionGate(),
      ),
    );
  }
}

class AdminSessionGate extends StatefulWidget {
  const AdminSessionGate({super.key});

  @override
  State<AdminSessionGate> createState() => _AdminSessionGateState();
}

class _AdminSessionGateState extends State<AdminSessionGate> {
  bool _loading = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');
    final restaurantId = prefs.getInt('restaurant_id');
    final name = prefs.getString('admin_name');

    if (token != null && token.isNotEmpty && restaurantId != null) {
      if (!mounted) return;
      context.read<AdminProvider>().setRestaurant(restaurantId, name ?? 'Admin');
      setState(() {
        _hasSession = true;
        _loading = false;
      });
      return;
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _hasSession ? const MainDashboard() : const LoginScreen();
  }
}
