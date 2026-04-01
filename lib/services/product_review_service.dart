import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReviewStatus { pending, approved, rejected }

class ProductReviewStats {
  final double rating;
  final int reviewCount;

  const ProductReviewStats({required this.rating, required this.reviewCount});
}

class ProductReview {
  final String id;
  final String reviewerName;
  final String comment;
  final double rating;
  final DateTime createdAt;
  final int helpfulCount;
  final int reportCount;
  final ReviewStatus status;

  const ProductReview({
    required this.id,
    required this.reviewerName,
    required this.comment,
    required this.rating,
    required this.createdAt,
    this.helpfulCount = 0,
    this.reportCount = 0,
    this.status = ReviewStatus.pending,
  });

  factory ProductReview.fromMap(Map<String, dynamic> map) {
    final rawRating = map['rating'];
    double parsedRating = 5.0;
    if (rawRating is num) {
      parsedRating = rawRating.toDouble();
    } else if (rawRating is String) {
      parsedRating = double.tryParse(rawRating) ?? 5.0;
    }

    final rawCreatedAt = map['createdAt']?.toString();
    final createdAt = DateTime.tryParse(rawCreatedAt ?? '') ?? DateTime.now();
    final generatedId =
        '${createdAt.microsecondsSinceEpoch}_${(map['reviewerName'] ?? '').toString().hashCode}_${(map['comment'] ?? '').toString().hashCode}';

    final rawHelpful = map['helpfulCount'];
    int helpfulCount = 0;
    if (rawHelpful is int) {
      helpfulCount = rawHelpful;
    } else if (rawHelpful is num) {
      helpfulCount = rawHelpful.toInt();
    } else if (rawHelpful is String) {
      helpfulCount = int.tryParse(rawHelpful) ?? 0;
    }

    final rawReport = map['reportCount'];
    int reportCount = 0;
    if (rawReport is int) {
      reportCount = rawReport;
    } else if (rawReport is num) {
      reportCount = rawReport.toInt();
    } else if (rawReport is String) {
      reportCount = int.tryParse(rawReport) ?? 0;
    }

    final statusValue = (map['status'] ?? '').toString().trim().toLowerCase();
    final status = switch (statusValue) {
      'approved' => ReviewStatus.approved,
      'rejected' => ReviewStatus.rejected,
      'pending' => ReviewStatus.pending,
      _ => ReviewStatus.approved,
    };

    return ProductReview(
      id: (map['id'] ?? generatedId).toString(),
      reviewerName: (map['reviewerName'] ?? 'Người dùng').toString(),
      comment: (map['comment'] ?? '').toString(),
      rating: parsedRating.clamp(1.0, 5.0),
      createdAt: createdAt,
      helpfulCount: helpfulCount,
      reportCount: reportCount,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reviewerName': reviewerName,
      'comment': comment,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'helpfulCount': helpfulCount,
      'reportCount': reportCount,
      'status': status.name,
    };
  }

  ProductReview copyWith({
    String? id,
    String? reviewerName,
    String? comment,
    double? rating,
    DateTime? createdAt,
    int? helpfulCount,
    int? reportCount,
    ReviewStatus? status,
  }) {
    return ProductReview(
      id: id ?? this.id,
      reviewerName: reviewerName ?? this.reviewerName,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reportCount: reportCount ?? this.reportCount,
      status: status ?? this.status,
    );
  }
}

class ProductReviewService {
  ProductReviewService._();

