import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ShowroomApiService {
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
  ];
  static const Duration _networkTimeout = Duration(seconds: 15);
  static const int _maxAttemptsPerEndpoint = 2;
  static const Duration _cacheTtl = Duration(hours: 24);
  static const String _cachePrefix = 'showroom_cache_v4_';

  /// Tìm showroom theo GPS thật của khách hàng
  /// - Chỉ tìm trong bán kính 300km
  /// - Lọc theo brand (hãng xe) mà khách chọn
  /// - Sắp xếp theo khoảng cách gần nhất
  /// - KHÔNG dùng fallback data
  Future<List<Map<String, dynamic>>> fetchNearbyShowrooms({
    required double latitude,
    required double longitude,
    int radiusInMeters = 300000, // 300km
    int limit = 30,
    bool forceRefresh = false,
    String? brand,
  }) async {
    log('🔍 Bắt đầu tìm showroom từ GPS: ($latitude, $longitude)');
    log('📏 Bán kính: ${radiusInMeters / 1000}km, Brand: ${brand ?? "tất cả"}');

    // Kiểm tra cache trước
    final cacheKey = _buildCacheKey(latitude, longitude, radiusInMeters, brand);
    if (!forceRefresh) {
      final cached = await _readCache(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        log('✅ Sử dụng cache: ${cached.length} showroom');
        return cached.take(limit).toList();
      }
    }

    // Gọi OpenStreetMap API để tìm showroom
    final allShowrooms = await _searchFromOSM(
      latitude,
      longitude,
      radiusInMeters,
    );

    if (allShowrooms.isEmpty) {
      log(
        '❌ Không tìm thấy showroom nào trong bán kính ${radiusInMeters / 1000}km',
      );
      return [];
    }

    log('📍 Tìm thấy ${allShowrooms.length} showroom từ OpenStreetMap');

    // Tính khoảng cách cho tất cả showroom
    for (var showroom in allShowrooms) {
      final lat = showroom['lat'] as double;
      final lng = showroom['lng'] as double;
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        lat,
        lng,
      );
      showroom['distance'] = distance;
    }

    // Lọc theo brand nếu có
    List<Map<String, dynamic>> filteredShowrooms = allShowrooms;
    if (brand != null && brand.isNotEmpty) {
      final normalizedBrand = brand.trim().toLowerCase();
      filteredShowrooms = allShowrooms.where((showroom) {
        final showroomBrand = (showroom['brand'] as String? ?? '')
            .toLowerCase();
        final showroomName = (showroom['name'] as String? ?? '').toLowerCase();

        // Check nếu brand hoặc name chứa tên hãng xe
        return showroomBrand.contains(normalizedBrand) ||
            showroomName.contains(normalizedBrand);
      }).toList();

      if (filteredShowrooms.isEmpty) {
        log(
          '⚠️ Không tìm thấy showroom cho brand "$brand" trong bán kính ${radiusInMeters / 1000}km',
        );
        log('💡 Có ${allShowrooms.length} showroom khác hãng trong khu vực');
        return []; // Trả về rỗng theo yêu cầu - không dùng fallback
      }
    }

    // Sắp xếp theo khoảng cách gần nhất
    filteredShowrooms.sort((a, b) {
      final distA = a['distance'] as double;
      final distB = b['distance'] as double;
      return distA.compareTo(distB);
    });

    // Lưu cache
    final results = filteredShowrooms.take(limit).toList();
    await _writeCache(cacheKey, results);

    log(
      '✅ Trả về ${results.length} showroom, gần nhất: ${((results.first['distance'] as double) / 1000).toStringAsFixed(1)}km',
    );
    return results;
  }

  /// Tìm kiếm showroom từ OpenStreetMap Overpass API
  Future<List<Map<String, dynamic>>> _searchFromOSM(
    double latitude,
    double longitude,
    int radiusInMeters,
  ) async {
    // Query tìm tất cả car dealership/showroom
    final query =
        '''
[out:json][timeout:20];
(
  node["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  way["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  node["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
  way["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
  node["shop"="car_repair"]["service:vehicle:car_dealer"="yes"](around:$radiusInMeters,$latitude,$longitude);
  way["shop"="car_repair"]["service:vehicle:car_dealer"="yes"](around:$radiusInMeters,$latitude,$longitude);
);
out center tags;
''';

    log('🌐 Gọi Overpass API...');

    // Thử các endpoint cho đến khi có kết quả
    for (final endpoint in _endpoints) {
      for (var attempt = 1; attempt <= _maxAttemptsPerEndpoint; attempt++) {
        try {
          log('🔗 Endpoint: $endpoint (lần $attempt)');

          final client = HttpClient();
          client.connectionTimeout = _networkTimeout;

          final request = await client
              .postUrl(Uri.parse(endpoint))
              .timeout(_networkTimeout);

          request.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/x-www-form-urlencoded',
          );
          request.headers.set(
            HttpHeaders.userAgentHeader,
            'FlutterCarShowroomFinder/2.0',
          );

          request.write('data=${Uri.encodeQueryComponent(query)}');

          final response = await request.close().timeout(_networkTimeout);
          final responseBody = await response
              .transform(utf8.decoder)
              .join()
              .timeout(_networkTimeout);

          client.close(force: true);

          if (response.statusCode != 200) {
            log('❌ Status code: ${response.statusCode}');
            continue;
          }

          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final elements = (decoded['elements'] as List<dynamic>? ?? []);

          if (elements.isEmpty) {
            log('⚠️ API trả về 0 kết quả');
            continue;
          }

          log('📦 Nhận được ${elements.length} elements từ OSM');

          // Parse kết quả
          final results = <Map<String, dynamic>>[];
          final seen = <String>{};

          for (final item in elements) {
            final element = item as Map<String, dynamic>;
            final tags = (element['tags'] as Map<String, dynamic>? ?? {});

            // Lấy tọa độ
            final lat = (element['lat'] ?? (element['center']?['lat'])) as num?;
            final lng = (element['lon'] ?? (element['center']?['lon'])) as num?;
            if (lat == null || lng == null) continue;

            // Lấy tên
            final name = (tags['name'] as String?)?.trim();
            if (name == null || name.isEmpty) continue;

            // Lấy brand/hãng xe
            final brand =
                (tags['brand'] as String?)?.trim() ??
                (tags['operator'] as String?)?.trim() ??
                _inferBrandFromName(name);

            // Lấy thông tin khác
            final phone =
                (tags['phone'] as String?)?.trim() ??
                (tags['contact:phone'] as String?)?.trim() ??
                '';

            final address = _buildAddress(tags);

            // Deduplicate
            final dedupeKey =
                '$name|${lat.toStringAsFixed(5)}|${lng.toStringAsFixed(5)}';
            if (seen.contains(dedupeKey)) continue;
            seen.add(dedupeKey);

            results.add({
              'name': name,
              'brand': brand,
              'lat': lat.toDouble(),
              'lng': lng.toDouble(),
              'address': address,
              'phone': phone,
            });
          }

          log('✅ Parse được ${results.length} showroom hợp lệ');
          return results;
        } on SocketException catch (e) {
          log('❌ Network error: $e');
        } on TimeoutException catch (e) {
          log('⏰ Timeout: $e');
        } on HttpException catch (e) {
          log('❌ HTTP error: $e');
        } catch (e) {
          log('❌ Unknown error: $e');
        }

        // Đợi trước khi retry
        if (attempt < _maxAttemptsPerEndpoint) {
          await Future<void>.delayed(Duration(milliseconds: 1000 * attempt));
        }
      }
    }

    // Thử dùng cache cũ nếu tất cả endpoint đều fail
    final cacheKey = _buildCacheKey(latitude, longitude, radiusInMeters, null);
    final stale = await _readCache(cacheKey, allowExpired: true);
    if (stale != null && stale.isNotEmpty) {
      log('⚠️ API thất bại, sử dụng cache cũ: ${stale.length} showroom');
      return stale;
    }

    log('❌ Không thể lấy dữ liệu từ bất kỳ endpoint nào');
    return [];
  }

  /// Xây dựng địa chỉ từ OSM tags
  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[
      (tags['addr:housenumber'] as String?)?.trim() ?? '',
      (tags['addr:street'] as String?)?.trim() ?? '',
      (tags['addr:district'] as String?)?.trim() ?? '',
      (tags['addr:city'] as String?)?.trim() ?? '',
      (tags['addr:province'] as String?)?.trim() ?? '',
      (tags['addr:state'] as String?)?.trim() ?? '',
      (tags['addr:country'] as String?)?.trim() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    // Fallback: full address
    final full = (tags['addr:full'] as String?)?.trim();
    if (full != null && full.isNotEmpty) return full;

    // Fallback: city/province only
    final city =
        (tags['addr:city'] as String?)?.trim() ??
        (tags['addr:province'] as String?)?.trim() ??
        (tags['addr:state'] as String?)?.trim();

    if (city != null && city.isNotEmpty) return city;

    return 'Địa chỉ chưa cập nhật';
  }

  /// Suy luận brand từ tên showroom
  String _inferBrandFromName(String name) {
    final nameLower = name.toLowerCase();

    final brands = {
      'toyota': 'Toyota',
      'honda': 'Honda',
      'ford': 'Ford',
      'hyundai': 'Hyundai',
      'mazda': 'Mazda',
      'kia': 'Kia',
      'mitsubishi': 'Mitsubishi',
      'nissan': 'Nissan',
      'suzuki': 'Suzuki',
      'mercedes': 'Mercedes-Benz',
      'bmw': 'BMW',
      'audi': 'Audi',
      'lexus': 'Lexus',
      'volkswagen': 'Volkswagen',
      'vw': 'Volkswagen',
      'vinfast': 'VinFast',
      'thaco': 'Thaco',
      'tc motor': 'TC Motor',
      'chevrolet': 'Chevrolet',
      'isuzu': 'Isuzu',
      'peugeot': 'Peugeot',
      'volvo': 'Volvo',
      'subaru': 'Subaru',
      'porsche': 'Porsche',
      'ferrari': 'Ferrari',
      'lamborghini': 'Lamborghini',
      'maserati': 'Maserati',
      'bentley': 'Bentley',
      'rolls-royce': 'Rolls-Royce',
      'tesla': 'Tesla',
      'land rover': 'Land Rover',
      'jaguar': 'Jaguar',
      'mini': 'Mini',
      'jeep': 'Jeep',
      'chrysler': 'Chrysler',
      'dodge': 'Dodge',
      'ram': 'RAM',
      'gmc': 'GMC',
      'cadillac': 'Cadillac',
      'buick': 'Buick',
      'acura': 'Acura',
      'infiniti': 'Infiniti',
      'genesis': 'Genesis',
      'lincoln': 'Lincoln',
    };

    for (final entry in brands.entries) {
      if (nameLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Unknown';
  }

  /// Đọc cache
  Future<List<Map<String, dynamic>>?> _readCache(
    String key, {
    bool allowExpired = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final updatedAt = decoded['updatedAt'] as int?;
      final items = decoded['items'] as List<dynamic>?;

      if (updatedAt == null || items == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - updatedAt;
      if (!allowExpired && age > _cacheTtl.inMilliseconds) {
        await prefs.remove(key);
        return null;
      }

      return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      log('❌ Cache read error: $e');
      return null;
    }
  }

  /// Ghi cache
  Future<void> _writeCache(String key, List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'items': items,
      });
      await prefs.setString(key, payload);
    } catch (e) {
      log('❌ Cache write error: $e');
    }
  }

  /// Tạo cache key
  String _buildCacheKey(double lat, double lng, int radius, String? brand) {
    final latRounded = lat.toStringAsFixed(2);
    final lngRounded = lng.toStringAsFixed(2);
    final brandKey = brand?.toLowerCase().trim() ?? 'all';
    return '$_cachePrefix${latRounded}_${lngRounded}_${radius}_$brandKey';
  }
}
