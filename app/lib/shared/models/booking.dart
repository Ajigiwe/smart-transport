/// SmartTransport GH Booking Model
class Booking {
  final int id;
  final int tripId;
  final int passengerId;
  final String status;
  final DateTime requestedAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.status,
    required this.requestedAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      tripId: json['trip_id'] ?? 0,
      passengerId: json['passenger_id'] ?? 0,
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(json['requested_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'status': status,
    };
  }
}
