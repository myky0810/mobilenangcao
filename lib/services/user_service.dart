import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firebase_helper.dart';
import '../models/user_model.dart';

/// Typed user access layer.
///
/// UNIFIED SERVICE: Supports both phone and Google (email) login.
/// - Phone login: users/{normalizedPhone}
/// - Google login: users/{email.toLowerCase()}
class UserService {
  UserService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Xác định document ID từ identifier (phone hoặc email)
  /// - Nếu chứa '@' → email (Google login) → lowercase
  /// - Nếu không → phone → normalize
  static String getDocumentId(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      return trimmed.toLowerCase(); // Email (Google login)
    }
    return FirebaseHelper.normalizePhone(trimmed); // Phone login
  }

  /// Lấy document reference từ identifier (phone hoặc email)
  static DocumentReference<Map<String, dynamic>> userRef(String identifier) {
    final docId = getDocumentId(identifier);
    return _db.collection('users').doc(docId);
  }

  /// Backward compatibility: get by phone
  static DocumentReference<Map<String, dynamic>> userRefByPhone(String phone) {
    return userRef(phone);
  }

  /// Lấy user từ identifier (phone hoặc email)
  static Future<UserModel?> get(String identifier) async {
    final ref = userRef(identifier);
    final doc = await ref.get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  /// Backward compatibility
  static Future<UserModel?> getByPhone(String phone) => get(phone);

  /// Watch user realtime từ identifier
  static Stream<UserModel?> watch(String identifier) {
    final ref = userRef(identifier);
    return ref.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  /// Backward compatibility
  static Stream<UserModel?> watchByPhone(String phone) => watch(phone);

  /// Upsert user (tạo hoặc update)
  static Future<void> upsert(String identifier, UserModel user) async {
    final ref = userRef(identifier);
    await ref.set(user.toMap(), SetOptions(merge: true));
  }

  /// Backward compatibility
  static Future<void> upsertByPhone(String phone, UserModel user) =>
      upsert(phone, user);

  /// Update một số field của user
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
}
