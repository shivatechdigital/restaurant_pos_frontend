import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart'; // ← NAYA
import 'providers/cart_provider.dart'; // ← NAYA
import 'providers/order_provider.dart'; // ← NAYA
import 'screens/landing_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/off_premise_order_screen.dart';
import 'services/session_service.dart';
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
        ChangeNotifierProvider(create: (_) => MenuProvider()), // ← NAYA
        ChangeNotifierProvider(create: (_) => CartProvider()), // ← NAYA
        ChangeNotifierProvider(create: (_) => OrderProvider()), // ← NAYA
      ],
      child: MaterialApp(
        title: 'Restaurant POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Trebuchet MS',
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFF45B15),
          scaffoldBackgroundColor: const Color(0xFFF7F7F7),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF191919),
            elevation: 0,
            centerTitle: false,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: const SessionCheckScreen(),
      ),
    );
  }
}

// Refresh/reopen ke baad saved table-lock session mile toh seedha Menu par le jao
class SessionCheckScreen extends StatefulWidget {
  const SessionCheckScreen({super.key});

  @override
  State<SessionCheckScreen> createState() => _SessionCheckScreenState();
}

class _SessionCheckScreenState extends State<SessionCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await SessionService.getSession();
    if (!mounted) return;

    if (session != null) {
      if (session['type'] == 'off_premise') {
        context.read<OrderProvider>().setSessionId(
          session['session_id'] as String,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OffPremiseTrackingScreen(
              sessionId: session['session_id'] as String,
              orderType: session['order_type'] as String,
              pickupToken: session['pickup_token'] as String?,
            ),
          ),
        );
        return;
      }
      // Refresh se pehle wala cart bhi wapas load karo
      await context.read<CartProvider>().loadCart();
      if (!mounted) return;

      final restaurantId = session['restaurant_id'] as String;
      final tableId = session['table_id'] as int;
      SocketService().connect(restaurantId, tableId.toString());

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MenuScreen(
            restaurantId: restaurantId,
            tableNumber: session['table_number'] as String,
            tableId: tableId,
            sessionId: session['session_id'] as String,
            roomCode: session['room_code'] as String,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFFF45B15))),
    );
  }
}
