import 'package:cloud_firestore/cloud_firestore.dart';

/// Lưu xe của khách hàng theo từng user trên Firestore.
///
/// Schema đề xuất (tách bạch theo user):
/// users/{userId}/garageVehicles/{vehicleId}
///
/// Vì `FirebaseService` đang dùng collection `users`, nên đặt subcollection
/// dưới `users/{userId}` sẽ đúng với yêu cầu: đăng nhập tài khoản khác chỉ
/// cần thêm field vào đúng document/subcollection là MyCar hiển thị được.
class GarageService {
  GarageService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _vehiclesRef(String userId) {
    return _db.collection('users').doc(userId).collection('garageVehicles');
  }

  /// Stream danh sách xe trong garage của user.
  static Stream<List<Map<String, dynamic>>> streamVehicles(String userId) {
    return _vehiclesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  /// Thêm/ghi đè 1 xe theo vehicleId.
  static Future<void> upsertVehicle({
    required String userId,
    required String vehicleId,
    required Map<String, dynamic> data,
  }) async {
    await _vehiclesRef(userId).doc(vehicleId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Seed 1 "xe cứng" nếu user chưa có xe nào.
  ///
  /// Xe này chỉ là dữ liệu mẫu giúp MyCar không bị trống cho tài khoản mới.
  /// Bạn có thể vào Firestore sửa/đổi field theo ý để hiển thị đúng UI.
  static Future<void> ensureSeedVehicleForUser(String userId) async {
    final snap = await _vehiclesRef(userId).limit(1).get();
    if (snap.docs.isNotEmpty) return;

    const vehicleId = 'seed_bmw_m4';

    await upsertVehicle(
      userId: userId,
      vehicleId: vehicleId,
      data: {
        'status': 'ACTIVE',
        'name': 'BMW M4 Competition',
        'subtitle': 'Black Phantom Edition',
        'imageUrl':
            'https://images.unsplash.com/photo-1511910849309-0dffb8782df0?auto=format&fit=crop&w=1600&q=60',
        'odometerLabel': 'ODOMETER',
        'odometerValue': '12,482 km',
        'fuelLabel': 'FUEL LEVEL',
        'fuelValue': '85%',
        'createdAt': FieldValue.serverTimestamp(),
        'isSeed': true,
      },
    );
  }
}
