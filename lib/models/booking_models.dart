import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking models used by multiple screens:
/// - `BookCarScreen` writes booking test-drive (?) data
/// - `TestDriveScreen` reads from `test_drive_bookings`
/// - `DepositScreen` writes to `deposits`
///
/// Keeping them in one file helps admin manage Firestore collections consistently.

class TestDriveBooking {
  final String? id;
  final String userPhone;

  final String carName;
  final String carBrand;
  final String? carImage;
  final String? carPrice;

  final String date; // stored as formatted string in your UI
  final String time;

  final String name;
  final String phone;
  final String email;

  final String? showroomName;
  final String? showroomAddress;
  final String? googleMapsUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TestDriveBooking({
    this.id,
    required this.userPhone,
    required this.carName,
    required this.carBrand,
    this.carImage,
    this.carPrice,
    required this.date,
    required this.time,
    required this.name,
    required this.phone,
    required this.email,
    this.showroomName,
    this.showroomAddress,
    this.googleMapsUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory TestDriveBooking.fromFirestore(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    DateTime? parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return TestDriveBooking(
      id: documentId,
      userPhone: (map['userPhone'] as String?)?.trim() ?? '',
      carName: (map['carName'] as String?)?.trim() ?? '',
      carBrand: (map['carBrand'] as String?)?.trim() ?? '',
      carImage: (map['carImage'] as String?)?.toString(),
      carPrice: (map['carPrice'] as String?)?.toString(),
      date: (map['date'] as String?)?.trim() ?? '',
      time: (map['time'] as String?)?.trim() ?? '',
      name: (map['name'] as String?)?.trim() ?? '',
      phone: (map['phone'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      showroomName: (map['showroomName'] as String?)?.trim(),
      showroomAddress: (map['showroomAddress'] as String?)?.trim(),
      googleMapsUrl: (map['googleMapsUrl'] as String?)?.trim(),
      createdAt: parseTs(map['createdAt']),
      updatedAt: parseTs(map['updatedAt']),
    );
  }

  factory TestDriveBooking.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TestDriveBooking.fromFirestore(
      doc.data() ?? <String, dynamic>{},
      documentId: doc.id,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    return {
      'userPhone': userPhone,
      'carName': carName,
      'carBrand': carBrand,
      'carImage': carImage,
      'carPrice': carPrice,
      'date': date,
      'time': time,
      'name': name,
      'phone': phone,
      'email': email,
      'showroomName': showroomName,
      'showroomAddress': showroomAddress,
      'googleMapsUrl': googleMapsUrl,
      if (includeTimestamps) 'updatedAt': FieldValue.serverTimestamp(),
      if (includeTimestamps && createdAt == null)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class DepositOrder {
  final String? id;
  final String userPhone;

  final String carName;
  final String carBrand;
  final String carImage;
  final String carPrice;

  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String address;
  final String? notes;

  final int depositAmount;
  final String paymentMethod;

  final Map<String, dynamic>? showroom;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DepositOrder({
    this.id,
    required this.userPhone,
    required this.carName,
    required this.carBrand,
    required this.carImage,
    required this.carPrice,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.address,
    this.notes,
    required this.depositAmount,
    required this.paymentMethod,
    this.showroom,
    this.createdAt,
    this.updatedAt,
  });

  factory DepositOrder.fromFirestore(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    DateTime? parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    int parseAmount(Object? raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    return DepositOrder(
      id: documentId,
      userPhone: (map['userPhone'] as String?)?.trim() ?? '',
      carName: (map['carName'] as String?)?.trim() ?? '',
      carBrand: (map['carBrand'] as String?)?.trim() ?? '',
      carImage: (map['carImage'] as String?)?.trim() ?? '',
      carPrice: (map['carPrice'] as String?)?.trim() ?? '',
      customerName: (map['name'] as String?)?.trim() ?? '',
      customerPhone: (map['phone'] as String?)?.trim() ?? '',
      customerEmail: (map['email'] as String?)?.trim() ?? '',
      address: (map['address'] as String?)?.trim() ?? '',
      notes: (map['notes'] as String?)?.trim(),
      depositAmount: parseAmount(map['depositAmount'] ?? map['amount']),
      paymentMethod: (map['paymentMethod'] as String?)?.trim() ?? '',
      showroom: map['showroom'] is Map
          ? Map<String, dynamic>.from(map['showroom'] as Map)
          : null,
      createdAt: parseTs(map['createdAt']),
      updatedAt: parseTs(map['updatedAt']),
    );
  }

  factory DepositOrder.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return DepositOrder.fromFirestore(
      doc.data() ?? <String, dynamic>{},
      documentId: doc.id,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    return {
      'userPhone': userPhone,
      'carName': carName,
      'carBrand': carBrand,
      'carImage': carImage,
      'carPrice': carPrice,
      'name': customerName,
      'phone': customerPhone,
      'email': customerEmail,
      'address': address,
      'notes': notes,
      'depositAmount': depositAmount,
      'paymentMethod': paymentMethod,
      'showroom': showroom,
      if (includeTimestamps) 'updatedAt': FieldValue.serverTimestamp(),
      if (includeTimestamps && createdAt == null)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
