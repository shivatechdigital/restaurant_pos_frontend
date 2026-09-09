import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kTableId = 'session_table_id';
  static const _kRestaurantId = 'session_restaurant_id';
  static const _kTableNumber = 'session_table_number';
  static const _kSessionId = 'session_session_id';
  static const _kRoomCode = 'session_room_code';
  static const _kSessionType = 'session_type';
  static const _kOrderType = 'session_order_type';
  static const _kPickupToken = 'session_pickup_token';

  // Table lock hone par session save karo
  static Future<void> saveSession({
    required int tableId,
    required String restaurantId,
    required String tableNumber,
    required String sessionId,
    required String roomCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTableId, tableId);
    await prefs.setString(_kRestaurantId, restaurantId);
    await prefs.setString(_kTableNumber, tableNumber);
    await prefs.setString(_kSessionId, sessionId);
    await prefs.setString(_kRoomCode, roomCode);
    await prefs.setString(_kSessionType, 'dine_in');
  }

  static Future<void> saveOffPremiseSession({
    required String sessionId,
    required String orderType,
    String? pickupToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTableId);
    await prefs.remove(_kRestaurantId);
    await prefs.remove(_kTableNumber);
    await prefs.remove(_kRoomCode);
    await prefs.setString(_kSessionType, 'off_premise');
    await prefs.setString(_kSessionId, sessionId);
    await prefs.setString(_kOrderType, orderType);
    if (pickupToken != null) {
      await prefs.setString(_kPickupToken, pickupToken);
    } else {
      await prefs.remove(_kPickupToken);
    }
  }

  // App start hote hi saved session check karo
  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final tableId = prefs.getInt(_kTableId);
    final restaurantId = prefs.getString(_kRestaurantId);
    final tableNumber = prefs.getString(_kTableNumber);
    final sessionId = prefs.getString(_kSessionId);
    final roomCode = prefs.getString(_kRoomCode);

    if (prefs.getString(_kSessionType) == 'off_premise' && sessionId != null) {
      return {
        'type': 'off_premise',
        'session_id': sessionId,
        'order_type': prefs.getString(_kOrderType) ?? 'takeaway',
        'pickup_token': prefs.getString(_kPickupToken),
      };
    }

    if (tableId == null ||
        restaurantId == null ||
        tableNumber == null ||
        sessionId == null ||
        roomCode == null) {
      return null;
    }

    return {
      'table_id': tableId,
      'type': 'dine_in',
      'restaurant_id': restaurantId,
      'table_number': tableNumber,
      'session_id': sessionId,
      'room_code': roomCode,
    };
  }

  // Logout / table release hone par session clear karo
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTableId);
    await prefs.remove(_kRestaurantId);
    await prefs.remove(_kTableNumber);
    await prefs.remove(_kSessionId);
    await prefs.remove(_kRoomCode);
    await prefs.remove(_kSessionType);
    await prefs.remove(_kOrderType);
    await prefs.remove(_kPickupToken);
  }
}
