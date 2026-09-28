class TableModel {
  final int id;
  final String tableNumber;
  final int capacity;
  final String status; // available, occupied, reserved, cleaning
  final String? occupiedByPhone;
  final String? roomCode;
  final DateTime? occupiedAt;
  final int? activeSessionId;
  final double runningAmount;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.occupiedByPhone,
    this.roomCode,
    this.occupiedAt,
    this.activeSessionId,
    this.runningAmount = 0,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      tableNumber: json['table_number'],
      capacity: json['capacity'] ?? 4,
      status: json['status'] ?? 'available',
      occupiedByPhone: json['occupied_by_phone'],
      roomCode: json['room_code'],
      occupiedAt: DateTime.tryParse(json['occupied_at'] ?? ''),
      activeSessionId: json['active_session_id'] is int
          ? json['active_session_id'] as int
          : int.tryParse(json['active_session_id']?.toString() ?? ''),
      runningAmount: json['running_amount'] is num
          ? (json['running_amount'] as num).toDouble()
          : double.tryParse(json['running_amount']?.toString() ?? '') ?? 0,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isCleaning => status == 'cleaning';
  bool get isReserved => status == 'reserved';
}
