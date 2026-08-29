/// SmartTransport GH Route Model
class AppRoute {
  final int id;
  final String name;
  final String startPoint;
  final String endPoint;
  final double fare;
  final String? stops;
  final bool isActive;
  final DateTime createdAt;

  AppRoute({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.fare,
    this.stops,
    required this.isActive,
    required this.createdAt,
  });

  factory AppRoute.fromJson(Map<String, dynamic> json) {
    return AppRoute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startPoint: json['start_point'] ?? '',
      endPoint: json['end_point'] ?? '',
      fare: (json['fare'] ?? 0).toDouble(),
      stops: json['stops'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start_point': startPoint,
      'end_point': endPoint,
      'fare': fare,
      'stops': stops,
    };
  }

  List<String> get stopsList {
    if (stops == null || stops!.isEmpty) return [];
    return stops!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
