class CarDetailData {
  final String id;
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
  final String? category;
  final String? seats;
  final String? fuelType;
  final String? driveType;
  final String? transmission;
  final int? horsepower;
  final String? engine;
  final String? dimensions;
  final String? purpose;
  final String? videoUrl;

  const CarDetailData({
    required this.id,
    required this.name,
    required this.brand,
    required this.image,
    required this.price,
    required this.description,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.isNew,
    this.phoneNumber,
    this.category,
    this.seats,
    this.fuelType,
    this.driveType,
    this.transmission,
    this.horsepower,
    this.engine,
    this.dimensions,
    this.purpose,
  this.videoUrl,
  });

  factory CarDetailData.fromRouteArguments(Object? args) {
    if (args is CarDetailData) {
      return args;
    }
    if (args is Map<String, dynamic>) {
      return CarDetailData.fromMap(args);
    }
    if (args is Map) {
      return CarDetailData.fromMap(Map<String, dynamic>.from(args));
    }
    throw ArgumentError('Unsupported detail car arguments: $args');
  }

  factory CarDetailData.fromMap(Map<String, dynamic> map) {
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

    return CarDetailData(
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
      category: (map['category'] as String?)?.trim(),
      seats: (map['seats'] as String?)?.trim(),
      fuelType: (map['fuelType'] as String?)?.trim(),
      driveType: (map['driveType'] as String?)?.trim(),
      transmission: (map['transmission'] as String?)?.trim(),
      horsepower: (map['horsepower'] as num?)?.toInt(),
      engine: (map['engine'] as String?)?.trim(),
      dimensions: (map['dimensions'] as String?)?.trim(),
      purpose: (map['purpose'] as String?)?.trim(),
    videoUrl: (map['videoUrl'] ?? map['video'] ?? map['videoURL'])
      ?.toString()
      .trim(),
    );
  }

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
  'videoUrl': videoUrl,
    };
  }
}
