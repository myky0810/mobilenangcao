import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firestore-only auth (phone + password) per your requirement.
///
/// Collection: `users`
/// Document id: normalized phone (unique)
/// Fields:
/// - phone: normalized phone
/// - passwordSalt: random salt (base64)
/// - passwordHash: sha256(salt + password) (hex)
/// - createdAt: server timestamp
class FirebaseHelper {
  FirebaseHelper._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static String normalizePhone(String input) {
    var p = input.trim().replaceAll(' ', '');
    if (p.startsWith('+84')) {
      p = '0${p.substring(3)}';
    }
    return p;
  }

  static String _randomSaltBase64({int bytes = 16}) {
    final rnd = Random.secure();
    final data = List<int>.generate(bytes, (_) => rnd.nextInt(256));
    return base64UrlEncode(data);
  }

  static String _hashPassword({
    required String saltBase64,
    required String pass,
  }) {
    final bytes = utf8.encode('$saltBase64$pass');
    return sha256.convert(bytes).toString();
  }

  static Future<bool> phoneExists(String phone) async {
    final normalized = normalizePhone(phone);
    final doc = await _users.doc(normalized).get();
    return doc.exists;
  }

  static Future<void> register({
    required String phone,
    required String password,
  }) async {
    final normalized = normalizePhone(phone);
    final ref = _users.doc(normalized);

    // Use a transaction to avoid race conditions when 2 users register same phone.
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'phone-already-in-use',
          message: 'Số điện thoại đã được sử dụng cho 1 tài khoản.',
        );
      }
      final salt = _randomSaltBase64();
      final hash = _hashPassword(saltBase64: salt, pass: password);
      tx.set(ref, {
        'phone': normalized,
        'passwordSalt': salt,
        'passwordHash': hash,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> login({
    required String phone,
    required String password,
  }) async {
    final normalized = normalizePhone(phone);
    final doc = await _users.doc(normalized).get();
    if (!doc.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'user-not-found',
        message: 'Số điện thoại chưa được đăng kí.',
      );
    }

    final data = doc.data();
    final salt = data?['passwordSalt'] as String?;
    final hash = data?['passwordHash'] as String?;
    if (salt == null || hash == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'corrupt-user',
        message: 'Tài khoản bị lỗi dữ liệu.',
      );
    }

    final inputHash = _hashPassword(saltBase64: salt, pass: password);
    if (inputHash != hash) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'wrong-password',
        message: 'Mật khẩu không đúng.',
      );
    }
  }

  static Future<void> changePassword({
    required String phone,
    required String oldPassword,
    required String newPassword,
  }) async {
    final normalized = normalizePhone(phone);
    final ref = _users.doc(normalized);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'user-not-found',
          message: 'Tài khoản không tồn tại.',
        );
      }

      final data = snap.data();
      final salt = data?['passwordSalt'] as String?;
      final hash = data?['passwordHash'] as String?;
      if (salt == null || hash == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'corrupt-user',
          message: 'Tài khoản bị lỗi dữ liệu.',
        );
      }

      final inputHash = _hashPassword(saltBase64: salt, pass: oldPassword);
      if (inputHash != hash) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'wrong-password',
          message: 'Mật khẩu cũ không đúng.',
        );
      }

      final newSalt = _randomSaltBase64();
      final newHash = _hashPassword(saltBase64: newSalt, pass: newPassword);
      tx.update(ref, {
        'passwordSalt': newSalt,
        'passwordHash': newHash,
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> deleteAccount({required String phone}) async {
    final normalized = normalizePhone(phone);
    final ref = _users.doc(normalized);

    // Best-effort: delete avatar objects if they exist.
    // (We don't know the extension, so try common ones.)
    try {
      final storage = FirebaseStorage.instance;
      final candidates = <String>[
        'avatars/$normalized/avatar.jpg',
        'avatars/$normalized/avatar.png',
        'avatars/$normalized/avatar.webp',
      ];
      for (final path in candidates) {
        try {
          await storage.ref(path).delete();
        } catch (_) {
          // Ignore missing or permission errors.
        }
      }
    } catch (_) {
      // Ignore if storage is not available on the current platform.
    }

    await ref.delete();
  }
}
