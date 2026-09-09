class WaiterRequest {
  final int tableId;
  final String tableNumber;
  final String requestType;
  final String message;
  final DateTime timestamp;
  bool isRead;

  WaiterRequest({
    required this.tableId,
    required this.tableNumber,
    required this.requestType,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory WaiterRequest.fromSocket(Map<String, dynamic> data) {
    return WaiterRequest(
      tableId: data['table_id'] ?? 0,
      tableNumber: data['table_number'] ?? '?',
      requestType: data['request_type'] ?? 'general',
      message: data['message'] ?? 'Waiter needed',
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  String get emoji {
    switch (requestType) {
      case 'water':
        return '💧';
      case 'tissue':
        return '🧻';
      case 'bill':
        return '🧾';
      case 'cleaning':
        return '🧹';
      case 'custom':
        return '📝';
      default:
        return '🛎️';
    }
  }

  // Kitne seconds pehle aaya
  int get secondsAgo => DateTime.now().difference(timestamp).inSeconds;
}
