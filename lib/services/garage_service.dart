import 'package:cloud_firestore/cloud_firestore.dart';

/// Lưu xe của khách hàng theo từng user trên Firestore.
///
/// Schema (tách bạch theo user, dễ quản lý trên Firestore Console):
///   users/{phone}/garageVehicles/{vehicleId}
///
/// Mỗi document xe luôn chứa:
///   - ownerPhone : số điện thoại chủ xe (= userId)
///   - vehicleId  : ID xe (trùng document ID)
///   - name, subtitle, status, imageUrl, …
///   - createdAt, updatedAt : timestamp
///
/// → Trên Firestore Console bạn có thể mở bất kì document nào và biết ngay
///   xe thuộc tài khoản nào nhờ field `ownerPhone`.
class GarageService {
  GarageService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _vehiclesRef(String userId) {
    return _db.collection('users').doc(userId).collection('garageVehicles');
  }

  // ─── READ ───────────────────────────────────────────────────────────

  /// Stream danh sách xe trong garage của user.
  static Stream<List<Map<String, dynamic>>> streamVehicles(String userId) {
    return _vehiclesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  // ─── WRITE ──────────────────────────────────────────────────────────

  /// Thêm / cập nhật 1 xe. Luôn ghi kèm `ownerPhone` & `vehicleId`.
  static Future<void> upsertVehicle({
    required String userId,
    required String vehicleId,
    required Map<String, dynamic> data,
  }) async {
    await _vehiclesRef(userId).doc(vehicleId).set({
      ...data,
      'ownerPhone': userId,
      'vehicleId': vehicleId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Xoá 1 xe khỏi garage.
  static Future<void> deleteVehicle({
    required String userId,
    required String vehicleId,
  }) async {
    await _vehiclesRef(userId).doc(vehicleId).delete();
  }

  /// Thêm xe vừa mua/đặt cọc vào garage với status ORDERED.
  /// vehicleId nên dùng bookingId hoặc tương tự để tránh trùng.
  static Future<void> addPurchasedCar({
    required String userId,
    required String carName,
    required String carBrand,
    required String carImage,
    String bookingId = '',
    String showroomName = '',
  }) async {
    final vehicleId = bookingId.isNotEmpty
        ? 'purchased_$bookingId'
        : 'purchased_${DateTime.now().millisecondsSinceEpoch}';

    await upsertVehicle(
      userId: userId,
      vehicleId: vehicleId,
      data: {
        'name': carName,
        'subtitle': carBrand,
        'status': 'ORDERED',
        'imageUrl': carImage,
        'odometerLabel': 'SHOWROOM',
        'odometerValue': showroomName.isNotEmpty ? showroomName : 'Chờ giao xe',
        'fuelLabel': 'TRẠNG THÁI',
        'fuelValue': 'Đã đặt cọc',
        'bookingId': bookingId,
        'isSeed': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // ─── SEED ───────────────────────────────────────────────────────────

  /// Seed 2 xe mẫu nếu user chưa có xe nào.
  ///
  /// Nếu user đã có xe nhưng xe seed cũ dùng URL mạng → tự sửa sang asset.
  static Future<void> ensureSeedVehicleForUser(String userId) async {
    // ── Ảnh local trong assets/images/products/ ──
    const bmwImage =
        'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg';
    const benzImage =
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-769aa742caf3f44036ee9931eb310892b3.jpg';

    final snap = await _vehiclesRef(userId).limit(1).get();

    if (snap.docs.isEmpty) {
      // ─ Chưa có xe → seed 2 xe mẫu ─
      await upsertVehicle(
        userId: userId,
        vehicleId: 'seed_bmw_m4',
        data: {
          'status': 'ACTIVE',
          'name': 'BMW M4 Competition',
          'subtitle': 'Black Phantom Edition',
          'imageUrl': bmwImage,
          'odometerLabel': 'ODOMETER',
          'odometerValue': '12,482 km',
          'fuelLabel': 'FUEL LEVEL',
          'fuelValue': '85%',
          'createdAt': FieldValue.serverTimestamp(),
          'isSeed': true,
        },
      );

      await upsertVehicle(
        userId: userId,
        vehicleId: 'seed_benz_g63',
        data: {
          'status': 'IN SERVICE',
          'name': 'Mercedes-Benz G-Wagon',
          'subtitle': 'Obsidian Silver',
          'imageUrl': benzImage,
          'odometerLabel': 'ODOMETER',
          'odometerValue': '4,120 km',
          'fuelLabel': 'NEXT SERVICE',
          'fuelValue': '2,500 km',
          'createdAt': FieldValue.serverTimestamp(),
          'isSeed': true,
        },
      );
      return;
    }

    // ─ Đã có xe → kiểm tra & sửa seed cũ / tạo seed thiếu ─
    await _fixOrCreateSeed(userId, 'seed_bmw_m4', bmwImage, {
      'status': 'ACTIVE',
      'name': 'BMW M4 Competition',
      'subtitle': 'Black Phantom Edition',
      'odometerLabel': 'ODOMETER',
      'odometerValue': '12,482 km',
      'fuelLabel': 'FUEL LEVEL',
      'fuelValue': '85%',
    });
    await _fixOrCreateSeed(userId, 'seed_benz_g63', benzImage, {
      'status': 'IN SERVICE',
      'name': 'Mercedes-Benz G-Wagon',
      'subtitle': 'Obsidian Silver',
      'odometerLabel': 'ODOMETER',
      'odometerValue': '4,120 km',
      'fuelLabel': 'NEXT SERVICE',
      'fuelValue': '2,500 km',
    });
  }

  /// Sửa seed cũ (URL mạng → asset, bổ sung ownerPhone) hoặc tạo mới nếu chưa có.
  static Future<void> _fixOrCreateSeed(
    String userId,
    String vehicleId,
    String localImage,
    Map<String, dynamic> seedData,
  ) async {
    final doc = await _vehiclesRef(userId).doc(vehicleId).get();

    if (!doc.exists) {
      // Seed chưa tồn tại → tạo mới
      await upsertVehicle(
        userId: userId,
        vehicleId: vehicleId,
        data: {
          ...seedData,
          'imageUrl': localImage,
          'createdAt': FieldValue.serverTimestamp(),
          'isSeed': true,
        },
      );
      return;
    }

    // Seed đã tồn tại → kiểm tra & sửa nếu cần
    final data = doc.data() ?? {};
    final currentUrl = (data['imageUrl'] ?? '').toString();
    final hasOwner = data.containsKey('ownerPhone');

    if (currentUrl.startsWith('http') || !hasOwner) {
      await _vehiclesRef(userId).doc(vehicleId).update({
        'imageUrl': localImage,
        'ownerPhone': userId,
        'vehicleId': vehicleId,
      });
    }
  }
}
