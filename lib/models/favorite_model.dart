import 'package:cloud_firestore/cloud_firestore.dart';

/// Favorite item stored under `{userProfile}/favorites/{carId}` where:
/// - Google profile: `users_google/{uid}`
/// - Phone profile : `users_phone/{normalizedPhone}`
///
/// Your current app stores favorites as Map (route arguments). This model gives
/// you a typed structure for admin / future UI.
class FavoriteItem {
  final String id; // carId
  final Map<String, dynamic>
  carData; // keep flexible for backward compatibility
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FavoriteItem({
    required this.id,
    required this.carData,
    this.createdAt,
    this.updatedAt,
  });

  factory FavoriteItem.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime? parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    final normalized = Map<String, dynamic>.from(map);
    normalized.remove('createdAt');
    normalized.remove('updatedAt');

    return FavoriteItem(
      id: docId,
      carData: normalized,
      createdAt: parseTs(map['createdAt']),
      updatedAt: parseTs(map['updatedAt']),
    );
  }

  factory FavoriteItem.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return FavoriteItem.fromFirestore(
      doc.data() ?? <String, dynamic>{},
      doc.id,
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    return {
      ...carData,
      if (includeTimestamps && createdAt == null)
        'createdAt': FieldValue.serverTimestamp(),
      if (includeTimestamps) 'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
