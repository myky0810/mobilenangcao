import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_helper.dart';
import '../models/user_model.dart';

/// ✅ Unified Google + Phone Registration & Login Service
/// 
/// Database Structure:
/// - Collection: `users` (single collection)
/// - Document ID: normalized phone (consistent across both methods)
/// - Fields: provider (google|phone), uid (optional for Google), phone, email, name, etc.
class GooglePhoneRegistration {
  GooglePhoneRegistration._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _usersCollection = 'users';

  // ============================================================================
  // 📱 PHONE REGISTRATION & LOGIN (Firestore-only)
  // ============================================================================

  /// ✅ Register with Phone + Password
  static Future<void> registerWithPhone({
    required String phone,
    required String password,
  }) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    final ref = _db.collection(_usersCollection).doc(normalized);

    // Check if already exists
    final exists = await ref.get();
    if (exists.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'phone-already-exists',
        message: 'Số điện thoại này đã được đăng ký',
      );
    }

    // Generate salt & hash password
    final salt = FirebaseHelper.generateSalt();
    final hash = FirebaseHelper.hashPassword(salt: salt, password: password);

    // Create user document
    await ref.set({
      'phone': normalized,
      'passwordSalt': salt,
      'passwordHash': hash,
      'provider': 'phone',
      'role': 'user',
      'name': '',
      'email': '',
      'avatarUrl': '',
      'gender': 'Nam',
      'dob': null,
      'provinceCode': null,
      'districtCode': null,
      'wardCode': null,
      'street': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Phone registration success: $normalized');
  }

  /// ✅ Login with Phone + Password
  static Future<String> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    final ref = _db.collection(_usersCollection).doc(normalized);

    final doc = await ref.get();
    if (!doc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'user-not-found',
        message: 'Số điện thoại này chưa được đăng ký',
      );
    }

    final data = doc.data() ?? {};
    final salt = data['passwordSalt'] as String?;
    final hash = data['passwordHash'] as String?;

    if (salt == null || hash == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'corrupt-user',
        message: 'Tài khoản bị lỗi dữ liệu',
      );
    }

    final inputHash = FirebaseHelper.hashPassword(salt: salt, password: password);
    if (inputHash != hash) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'wrong-password',
        message: 'Mật khẩu không chính xác',
      );
    }

    // Update lastLogin
    await ref.update({
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Phone login success: $normalized');
    return normalized;
  }

  // ============================================================================
  // 🔐 GOOGLE LOGIN (Firebase Auth + Firestore)
  // ============================================================================

  /// ✅ Get phone number for a Google UID (if already registered)
  static Future<String?> getPhoneByGoogleUid(String uid) async {
    try {
      final snapshot = await _db
          .collection(_usersCollection)
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final phone = snapshot.docs.first.data()['phone'] as String?;
        return phone;
      }
      return null;
    } catch (e) {
      print('❌ Error getting phone by UID: $e');
      return null;
    }
  }

  /// ✅ Register Google login with phone number (first time)
  /// Bắt buộc có phone để làm Document ID
  static Future<String> registerGoogleWithPhone({
    required User firebaseUser,
    required String phone,
  }) async {
    try {
      final normalized = FirebaseHelper.normalizePhone(phone);

      // Check xem phone đã được dùng bởi user khác chưa
      final existingDoc = await _db
          .collection(_usersCollection)
          .doc(normalized)
          .get();

      if (existingDoc.exists) {
        final existingUid = existingDoc.data()?['uid'] as String?;
        if (existingUid != null && existingUid != firebaseUser.uid) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'phone-already-used',
            message: 'Số điện thoại này đã được sử dụng bởi tài khoản khác',
          );
        }
      }

      // Email để lấy thông tin
      final email = (firebaseUser.email ?? '').toLowerCase();

      // Save user document với phone làm ID
      await _db.collection(_usersCollection).doc(normalized).set({
        'phone': normalized,
        'uid': firebaseUser.uid,
        'provider': 'google',
        'role': 'user',
        'email': email,
        'name': firebaseUser.displayName ?? 'Người dùng Google',
        'avatarUrl': firebaseUser.photoURL ?? '',
        'gender': 'Nam',
        'dob': null,
        'provinceCode': null,
        'districtCode': null,
        'wardCode': null,
        'street': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Google +Phone registration success: $normalized');
      return normalized;
    } catch (e) {
      print('❌ Google+Phone registration error: $e');
      rethrow;
    }
  }

  /// ✅ Record Google login (if phone already exists)
  /// Dùng khi user đã từng đăng ký Google+Phone
  static Future<String> recordGoogleLogin(User firebaseUser) async {
    try {
      final phone = await getPhoneByGoogleUid(firebaseUser.uid);
      if (phone == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'no-phone-found',
          message: 'Không tìm thấy số điện thoại. Vui lòng đăng ký lại.',
        );
      }

      // Update lastLogin
      await _db.collection(_usersCollection).doc(phone).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Google login (existing): $phone');
      return phone;
    } catch (e) {
      print('❌ Google login error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 🔄 UTILITY METHODS
  // ============================================================================

  /// Get user by phone
  static Future<UserModel?> getUserByPhone(String phone) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    final doc = await _db.collection(_usersCollection).doc(normalized).get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  /// Watch user by phone (realtime)
  static Stream<UserModel?> watchUserByPhone(String phone) {
    final normalized = FirebaseHelper.normalizePhone(phone);
    return _db
        .collection(_usersCollection)
        .doc(normalized)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  /// Update user fields
  static Future<void> updateUserFields(
    String phone,
    Map<String, dynamic> fields,
  ) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    await _db.collection(_usersCollection).doc(normalized).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ User updated: $normalized');
  }

  /// Logout (Firebase Auth only)
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}

    print('✅ Logged out');
  }

  /// Check if user exists by phone
  static Future<bool> userExists(String phone) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    final doc =
        await _db.collection(_usersCollection).doc(normalized).get();
    return doc.exists;
  }

  /// Change password
  static Future<void> changePassword({
    required String phone,
    required String oldPassword,
    required String newPassword,
  }) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    final ref = _db.collection(_usersCollection).doc(normalized);

    final doc = await ref.get();
    if (!doc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'user-not-found',
        message: 'Tài khoản không tồn tại',
      );
    }

    final data = doc.data() ?? {};
    final salt = data['passwordSalt'] as String?;
    final hash = data['passwordHash'] as String?;

    if (salt == null || hash == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'no-password',
        message: 'Tài khoản này đăng nhập qua Google, không có mật khẩu',
      );
    }

    // Verify old password
    final oldHash =
        FirebaseHelper.hashPassword(salt: salt, password: oldPassword);
    if (oldHash != hash) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'wrong-password',
        message: 'Mật khẩu cũ không chính xác',
      );
    }

    // Update with new password
    final newSalt = FirebaseHelper.generateSalt();
    final newHash =
        FirebaseHelper.hashPassword(salt: newSalt, password: newPassword);

    await ref.update({
      'passwordSalt': newSalt,
      'passwordHash': newHash,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Password changed: $normalized');
  }
}
