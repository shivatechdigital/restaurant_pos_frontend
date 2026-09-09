import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/kitchen_provider.dart';
import 'screens/login_screen.dart';
import 'screens/kds_dashboard.dart';
import 'config/socket_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KitchenProvider()),
      ],
      child: MaterialApp(
        title: 'Kitchen Display',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFB71C1C),
        ),
        home: const KitchenSessionGate(),
      ),
    );
  }
}

class KitchenSessionGate extends StatefulWidget {
  const KitchenSessionGate({super.key});

  @override
  State<KitchenSessionGate> createState() => _KitchenSessionGateState();
}

class _KitchenSessionGateState extends State<KitchenSessionGate> {
  bool _loading = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('kitchen_token');
    final role = prefs.getString('kitchen_role');
    final restaurantId = prefs.getInt('kitchen_restaurant_id');

    if (token != null && token.isNotEmpty &&
        restaurantId != null && (role == 'kitchen' || role == 'admin')) {
      SocketService().connect(restaurantId.toString());
      if (!mounted) return;
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _hasSession ? const KDSDashboard() : const LoginScreen();
  }
}
