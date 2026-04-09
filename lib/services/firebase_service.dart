import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

/// Service để quản lý dữ liệu user trong Firestore
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _cleanupFlagKey = 'legacy_deposit_cleanup_done_v1';

  // Collection users
  // Provider-aware users collection reference getter
  static CollectionReference<Map<String, dynamic>>?
  _usersCollectionByCurrentAuth() {
    final uid = _auth.currentUser?.uid;
    if (uid != null)
      return _firestore.collection(UserService.googleUsersCollection);
    return null;
  }

  /// Lưu thông tin user vào Firestore
  static Future<void> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final usersCol = _usersCollectionByCurrentAuth();
      if (usersCol != null) {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;
        // Always key Google users by uid. Ignore caller-provided userId to avoid
        // creating random/legacy doc IDs in Firestore.
        await usersCol.doc(uid).set({
          ...userData,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  /// Cập nhật thông tin user
  static Future<void> updateUserData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final usersCol = _usersCollectionByCurrentAuth();
      if (usersCol != null) {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;
        await usersCol.doc(uid).update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user theo ID
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final usersCol = _usersCollectionByCurrentAuth();
      if (usersCol == null) return null;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await usersCol.doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  /// Stream để theo dõi thay đổi của user data
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDataStream(
    String userId,
  ) {
    final usersCol = _usersCollectionByCurrentAuth();
    if (usersCol == null) {
      return Stream.empty();
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.empty();
    return usersCol.doc(uid).snapshots();
  }

  /// Lưu thông tin user sau khi đăng ký
  static Future<void> saveUserAfterRegister({
    required String phone,
    String? name,
    String? email,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await saveUserData(
          userId: currentUser.uid,
          userData: {
            'phone': phone,
            'name': name ?? 'Người dùng',
            'email': email,
            'photoURL': currentUser.photoURL,
          },
        );
      }
    } catch (e) {
      print('Error saving user after register: $e');
      rethrow;
    }
  }

  /// Lưu thông tin user từ Google Sign In
  static Future<void> saveUserFromGoogle(User user) async {
    try {
      await saveUserData(
        userId: user.uid,
        userData: {
          'name': user.displayName ?? 'Người dùng',
          'email': user.email,
          'photoURL': user.photoURL,
          'phone': user.phoneNumber,
          'provider': 'google',
        },
      );
    } catch (e) {
      print('Error saving Google user: $e');
      rethrow;
    }
  }

  /// Xóa dữ liệu user
  static Future<void> deleteUserData(String userId) async {
    try {
      final usersCol = _usersCollectionByCurrentAuth();
      if (usersCol != null) {
        final uid = _auth.currentUser?.uid;
        if (uid == null) return;
        await usersCol.doc(uid).delete();
      }
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  /// Kiểm tra user đã tồn tại chưa
  static Future<bool> userExists(String userId) async {
    try {
      final usersCol = _usersCollectionByCurrentAuth();
      if (usersCol == null) return false;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;
      final doc = await usersCol.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user exists: $e');
      return false;
    }
  }

  /// Lấy danh sách tất cả users (admin only)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final usersCol = _usersCollectionByCurrentAuth();
      if (usersCol == null) return [];
      final snapshot = await usersCol.get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Tìm user theo số điện thoại
  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      // For phone-based lookup, use the phone collection
      final phoneRef = FirebaseFirestore.instance.collection(
        UserService.phoneUsersCollection,
      );
      final snapshot = await phoneRef
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {'id': doc.id, ...doc.data()};
      }
      return null;
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  /// Cập nhật ảnh đại diện
  static Future<void> updateProfilePhoto({
    required String userId,
    required String photoURL,
  }) async {
    try {
      await updateUserData(userId: userId, data: {'photoURL': photoURL});
    } catch (e) {
      print('Error updating profile photo: $e');
      rethrow;
    }
  }

  /// Cập nhật tên người dùng
  static Future<void> updateDisplayName({
    required String userId,
    required String name,
  }) async {
    try {
      await updateUserData(userId: userId, data: {'name': name});
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  /// Dọn dữ liệu đặt cọc cũ một lần duy nhất sau khi gỡ tính năng.
  static Future<void> cleanupLegacyDepositDataOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyDone = prefs.getBool(_cleanupFlagKey) ?? false;
    if (alreadyDone) {
      return;
    }

    // Xóa các field đặt cọc còn sót trong collection booking lái thử.
    await _removeLegacyDepositFieldsFromBookings();

    // Xóa dữ liệu trong collection booking_deposits nếu còn tồn tại.
    await _deleteLegacyDepositsCollection();

    await prefs.setBool(_cleanupFlagKey, true);
  }

  static Future<void> _removeLegacyDepositFieldsFromBookings() async {
    const pageSize = 300;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('test_drive_bookings')
          .orderBy(FieldPath.documentId)
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      WriteBatch batch = _firestore.batch();
      var writes = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final hasLegacyFields =
            data.containsKey('depositRequested') ||
            data.containsKey('depositRate') ||
            data.containsKey('depositAmount') ||
            data.containsKey('depositStatus');

        if (!hasLegacyFields) {
          continue;
        }

        batch.update(doc.reference, {
          'depositRequested': FieldValue.delete(),
          'depositRate': FieldValue.delete(),
          'depositAmount': FieldValue.delete(),
          'depositStatus': FieldValue.delete(),
        });
        writes++;

        if (writes == 400) {
          await batch.commit();
          batch = _firestore.batch();
          writes = 0;
        }
      }

      if (writes > 0) {
        await batch.commit();
      }

      lastDoc = snapshot.docs.last;
    }
  }

  static Future<void> _deleteLegacyDepositsCollection() async {
    const pageSize = 400;
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;

    while (true) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('booking_deposits')
          .orderBy(FieldPath.documentId)
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      lastDoc = snapshot.docs.last;
    }
  }
}
