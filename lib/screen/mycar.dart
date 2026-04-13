import 'package:flutter/material.dart';

import '../data/firebase_helper.dart';
import '../services/garage_service.dart';
import '../screen/elite_members.dart';
import '../widgets/floating_car_bottom_nav.dart';
import '../widgets/scrollview_animation.dart';

class MyCarScreen extends StatefulWidget {
  const MyCarScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<MyCarScreen> createState() => _MyCarScreenState();
}

class _MyCarScreenState extends State<MyCarScreen> {
  static const _cardSurface = Color(0xFF14161B);
  static const List<Color> _showroomGradient = <Color>[
    Color(0xFF545454),
    Color(0xFF3A3A3A),
    Color(0xFF252525),
    Color(0xFF171717),
  ];

  static const LinearGradient _showroomBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _showroomGradient,
    stops: [0.0, 0.35, 0.75, 1.0],
  );

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

    return Container(
      decoration: const BoxDecoration(gradient: _showroomBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          child: userId == null
              ? ScrollViewAnimation.children(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
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

                    return ScrollViewAnimation.children(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
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
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Text(
          'Xe của tôi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 2),
      ],
    );
  }

  Widget _buildMemberStatusCard() {
    final phoneArg = widget.phoneNumber;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            EliteMembersScreen.routeName,
            arguments: phoneArg,
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF10131B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.workspace_premium_rounded, color: Color(0xFF2F6FED)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TRẠNG THÁI THÀNH VIÊN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewVehicleCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final phoneArg = _normalizedPhone;
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: phoneArg,
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
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
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return FloatingCarBottomNav(
      currentIndex: _activeNavIndex,
      onTap: (index) {
        if (_activeNavIndex == index) return;
        setState(() => _activeNavIndex = index);

        // Nếu đang ở admin, chỉ đổi tab, không điều hướng
        final isAdmin = ModalRoute.of(context)?.settings.name == '/admin';
        if (isAdmin) return;

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
    final statusText = _statusToVi(status);
    final name = (vehicle['name'] ?? '').toString();
    final subtitle = (vehicle['subtitle'] ?? '').toString();
    final imageUrl = (vehicle['imageUrl'] ?? '').toString();

    final odometerLabel = (vehicle['odometerLabel'] ?? 'ODOMETER').toString();
    final odometerValue = (vehicle['odometerValue'] ?? '').toString();
    final fuelLabel = (vehicle['fuelLabel'] ?? '').toString();
    final fuelValue = (vehicle['fuelValue'] ?? '').toString();

    final statusColor = status.toUpperCase().contains('ACTIVE')
        ? const Color(0xFF2F6FED)
        : status.toUpperCase().contains('ORDERED')
        ? const Color(0xFFFF9800)
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
                    child: imageUrl.startsWith('assets/')
                        ? Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg',
                                  fit: BoxFit.cover,
                                ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg',
                                  fit: BoxFit.cover,
                                ),
                          ),
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
                      // Tăng độ tương phản để nhìn rõ trạng thái
                      color: statusColor.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.98),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.98),
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
                const SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  color: const Color(0xFF2F6FED),
                  size: 18,
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

  static String _statusToVi(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return 'KHÔNG RÕ';

    // Handle common combined states like: "order active", "ordered active"...
    final hasActive = s.contains('active');
    final hasOrdered = s.contains('ordered') || s.contains('order');

    if (hasOrdered && hasActive) return 'ĐÃ ĐẶT (ĐANG HIỆU LỰC)';
    if (hasActive) return 'ĐANG HOẠT ĐỘNG';
    if (hasOrdered) return 'ĐÃ ĐẶT';

    if (s.contains('pending')) return 'ĐANG CHỜ';
    if (s.contains('expired')) return 'HẾT HẠN';
    if (s.contains('cancelled') || s.contains('canceled')) return 'ĐÃ HỦY';

    // Fallback: giữ nguyên nhưng viết hoa để giống pill cũ
    return raw.toUpperCase();
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
