import 'package:flutter/material.dart';

import '../data/firebase_helper.dart';
import '../services/garage_service.dart';
import '../widgets/floating_car_bottom_nav.dart';

class MyCarScreen extends StatefulWidget {
  const MyCarScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<MyCarScreen> createState() => _MyCarScreenState();
}

class _MyCarScreenState extends State<MyCarScreen> {
  static const _bgTop = Color(0xFF070A12);
  static const _bgBottom = Color(0xFF050511);

  static const _cardSurface = Color(0xFF14161B);

  int _activeNavIndex = 2;

  String? get _normalizedPhone {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    return FirebaseHelper.normalizePhone(phone);
  }

  @override
  void initState() {
    super.initState();

    final userId = _normalizedPhone;
    if (userId != null) {
      // Seed 1 xe mẫu cho tài khoản mới (chỉ chạy khi garage chưa có xe).
      // ignore: discarded_futures
      GarageService.ensureSeedVehicleForUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _normalizedPhone;

    return Scaffold(
      backgroundColor: _bgBottom,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: userId == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildMemberStatusCard(),
                    const SizedBox(height: 18),
                    const Text(
                      'Bạn cần đăng nhập để xem Garage.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: GarageService.streamVehicles(userId),
                  builder: (context, snapshot) {
                    final vehicles =
                        snapshot.data ?? const <Map<String, dynamic>>[];

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildMemberStatusCard(),
                        const SizedBox(height: 16),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            vehicles.isEmpty) ...[
                          const SizedBox(height: 18),
                          const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2F6FED),
                            ),
                          ),
                        ] else if (vehicles.isEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Chưa có xe nào trong Garage.\nBạn có thể thêm xe trực tiếp trên Firestore vào users/{userId}/garageVehicles.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ] else ...[
                          for (final v in vehicles) ...[
                            _GarageVehicleCard(vehicle: v),
                            const SizedBox(height: 16),
                          ],
                        ],
                        const SizedBox(height: 6),
                        _buildAddNewVehicleCard(),
                        const SizedBox(height: 90),
                      ],
                    );
                  },
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'My Garage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Curated Collection',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMemberStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82C8), Color(0xFF1E5A9E)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.badge_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEMBER STATUS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Elite Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildAddNewVehicleCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.add, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add New Vehicle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Register a new LuxeDrive compatible car',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return FloatingCarBottomNav(
      currentIndex: _activeNavIndex,
      onTap: (index) {
        if (_activeNavIndex == index) return;
        setState(() => _activeNavIndex = index);

        Future.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          final phoneArg = _normalizedPhone;

          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: phoneArg,
            );
          } else if (index == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/newcar',
              arguments: phoneArg,
            );
          } else if (index == 2) {
            // already on MyCar
          } else if (index == 3) {
            Navigator.pushReplacementNamed(
              context,
              '/favorite',
              arguments: phoneArg,
            );
          } else if (index == 4) {
            Navigator.pushReplacementNamed(
              context,
              '/profile',
              arguments: phoneArg,
            );
          }
        });
      },
    );
  }
}

class _GarageVehicleCard extends StatelessWidget {
  const _GarageVehicleCard({required this.vehicle});

  final Map<String, dynamic> vehicle;

  static const _surface = Color(0xFF121316);

  @override
  Widget build(BuildContext context) {
    final status = (vehicle['status'] ?? '').toString();
    final name = (vehicle['name'] ?? '').toString();
    final subtitle = (vehicle['subtitle'] ?? '').toString();
    final imageUrl = (vehicle['imageUrl'] ?? '').toString();

    final odometerLabel = (vehicle['odometerLabel'] ?? 'ODOMETER').toString();
    final odometerValue = (vehicle['odometerValue'] ?? '').toString();
    final fuelLabel = (vehicle['fuelLabel'] ?? '').toString();
    final fuelValue = (vehicle['fuelValue'] ?? '').toString();

    final statusColor = status.toUpperCase().contains('ACTIVE')
        ? const Color(0xFF2F6FED)
        : const Color(0xFF7C6CFF);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.92,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.80),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.mode_edit_outline_rounded,
                  color: statusColor.withValues(alpha: 0.9),
                  size: 16,
                ),
              ],
            ),
          ),
          if (subtitle.isNotEmpty) const SizedBox(height: 2),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.speed_rounded,
                    label: odometerLabel,
                    value: odometerValue,
                    accent: const Color(0xFF2F6FED),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: fuelLabel.toUpperCase().contains('SERVICE')
                        ? Icons.build_rounded
                        : Icons.local_gas_station_rounded,
                    label: fuelLabel,
                    value: fuelValue,
                    accent: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1116),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: accent.withValues(alpha: 0.95)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
