import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ShowroomApiService {
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
  ];
  static const Duration _cacheTtl = Duration(minutes: 20);
  static const String _cachePrefix = 'showroom_cache_v1_';

  Future<List<Map<String, dynamic>>> fetchNearbyShowrooms({
    required double latitude,
    required double longitude,
    int radiusInMeters = 250000,
    int limit = 30,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(latitude, longitude, radiusInMeters);
    if (!forceRefresh) {
      final cached = await _readCache(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.take(limit).toList();
      }
    }

    final query = '''
[out:json][timeout:35];
(
  node["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  way["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  relation["shop"="car"](around:$radiusInMeters,$latitude,$longitude);
  node["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
  way["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
  relation["amenity"="car_dealership"](around:$radiusInMeters,$latitude,$longitude);
);
out center tags;
''';

    HttpException? lastHttpError;

    for (final endpoint in _endpoints) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 20);

      try {
        final request = await client.postUrl(Uri.parse(endpoint));
        request.headers.set(
          HttpHeaders.contentTypeHeader,
          'application/x-www-form-urlencoded',
        );
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'doan_cuoiki_flutter_showroom/1.0',
        );
        request.write('data=${Uri.encodeQueryComponent(query)}');

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode != 200) {
          lastHttpError = HttpException(
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

          final brand = (tags['brand'] as String?)?.trim();
          final phone = (tags['phone'] as String?)?.trim() ??
              (tags['contact:phone'] as String?)?.trim() ??
              '';

          final address = _buildAddress(tags);
          final dedupeKey =
              '$name|${lat.toStringAsFixed(5)}|${lng.toStringAsFixed(5)}';
          if (seen.contains(dedupeKey)) continue;
          seen.add(dedupeKey);

          results.add({
            'name': name,
            'brand': (brand == null || brand.isEmpty)
                ? _inferBrandFromName(name)
                : brand,
            'lat': lat.toDouble(),
            'lng': lng.toDouble(),
            'address': address,
            'phone': phone,
          });
        }

        if (results.isNotEmpty) {
          await _writeCache(cacheKey, results);
        }
        return results.take(limit).toList();
      } on HttpException catch (e) {
        lastHttpError = e;
      } finally {
        client.close(force: true);
      }
    }

    final stale = await _readCache(cacheKey, allowExpired: true);
    if (stale != null && stale.isNotEmpty) {
      return stale.take(limit).toList();
    }

    throw lastHttpError ??
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

      return items
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
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

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[
      (tags['addr:housenumber'] as String?)?.trim() ?? '',
      (tags['addr:street'] as String?)?.trim() ?? '',
      (tags['addr:suburb'] as String?)?.trim() ?? '',
      (tags['addr:city'] as String?)?.trim() ?? '',
      (tags['addr:province'] as String?)?.trim() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(', ');

    final fallback = (tags['addr:full'] as String?)?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;

    return 'Địa chỉ đang cập nhật';
  }

  String _inferBrandFromName(String name) {
    const knownBrands = <String>[
      'Toyota',
      'Hyundai',
      'Kia',
      'Mazda',
      'Mercedes',
      'BMW',
      'Audi',
      'Ford',
      'Honda',
      'Mitsubishi',
      'Nissan',
      'VinFast',
      'Volvo',
      'Lexus',
      'Porsche',
      'Subaru',
      'Peugeot',
      'Chevrolet',
      'Isuzu',
      'Suzuki',
      'MG',
    ];

    for (final brand in knownBrands) {
      if (name.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }
    return 'Showroom ô tô';
  }
}
