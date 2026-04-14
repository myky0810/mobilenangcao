import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/admin_ui.dart';

class AdminTestDriveBookingsScreen extends StatefulWidget {
  const AdminTestDriveBookingsScreen({super.key});

  @override
  State<AdminTestDriveBookingsScreen> createState() =>
      _AdminTestDriveBookingsScreenState();
}

class _AdminTestDriveBookingsScreenState
    extends State<AdminTestDriveBookingsScreen> {
  static const Color _bg = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFFFF5FA2);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFEF4444);

  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('test_drive_bookings');

  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  String _searchQuery = '';

  static const List<String> _statusFilters = [
    'all',
    'pending',
    'confirmed',
    'cancelled',
    'completed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          const AdminPageHeader(title: 'Quản lý lịch lái thử'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo xe, khách hàng, SĐT, email...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close, color: Colors.white54),
                          )
                        : null,
                    filled: true,
                    fillColor: _card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusFilters.map((status) {
                    final isSelected = _filterStatus == status;
                    return adminFilterChip(
                      label: _statusLabel(status),
                      selected: isSelected,
                      selectedColor: kAdminPrimary,
                      unselectedColor: _card,
                      onTap: () => setState(() => _filterStatus = status),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ref.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không thể tải lịch lái thử: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final bookings = (snapshot.data?.docs ?? [])
                    .map((doc) => {'docId': doc.id, ...doc.data()})
                    .toList();

                final filtered = bookings.where(_matches).toList()
                  ..sort((a, b) {
                    final at = _sortableDate(b['createdAt'] ?? b['updatedAt']);
                    final bt = _sortableDate(a['createdAt'] ?? a['updatedAt']);
                    return at.compareTo(bt);
                  });

                if (filtered.isEmpty) {
                  return _buildEmptyState('Không có lịch lái thử phù hợp');
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildCard(filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(Map<String, dynamic> booking) {
    final status = _normalizeStatus(booking['status']);
    if (_filterStatus != 'all' && status != _filterStatus) return false;

    if (_searchQuery.isEmpty) return true;

    String s(Object? v) => (v ?? '').toString().toLowerCase().trim();

    final haystack = [
      s(booking['carName']),
      s(booking['carBrand']),
      s(booking['name']),
      s(booking['phone']),
      s(booking['email']),
      s(booking['userPhone']),
      s(booking['showroomName']),
      s(booking['showroomAddress']),
      s(booking['docId']),
    ].join(' ');

    return haystack.contains(_searchQuery);
  }

  String _normalizeStatus(Object? raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    if (value.isEmpty) return 'pending';
    if (value == 'canceled') return 'cancelled';
    return value;
  }

  DateTime _sortableDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return _success;
      case 'pending':
        return _accent;
      case 'cancelled':
        return _danger;
      case 'completed':
        return const Color(0xFF38BDF8);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'all':
        return 'Tất cả';
      case 'pending':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã huỷ';
      case 'completed':
        return 'Hoàn tất';
      default:
        return status;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.event_note, color: Colors.white24, size: 64),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.leagueSpartan(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> booking) {
    final status = _normalizeStatus(booking['status']);
    final color = _statusColor(status);

    final carName = (booking['carName'] ?? 'Không xác định').toString();
    final userName = (booking['name'] ?? 'Không rõ').toString();
    final userPhone = (booking['phone'] ?? booking['userPhone'] ?? '').toString();
    final showroom = (booking['showroomName'] ?? '').toString();
    final date = (booking['date'] ?? '').toString();
    final time = (booking['time'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  carName,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$userName • $userPhone',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (date.isNotEmpty || time.isNotEmpty)
            Text(
              '$date ${time.isNotEmpty ? '• $time' : ''}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          if (showroom.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Showroom: $showroom',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
