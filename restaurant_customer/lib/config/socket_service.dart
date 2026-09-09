import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String restaurantId, String tableId) {
    if (_socket?.connected == true) return;

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('🔌 Socket Connected');
      _socket!.emit('join_restaurant', restaurantId);
      _socket!.emit('join_table', tableId);
    });

    _socket!.onDisconnect((_) => debugPrint('🔌 Disconnected'));
    _socket!.onConnectError((e) => debugPrint('❌ Socket Error: $e'));
  }

  void on(String event, Function callback) {
    _socket?.on(event, (data) => callback(data));
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
