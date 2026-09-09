import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/waiter_provider.dart';
import 'screens/login_screen.dart';
import 'services/app_preferences.dart';
import 'widgets/screen_registry.dart';
import 'widgets/waiter_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerWaiterScreens();
  await AppPreferences.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WaiterProvider(),
      child: MaterialApp(
        title: 'Waiter App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0D47A1),
        ),
        home: const SessionCheckScreen(),
      ),
    );
  }
}

class SessionCheckScreen extends StatefulWidget {
  const SessionCheckScreen({super.key});

  @override
  State<SessionCheckScreen> createState() => _SessionCheckScreenState();
}

class _SessionCheckScreenState extends State<SessionCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    final waiter = context.read<WaiterProvider>();
    final isLoggedIn = await waiter.restoreSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn
            ? screenForRoute(waiterRouteFromName(AppPreferences.defaultView))
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
