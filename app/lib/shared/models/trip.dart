/// SmartTransport GH Trip Model
class Trip {
  final int id;
  final int routeId;
  final int driverId;
  final int vehicleId;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.vehicleId,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? 0,
      routeId: json['route_id'] ?? 0,
      driverId: json['driver_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      status: json['status'] ?? 'scheduled',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'status': status,
    };
  }
}
