/// SmartTransport GH Vehicle Model
class Vehicle {
  final int id;
  final String plateNumber;
  final int capacity;
  final int? driverId;
  final String status;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.capacity,
    this.driverId,
    required this.status,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      plateNumber: json['plate_number'] ?? '',
      capacity: json['capacity'] ?? 4,
      driverId: json['driver_id'],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plate_number': plateNumber,
      'capacity': capacity,
      'driver_id': driverId,
      'status': status,
    };
  }
}
