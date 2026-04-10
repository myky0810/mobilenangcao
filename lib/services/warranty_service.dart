import 'package:cloud_firestore/cloud_firestore.dart';

/// Quản lý bảo hành xe theo user trên Firestore.
///
/// Schema:
///   users/{phone}/warranties/{vin}
///
/// Mỗi document warranty chứa:
///   - ownerPhone, vin, carName, carBrand, licensePlate
///   - purchaseDate, startDate, endDate
///   - odoAtActivation, showroomName, showroomAddress
///   - status: pending | active | expired
///   - bookingId, transactionId (nếu tạo từ đặt cọc)
///   - createdAt, updatedAt
class WarrantyService {
  WarrantyService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _ref(String userId) {
    return _db.collection('users').doc(userId).collection('warranties');
  }

  // ─── READ ───────────────────────────────────────────────────────────

  /// Stream tất cả warranties của user, mới nhất trước.
  static Stream<List<Map<String, dynamic>>> streamWarranties(String userId) {
    return _ref(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  // ─── WRITE ──────────────────────────────────────────────────────────

  /// Kích hoạt bảo hành thủ công (VIN + ODO + ngày mua).
  /// Status = active ngay lập tức.
  static Future<void> activateWarranty({
    required String userId,
    required String vin,
    required String carName,
    required String carBrand,
    String licensePlate = '',
    required String purchaseDate,
    required String odoAtActivation,
    String showroomName = '',
    String showroomAddress = '',
  }) async {
    final now = DateTime.now();
    final endDate = DateTime(now.year + 3, now.month, now.day);

    await _ref(userId).doc(vin).set({
      'vin': vin,
      'ownerPhone': userId,
      'carName': carName,
      'carBrand': carBrand,
      'licensePlate': licensePlate,
      'purchaseDate': purchaseDate,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'odoAtActivation': odoAtActivation,
      'showroomName': showroomName,
      'showroomAddress': showroomAddress,
      'status': 'active',
      'bookingId': '',
      'transactionId': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Tự tạo warranty ở trạng thái **pending** khi khách đặt cọc/mua xe.
  /// Document ID = "pending_{bookingId}" (vì chưa có VIN).
  static Future<void> createPendingWarranty({
    required String userId,
    required String carName,
    required String carBrand,
    String carImage = '',
    String showroomName = '',
    String showroomAddress = '',
    String bookingId = '',
    String transactionId = '',
  }) async {
    final docId = bookingId.isNotEmpty
        ? 'pending_$bookingId'
        : 'pending_${DateTime.now().millisecondsSinceEpoch}';

    await _ref(userId).doc(docId).set({
      'vin': '',
      'ownerPhone': userId,
      'carName': carName,
      'carBrand': carBrand,
      // Dùng chung key với UI: Warranty screen ưu tiên imageUrl, fallback carImage.
      // Ở app này ảnh thường là asset path, nên lưu vào carImage để nhất quán với booking/garage.
      'carImage': carImage,
      'licensePlate': '',
      'purchaseDate': '',
      'startDate': null,
      'endDate': null,
      'odoAtActivation': '',
      'showroomName': showroomName,
      'showroomAddress': showroomAddress,
      'status': 'pending',
      'bookingId': bookingId,
      'transactionId': transactionId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kích hoạt 1 warranty đang pending: user nhập VIN + ODO + ngày mua.
  /// Xoá document pending cũ → tạo document mới với VIN làm ID.
  static Future<void> activatePendingWarranty({
    required String userId,
    required String pendingDocId,
    required String vin,
    required String purchaseDate,
    required String odoAtActivation,
    String licensePlate = '',
  }) async {
    final oldDoc = await _ref(userId).doc(pendingDocId).get();
    if (!oldDoc.exists) return;

    final oldData = oldDoc.data() ?? {};
    final now = DateTime.now();
    final endDate = DateTime(now.year + 3, now.month, now.day);

    // Tạo document mới với VIN
    await _ref(userId).doc(vin).set({
      ...oldData,
      'vin': vin,
      'licensePlate': licensePlate,
      'purchaseDate': purchaseDate,
      'odoAtActivation': odoAtActivation,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Xoá document pending cũ
    await _ref(userId).doc(pendingDocId).delete();
  }

  /// Xoá warranty.
  static Future<void> deleteWarranty({
    required String userId,
    required String docId,
  }) async {
    await _ref(userId).doc(docId).delete();
  }
}
