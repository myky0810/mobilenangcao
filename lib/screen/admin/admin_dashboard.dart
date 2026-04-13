import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import 'widgets/admin_ui.dart';

class AdminDashboard extends StatefulWidget {
  final String? phoneNumber;
  final UserModel? adminUser;

  const AdminDashboard({super.key, this.phoneNumber, this.adminUser});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accentBlue = Color(0xFF00A8FF);
  static const Color _accentGreen = Color(0xFF00FF88);
  static const Color _accentOrange = Color(0xFFFF9500);
  static const Color _accentPink = Color(0xFFFF5FA2);

  int _refreshSeed = 0;

  Future<int> _countCollection(String collection) async {
    final value = await FirebaseFirestore.instance
        .collection(collection)
        .count()
        .get();
    return value.count ?? 0;
  }

  Future<int> _countWhere(
    String collection,
    String field,
    String expected,
  ) async {
    final value = await FirebaseFirestore.instance
        .collection(collection)
        .where(field, isEqualTo: expected)
        .count()
        .get();
    return value.count ?? 0;
  }

  Future<double> _sumConfirmedDeposits() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('deposits')
        .where('depositStatus', isEqualTo: 'confirmed')
        .get();

    var total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final raw = data['depositAmount'];
      if (raw is num) {
        total += raw.toDouble();
      }
    }
    return total;
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    try {
      final values = await Future.wait<dynamic>([
        _countCollection('users'),
        _countCollection('products'),
        _countCollection('deposits'),
        _countCollection('test_drive_bookings'),
        _countCollection('warranties'),
        _countCollection('notifications'),
        _countWhere('deposits', 'depositStatus', 'pending'),
        _countWhere('test_drive_bookings', 'status', 'pending'),
        _sumConfirmedDeposits(),
      ]);

      return {
        'users': values[0] as int,
        'products': values[1] as int,
        'deposits': values[2] as int,
        'bookings': values[3] as int,
        'warranties': values[4] as int,
        'notifications': values[5] as int,
        'pendingDeposits': values[6] as int,
        'pendingBookings': values[7] as int,
        'totalDepositsAmount': values[8] as double,
        'loadedAt': DateTime.now(),
      };
    } catch (_) {
      return {
        'users': 0,
        'products': 0,
        'deposits': 0,
        'bookings': 0,
        'warranties': 0,
        'notifications': 0,
        'pendingDeposits': 0,
        'pendingBookings': 0,
        'totalDepositsAmount': 0.0,
        'loadedAt': DateTime.now(),
      };
    }
  }

  List<_DashboardMetric> _buildSystemMetrics(Map<String, dynamic> stats) {
    return [
      _DashboardMetric(
        label: 'Người dùng',
        value: (stats['users'] as int? ?? 0).toDouble(),
        color: _accentBlue,
      ),
      _DashboardMetric(
        label: 'Sản phẩm',
        value: (stats['products'] as int? ?? 0).toDouble(),
        color: _accentGreen,
      ),
      _DashboardMetric(
        label: 'Đặt cọc',
        value: (stats['deposits'] as int? ?? 0).toDouble(),
        color: _accentOrange,
      ),
      _DashboardMetric(
        label: 'Lái thử',
        value: (stats['bookings'] as int? ?? 0).toDouble(),
        color: _accentPink,
      ),
      _DashboardMetric(
        label: 'Bảo hành',
        value: (stats['warranties'] as int? ?? 0).toDouble(),
        color: Colors.purpleAccent,
      ),
      _DashboardMetric(
        label: 'Thông báo',
        value: (stats['notifications'] as int? ?? 0).toDouble(),
        color: Colors.cyanAccent,
      ),
    ];
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<_DashboardMetric> metrics) {
    final maxValue = metrics.fold<double>(
      0,
      (p, e) => e.value > p ? e.value : p,
    );
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biểu đồ phân bổ hệ thống',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...metrics.map((metric) {
            final ratio = (metric.value / safeMax).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        metric.label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        metric.value.toInt().toString(),
                        style: TextStyle(
                          color: metric.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(metric.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPendingSection(Map<String, dynamic> stats) {
    final pendingDeposits = stats['pendingDeposits'] as int? ?? 0;
    final pendingBookings = stats['pendingBookings'] as int? ?? 0;
    final deposits = stats['deposits'] as int? ?? 0;
    final bookings = stats['bookings'] as int? ?? 0;

    final depositRatio = deposits == 0 ? 0.0 : pendingDeposits / deposits;
    final bookingRatio = bookings == 0 ? 0.0 : pendingBookings / bookings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khối lượng cần xử lý',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildPendingRow(
            title: 'Đặt cọc chờ duyệt',
            pendingCount: pendingDeposits,
            totalCount: deposits,
            ratio: depositRatio,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 10),
          _buildPendingRow(
            title: 'Lái thử chờ duyệt',
            pendingCount: pendingBookings,
            totalCount: bookings,
            ratio: bookingRatio,
            color: Colors.lightBlueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRow({
    required String title,
    required int pendingCount,
    required int totalCount,
    required double ratio,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '$pendingCount/$totalCount',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(double totalAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            _accentGreen.withValues(alpha: 0.22),
            _accentBlue.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _accentGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doanh thu từ cọc đã xác nhận',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: '₫',
            ).format(totalAmount),
            style: GoogleFonts.leagueSpartan(
              color: _accentGreen,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _showroomBase,
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshSeed),
        future: _loadDashboardStats(),
        builder: (context, snapshot) {
          final stats =
              snapshot.data ??
              <String, dynamic>{
                'users': 0,
                'products': 0,
                'deposits': 0,
                'bookings': 0,
                'warranties': 0,
                'notifications': 0,
                'pendingDeposits': 0,
                'pendingBookings': 0,
                'totalDepositsAmount': 0.0,
                'loadedAt': DateTime.now(),
              };
          final loadedAt = (stats['loadedAt'] as DateTime?) ?? DateTime.now();
          final metrics = _buildSystemMetrics(stats);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _refreshSeed++);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tổng quan hệ thống',
                        style: kAdminHeaderTitleStyle,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _refreshSeed++),
                      style: adminOutlineButtonStyle(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Làm mới'),
                    ),
                  ],
                ),
                Text(
                  'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(loadedAt)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSummaryCard(
                      title: 'Người dùng',
                      value: (stats['users'] ?? 0).toString(),
                      icon: Icons.people_rounded,
                      color: _accentBlue,
                    ),
                    _buildSummaryCard(
                      title: 'Sản phẩm',
                      value: (stats['products'] ?? 0).toString(),
                      icon: Icons.directions_car_rounded,
                      color: _accentGreen,
                    ),
                    _buildSummaryCard(
                      title: 'Đặt cọc',
                      value: (stats['deposits'] ?? 0).toString(),
                      icon: Icons.receipt_long_rounded,
                      color: _accentOrange,
                    ),
                    _buildSummaryCard(
                      title: 'Lái thử',
                      value: (stats['bookings'] ?? 0).toString(),
                      icon: Icons.calendar_month_rounded,
                      color: _accentPink,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildBarChart(metrics),
                const SizedBox(height: 14),
                _buildPendingSection(stats),
                const SizedBox(height: 14),
                _buildRevenueCard(
                  (stats['totalDepositsAmount'] as double?) ?? 0.0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardMetric {
  final String label;
  final double value;
  final Color color;

  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.color,
  });
}
