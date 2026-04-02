import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified Car Model for Firebase and UI
/// Combines functionality from CarDetailData and CarModel
class CarModel {
  final String? id;
  final String name;
  final String brand;
  final String image;
  final String price;
  final String description;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool isNew;
  final String? phoneNumber;
  final String category;
  final String seats;
  final String fuelType;
  final String driveType;
  final String transmission;
  final int horsepower;
  final String engine;
  final String dimensions;
  final String purpose;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CarModel({
    this.id,
    required this.name,
    required this.brand,
    required this.image,
    required this.price,
    this.description = '',
    this.images = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isNew = true,
    this.phoneNumber,
    required this.category,
    required this.seats,
    required this.fuelType,
    required this.driveType,
    required this.transmission,
    required this.horsepower,
    required this.engine,
    this.dimensions = '',
    required this.purpose,
    this.createdAt,
    this.updatedAt,
  });

  // ============ Factory Constructors ============

  /// Create CarModel from route arguments (for navigation)
  factory CarModel.fromRouteArguments(Object? args) {
    if (args is CarModel) {
      return args;
    }
    if (args is Map<String, dynamic>) {
      return CarModel.fromMap(args);
    }
    if (args is Map) {
      return CarModel.fromMap(Map<String, dynamic>.from(args));
    }
    throw ArgumentError('Unsupported car arguments: $args');
  }

  /// Create CarModel from Map (for JSON/Route arguments)
  factory CarModel.fromMap(Map<String, dynamic> map) {
    final primaryImage = (map['carImage'] ?? map['image'] ?? '')
        .toString()
        .trim();
    final rawImages = map['carImages'] ?? map['images'] ?? map['gallery'];
    final images = <String>[
      ...switch (rawImages) {
        final List list =>
          list.map((item) => item.toString()).where((item) => item.isNotEmpty),
        _ => const <String>[],
      },
    ];

    if (images.isEmpty && primaryImage.isNotEmpty) {
      images.add(primaryImage);
    }

    final normalizedImages = images.isNotEmpty
        ? images
        : ['assets/images/products/car1.jpg'];

    String normalizeIdPart(Object? raw) {
      return raw?.toString().trim() ?? '';
    }

    final nameForId = normalizeIdPart(map['carName'] ?? map['name'] ?? 'Xe');
    final brandForId = normalizeIdPart(
      map['carBrand'] ?? map['brand'] ?? map['subtitle'] ?? 'Unknown',
    );
    final priceForId = normalizeIdPart(map['carPrice'] ?? map['price'] ?? '');
    final rawId = map['id'] ?? map['carId'] ?? '';
    final idValue = rawId.toString().trim().isNotEmpty
        ? rawId.toString()
        : '${brandForId}_$nameForId${priceForId.isNotEmpty ? '_$priceForId' : ''}';

    double parseRating(Object? raw) {
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? 4.5;
      return 4.5;
    }

    int parseReviewCount(Object? raw) {
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    return CarModel(
      id: idValue,
      name: nameForId,
      brand: brandForId.isNotEmpty ? brandForId : 'Unknown',
      image: primaryImage.isNotEmpty
          ? primaryImage
          : (normalizedImages.isNotEmpty
                ? normalizedImages.first
                : 'assets/images/products/car1.jpg'),
      price: (map['carPrice'] ?? map['price'] ?? 'Liên hệ').toString(),
      description:
          (map['carDescription'] ??
                  map['description'] ??
                  'Thông tin chi tiết đang được cập nhật.')
              .toString(),
      images: normalizedImages,
      rating: parseRating(map['rating']),
      reviewCount: parseReviewCount(map['reviewCount']),
      isNew: map['isNew'] == true,
      phoneNumber: (map['phoneNumber'] as String?)?.trim(),
      category: (map['category'] as String?)?.trim() ?? '',
      seats: (map['seats'] as String?)?.trim() ?? '',
      fuelType: (map['fuelType'] as String?)?.trim() ?? '',
      driveType: (map['driveType'] as String?)?.trim() ?? '',
      transmission: (map['transmission'] as String?)?.trim() ?? '',
      horsepower: (map['horsepower'] as num?)?.toInt() ?? 0,
      engine: (map['engine'] as String?)?.trim() ?? '',
      dimensions: (map['dimensions'] as String?)?.trim() ?? '',
      purpose: (map['purpose'] as String?)?.trim() ?? '',
    );
  }

  /// Create CarModel from Firebase Document
  factory CarModel.fromFirestore(
    Map<String, dynamic> map, [
    String? documentId,
  ]) {
    return CarModel(
      id: documentId,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      image: map['image'] ?? '',
      price: map['price'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isNew: map['isNew'] ?? true,
      phoneNumber: map['phoneNumber'],
      category: map['category'] ?? '',
      seats: map['seats'] ?? '',
      fuelType: map['fuelType'] ?? '',
      driveType: map['driveType'] ?? '',
      transmission: map['transmission'] ?? '',
      horsepower: map['horsepower'] ?? 0,
      engine: map['engine'] ?? '',
      dimensions: map['dimensions'] ?? '',
      purpose: map['purpose'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create CarModel from DocumentSnapshot
  factory CarModel.fromSnapshot(DocumentSnapshot doc) {
    return CarModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ============ Conversion Methods ============

  /// Convert to Map for route arguments (navigation)
  Map<String, dynamic> toRouteArguments() {
    return {
      'id': id,
      'carName': name,
      'carBrand': brand,
      'carImage': image,
      'carPrice': price,
      'carDescription': description,
      'carImages': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'isNew': isNew,
      'phoneNumber': phoneNumber,
      'category': category,
      'seats': seats,
      'fuelType': fuelType,
      'transmission': transmission,
      'driveType': driveType,
      'horsepower': horsepower,
      'engine': engine,
      'dimensions': dimensions,
      'purpose': purpose,
    };
  }

  /// Convert to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'image': image,
      'price': price,
      'description': description,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'isNew': isNew,
      'phoneNumber': phoneNumber,
      'category': category,
      'seats': seats,
      'fuelType': fuelType,
      'driveType': driveType,
      'transmission': transmission,
      'horsepower': horsepower,
      'engine': engine,
      'dimensions': dimensions,
      'purpose': purpose,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // ============ Utility Methods ============

  /// Copy with để tạo bản sao với một số thay đổi
  CarModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? image,
    String? price,
    String? description,
    List<String>? images,
    double? rating,
    int? reviewCount,
    bool? isNew,
    String? phoneNumber,
    String? category,
    String? seats,
    String? fuelType,
    String? driveType,
    String? transmission,
    int? horsepower,
    String? engine,
    String? dimensions,
    String? purpose,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      image: image ?? this.image,
      price: price ?? this.price,
      description: description ?? this.description,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isNew: isNew ?? this.isNew,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      category: category ?? this.category,
      seats: seats ?? this.seats,
      fuelType: fuelType ?? this.fuelType,
      driveType: driveType ?? this.driveType,
      transmission: transmission ?? this.transmission,
      horsepower: horsepower ?? this.horsepower,
      engine: engine ?? this.engine,
      dimensions: dimensions ?? this.dimensions,
      purpose: purpose ?? this.purpose,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CarModel(id: $id, name: $name, brand: $brand, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ============ Backward Compatibility ============
// Type alias for backward compatibility with old code using CarDetailData
typedef CarDetailData = CarModel;
