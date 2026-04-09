import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firebase_helper.dart';
import '../models/user_model.dart';

/// ✅ Unified User Service - Single Collection
/// 
/// Uses only one collection: `users`
/// Document ID: normalized phone (consistent for both Google and Phone login)
/// 
/// Provider-aware logic:
/// - Google login: sets provider='google', uid={firebaseAuthUid}
/// - Phone login: sets provider='phone', may have passwordHash/Salt
class UserService {
  UserService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// ✅ Get user ref from phone (current single collection approach)
  static DocumentReference<Map<String, dynamic>> userRefByPhone(String phone) {
    final docId = FirebaseHelper.normalizePhone(phone);
    return _db.collection(_usersCollection).doc(docId);
  }

  /// ✅ Get current user ref (based on FirebaseAuth or phoneIdentifier)
  static DocumentReference<Map<String, dynamic>>? currentUserProfileRef({
    String? phoneIdentifier,
  }) {
    // Try to get phone from either parameter or context
    final phone = phoneIdentifier;
    if (phone == null || phone.trim().isEmpty) {
      return null;
    }
    return userRefByPhone(phone);
  }

  /// ✅ Resolve current login provider
  static String currentProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'phone';
    final providers = user.providerData.map((e) => e.providerId).toList();
    if (providers.any((p) => p.contains('google'))) return 'google';
    return 'phone';
  }

  /// ✅ Get current user's Firebase UID
  static String? getCurrentUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// ✅ Get current user (prefer this)
  static Future<UserModel?> getCurrentUser({String? phoneIdentifier}) async {
    final ref = currentUserProfileRef(phoneIdentifier: phoneIdentifier);
    if (ref == null) return null;
    final doc = await ref.get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  /// ✅ Watch current user realtime (prefer this)
  static Stream<UserModel?> watchCurrentUser({String? phoneIdentifier}) {
    final ref = currentUserProfileRef(phoneIdentifier: phoneIdentifier);
    if (ref == null) return Stream.value(null);
    return ref.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  /// ✅ Update current user fields (prefer this)
  static Future<void> updateCurrentUserFields(
    Map<String, dynamic> fields, {
    String? phoneIdentifier,
  }) async {
    final ref = currentUserProfileRef(phoneIdentifier: phoneIdentifier);
    if (ref == null) {
      print('❌ Cannot update: Missing phone identifier');
      return;
    }

    await ref.set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ⚠️ LEGACY: Use getCurrentUser() instead
  static Future<UserModel?> get(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return null;
    final ref = userRefByPhone(trimmed);
    final doc = await ref.get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  /// Backward compatibility
  static Future<UserModel?> getByPhone(String phone) => get(phone);

  /// ⚠️ LEGACY: Use watchCurrentUser() instead
  static Stream<UserModel?> watch(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return Stream.value(null);
    final ref = userRefByPhone(trimmed);
    return ref.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  /// Backward compatibility
  static Stream<UserModel?> watchByPhone(String phone) => watch(phone);

  /// ⚠️ LEGACY: Use updateCurrentUserFields() instead
  static Future<void> upsert(String identifier, UserModel user) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return;
    final ref = userRefByPhone(trimmed);
    await ref.set(user.toMap(), SetOptions(merge: true));
  }

  /// Backward compatibility
  static Future<void> upsertByPhone(String phone, UserModel user) =>
      upsert(phone, user);

  /// ⚠️ LEGACY: Use updateCurrentUserFields() instead
  static Future<void> updateFields(
    String identifier,
    Map<String, dynamic> fields,
  ) async {
    final ref = userRefByPhone(identifier);
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

  /// ⚠️ DEPRECATED: Use GooglePhoneRegistration.loginWithGoogle() instead
  /// Kept for backward compatibility only
  @Deprecated('Use GooglePhoneRegistration service instead')
  static Future<void> saveUserToFirestore(
    User firebaseUser,
    String method,
  ) async {
    print('⚠️ saveUserToFirestore is deprecated. Use GooglePhoneRegistration instead.');
    // No-op for now
  }

  /// ⚠️ DEPRECATED: Use GooglePhoneRegistration.loginWithPhone() instead
  @Deprecated('Use GooglePhoneRegistration service instead')
  static Future<void> savePhoneUserLoginToFirestore(String phone) async {
    print('⚠️ savePhoneUserLoginToFirestore is deprecated. Use GooglePhoneRegistration instead.');
    // No-op for now
  }
}
