import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/cars_data.dart';
import '../models/car_detail.dart';

class AdminMigrationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, int>> migrateUsers({bool logRun = true}) async {
    final snapshot = await _db.collection('users').get();
    var updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final patch = <String, dynamic>{
        ..._deleteTrailingSpaceKeys(const [
          'name',
          'email',
          'phone',
          'phoneNumber',
          'role',
          'provider',
          'uid',
        ]),
      };

      final phone = (data['phone'] ?? '').toString().trim();
      final phoneNumber = (data['phoneNumber'] ?? '').toString().trim();
      if (phone.isEmpty && phoneNumber.isNotEmpty) {
        patch['phone'] = phoneNumber;
      }
      if (phoneNumber.isEmpty && phone.isNotEmpty) {
        patch['phoneNumber'] = phone;
      }

      if ((data['role'] ?? '').toString().trim().isEmpty) {
        patch['role'] = 'user';
      }
      if ((data['provider'] ?? '').toString().trim().isEmpty) {
        patch['provider'] = 'phone';
      }

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(patch);
        updated++;
      }
    }

    final result = {'scanned': snapshot.docs.length, 'updated': updated};
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'users',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static Future<Map<String, int>> migrateProducts({bool logRun = true}) async {
    final snapshot = await _db.collection('products').get();
    final brandsSnapshot = await _db.collection('brands').get();
    final brandNameToId = <String, String>{};
    for (final brandDoc in brandsSnapshot.docs) {
      final data = brandDoc.data();
      final name = (data['brandName'] ?? data['name'] ?? data['brand'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (name.isNotEmpty) {
        brandNameToId[name] = brandDoc.id;
      }
    }

    final carsDataById = <String, Map<String, dynamic>>{
      for (final car in CarsData.allCars) car.id: _carsDataToProductsMap(car),
    };

    var scanned = snapshot.docs.length;
    var updated = 0;

    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
      for (final doc in snapshot.docs) doc.id: doc,
    };

    for (final entry in carsDataById.entries) {
      final productId = entry.key;
      if (docsById.containsKey(productId)) continue;

      final seeded = Map<String, dynamic>.from(entry.value);
      final brandKey = (seeded['brandName'] ?? seeded['brand'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final mappedBrandId = brandNameToId[brandKey] ?? '';
      if (mappedBrandId.isNotEmpty) {
        seeded['brandId'] = mappedBrandId;
      }
      seeded['createdAt'] = FieldValue.serverTimestamp();
      seeded['updatedAt'] = FieldValue.serverTimestamp();

      await _db
          .collection('products')
          .doc(productId)
          .set(seeded, SetOptions(merge: true));
      updated++;
      scanned++;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final patch = <String, dynamic>{
        ..._deleteTrailingSpaceKeys(const [
          'name',
          'carName',
          'brand',
          'brandName',
          'carBrand',
          'brandId',
          'price',
          'carPrice',
          'priceNote',
          'image',
          'carImage',
          'gallery',
          'images',
          'carImages',
          'description',
          'carDescription',
          'rating',
          'reviewCount',
          'category',
          'seats',
          'fuelType',
          'driveType',
          'transmission',
          'horsepower',
          'engine',
          'dimensions',
          'purpose',
        ]),
      };

      final defaultMap = carsDataById[doc.id];
      if (defaultMap != null) {
        for (final entry in defaultMap.entries) {
          final key = entry.key;
          final defaultValue = entry.value;
          final currentValue = data[key];
          if (_isMissingValue(currentValue) && !_isMissingValue(defaultValue)) {
            patch[key] = defaultValue;
          }
        }
      }

      final name = (data['name'] ?? data['carName'] ?? '').toString().trim();
      final brand =
          (data['brand'] ?? data['brandName'] ?? data['carBrand'] ?? '')
              .toString()
              .trim();
      final price = (data['price'] ?? data['carPrice'] ?? '').toString().trim();
      final image = (data['image'] ?? data['carImage'] ?? '').toString().trim();

      if ((data['id'] ?? '').toString().trim().isEmpty) {
        patch['id'] = doc.id;
      }
      if ((data['name'] ?? '').toString().trim().isEmpty && name.isNotEmpty) {
        patch['name'] = name;
      }
      if ((data['carName'] ?? '').toString().trim().isEmpty &&
          name.isNotEmpty) {
        patch['carName'] = name;
      }
      if ((data['brand'] ?? '').toString().trim().isEmpty && brand.isNotEmpty) {
        patch['brand'] = brand;
      }
      if ((data['brandName'] ?? '').toString().trim().isEmpty &&
          brand.isNotEmpty) {
        patch['brandName'] = brand;
      }
      if ((data['carBrand'] ?? '').toString().trim().isEmpty &&
          brand.isNotEmpty) {
        patch['carBrand'] = brand;
      }
      if ((data['price'] ?? '').toString().trim().isEmpty && price.isNotEmpty) {
        patch['price'] = price;
      }
      if ((data['carPrice'] ?? '').toString().trim().isEmpty &&
          price.isNotEmpty) {
        patch['carPrice'] = price;
      }
      if ((data['image'] ?? '').toString().trim().isEmpty && image.isNotEmpty) {
        patch['image'] = image;
      }
      if ((data['carImage'] ?? '').toString().trim().isEmpty &&
          image.isNotEmpty) {
        patch['carImage'] = image;
      }

      final brandId = (data['brandId'] ?? '').toString().trim();
      final normalizedBrand = brand.toLowerCase();
      if (brandId.isEmpty && normalizedBrand.isNotEmpty) {
        final mappedBrandId = brandNameToId[normalizedBrand] ?? '';
        if (mappedBrandId.isNotEmpty) {
          patch['brandId'] = mappedBrandId;
        }
      }

      final normalizedGallery =
          ((data['gallery'] as List?) ??
                  (data['images'] as List?) ??
                  (data['carImages'] as List?) ??
                  const <dynamic>[])
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
      if (normalizedGallery.isEmpty && image.isNotEmpty) {
        normalizedGallery.add(image);
      }

      if (normalizedGallery.isNotEmpty) {
        final hasGallery =
            data['gallery'] is List && (data['gallery'] as List).isNotEmpty;
        final hasImages =
            data['images'] is List && (data['images'] as List).isNotEmpty;
        final hasCarImages =
            data['carImages'] is List && (data['carImages'] as List).isNotEmpty;

        if (!hasGallery) {
          patch['gallery'] = normalizedGallery;
        }
        if (!hasImages) {
          patch['images'] = normalizedGallery;
        }
        if (!hasCarImages) {
          patch['carImages'] = normalizedGallery;
        }
      }

      if ((data['priceNote'] ?? '').toString().trim().isEmpty) {
        patch['priceNote'] = 'Liên hệ';
      }

      if ((data['carDescription'] ?? '').toString().trim().isEmpty) {
        final description = (data['description'] ?? '').toString().trim();
        if (description.isNotEmpty) {
          patch['carDescription'] = description;
        }
      }

      if (data.containsKey('isNew')) {
        patch['isNew'] = FieldValue.delete();
      }

      final canonicalDefaults = <String, dynamic>{
        'category': (data['category'] ?? '').toString(),
        'seats': (data['seats'] ?? '').toString(),
        'fuelType': (data['fuelType'] ?? '').toString(),
        'driveType': (data['driveType'] ?? '').toString(),
        'transmission': (data['transmission'] ?? '').toString(),
        'horsepower': _parseInt(data['horsepower'], fallback: 0),
        'engine': (data['engine'] ?? '').toString(),
        'dimensions': (data['dimensions'] ?? '').toString(),
        'purpose': (data['purpose'] ?? '').toString(),
        'rating': _parseDouble(data['rating'], fallback: 4.5),
        'reviewCount': _parseInt(data['reviewCount'], fallback: 0),
      };

      for (final entry in canonicalDefaults.entries) {
        final key = entry.key;
        final fallbackValue = entry.value;
        final currentValue = data[key];
        if (_isMissingValue(currentValue)) {
          patch[key] = fallbackValue;
        }
      }

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(patch);
        updated++;
      }
    }

    final result = {'scanned': scanned, 'updated': updated};
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'products',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static Map<String, dynamic> _carsDataToProductsMap(CarDetailData car) {
    final gallery = car.images
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final primaryImage = car.image.toString().trim();
    final normalizedGallery = gallery.isNotEmpty
        ? gallery
        : (primaryImage.isNotEmpty ? <String>[primaryImage] : <String>[]);

    return {
      'id': car.id,
      'name': car.name,
      'carName': car.name,
      'brand': car.brand,
      'brandName': car.brand,
      'carBrand': car.brand,
      'price': car.price,
      'carPrice': car.price,
      'priceNote': 'Liên hệ',
      'image': primaryImage,
      'carImage': primaryImage,
      'gallery': normalizedGallery,
      'images': normalizedGallery,
      'carImages': normalizedGallery,
      'description': car.description,
      'carDescription': car.description,
      'rating': car.rating,
      'reviewCount': car.reviewCount,
      'category': car.category ?? '',
      'seats': car.seats ?? '',
      'fuelType': car.fuelType ?? '',
      'driveType': car.driveType ?? '',
      'transmission': car.transmission ?? '',
      'horsepower': car.horsepower,
      'engine': car.engine ?? '',
      'dimensions': car.dimensions ?? '',
      'purpose': car.purpose ?? '',
    };
  }

  static bool _isMissingValue(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    return false;
  }

  static int _parseInt(dynamic raw, {int fallback = 0}) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    return fallback;
  }

  static double _parseDouble(dynamic raw, {double fallback = 0.0}) {
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      return double.tryParse(raw.trim().replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  static Future<Map<String, int>> migrateBrands({bool logRun = true}) async {
    final snapshot = await _db.collection('brands').get();
    final productsSnapshot = await _db.collection('products').get();
    final inferredBrandNameById = <String, String>{};

    for (final productDoc in productsSnapshot.docs) {
      final data = productDoc.data();
      final brandId = (data['brandId'] ?? '').toString().trim();
      final brandName = _extractBrandNameFromMap(data);
      if (brandId.isEmpty || brandName.isEmpty) continue;
      inferredBrandNameById.putIfAbsent(brandId, () => brandName);
    }

    var updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final patch = <String, dynamic>{
        ..._deleteTrailingSpaceKeys(const [
          'brandName',
          'name',
          'brand',
          'slug',
          'productCount',
        ]),
      };

      final currentBrandName = _extractBrandNameFromMap(data);
      final brandName = currentBrandName.isNotEmpty
          ? currentBrandName
          : (inferredBrandNameById[doc.id] ?? '');
      final resolvedBrandName = brandName.trim();

      final hasBrandNameKey = data.containsKey('brandName');
      final hasNameKey = data.containsKey('name');
      final hasBrandKey = data.containsKey('brand');
      final hasSlugKey = data.containsKey('slug');

      if (!hasBrandNameKey ||
          (data['brandName'] ?? '').toString().trim().isEmpty) {
        patch['brandName'] = resolvedBrandName;
      }
      if (!hasNameKey || (data['name'] ?? '').toString().trim().isEmpty) {
        patch['name'] = resolvedBrandName;
      }
      if (!hasBrandKey || (data['brand'] ?? '').toString().trim().isEmpty) {
        patch['brand'] = resolvedBrandName;
      }

      if (!hasSlugKey || (data['slug'] ?? '').toString().trim().isEmpty) {
        patch['slug'] = resolvedBrandName.isEmpty
            ? ''
            : _slugify(resolvedBrandName);
      }

      if (data['productCount'] is! int) {
        final count = int.tryParse('${data['productCount'] ?? 0}') ?? 0;
        patch['productCount'] = count;
      }

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(patch);
        updated++;
      }
    }

    final result = {'scanned': snapshot.docs.length, 'updated': updated};
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'brands',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static String _extractBrandNameFromMap(Map<String, dynamic> data) {
    final brandName = (data['brandName'] ?? '').toString().trim();
    final name = (data['name'] ?? '').toString().trim();
    final brand = (data['brand'] ?? '').toString().trim();
    final carBrand = (data['carBrand'] ?? '').toString().trim();

    if (brandName.isNotEmpty) return brandName;
    if (name.isNotEmpty) return name;
    if (brand.isNotEmpty) return brand;
    if (carBrand.isNotEmpty) return carBrand;
    return '';
  }

  static Future<Map<String, int>> migrateDeposits({bool logRun = true}) async {
    final result = await _migrateSimpleCollection(
      collection: 'deposits',
      fields: const [
        'status',
        'depositStatus',
        'customerName',
        'customerPhone',
        'customerEmail',
        'carName',
        'carBrand',
        'depositAmount',
      ],
    );
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'deposits',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static Future<Map<String, int>> migrateBookings({bool logRun = true}) async {
    final result = await _migrateSimpleCollection(
      collection: 'bookings',
      fields: const [
        'status',
        'customerName',
        'customerPhone',
        'customerEmail',
        'carName',
        'carBrand',
        'bookingDate',
      ],
    );
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'bookings',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static Future<Map<String, int>> migrateWarranties({
    bool logRun = true,
  }) async {
    final result = await _migrateSimpleCollection(
      collection: 'warranties',
      fields: const [
        'status',
        'customerName',
        'customerPhone',
        'customerEmail',
        'carName',
        'carBrand',
        'vin',
        'licensePlate',
      ],
    );
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'warranties',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static Future<Map<String, int>> migrateNotifications({
    bool logRun = true,
  }) async {
    final snapshot = await _db.collection('notifications').get();
    var updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final patch = <String, dynamic>{
        ..._deleteTrailingSpaceKeys(const [
          'title',
          'description',
          'type',
          'productId',
          'carModel',
          'originalPrice',
          'discountPrice',
          'discountPercent',
          'imageUrl',
          'bannerKey',
          'bannerIndex',
          'isRead',
        ]),
      };

      if ((data['type'] ?? '').toString().trim().isEmpty) {
        patch['type'] = 'announcement';
      }
      if (data['bannerIndex'] is! int) {
        patch['bannerIndex'] = int.tryParse('${data['bannerIndex'] ?? 0}') ?? 0;
      }
      if (data['isRead'] is! bool) {
        patch['isRead'] = data['isRead'] == true;
      }

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(patch);
        updated++;
      }
    }

    final result = {'scanned': snapshot.docs.length, 'updated': updated};
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'notifications',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static Future<Map<String, int>> migrateBanners({bool logRun = true}) async {
    final snapshot = await _db.collection('banners').get();
    var updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final patch = <String, dynamic>{
        ..._deleteTrailingSpaceKeys(const [
          'badge',
          'title',
          'subtitle',
          'buttonText',
          'image',
          'imageUrl',
          'sortOrder',
          'accentColor',
          'subtitleColor',
          'gradientColors',
          'description',
          'benefits',
          'bannerKey',
          'productId',
          'carModel',
          'originalPrice',
          'discountPrice',
          'discountPercent',
        ]),
      };

      final image = (data['image'] ?? '').toString().trim();
      final imageUrl = (data['imageUrl'] ?? '').toString().trim();
      if (image.isEmpty && imageUrl.isNotEmpty) {
        patch['image'] = imageUrl;
      }
      if (imageUrl.isEmpty && image.isNotEmpty) {
        patch['imageUrl'] = image;
      }

      if ((data['buttonText'] ?? '').toString().trim().isEmpty) {
        patch['buttonText'] = 'Khám phá ngay';
      }

      if (data['sortOrder'] is! int) {
        patch['sortOrder'] = int.tryParse('${data['sortOrder'] ?? 1}') ?? 1;
      }

      if (data['gradientColors'] is! List) {
        patch['gradientColors'] = const [0xFF0D1117, 0xFF161B22, 0xFF21262D];
      }

      if (data['benefits'] is! List) {
        patch['benefits'] = const <String>[];
      }

      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(patch);
        updated++;
      }
    }

    final result = {'scanned': snapshot.docs.length, 'updated': updated};
    if (logRun) {
      await _safeWriteMigrationLog(
        mode: 'single',
        collection: 'banners',
        success: true,
        scanned: result['scanned'] ?? 0,
        updated: result['updated'] ?? 0,
      );
    }
    return result;
  }

  static Future<Map<String, dynamic>> migrateAllCollections({
    String? triggeredByPhone,
    String? triggeredByUid,
  }) async {
    final startedAt = DateTime.now();
    final details = <String, Map<String, int>>{};
    final failures = <String, String>{};
    var totalScanned = 0;
    var totalUpdated = 0;

    Future<void> run(
      String collection,
      Future<Map<String, int>> Function() action,
    ) async {
      try {
        final result = await action();
        details[collection] = result;
        totalScanned += result['scanned'] ?? 0;
        totalUpdated += result['updated'] ?? 0;
      } catch (e) {
        failures[collection] = e.toString();
      }
    }

    await run('users', () => migrateUsers(logRun: false));
    await run('products', () => migrateProducts(logRun: false));
    await run('brands', () => migrateBrands(logRun: false));
    await run('deposits', () => migrateDeposits(logRun: false));
    await run('bookings', () => migrateBookings(logRun: false));
    await run('warranties', () => migrateWarranties(logRun: false));
    await run('notifications', () => migrateNotifications(logRun: false));
    await run('banners', () => migrateBanners(logRun: false));

    final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
    final success = failures.isEmpty;

    final summary = <String, dynamic>{
      'scanned': totalScanned,
      'updated': totalUpdated,
      'failedCollections': failures.length,
      'durationMs': durationMs,
      'details': details,
      'failures': failures,
      'success': success,
    };

    await _safeWriteMigrationLog(
      mode: 'all',
      collection: 'all',
      success: success,
      scanned: totalScanned,
      updated: totalUpdated,
      details: details,
      failures: failures,
      durationMs: durationMs,
      triggeredByPhone: triggeredByPhone,
      triggeredByUid: triggeredByUid,
    );

    return summary;
  }

  static Future<Map<String, int>> _migrateSimpleCollection({
    required String collection,
    required List<String> fields,
  }) async {
    final snapshot = await _db.collection(collection).get();
    var updated = 0;

    for (final doc in snapshot.docs) {
      final patch = _deleteTrailingSpaceKeys(fields);
      if (patch.isNotEmpty) {
        patch['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.update(patch);
        updated++;
      }
    }

    return {'scanned': snapshot.docs.length, 'updated': updated};
  }

  static Map<String, dynamic> _deleteTrailingSpaceKeys(List<String> fields) {
    final result = <String, dynamic>{};
    for (final field in fields) {
      result['$field '] = FieldValue.delete();
    }
    return result;
  }

  static String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
  }

  static Future<void> _safeWriteMigrationLog({
    required String mode,
    required String collection,
    required bool success,
    required int scanned,
    required int updated,
    Map<String, Map<String, int>>? details,
    Map<String, String>? failures,
    int? durationMs,
    String? triggeredByPhone,
    String? triggeredByUid,
  }) async {
    try {
      await _db.collection('admin_migration_logs').add({
        'mode': mode,
        'collection': collection,
        'success': success,
        'scanned': scanned,
        'updated': updated,
        'failedCollections': failures?.length ?? 0,
        'details': details ?? <String, dynamic>{},
        'failures': failures ?? <String, dynamic>{},
        'durationMs': durationMs ?? 0,
        'triggeredByPhone': triggeredByPhone ?? '',
        'triggeredByUid': triggeredByUid ?? '',
        'triggeredAtClient': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Keep migration flow successful even when logging fails.
    }
  }
}