  static const String _storageKey = 'product_reviews_v1';
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> _readStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> _writeStorage(Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(value));
  }

  static Future<List<ProductReview>> _readLocalReviews(String carId) async {
    final all = await _readStorage();
    final rawList = all[carId];
    if (rawList is! List) {
      return <ProductReview>[];
    }

    final reviews = rawList
        .whereType<Map>()
        .map((item) => ProductReview.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    return reviews;
  }

  static Future<void> _saveLocalReviews(
    String carId,
    List<ProductReview> reviews,
  ) async {
    final all = await _readStorage();
    all[carId] = reviews.map((e) => e.toMap()).toList();
    await _writeStorage(all);
  }

  static Future<List<ProductReview>> _readRemoteReviews(String carId) async {
    try {
      final snapshot = await _db
          .collection('product_reviews')
          .doc(carId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return <ProductReview>[];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAtRaw = data['createdAt'];
        DateTime createdAt = DateTime.now();
        if (createdAtRaw is Timestamp) {
          createdAt = createdAtRaw.toDate();
        } else if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
        }

        return ProductReview.fromMap({
          ...data,
          'id': (data['id'] ?? doc.id).toString(),
          'createdAt': createdAt.toIso8601String(),
        });
      }).toList();
    } catch (_) {
      return <ProductReview>[];
    }
  }

  static Future<void> _saveRemoteReview(String carId, ProductReview review) async {
    try {
      await _db
          .collection('product_reviews')
          .doc(carId)
          .collection('reviews')
          .doc(review.id)
          .set({
            'id': review.id,
            'reviewerName': review.reviewerName,
            'comment': review.comment,
            'rating': review.rating,
            'helpfulCount': review.helpfulCount,
            'reportCount': review.reportCount,
            'status': review.status.name,
            'createdAt': Timestamp.fromDate(review.createdAt),
          }, SetOptions(merge: true));
    } catch (_) {
      // Keep local persistence as fallback when remote write is unavailable.
    }
  }

  static Future<List<ProductReview>> getReviews(String carId) async {
    final localReviews = await _readLocalReviews(carId);
    final remoteReviews = await _readRemoteReviews(carId);

    final mergedById = <String, ProductReview>{};
    for (final review in localReviews) {
      mergedById[review.id] = review;
    }
    for (final review in remoteReviews) {
      mergedById[review.id] = review;
    }

    final reviews = mergedById.values.toList();

    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (reviews.isNotEmpty) {
      await _saveLocalReviews(carId, reviews);
    }

    return reviews;
  }

  static Future<List<ProductReview>> getPublicReviews(String carId) async {
    final all = await getReviews(carId);
    return all.where((review) => review.status == ReviewStatus.approved).toList();
  }

  static ProductReviewStats calculateDisplayStats({
    required double baseRating,
    required int baseReviewCount,
    required List<ProductReview> approvedReviews,
  }) {
    if (approvedReviews.isEmpty) {
      return ProductReviewStats(
        rating: baseRating,
        reviewCount: baseReviewCount,
      );
    }

    final approvedCount = approvedReviews.length;
    final approvedSum = approvedReviews.fold<double>(
      0.0,
      (sum, review) => sum + review.rating,
    );
    final avg = approvedSum / approvedCount;
    return ProductReviewStats(
      rating: avg,
      reviewCount: approvedCount,
    );
  }

  static Future<void> addReview(String carId, ProductReview review) async {
    final existing = await _readLocalReviews(carId);
    final next = <ProductReview>[...existing, review];
    await _saveLocalReviews(carId, next);
    await _saveRemoteReview(carId, review);
  }

  static Future<void> setReviewStatus({
    required String carId,
    required String reviewId,
    required ReviewStatus status,
  }) async {
    final existing = await _readLocalReviews(carId);
    final updated = existing.map((review) {
      if (review.id != reviewId) return review;
      return review.copyWith(status: status);
    }).toList();

    await _saveLocalReviews(carId, updated);

    try {
      await _db
          .collection('product_reviews')
          .doc(carId)
          .collection('reviews')
          .doc(reviewId)
          .set({'status': status.name}, SetOptions(merge: true));
    } catch (_) {
      // Keep local data when remote is unavailable.
    }
  }

  static Future<void> reportReview({
    required String carId,
    required String reviewId,
  }) async {
    final existing = await _readLocalReviews(carId);
    ProductReview? target;
    final updated = existing.map((review) {
      if (review.id != reviewId) return review;
      final nextCount = review.reportCount + 1;
      final nextStatus = nextCount >= 3 ? ReviewStatus.pending : review.status;
      final next = review.copyWith(reportCount: nextCount, status: nextStatus);
      target = next;
      return next;
    }).toList();

    await _saveLocalReviews(carId, updated);

    if (target == null) return;

    try {
      await _db
          .collection('product_reviews')
          .doc(carId)
          .collection('reviews')
          .doc(reviewId)
          .set({
            'reportCount': target!.reportCount,
            'status': target!.status.name,
          }, SetOptions(merge: true));
    } catch (_) {
      // Keep local data when remote is unavailable.
    }
  }

  static String createReviewId() {
    return 'review_${DateTime.now().microsecondsSinceEpoch}';
  }
}
