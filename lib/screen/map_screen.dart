import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:doan_cuoiki/services/showroom_api_service.dart';
import 'package:doan_cuoiki/services/routing_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedShowroom;
  final String? preferredBrand;

  const MapScreen({super.key, this.selectedShowroom, this.preferredBrand});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final ShowroomApiService _showroomApiService = ShowroomApiService();
  final RoutingApiService _routingApiService = RoutingApiService();

  Position? _currentPosition;
  String? _locationError;
  bool _isRequestingLocation = true;
  bool _isLoadingShowrooms = false;
  bool _isLoadingRoute = false;
  bool _locationPermissionGranted = false;

  /// Các tuyến từ OSRM (tối đa 3): tuyến chính + phụ.
  List<Map<String, dynamic>> _routeOptions = [];
  int _selectedRouteIndex = 0;
  List<Map<String, dynamic>> _nearestShowrooms = [];
  List<Map<String, dynamic>> _showrooms = [];
  Map<String, dynamic>? _selectedShowroom;
  Set<Marker> _markers = <Marker>{};
  Set<Polyline> _polylines = <Polyline>{};

  // Vị trí mặc định: Hà Nội
  static const LatLng _defaultPosition = LatLng(21.027763, 105.834160);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra GPS có bật không
      bool serviceEnabled;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (_) {
        serviceEnabled = false;
      }

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Vui lòng bật GPS để xác định showroom gần nhất';
          _isRequestingLocation = false;
          _locationPermissionGranted = false;
        });
        return;
      }

      // Kiểm tra / xin quyền
      LocationPermission permission;
      try {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      } catch (_) {
        permission = LocationPermission.denied;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Không có quyền truy cập vị trí. Vui lòng cấp quyền trong cài đặt.';
          _isRequestingLocation = false;
          _locationPermissionGranted = false;
        });
        return;
      }

      // Đánh dấu đã có quyền (để bật myLocationEnabled an toàn)
      if (mounted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }

      // Lấy vị trí hiện tại
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        // Requirement: bắt buộc GPS realtime, không dùng lastKnown.
        if (!mounted) return;
        setState(() {
          _currentPosition = null;
          _isRequestingLocation = false;
          _locationError =
              'Không thể lấy vị trí GPS hiện tại. Vui lòng bật GPS và thử lại.';
          _locationPermissionGranted = false;
          _showrooms = [];
          _nearestShowrooms = [];
          _selectedShowroom = null;
          _markers = <Marker>{};
          _polylines = <Polyline>{};
          _routeOptions = [];
          _selectedRouteIndex = 0;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isRequestingLocation = false;
        _locationError = null;
      });

      await _loadNearbyShowroomsFromApi();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Lỗi xác định vị trí. Đang hiển thị bản đồ mặc định.';
        _isRequestingLocation = false;
        _locationPermissionGranted = false;
      });
    }
  }

  Future<void> _loadNearbyShowroomsFromApi() async {
    await _loadNearbyShowroomsFromApiInternal(forceRefresh: false);
  }

  Future<void> _loadNearbyShowroomsFromApiInternal({
    required bool forceRefresh,
  }) async {
    if (_currentPosition == null) return;
    if (!mounted) return;
    setState(() {
      _isLoadingShowrooms = true;
    });

    try {
      // Thử cache trước để tăng tốc
      if (!forceRefresh) {
        final cachedShowrooms = await _showroomApiService.fetchNearbyShowrooms(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusInMeters: 300000,
          limit: 40,
          forceRefresh: false,
          brand: widget.preferredBrand,
        );

        if (cachedShowrooms.isNotEmpty) {
          if (!mounted) return;
          // fetchNearbyShowrooms đã filter theo brand ở service.
          // Requirement: nếu không có showroom cho brand trong 300km => không hiển thị showroom khác hãng.
          _showrooms = cachedShowrooms;
          if (_showrooms.isEmpty) {
            setState(() {
              _nearestShowrooms = [];
              _selectedShowroom = null;
              _locationError =
                  'Không tìm thấy showroom ${widget.preferredBrand ?? ''} trong bán kính 300km từ vị trí GPS thật của bạn';
              _isLoadingShowrooms = false;
              _markers = _buildOnlyUserMarker();
              _polylines = <Polyline>{};
              _routeOptions = [];
              _selectedRouteIndex = 0;
            });
            return;
          }

          _locationError = null;
          _updateNearestShowrooms();
          _selectedShowroom = _nearestShowrooms.isNotEmpty
              ? _nearestShowrooms.first
              : null;
          _setShowroomMarkers();

          setState(() {
            _isLoadingShowrooms = false;
          });

          // Load route trong background
          _loadRouteToSelectedShowroom();
          _moveCameraToNearestShowroom();
          return;
        }
      }

      final apiShowrooms = await _showroomApiService.fetchNearbyShowrooms(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusInMeters: 300000, // 300km radius
        limit: 40,
        forceRefresh: forceRefresh,
        brand: widget.preferredBrand,
      );
      if (!mounted) return;
      if (apiShowrooms.isEmpty) {
        setState(() {
          _showrooms = [];
          _nearestShowrooms = [];
          _selectedShowroom = null;
          _locationError =
              'Không tìm thấy showroom ${widget.preferredBrand ?? ''} trong bán kính 300km từ vị trí GPS thật của bạn';
          _isLoadingShowrooms = false;
          _markers = _buildOnlyUserMarker();
          _polylines = <Polyline>{};
          _routeOptions = [];
          _selectedRouteIndex = 0;
        });
        return;
      }

      // fetchNearbyShowrooms đã filter theo brand ở service.
      // Requirement: không fallback sang hãng khác.
      _showrooms = apiShowrooms;
      _locationError = null;
      _updateNearestShowrooms();
      _selectedShowroom = _nearestShowrooms.isNotEmpty
          ? _nearestShowrooms.first
          : null;
      _setShowroomMarkers();
      await _loadRouteToSelectedShowroom();
      await _moveCameraToNearestShowroom();

      if (!mounted) return;
      setState(() {
        _isLoadingShowrooms = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingShowrooms = false;
        _locationError =
            'Lỗi kết nối OpenStreetMap API. Vui lòng kiểm tra mạng và thử lại.';
        _markers = _buildOnlyUserMarker();
      });
    }
  }

  Future<void> _refreshShowrooms() async {
    if (_isLoadingShowrooms || _isLoadingRoute) return;
    if (!mounted) return;
    setState(() {
      _locationError = null;
    });

    try {
      final latestPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = latestPosition;
      });
    } catch (_) {
      // Giữ vị trí hiện tại nếu không lấy được GPS mới.
    }

    await _loadNearbyShowroomsFromApiInternal(forceRefresh: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã làm mới showroom gần bạn'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _setShowroomMarkers() {
    final selected = _effectiveShowroom();
    final markers = _showrooms.map((showroom) {
      return Marker(
        markerId: MarkerId(
          '${showroom['name']}_${showroom['lat']}_${showroom['lng']}',
        ),
        position: LatLng(showroom['lat'] as double, showroom['lng'] as double),
        infoWindow: InfoWindow(
          title: showroom['name'] as String,
          snippet: showroom['address'] as String,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected != null && selected['name'] == showroom['name']
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueOrange,
        ),
      );
    }).toSet();

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Set<Marker> _buildOnlyUserMarker() {
    final markers = <Marker>{};
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  void _updateNearestShowrooms() {
    if (_currentPosition == null || _showrooms.isEmpty) return;

    final sorted =
        _showrooms.map((showroom) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            showroom['lat'] as double,
            showroom['lng'] as double,
          );
          return {'showroom': showroom, 'distance': distance};
        }).toList()..sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );

    _nearestShowrooms = sorted
        .take(3)
        .map((e) => e['showroom'] as Map<String, dynamic>)
        .toList();
  }

  Map<String, dynamic>? _findNearestShowroomByPosition() {
    if (_nearestShowrooms.isNotEmpty) return _nearestShowrooms.first;
    if (_showrooms.isNotEmpty && _currentPosition != null) {
      return _showrooms.first;
    }
    return null;
  }

  Map<String, dynamic>? _effectiveShowroom() {
    return _selectedShowroom ??
        widget.selectedShowroom ??
        _findNearestShowroomByPosition();
  }

  Future<void> _moveCameraToNearestShowroom() async {
    final target = _effectiveShowroom();
    if (target == null || !_controller.isCompleted) return;

    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(target['lat'] as double, target['lng'] as double),
        13.5,
      ),
    );
  }

  Future<void> _focusShowroom(Map<String, dynamic> showroom) async {
    setState(() {
      _selectedShowroom = showroom;
    });
    _setShowroomMarkers();
    await _loadRouteToSelectedShowroom();
    await _moveCameraToNearestShowroom();
  }

  Future<void> _loadRouteToSelectedShowroom() async {
    final target = _effectiveShowroom();
    if (_currentPosition == null || target == null) return;

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = true;
    });

    final routes = await _routingApiService.getRoutes(
      origin: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      destination: LatLng(target['lat'] as double, target['lng'] as double),
    );

    if (!mounted) return;
    if (routes == null || routes.isEmpty) {
      setState(() {
        _isLoadingRoute = false;
        _routeOptions = [];
        _selectedRouteIndex = 0;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('fallback_route'),
            points: [
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              LatLng(target['lat'] as double, target['lng'] as double),
            ],
            color: const Color(0xFF4285F4),
            width: 5,
            geodesic: true,
          ),
        };
      });
      await _fitCameraToRoute([
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(target['lat'] as double, target['lng'] as double),
      ]);
      return;
    }

    setState(() {
      _isLoadingRoute = false;
      _routeOptions = routes;
      _selectedRouteIndex = 0;
      _polylines = _buildPolylinesForRoutes(routes, _selectedRouteIndex);
    });

    final allPoints = <LatLng>[];
    for (final r in routes) {
      allPoints.addAll(r['points'] as List<LatLng>);
    }
    await _fitCameraToRoute(allPoints);
  }

  /// Tuyến đang chọn: xanh đậm (Google), các tuyến khác: xám mỏng.
  Set<Polyline> _buildPolylinesForRoutes(
    List<Map<String, dynamic>> routes,
    int selectedIndex,
  ) {
    const primaryBlue = Color(0xFF4285F4);
    const altGray = Color(0xFF9E9E9E);

    final set = <Polyline>{};
    for (var i = 0; i < routes.length; i++) {
      final points = routes[i]['points'] as List<LatLng>;
      final isSelected = i == selectedIndex;
      set.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: points,
          color: isSelected ? primaryBlue : altGray,
          width: isSelected ? 7 : 4,
          zIndex: isSelected ? 2 : 1,
        ),
      );
    }
    return set;
  }

  void _selectRouteIndex(int index) {
    if (index < 0 || index >= _routeOptions.length) return;
    setState(() {
      _selectedRouteIndex = index;
      _polylines = _buildPolylinesForRoutes(_routeOptions, _selectedRouteIndex);
    });
  }

  Future<void> _fitCameraToRoute(List<LatLng> points) async {
    if (points.isEmpty || !_controller.isCompleted) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  /// Mở Google Maps để chỉ đường từ vị trí hiện tại đến showroom.
  Future<void> _openGoogleMapsDirection(Map<String, dynamic> showroom) async {
    final lat = showroom['lat'];
    final lng = showroom['lng'];
    final name = Uri.encodeComponent(showroom['name'] as String? ?? '');

    // Thử mở Google Maps app trước, nếu không có thì mở trên browser
    final googleMapsUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');

    // URL web fallback
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
      '&destination_place_id=$name'
      '&travelmode=driving',
    );

    bool launched = false;

    // Thử mở Google Maps app trực tiếp
    if (await canLaunchUrl(googleMapsUri)) {
      launched = await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    }

    // Nếu không mở được app thì mở trên browser
    if (!launched) {
      launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps')),
      );
    }
  }

  Future<void> _callShowroom(Map<String, dynamic> showroom) async {
    final phone = showroom['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có số điện thoại showroom này')),
        );
      }
      return;
    }

    final telUri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(telUri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thực hiện được cuộc gọi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _effectiveShowroom();
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : (target != null
              ? LatLng(target['lat'] as double, target['lng'] as double)
              : _defaultPosition);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text(
          'Showroom gần nhất',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          if (_isLoadingShowrooms || _isLoadingRoute)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Làm mới showroom',
            onPressed: (_isLoadingShowrooms || _isLoadingRoute)
                ? null
                : _refreshShowrooms,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Google Map (luôn hiển thị) ──────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 13,
            ),
            mapType: MapType.normal,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
              if (!mounted) return;
              // Di chuyển camera khi map đã sẵn sàng
              Future.delayed(const Duration(milliseconds: 300), () {
                _moveCameraToNearestShowroom();
              });
            },
          ),

          // ── Loading indicator vị trí ────────────────────────────────
          if (_isRequestingLocation)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    color: Color(0xFF4285F4),
                  ),
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Đang xác định vị trí...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Loading showrooms ───────────────────────────────────────
          if (_isLoadingShowrooms && !_isRequestingLocation)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.transparent,
                color: Color(0xFF0F9D58),
              ),
            ),

          // ── Loading route ───────────────────────────────────────────
          if (_isLoadingRoute)
            const Positioned(
              top: 3,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: Color(0xFFFBBC05),
              ),
            ),

          // ── Thông báo lỗi ──────────────────────────────────────────
          if (_locationError != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationError!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _locationError = null),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Các tuyến đường (route options) ────────────────────────
          if (_routeOptions.isNotEmpty)
            Positioned(
              top: (_locationError != null) ? 80 : 16,
              left: 8,
              right: 8,
              child: SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _routeOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final r = _routeOptions[index];
                    final distanceMeters = r['distanceMeters'] as double;
                    final durationSeconds = r['durationSeconds'] as double;
                    final selected = index == _selectedRouteIndex;
                    return Material(
                      elevation: selected ? 6 : 2,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _selectRouteIndex(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 136,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF4285F4)
                                  : Colors.black12,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 16,
                                    color: selected
                                        ? const Color(0xFF0F9D58)
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formatDuration(durationSeconds),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: selected
                                            ? const Color(0xFF0F9D58)
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDistance(distanceMeters),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (selected)
                                const Text(
                                  '✓ Tuyến được chọn',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF4285F4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Danh sách showroom gần nhất ─────────────────────────────
          if (_nearestShowrooms.length > 1)
            Positioned(
              left: 12,
              right: 12,
              bottom: target != null ? 216 : 24,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cửa hàng gần bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._nearestShowrooms.take(3).map((showroom) {
                      final isSelected =
                          _effectiveShowroom()?['name'] == showroom['name'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _focusShowroom(showroom),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFF3B82C8,
                                    ).withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3B82C8)
                                    : Colors.white24,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.store_mall_directory,
                                  color: isSelected
                                      ? const Color(0xFF4285F4)
                                      : Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${showroom['brand'] ?? 'Hãng xe'} — ${showroom['name']}'
                                    ' (${_distanceText(showroom)})',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4285F4),
                                    size: 14,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // ── Popup thông tin showroom được chọn ──────────────────────
          if (target != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D1A).withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tên showroom
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF4285F4),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            target['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Địa chỉ
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        target['address'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hãng xe + khoảng cách
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Row(
                        children: [
                          Text(
                            'Hãng: ${target['brand'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          if (_currentPosition != null) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.straighten,
                              color: Color(0xFF4FC3F7),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _distanceText(target),
                              style: const TextStyle(
                                color: Color(0xFF4FC3F7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Nút hành động
                    Row(
                      children: [
                        // Nút Chỉ đường (mở Google Maps app)
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () => _openGoogleMapsDirection(target),
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text(
                              'Chỉ đường',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nút Gọi điện
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () => _callShowroom(target),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('Gọi'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4FC3F7),
                              side: const BorderSide(color: Color(0xFF4FC3F7)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Nút chọn showroom này
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _selectShowroom(target),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text(
                          'Chọn showroom này',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Nút định vị lại ─────────────────────────────────────────
          Positioned(
            top: (_locationError != null) ? 80 : 16,
            right: 16,
            child: Column(
              children: [
                // Chỉ hiện khi không có route options (route options đã ở top)
                if (_routeOptions.isEmpty)
                  FloatingActionButton.small(
                    heroTag: 'recenter_map',
                    backgroundColor: const Color(0xFF1A1A2E),
                    onPressed: () async {
                      await _moveCameraToNearestShowroom();
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                if (_routeOptions.isNotEmpty) ...[
                  const SizedBox(height: 90),
                  FloatingActionButton.small(
                    heroTag: 'recenter_map2',
                    backgroundColor: const Color(0xFF1A1A2E),
                    onPressed: () async {
                      if (_routeOptions.isNotEmpty) {
                        final allPoints = <LatLng>[];
                        for (final r in _routeOptions) {
                          allPoints.addAll(r['points'] as List<LatLng>);
                        }
                        await _fitCameraToRoute(allPoints);
                      } else {
                        await _moveCameraToNearestShowroom();
                      }
                    },
                    child: const Icon(Icons.fit_screen, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),

          // ── Thông báo khi không có showroom ────────────────────────
          if (!_isRequestingLocation &&
              !_isLoadingShowrooms &&
              _showrooms.isEmpty &&
              _locationError == null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store_outlined, color: Colors.white54, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Không có showroom trong khu vực',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _distanceText(Map<String, dynamic> showroom) {
    if (_currentPosition == null) return '--';
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      showroom['lat'] as double,
      showroom['lng'] as double,
    );
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '$hours giờ $minutes phút';
    return '$minutes phút';
  }

  /// Chọn showroom và trả về thông tin cho màn hình trước
  void _selectShowroom(Map<String, dynamic> showroom) {
    final lat = showroom['lat'] as double;
    final lng = showroom['lng'] as double;
    final name = showroom['name'] as String? ?? '';
    final brand = showroom['brand'] as String? ?? '';

    // Tạo Google Maps URL
    final googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    // Tạo địa chỉ fallback nếu address trống hoặc là placeholder
    String address = showroom['address'] as String? ?? '';
    if (address.isEmpty ||
        address.toLowerCase().contains('đang cập nhật') ||
        address.toLowerCase().contains('vị trí showroom')) {
      // Tạo địa chỉ từ tên và brand
      if (name.isNotEmpty && brand.isNotEmpty) {
        address = '$name - $brand Showroom';
      } else if (name.isNotEmpty) {
        address = '$name';
      } else {
        address = 'Showroom $brand';
      }

      // Thêm tọa độ làm reference
      address += ' (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    }

    // Cập nhật showroom data với địa chỉ được cải thiện
    final updatedShowroom = Map<String, dynamic>.from(showroom);
    updatedShowroom['address'] = address;

    // Trả về thông tin showroom kèm URL
    Navigator.pop(context, {
      'showroom': updatedShowroom,
      'googleMapsUrl': googleMapsUrl,
    });
  }
}
