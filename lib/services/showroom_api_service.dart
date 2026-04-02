import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ShowroomApiService {
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
  ];
  static const Duration _networkTimeout = Duration(seconds: 22);
  static const int _maxAttemptsPerEndpoint = 2;
  static const Duration _cacheTtl = Duration(
    hours: 2,
  ); // Tăng thời gian cache từ 20 phút lên 2 giờ
  static const String _cachePrefix =
      'showroom_cache_v2_'; // Bump version để force refresh

  Future<List<Map<String, dynamic>>> fetchNearbyShowrooms({
    required double latitude,
    required double longitude,
    int radiusInMeters = 300000, // Default 300km
    int limit = 30,
    bool forceRefresh = false,
    String? brand,
  }) async {
    final cacheKey = _buildCacheKey(latitude, longitude, radiusInMeters);
    if (!forceRefresh) {
      final cached = await _readCache(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        // Thêm null safety cho cached data
        final validCached = cached
            .where(
              (item) =>
                  item['name'] != null &&
                  item['lat'] != null &&
                  item['lng'] != null,
            )
            .toList();
        return validCached.take(limit).toList();
      }
    }

    final normalizedBrand = (brand ?? '').trim();
    final brandFilter = normalizedBrand.isEmpty
        ? ''
        : '\n  node["brand"~"${_escapeOverpassRegex(normalizedBrand)}",i](around:$radiusInMeters,$latitude,$longitude);\n'
              '  way["brand"~"${_escapeOverpassRegex(normalizedBrand)}",i](around:$radiusInMeters,$latitude,$longitude);\n'
              '  relation["brand"~"${_escapeOverpassRegex(normalizedBrand)}",i](around:$radiusInMeters,$latitude,$longitude);\n'
              '  node["name"~"${_escapeOverpassRegex(normalizedBrand)}",i](around:$radiusInMeters,$latitude,$longitude);\n'
              '  way["name"~"${_escapeOverpassRegex(normalizedBrand)}",i](around:$radiusInMeters,$latitude,$longitude);\n'
              '  relation["name"~"${_escapeOverpassRegex(normalizedBrand)}",i](around:$radiusInMeters,$latitude,$longitude);\n';

    final query =
        '''
[out:json][timeout:35];
(
  node["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  way["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  relation["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  node["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
  way["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
  relation["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
$brandFilter
);
out center tags;
''';

    Exception? lastError;

    for (final endpoint in _endpoints) {
      for (var attempt = 1; attempt <= _maxAttemptsPerEndpoint; attempt++) {
        final client = HttpClient();
        client.connectionTimeout = _networkTimeout;

        try {
          final request = await client
              .postUrl(Uri.parse(endpoint))
              .timeout(_networkTimeout);
          request.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/x-www-form-urlencoded',
          );
          request.headers.set(
            HttpHeaders.userAgentHeader,
            'doan_cuoiki_flutter_showroom/1.0',
          );
          request.write('data=${Uri.encodeQueryComponent(query)}');

          final response = await request.close().timeout(_networkTimeout);
          final responseBody = await response
              .transform(utf8.decoder)
              .join()
              .timeout(_networkTimeout);

          if (response.statusCode != 200) {
            lastError = HttpException(
              'Overpass API failed with status: ${response.statusCode}',
            );
            continue;
          }

          final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
          final elements = (decoded['elements'] as List<dynamic>? ?? const []);

          final results = <Map<String, dynamic>>[];
          final seen = <String>{};

          for (final item in elements) {
            final element = item as Map<String, dynamic>;
            final tags = (element['tags'] as Map<String, dynamic>? ?? {});

            final lat = (element['lat'] ?? (element['center']?['lat'])) as num?;
            final lng = (element['lon'] ?? (element['center']?['lon'])) as num?;
            if (lat == null || lng == null) continue;

            final name = (tags['name'] as String?)?.trim();
            if (name == null || name.isEmpty) continue;

            final elementBrand = (tags['brand'] as String?)?.trim();
            final phone =
                (tags['phone'] as String?)?.trim() ??
                (tags['contact:phone'] as String?)?.trim() ??
                '';

            final address = _buildAddress(tags);
            final dedupeKey =
                '$name|${lat.toStringAsFixed(5)}|${lng.toStringAsFixed(5)}';
            if (seen.contains(dedupeKey)) continue;
            seen.add(dedupeKey);

            // Tính khoảng cách thực tế từ GPS khách hàng đến showroom
            final distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              lat.toDouble(),
              lng.toDouble(),
            );

            results.add({
              'name': name,
              'brand': (elementBrand == null || elementBrand.isEmpty)
                  ? _inferBrandFromName(name)
                  : elementBrand,
              'lat': lat.toDouble(),
              'lng': lng.toDouble(),
              'address': address,
              'phone': phone,
              'distance': distance, // Thêm khoảng cách thực tế (meters)
            });
          }

          if (results.isNotEmpty) {
            // Sắp xếp theo khoảng cách gần nhất
            results.sort(
              (a, b) =>
                  (a['distance'] as double).compareTo(b['distance'] as double),
            );
            await _writeCache(cacheKey, results);
          }
          return results.take(limit).toList();
        } on SocketException catch (e) {
          lastError = e;
        } on TimeoutException catch (e) {
          lastError = e;
        } on HttpException catch (e) {
          lastError = e;
        } catch (e) {
          lastError = Exception(e.toString());
        } finally {
          client.close(force: true);
        }

        if (attempt < _maxAttemptsPerEndpoint) {
          await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
        }
      }
    }

    final stale = await _readCache(cacheKey, allowExpired: true);
    if (stale != null && stale.isNotEmpty) {
      return stale.take(limit).toList();
    }

    throw lastError ??
        const HttpException('Unable to fetch showroom data from endpoints');
  }

  Future<List<Map<String, dynamic>>?> _readCache(
    String key, {
    bool allowExpired = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
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
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> _writeCache(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'items': items,
    });
    await prefs.setString(key, payload);
  }

  String _buildCacheKey(double lat, double lng, int radius) {
    final latRounded = lat.toStringAsFixed(2);
    final lngRounded = lng.toStringAsFixed(2);
    return '$_cachePrefix${latRounded}_${lngRounded}_$radius';
  }

  String _escapeOverpassRegex(String value) {
    // Escape các ký tự regex cơ bản để tránh lỗi query Overpass.
    // Overpass dùng regex kiểu PCRE.
    return value.replaceAllMapped(
      RegExp(r'([\\.^$|?*+()\[\]{}-])'),
      (m) => '\\${m[0]}',
    );
  }

  String _buildAddress(Map<String, dynamic> tags) {
    // Thử lấy địa chỉ structured trước
    final parts = <String>[
      (tags['addr:housenumber'] as String?)?.trim() ?? '',
      (tags['addr:street'] as String?)?.trim() ?? '',
      (tags['addr:suburb'] as String?)?.trim() ?? '',
      (tags['addr:city'] as String?)?.trim() ?? '',
      (tags['addr:province'] as String?)?.trim() ?? '',
      (tags['addr:state'] as String?)?.trim() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    if (parts.length >= 2) return parts.join(', ');

    // Fallback 1: địa chỉ đầy đủ
    final fallback = (tags['addr:full'] as String?)?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;

    // Fallback 2: description có thể chứa địa chỉ
    final description = (tags['description'] as String?)?.trim();
    if (description != null &&
        description.isNotEmpty &&
        (description.contains('street') ||
            description.contains('road') ||
            description.contains('avenue') ||
            description.contains('boulevard'))) {
      return description;
    }

    // Fallback 3: operator + city
    final operator = (tags['operator'] as String?)?.trim();
    final city =
        (tags['addr:city'] as String?)?.trim() ??
        (tags['addr:state'] as String?)?.trim() ??
        (tags['place'] as String?)?.trim();

    if (operator != null && city != null) {
      return '$operator, $city';
    }

    // Fallback 4: thông tin địa lý cơ bản
    final district = (tags['addr:district'] as String?)?.trim();
    if (district != null && city != null) {
      return '$district, $city';
    } else if (city != null) {
      return city;
    }

    // Fallback cuối: dùng name nếu có vẻ như địa chỉ
    final name = (tags['name'] as String?)?.trim();
    if (name != null &&
        name.isNotEmpty &&
        (name.contains('street') ||
            name.contains('road') ||
            name.contains('avenue') ||
            name.contains(','))) {
      return name;
    }

    return 'Showroom location available on Google Maps';
  }

  String _inferBrandFromName(String name) {
    final lowerName = name.toLowerCase();

    // Map các pattern brand với tên chuẩn
    const brandPatterns = {
      'toyota': ['toyota'],
      'hyundai': ['hyundai', 'huyndai'],
      'kia': ['kia'],
      'mazda': ['mazda'],
      'mercedes': ['mercedes', 'mercedes-benz', 'mb'],
      'bmw': ['bmw'],
      'audi': ['audi'],
      'ford': ['ford'],
      'honda': ['honda'],
      'mitsubishi': ['mitsubishi'],
      'nissan': ['nissan'],
      'vinfast': ['vinfast', 'vf'],
      'volvo': ['volvo'],
      'lexus': ['lexus'],
      'tesla': ['tesla'],
      'volkswagen': ['volkswagen', 'vw'],
      'peugeot': ['peugeot'],
      'subaru': ['subaru'],
      'isuzu': ['isuzu'],
      'suzuki': ['suzuki'],
      'chevrolet': ['chevrolet', 'chevy'],
      'land rover': ['land rover', 'landrover'],
      'jaguar': ['jaguar'],
    };

    for (final entry in brandPatterns.entries) {
      final standardBrand = entry.key;
      final patterns = entry.value;

      for (final pattern in patterns) {
        if (lowerName.contains(pattern)) {
          // Trả về tên chuẩn với chữ cái đầu viết hoa
          return standardBrand
              .split(' ')
              .map(
                (word) =>
                    word.substring(0, 1).toUpperCase() + word.substring(1),
              )
              .join(' ');
        }
      }
    }

    return 'Showroom xe';
  }
}
