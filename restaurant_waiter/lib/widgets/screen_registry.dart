import 'waiter_shell.dart';
import '../screens/table_map_screen.dart';
import '../screens/active_orders_screen.dart';
import '../screens/serve_orders_screen.dart';
import '../screens/track_order_screen.dart';
import '../screens/table_transfer_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';

/// Wires up [screenForRoute] so the shared sidebar/topbar can navigate
/// between screens without those screens importing each other directly.
/// Call this once before the app starts navigating (see main.dart).
void registerWaiterScreens() {
  screenForRoute = (route) {
    switch (route) {
      case WaiterRoute.floor:
        return const TableMapScreen();
      case WaiterRoute.orders:
        return const ActiveOrdersScreen();
      case WaiterRoute.serve:
        return const ServeOrdersScreen();
      case WaiterRoute.track:
        return const TrackOrderScreen();
      case WaiterRoute.transfer:
        return const TableTransferScreen();
      case WaiterRoute.notifications:
        return const NotificationsScreen();
      case WaiterRoute.settings:
        return const SettingsScreen();
    }
  };
}
