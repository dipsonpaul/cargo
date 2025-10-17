import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, driver, customer }

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isFirstLogin;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.isFirstLogin = false,
    this.profileImageUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: _parseRole(data['role']),
      isActive: _parseBool(data['isActive'], defaultValue: true),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      lastLogin: _parseDateTime(data['lastLogin']),
      isFirstLogin: _parseBool(data['isFirstLogin'], defaultValue: false),
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // Helper method to safely parse UserRole
  static UserRole _parseRole(dynamic value) {
    if (value == null) return UserRole.customer;

    String roleStr = value.toString().toLowerCase();

    // Handle both "UserRole.customer" and "customer" formats
    if (roleStr.contains('admin')) return UserRole.admin;
    if (roleStr.contains('driver')) return UserRole.driver;
    return UserRole.customer;
  }

  // Helper method to safely parse boolean values
  static bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  // Helper method to safely parse DateTime from multiple formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      // Handle Firestore Timestamp
      if (value is Timestamp) {
        return value.toDate();
      }

      // Handle String (ISO 8601 format)
      if (value is String) {
        return DateTime.parse(value);
      }

      // Handle DateTime (already parsed)
      if (value is DateTime) {
        return value;
      }

      // Handle milliseconds since epoch (int)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      print('Error parsing date value: $value, error: $e');
      return null;
    }

    print('Unknown date type: ${value.runtimeType}');
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isFirstLogin': isFirstLogin,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isFirstLogin,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
