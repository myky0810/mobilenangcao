import 'package:cloud_firestore/cloud_firestore.dart';

/// OTP document stored in `otp_codes/{phone}`.
class OtpCode {
  final String phoneNumber;
  final String otpCode;
  final bool verified;
  final int attempts;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? verifiedAt;

  const OtpCode({
    required this.phoneNumber,
    required this.otpCode,
    required this.verified,
    required this.attempts,
    required this.createdAt,
    required this.expiresAt,
    this.verifiedAt,
  });

  factory OtpCode.fromFirestore(Map<String, dynamic> map) {
    DateTime parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    return OtpCode(
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      otpCode: (map['otpCode'] as String?) ?? '',
      verified: (map['verified'] as bool?) ?? false,
      attempts: (map['attempts'] as int?) ?? 0,
      createdAt: parseTs(map['createdAt']),
      expiresAt: parseTs(map['expiresAt']),
      verifiedAt: map['verifiedAt'] != null ? parseTs(map['verifiedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'otpCode': otpCode,
      'verified': verified,
      'attempts': attempts,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }
}
