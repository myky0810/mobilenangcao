import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_helper.dart';
import '../models/user_model.dart';

/// Typed user access layer.
///
/// DUAL-PROFILE SERVICE: Supports both phone and Google (email) login.
///
/// ✅ Requirement: tách profile thành 2 collection khác nhau nhưng schema giống nhau.
/// - Google login profile: `users_google/{uid}`
/// - Phone login profile: `users_phone/{normalizedPhone}`
///
/// Notes:
/// - Các chức năng khác trong app có thể vẫn dùng collection khác (favorites, deposits...).
/// - Service này chỉ chịu trách nhiệm CHO PROFILE (name/email/phone/avatar/address...).
class UserService {
  UserService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String googleUsersCollection = 'users_google';
  static const String phoneUsersCollection = 'users_phone';

  static CollectionReference<Map<String, dynamic>> get _googleUsers =>
      _db.collection(googleUsersCollection);
  static CollectionReference<Map<String, dynamic>> get _phoneUsers =>
      _db.collection(phoneUsersCollection);

  static bool _looksLikeEmail(String value) => value.trim().contains('@');

  /// ✅ Google profile ref: users_google/{uid}
  static DocumentReference<Map<String, dynamic>>? googleUserRefByUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _googleUsers.doc(user.uid);
  }

  /// ✅ Phone profile ref: users_phone/{normalizedPhone}
  static DocumentReference<Map<String, dynamic>> phoneUserRefByPhone(
    String phone,
  ) {
    final docId = FirebaseHelper.normalizePhone(phone);
    return _phoneUsers.doc(docId);
  }

  /// ✅ Current profile ref, based on provider.
  /// - Google: use current FirebaseAuth uid
  /// - Phone: requires a phone identifier (from navigation argument)
  static DocumentReference<Map<String, dynamic>>? currentUserProfileRef({
    String? phoneIdentifier,
  }) {
    if (currentProvider() == 'google') {
      return googleUserRefByUid();
    }
    final phone = phoneIdentifier;
    if (phone == null || phone.trim().isEmpty) return null;
    return phoneUserRefByPhone(phone);
  }

  /// Resolve current login provider for choosing the correct profile collection.
  /// - If FirebaseAuth has google provider => google
  /// - Otherwise treat as phone (Firestore-only login)
  static String currentProvider() {
    final user = FirebaseAuth.instance.currentUser;
    final providers =
        user?.providerData.map((e) => e.providerId).toList() ??
        const <String>[];
    if (providers.any((p) => p.contains('google'))) return 'google';
    // Phone login in this app is Firestore-only (no PhoneAuth), so it may be null/anonymous.
    return 'phone';
  }

  /// Legacy method from the old single-collection design (`users/{uid}`).
  /// New requirement: tách hẳn 2 nguồn dữ liệu, KHÔNG migrate/merge giữa Google và Phone.
  /// Kept as a no-op for backward compatibility.
  static Future<void> ensureCanonicalUserDoc({String? legacyIdentifier}) async {
    return;
  }

  /// ✅ NEW: Lấy current user's UID
  static String? getCurrentUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Deprecated: kept for compile compatibility in older screens.
  /// Routes to the correct collection based on whether identifier looks like email.
  static DocumentReference<Map<String, dynamic>> userRef(String identifier) {
    final trimmed = identifier.trim();
    if (_looksLikeEmail(trimmed)) {
      // For google we always rely on uid, so this is only used as a fallback.
      return _googleUsers.doc(trimmed.toLowerCase());
    }
    return phoneUserRefByPhone(trimmed);
  }

  static DocumentReference<Map<String, dynamic>> userRefByPhone(String phone) =>
      phoneUserRefByPhone(phone);

  /// ✅ NEW: Lấy user hiện tại từ UID - ƯU TIÊN dùng hàm này
  static Future<UserModel?> getCurrentUser({String? phoneIdentifier}) async {
    final ref = currentUserProfileRef(phoneIdentifier: phoneIdentifier);
    if (ref == null) return null;
    final doc = await ref.get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  /// ✅ NEW: Watch current user realtime - ƯU TIÊN dùng hàm này
  static Stream<UserModel?> watchCurrentUser({String? phoneIdentifier}) {
    final ref = currentUserProfileRef(phoneIdentifier: phoneIdentifier);
    if (ref == null) return Stream.value(null);
    return ref.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  /// ✅ NEW: Update fields cho current user (theo UID) - ƯU TIÊN dùng hàm này
  static Future<void> updateCurrentUserFields(
    Map<String, dynamic> fields, {
    String? phoneIdentifier,
  }) async {
    final ref = currentUserProfileRef(phoneIdentifier: phoneIdentifier);
    if (ref == null) {
      print('❌ Cannot update: Missing profile identifier');
      return;
    }

    await ref.set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Lấy user từ identifier (phone hoặc email)
  /// ⚠️ LEGACY: Nên dùng getCurrentUser() thay thế
  static Future<UserModel?> get(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return null;

    // Google users: must use uid doc.
    if (_looksLikeEmail(trimmed)) {
      final ref = googleUserRefByUid();
      if (ref == null) return null;
      final doc = await ref.get();
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    }

    // Phone users: docId is normalized phone.
    final ref = phoneUserRefByPhone(trimmed);
    final doc = await ref.get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  /// Backward compatibility
  static Future<UserModel?> getByPhone(String phone) => get(phone);

  /// Watch user realtime từ identifier
  /// ⚠️ LEGACY: Nên dùng watchCurrentUser() thay thế
  static Stream<UserModel?> watch(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return Stream.value(null);

    if (_looksLikeEmail(trimmed)) {
      final ref = googleUserRefByUid();
      if (ref == null) return Stream.value(null);
      return ref.snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromSnapshot(doc);
      });
    }

    final ref = phoneUserRefByPhone(trimmed);
    return ref.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  /// Backward compatibility
  static Stream<UserModel?> watchByPhone(String phone) => watch(phone);

  /// Upsert user (tạo hoặc update)
  /// ⚠️ LEGACY: Nên dùng updateCurrentUserFields() thay thế
  static Future<void> upsert(String identifier, UserModel user) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return;
    if (_looksLikeEmail(trimmed)) {
      final ref = googleUserRefByUid();
      if (ref == null) return;
      await ref.set(user.toMap(), SetOptions(merge: true));
      return;
    }
    final ref = phoneUserRefByPhone(trimmed);
    await ref.set(user.toMap(), SetOptions(merge: true));
  }

  /// Backward compatibility
  static Future<void> upsertByPhone(String phone, UserModel user) =>
      upsert(phone, user);

  /// Update một số field của user
  /// ⚠️ LEGACY: Nên dùng updateCurrentUserFields() thay thế
  static Future<void> updateFields(
    String identifier,
    Map<String, dynamic> fields,
  ) async {
    final ref = userRef(identifier);
    await ref.set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Backward compatibility
  static Future<void> updateFieldsByPhone(
    String phone,
    Map<String, dynamic> fields,
  ) => updateFields(phone, fields);

  /// Check if identifier is email (Google login)
  static bool isGoogleLogin(String identifier) {
    return identifier.trim().contains('@');
  }

  /// Check if identifier is phone
  static bool isPhoneLogin(String identifier) {
    return !isGoogleLogin(identifier);
  }

  /// ✅ HÀM MỚI: Lưu user vào Firestore sau khi đăng nhập thành công
  /// - method = 'google': lưu vào users_google/{uid}
  /// - method = 'phone': lưu vào users_phone/{normalizedPhone}
  /// Logic: Kiểm tra đã tồn tại → chỉ update lastLogin. Chưa có → tạo mới document.
  static Future<void> saveUserToFirestore(
    User firebaseUser,
    String method,
  ) async {
    try {
      print('🔐 saveUserToFirestore: method=$method, uid=${firebaseUser.uid}');

      if (method == 'google') {
        // ===== GOOGLE LOGIN =====
        final docRef = _googleUsers.doc(firebaseUser.uid);
        final doc = await docRef.get();

        if (doc.exists) {
          // Đã có → chỉ update lastLogin
          print('✅ Google user exists → update lastLogin only');
          await docRef.update({
            'lastLogin': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Chưa có → tạo mới
          print('🆕 Creating new Google user document');
          await docRef.set({
            'uid': firebaseUser.uid,
            'name': firebaseUser.displayName ?? 'Người dùng Google',
            'email': firebaseUser.email ?? '',
            'phone': firebaseUser.phoneNumber ?? '',
            'avatarUrl': firebaseUser.photoURL ?? '',
            'provider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else if (method == 'phone') {
        // ===== PHONE LOGIN =====
        // Phone login trong app này là Firestore-only, không dùng FirebaseAuth PhoneAuth
        // Vì vậy firebaseUser.phoneNumber có thể null
        // Cần truyền phone từ bên ngoài hoặc lấy từ FirebaseHelper context

        final phoneNumber = firebaseUser.phoneNumber;
        if (phoneNumber == null || phoneNumber.trim().isEmpty) {
          print('⚠️ Phone login but no phoneNumber in firebaseUser');
          // Không thể lưu vào users_phone nếu không có phone
          return;
        }

        final normalizedPhone = FirebaseHelper.normalizePhone(phoneNumber);
        final docRef = _phoneUsers.doc(normalizedPhone);
        final doc = await docRef.get();

        if (doc.exists) {
          // Đã có → chỉ update lastLogin
          print('✅ Phone user exists → update lastLogin only');
          await docRef.update({
            'lastLogin': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Chưa có → tạo mới
          print('🆕 Creating new Phone user document');
          await docRef.set({
            'phone': normalizedPhone,
            'name': firebaseUser.displayName ?? 'Người dùng',
            'email': firebaseUser.email ?? '',
            'avatarUrl': firebaseUser.photoURL ?? '',
            'provider': 'phone',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      print('✅ saveUserToFirestore completed successfully');
    } catch (e) {
      print('❌ Error in saveUserToFirestore: $e');
      rethrow;
    }
  }

  /// ✅ HÀM MỚI: Cập nhật lastLogin cho Phone User (Firestore-only login)
  /// Dành cho trường hợp phone login không dùng FirebaseAuth PhoneAuth
  static Future<void> savePhoneUserLoginToFirestore(String phone) async {
    try {
      print('🔐 savePhoneUserLoginToFirestore: phone=$phone');
      final normalizedPhone = FirebaseHelper.normalizePhone(phone);
      final docRef = _phoneUsers.doc(normalizedPhone);
      final doc = await docRef.get();

      if (doc.exists) {
        // Đã có → chỉ update lastLogin
        print('✅ Phone user exists → update lastLogin only');
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Chưa có → tạo mới document với các trường cơ bản
        print('🆕 Creating new Phone user document');
        await docRef.set({
          'phone': normalizedPhone,
          'name': 'Người dùng',
          'email': '',
          'avatarUrl': '',
          'provider': 'phone',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ savePhoneUserLoginToFirestore completed');
    } catch (e) {
      print('❌ Error in savePhoneUserLoginToFirestore: $e');
      rethrow;
    }
  }
}
