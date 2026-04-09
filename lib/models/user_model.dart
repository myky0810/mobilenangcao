import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical user profile stored under Firestore provider collections:
/// - Google: `users_google/{uid}`
/// - Phone : `users_phone/{normalizedPhone}`
///
/// UNIFIED MODEL: Supports both phone and Google (email) login.
/// - Canonical:
///   - Google: id = FirebaseAuth uid
///   - Phone : id = normalizedPhone
/// - Legacy fallback: older data may still have id = email.toLowerCase() etc.
///
/// Notes:
/// - Keep fields optional to avoid breaking existing writes.
/// - 'phone' and 'phoneNumber' are aliases (for backward compatibility)
class UserModel {
  final String id;
  final String? phoneNumber;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? provider; // 'google', 'phone', or null

  // Extra profile fields used in Info/ChangeInfo screens
  final String? gender;
  final DateTime? dob;
  final int? provinceCode;
  final int? districtCode;
  final int? wardCode;

  // Address (used in info/changeinfo/deposit screens)
  final String? street;
  final String? wardName;
  final String? districtName;
  final String? provinceName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.phoneNumber,
    this.name = '',
    this.email,
    this.avatarUrl,
    this.provider,

    this.gender,
    this.dob,
    this.provinceCode,
    this.districtCode,
    this.wardCode,
    this.street,
    this.wardName,
    this.districtName,
    this.provinceName,
    this.createdAt,
    this.updatedAt,
  });

  /// Alias cho phoneNumber (backward compatibility)
  String? get phone => phoneNumber;

  factory UserModel.fromFirestore(Map<String, dynamic> map, String documentId) {
    DateTime? parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    int? parseInt(Object? raw) {
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw);
      return null;
    }

    return UserModel(
      id: documentId,
      phoneNumber:
          (map['phoneNumber'] as String?)?.trim() ??
          (map['phone'] as String?)?.trim(), // Support both fields
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?)?.trim(),
      avatarUrl: (map['avatarUrl'] as String?)?.trim(),
      provider: (map['provider'] as String?)?.trim(),

      gender: (map['gender'] as String?)?.trim(),
      dob: parseTs(map['dob']),
      provinceCode: parseInt(map['provinceCode']),
      districtCode: parseInt(map['districtCode']),
      wardCode: parseInt(map['wardCode']),
      street: (map['street'] as String?)?.trim(),
      wardName: (map['wardName'] as String?)?.trim(),
      districtName: (map['districtName'] as String?)?.trim(),
      provinceName: (map['provinceName'] as String?)?.trim(),
      createdAt: parseTs(map['createdAt']),
      updatedAt: parseTs(map['updatedAt']),
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel.fromFirestore(data, doc.id);
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    return {
      'phoneNumber': phoneNumber,
      'phone': phoneNumber, // Lưu cả 2 fields cho backward compatibility
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'provider': provider,

      'gender': gender,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'provinceCode': provinceCode,
      'districtCode': districtCode,
      'wardCode': wardCode,
      'street': street,
      'wardName': wardName,
      'districtName': districtName,
      'provinceName': provinceName,
      if (includeTimestamps) 'updatedAt': FieldValue.serverTimestamp(),
      if (includeTimestamps && createdAt == null)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? avatarUrl,
    String? provider,
    String? street,
    String? wardName,
    String? districtName,
    String? provinceName,
    String? gender,
    DateTime? dob,
    int? provinceCode,
    int? districtCode,
    int? wardCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      provider: provider ?? this.provider,
      street: street ?? this.street,
      wardName: wardName ?? this.wardName,
      districtName: districtName ?? this.districtName,
      provinceName: provinceName ?? this.provinceName,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      provinceCode: provinceCode ?? this.provinceCode,
      districtCode: districtCode ?? this.districtCode,
      wardCode: wardCode ?? this.wardCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress {
    final parts = [street, wardName, districtName, provinceName]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    return parts.join(', ');
  }
}
