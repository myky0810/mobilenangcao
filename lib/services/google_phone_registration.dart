import 'package:cloud_firestore/cloud_firestore.dart';

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
  }

  /// ✅ Get phone document id by email (fallback when UID not linked yet)
  static Future<String?> getPhoneByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final snapshot = await _db
        .collection(_usersCollection)
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final phone = (doc.data()['phone'] as String? ?? '').trim();
    if (phone.isNotEmpty) {
      return FirebaseHelper.normalizePhone(phone);
    }

    return FirebaseHelper.normalizePhone(doc.id);
  }

  /// ✅ Resolve phone for Google quick login (UID first, then email)
  static Future<String?> resolvePhoneForGoogleLogin({
    required String uid,
    required String email,
    required String displayName,
    required String photoURL,
  }) async {
    final phoneByUid = await getPhoneByGoogleUid(uid);
    if (phoneByUid != null && phoneByUid.trim().isNotEmpty) {
      final normalized = FirebaseHelper.normalizePhone(phoneByUid);
      await _touchGoogleLinkedLogin(
        phone: normalized,
        uid: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
      );
      return normalized;
    }

    final phoneByEmail = await getPhoneByEmail(email);
    if (phoneByEmail != null && phoneByEmail.trim().isNotEmpty) {
      final normalized = FirebaseHelper.normalizePhone(phoneByEmail);
      await _linkGoogleToExistingPhone(
        phone: normalized,
        uid: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
      );
      return normalized;
    }

    return null;
  }

  static Future<void> _touchGoogleLinkedLogin({
    required String phone,
    required String uid,
    required String email,
    required String displayName,
    required String photoURL,
  }) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    final ref = _db.collection(_usersCollection).doc(normalized);
    final existing = await ref.get();
    final existingData = existing.data() ?? <String, dynamic>{};

    final existingName = (existingData['name'] as String? ?? '').trim();
    final existingProvider = (existingData['provider'] as String? ?? '').trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhoto = photoURL.trim();

    final updates = <String, dynamic>{
      'uid': uid,
      'googleLinked': true,
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (normalizedEmail.isNotEmpty) {
      updates['email'] = normalizedEmail;
    }
    if (existingProvider.isEmpty) {
      updates['provider'] = 'google';
    }
    if (existingName.isEmpty && displayName.trim().isNotEmpty) {
      updates['name'] = displayName.trim();
    }
    if (normalizedPhoto.isNotEmpty) {
      updates['avatarUrl'] = normalizedPhoto;
    }

    await ref.set(updates, SetOptions(merge: true));
  }

  static Future<void> _linkGoogleToExistingPhone({
    required String phone,
    required String uid,
    required String email,
    required String displayName,
    required String photoURL,
  }) async {
    final normalized = FirebaseHelper.normalizePhone(phone);
    final ref = _db.collection(_usersCollection).doc(normalized);
    final existingDoc = await ref.get();
    final existingData = existingDoc.data() ?? <String, dynamic>{};

    final existingUid = (existingData['uid'] as String? ?? '').trim();
    if (existingUid.isNotEmpty && existingUid != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'google-account-conflict',
        message: 'Số điện thoại này đã liên kết với một tài khoản Google khác.',
      );
    }

    final existingName = (existingData['name'] as String? ?? '').trim();
    final existingProvider = (existingData['provider'] as String? ?? '').trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhoto = photoURL.trim();

    final updates = <String, dynamic>{
      'phone': normalized,
      'uid': uid,
      'googleLinked': true,
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (normalizedEmail.isNotEmpty) {
      updates['email'] = normalizedEmail;
    }
    if (existingProvider.isEmpty) {
      updates['provider'] = 'google';
    }
    if (existingName.isEmpty && displayName.trim().isNotEmpty) {
      updates['name'] = displayName.trim();
    }
    if (normalizedPhoto.isNotEmpty) {
      updates['avatarUrl'] = normalizedPhoto;
    }

    if (!existingDoc.exists) {
      updates['provider'] = 'google';
      updates['role'] = 'user';
      updates['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(updates, SetOptions(merge: true));
  }

  /// ✅ Register Google login with phone number (first time)
  /// Bắt buộc có phone để làm Document ID
  static Future<String> registerGoogleWithPhone({
    required String uid,
    required String email,
    required String displayName,
    required String photoURL,
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
        if (existingUid != null && existingUid != uid) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'phone-already-used',
            message: 'Số điện thoại này đã được sử dụng bởi tài khoản khác',
          );
        }
      }

      final existingData = existingDoc.data() ?? <String, dynamic>{};
      final existingRole = (existingData['role'] as String? ?? '').trim();
      final existingProvider = (existingData['provider'] as String? ?? '').trim();
      final existingName = (existingData['name'] as String? ?? '').trim();

      final emailLower = email.trim().toLowerCase();
      final display = displayName.trim();
      final photo = photoURL.trim();

      // Merge để không làm mất passwordHash/passwordSalt và role hiện có.
      await _db.collection(_usersCollection).doc(normalized).set({
        'phone': normalized,
        'uid': uid,
        'googleLinked': true,
        'provider': existingProvider.isEmpty ? 'google' : existingProvider,
        if (existingRole.isEmpty) 'role': 'user',
        if (emailLower.isNotEmpty) 'email': emailLower,
        if (existingName.isEmpty)
          'name': display.isNotEmpty ? display : 'Người dùng Google',
        if (photo.isNotEmpty) 'avatarUrl': photo,
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!existingDoc.exists) ...{
          'gender': 'Nam',
          'dob': null,
          'provinceCode': null,
          'districtCode': null,
          'wardCode': null,
          'street': '',
          'createdAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      print('✅ Google +Phone registration success: $normalized');
      return normalized;
    } catch (e) {
      print('❌ Google+Phone registration error: $e');
      rethrow;
    }
  }

  /// ✅ Record Google login (if phone already exists)
  /// Dùng khi user đã từng đăng ký Google+Phone
  static Future<String> recordGoogleLogin(String uid) async {
    try {
      final phone = await getPhoneByGoogleUid(uid);
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

  /// Logout (Firestore-only, no Firebase Auth)
  static Future<void> logout() async {
    // No-op: since we're not using Firebase Auth
    print('✅ Logged out (Firestore-only)');
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
