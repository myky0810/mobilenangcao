import 'dart:convert';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Routing qua OSRM — hỗ trợ tối đa 3 tuyến thay thế (alternatives).
class RoutingApiService {
  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  /// Trả về danh sách tuyến (thường 1–3), tuyến [0] là tuyến được gợi ý (nhanh nhất).
  Future<List<Map<String, dynamic>>?> getRoutes({
    required LatLng origin,
    required LatLng destination,
    int maxAlternatives = 3,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&alternatives=true&steps=false',
    );

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final routes = decoded['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) return null;

      final result = <Map<String, dynamic>>[];
      final take = routes.length < maxAlternatives ? routes.length : maxAlternatives;

      for (var i = 0; i < take; i++) {
        final r = routes[i] as Map<String, dynamic>;
        final coordinates =
            (r['geometry']?['coordinates'] as List<dynamic>? ?? const [])
                .map(
                  (c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ),
                )
                .toList();

        if (coordinates.isEmpty) continue;

        final distance = (r['distance'] as num?)?.toDouble() ?? 0;
        final duration = (r['duration'] as num?)?.toDouble() ?? 0;

        result.add({
          'points': coordinates,
          'distanceMeters': distance,
          'durationSeconds': duration,
          'index': i,
        });
      }

      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
