import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../services/user_service.dart';

class FavoriteService {
  static const String _favoritesKey = 'user_favorites';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _currentUid() => _auth.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>>? _favoritesRef() {
    // Try Google UID first
    final uid = _currentUid();
    if (uid != null && uid.isNotEmpty) {
      return _db
          .collection(UserService.googleUsersCollection)
          .doc(uid)
          .collection('favorites');
    }

    // Otherwise we cannot resolve phone-based favorites from auth alone
    return null;
  }

  static Future<List<Map<String, dynamic>>> _getLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encodedData = prefs.getString(_favoritesKey);
      if (encodedData != null) {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        final favorites = decodedData
            .map(
              (item) => _normalizeFavoriteMap(Map<String, dynamic>.from(item)),
            )
            .toList();
        await _saveLocalFavorites(favorites);
        return favorites;
      }
    } catch (e) {
      print('Error loading local favorites: $e');
    }
    return [];
  }

  static Future<void> _saveLocalFavorites(
    List<Map<String, dynamic>> favorites,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(favorites);
      await prefs.setString(_favoritesKey, encodedData);
    } catch (e) {
      print('Error saving local favorites: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> _getRemoteFavorites() async {
    final ref = _favoritesRef();
    if (ref == null) return [];

    try {
      final snapshot = await ref.get();
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs
          .map((doc) => _normalizeFavoriteMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error loading remote favorites: $e');
      return [];
    }
  }

  static Future<void> _upsertRemoteFavorite(Map<String, dynamic> car) async {
    final ref = _favoritesRef();
    if (ref == null) return;

    final normalizedCar = _normalizeFavoriteMap(car);
    final carId = normalizedCar['id']?.toString() ?? '';
    if (carId.isEmpty) return;

    try {
      await ref.doc(carId).set({
        ...normalizedCar,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving remote favorite: $e');
    }
  }

  static Future<void> _removeRemoteFavorite(String carId) async {
    final ref = _favoritesRef();
    if (ref == null) return;

    try {
      await ref.doc(carId).delete();
    } catch (e) {
      print('Error removing remote favorite: $e');
    }
  }

  // Lưu danh sách yêu thích
  static Future<void> saveFavorites(
    List<Map<String, dynamic>> favorites,
  ) async {
    try {
      final normalized = favorites.map(_normalizeFavoriteMap).toList();
      await _saveLocalFavorites(normalized);

      final ref = _favoritesRef();
      if (ref != null) {
        for (final car in normalized) {
          await _upsertRemoteFavorite(car);
        }
      }
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Lấy danh sách yêu thích
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final localFavorites = await _getLocalFavorites();
      final remoteFavorites = await _getRemoteFavorites();

      final mergedById = <String, Map<String, dynamic>>{};
      for (final item in localFavorites) {
        final id = (item['id'] ?? '').toString();
        if (id.isNotEmpty) mergedById[id] = item;
      }
      for (final item in remoteFavorites) {
        final id = (item['id'] ?? '').toString();
        if (id.isNotEmpty) mergedById[id] = item;
      }

      final merged = mergedById.values.toList();
      if (merged.isNotEmpty) {
        await _saveLocalFavorites(merged);

        if (_favoritesRef() != null) {
          for (final item in merged) {
            await _upsertRemoteFavorite(item);
          }
        }
      }

      return merged;
    } catch (e) {
      print('Error loading favorites: $e');
    }
    return [];
  }

  static String _normalizeFavoriteId(Map<String, dynamic> car) {
    final rawId = car['id'] ?? car['carId'] ?? '';
    final idText = rawId.toString().trim();
    if (idText.isNotEmpty) return idText;

    final name = (car['carName'] ?? car['name'] ?? 'Xe').toString().trim();
    final brand =
        (car['carBrand'] ?? car['brand'] ?? car['subtitle'] ?? 'Unknown')
            .toString()
            .trim();
    final price = (car['carPrice'] ?? car['price'] ?? '').toString().trim();

    final parts = [brand, name];
    if (price.isNotEmpty) parts.add(price);
    return parts.join('_').replaceAll(RegExp(r'\s+'), '_');
  }

  static Map<String, dynamic> _normalizeFavoriteMap(Map<String, dynamic> car) {
    final normalized = Map<String, dynamic>.from(car);
    normalized['id'] = _normalizeFavoriteId(normalized);
    return normalized;
  }

  // Thêm xe vào danh sách yêu thích
  static Future<void> addToFavorites(Map<String, dynamic> car) async {
    try {
      final favorites = await getFavorites();
      final normalizedCar = _normalizeFavoriteMap(car);
      final carId = normalizedCar['id']?.toString() ?? '';
      if (carId.isEmpty) {
        return;
      }

      if (!favorites.any((fav) => fav['id']?.toString() == carId)) {
        favorites.add(normalizedCar);
        await _saveLocalFavorites(favorites);
        await _upsertRemoteFavorite(normalizedCar);
      }
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  // Xóa xe khỏi danh sách yêu thích
  static Future<void> removeFromFavorites(String carId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((fav) => fav['id']?.toString() == carId);
      await _saveLocalFavorites(favorites);
      await _removeRemoteFavorite(carId);
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  // Kiểm tra xe có trong danh sách yêu thích không
  static Future<bool> isFavorite(String carId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((fav) => fav['id']?.toString() == carId);
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Xóa tất cả yêu thích
  static Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);

      final ref = _favoritesRef();
      if (ref != null) {
        final snapshot = await ref.get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  /// Xóa dữ liệu yêu thích trùng lặp và đồng bộ hóa dữ liệu
  /// Phương thức này sẽ:
  /// 1. Loại bỏ các bản trùng lặp
  /// 2. Chuẩn hóa các ID
  /// 3. Lưu danh sách làm sạch vào SharedPreferences
  static Future<void> deduplicateAndSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encodedData = prefs.getString(_favoritesKey);
      if (encodedData == null) return;

      final List<dynamic> decodedData = jsonDecode(encodedData);

      // Tạo map để theo dõi các ID đã xem
      final seenIds = <String>{};
      final deduplicatedList = <Map<String, dynamic>>[];

      for (final item in decodedData) {
        final car = Map<String, dynamic>.from(item);
        final normalized = _normalizeFavoriteMap(car);
        final id = normalized['id']?.toString() ?? '';

        // Chỉ thêm nếu chưa từng thấy ID này
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          deduplicatedList.add(normalized);
        }
      }

      // Lưu lại danh sách làm sạch
      await saveFavorites(deduplicatedList);
      print(
        'Deduplicated favorites: ${decodedData.length} -> ${deduplicatedList.length}',
      );
    } catch (e) {
      print('Error deduplicating favorites: $e');
    }
  }
}
