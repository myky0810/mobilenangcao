import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service để quản lý dữ liệu user trong Firestore
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection users
  static CollectionReference get _usersCollection =>
      _firestore.collection('users');

  /// Lưu thông tin user vào Firestore
  static Future<void> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _usersCollection.doc(userId).set({
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      await _usersCollection.doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user theo ID
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
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
    return _firestore.collection('users').doc(userId).snapshots();
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
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }

  /// Kiểm tra user đã tồn tại chưa
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking user exists: $e');
      return false;
    }
  }

  /// Lấy danh sách tất cả users (admin only)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Tìm user theo số điện thoại
  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final snapshot = await _usersCollection
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
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
}
