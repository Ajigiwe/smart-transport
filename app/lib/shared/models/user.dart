/// SmartTransport GH User Model
class User {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: UserRole.fromString(json['role'] ?? 'passenger'),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.value,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  bool get isAdmin => role == UserRole.admin;
  bool get isDriver => role == UserRole.driver;
  bool get isPassenger => role == UserRole.passenger;
}

/// User Role Enum
enum UserRole {
  passenger('passenger'),
  driver('driver'),
  admin('admin');
  
  final String value;
  const UserRole(this.value);
  
  factory UserRole.fromString(String value) {
    switch (value) {
      case 'passenger':
        return UserRole.passenger;
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.passenger;
    }
  }
}
