import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the `users` collection
/// 
/// ✅ Single collection unified structure:
/// - Document ID: normalized phone (phone-based)
/// - Fields: provider (google|phone), uid (optional), phone, email, name, etc.
class UserModel {
  final String? phone;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dob;
  final int? provinceCode;
  final int? districtCode;
  final int? wardCode;
  final String? street;
  final String? provider; // 'google' or 'phone'
  final String? uid; // Firebase UID (for Google login)
  final String? role; // 'user' or 'admin' (default: 'user')
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;

  UserModel({
    this.phone,
    this.email,
    this.name,
    this.avatarUrl,
    this.gender,
    this.dob,
    this.provinceCode,
    this.districtCode,
    this.wardCode,
    this.street,
    this.provider,
    this.uid,
    this.role,
    this.createdAt,
    this.lastLogin,
    this.updatedAt,
  });

  /// Create UserModel from Firestore document snapshot
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return UserModel(
      phone: (data['phone'] as String?)?.trim(),
      email: (data['email'] as String?)?.trim(),
      name: (data['name'] as String?)?.trim(),
      avatarUrl: (data['avatarUrl'] as String?)?.trim(),
      gender: (data['gender'] as String?)?.trim(),
      dob: _parseDateTime(data['dob']),
      provinceCode: _parseInt(data['provinceCode']),
      districtCode: _parseInt(data['districtCode']),
      wardCode: _parseInt(data['wardCode']),
      street: (data['street'] as String?)?.trim(),
      provider: (data['provider'] as String?)?.trim(),
      uid: (data['uid'] as String?)?.trim(),
      role: (data['role'] as String?)?.trim() ?? 'user',
      createdAt: _parseDateTime(data['createdAt']),
      lastLogin: _parseDateTime(data['lastLogin']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// Create UserModel from JSON map
  factory UserModel.fromMap(Map<String, dynamic> data) {
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return UserModel(
      phone: (data['phone'] as String?)?.trim(),
      email: (data['email'] as String?)?.trim(),
      name: (data['name'] as String?)?.trim(),
      avatarUrl: (data['avatarUrl'] as String?)?.trim(),
      gender: (data['gender'] as String?)?.trim(),
      dob: _parseDateTime(data['dob']),
      provinceCode: _parseInt(data['provinceCode']),
      districtCode: _parseInt(data['districtCode']),
      wardCode: _parseInt(data['wardCode']),
      street: (data['street'] as String?)?.trim(),
      provider: (data['provider'] as String?)?.trim(),
      uid: (data['uid'] as String?)?.trim(),
      role: (data['role'] as String?)?.trim() ?? 'user',
      createdAt: _parseDateTime(data['createdAt']),
      lastLogin: _parseDateTime(data['lastLogin']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// Convert UserModel to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'dob': dob,
      'provinceCode': provinceCode,
      'districtCode': districtCode,
      'wardCode': wardCode,
      'street': street,
      'provider': provider,
      'uid': uid,
      'role': role ?? 'user',
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? phone,
    String? email,
    String? name,
    String? avatarUrl,
    String? gender,
    DateTime? dob,
    int? provinceCode,
    int? districtCode,
    int? wardCode,
    String? street,
    String? provider,
    String? uid,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
  }) {
    return UserModel(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      provinceCode: provinceCode ?? this.provinceCode,
      districtCode: districtCode ?? this.districtCode,
      wardCode: wardCode ?? this.wardCode,
      street: street ?? this.street,
      provider: provider ?? this.provider,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(phone: $phone, name: $name, email: $email, provider: $provider, role: $role)';
  }

  /// Check if user is admin
  bool isAdmin() {
    return role == 'admin';
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return this.role == role;
  }
}
