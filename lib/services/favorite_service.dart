import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoriteService {
  static const String _favoritesKey = 'user_favorites';

  // Lưu danh sách yêu thích
  static Future<void> saveFavorites(
    List<Map<String, dynamic>> favorites,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(favorites);
      await prefs.setString(_favoritesKey, encodedData);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Lấy danh sách yêu thích
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encodedData = prefs.getString(_favoritesKey);
      if (encodedData != null) {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        return decodedData.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
    return [];
  }

  // Thêm xe vào danh sách yêu thích
  static Future<void> addToFavorites(Map<String, dynamic> car) async {
    try {
      final favorites = await getFavorites();
      // Kiểm tra xe đã có trong danh sách chưa
      if (!favorites.any((fav) => fav['id'] == car['id'])) {
        favorites.add(car);
        await saveFavorites(favorites);
      }
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  // Xóa xe khỏi danh sách yêu thích
  static Future<void> removeFromFavorites(String carId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((fav) => fav['id'] == carId);
      await saveFavorites(favorites);
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  // Kiểm tra xe có trong danh sách yêu thích không
  static Future<bool> isFavorite(String carId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((fav) => fav['id'] == carId);
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
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }
}
