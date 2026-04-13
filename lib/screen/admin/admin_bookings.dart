import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFFFF9500);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFEF4444);

  final CollectionReference<Map<String, dynamic>> _bookingsRef =
      FirebaseFirestore.instance.collection('bookings');
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'all';
  String _searchQuery = '';
  bool _isMigrating = false;

  static const List<String> _statusFilters = [
    'all',
    'pending',
    'confirmed',
    'cancelled',
    'completed',
  ];

  static const List<String> _statusOptions = [
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
      backgroundColor: _showroomBase,
      body: Column(
        children: [
          AdminPageHeader(
            title: 'Quản lý lịch đăng ký lái xe',
            actions: [
              OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigrateBookings,
                style: adminOutlineButtonStyle(),
                icon: _isMigrating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_alt_rounded, size: 16),
                label: const Text('Chuẩn hóa'),
              ),
            ],
          ),
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
                    hintText:
                        'Tìm theo xe, khách hàng, SĐT, email, mã booking...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
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
              stream: _bookingsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không thể tải lịch đặt cọc: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final bookings = (snapshot.data?.docs ?? [])
                    .map((doc) => {'docId': doc.id, ...doc.data()})
                    .toList();

                final filteredBookings =
                    bookings.where(_matchesBooking).toList()..sort(
                      (a, b) =>
                          _sortableDate(
                            b['createdAt'] ?? b['paidAt'] ?? b['updatedAt'],
                          ).compareTo(
                            _sortableDate(
                              a['createdAt'] ?? a['paidAt'] ?? a['updatedAt'],
                            ),
                          ),
                    );

                final stats = _computeStats(bookings);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsSection(stats),
                        const SizedBox(height: 10),
                        Text(
                          'Hiển thị ${filteredBookings.length}/${bookings.length} lịch đăng ký',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filteredBookings.isEmpty)
                          _buildEmptyState('Không có lịch đăng ký phù hợp')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredBookings.length,
                            itemBuilder: (context, index) {
                              return _buildBookingCard(filteredBookings[index]);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatCard(
          title: 'Tổng lịch',
          value: '${stats['totalCount']}',
          color: const Color(0xFF60A5FA),
        ),
        _buildStatCard(
          title: 'Đang chờ xử lý',
          value: '${stats['pendingCount']}',
          color: _accent,
        ),
        _buildStatCard(
          title: 'Đã xác nhận',
          value: '${stats['confirmedCount']}',
          color: _success,
        ),
        _buildStatCard(
          title: 'Hôm nay',
          value:
              '${stats['todayCount']} lịch | ${_formatCurrency(stats['todayRevenue'] as double)}',
          color: const Color(0xFF38BDF8),
          fullWidth: true,
        ),
        _buildStatCard(
          title: 'Tháng này',
          value:
              '${stats['monthCount']} lịch | ${_formatCurrency(stats['monthRevenue'] as double)}',
          color: const Color(0xFF22D3EE),
          fullWidth: true,
        ),
        _buildStatCard(
          title: 'Năm nay',
          value:
              '${stats['yearCount']} lịch | ${_formatCurrency(stats['yearRevenue'] as double)}',
          color: const Color(0xFF4ADE80),
          fullWidth: true,
        ),
      ],
    );
  }

  Future<void> _runMigrateBookings() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa lịch đặt xong: quét ${result['scanned']}, cập nhật ${result['updated']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuẩn hóa lịch đặt thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = fullWidth ? width - 32 : (width - 42) / 2;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.leagueSpartan(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = _normalizeStatus(booking['status']);
    final carName = (booking['carName'] ?? 'Không xác định').toString();
    final userName = _bookingCustomerName(booking);
    final docId = (booking['docId'] ?? '').toString();
    final bookingId = (booking['bookingId'] ?? docId).toString();
    final bookingDate = _extractDate(
      booking['createdAt'] ?? booking['paidAt'] ?? booking['updatedAt'],
    );
    final depositAmount = _toDouble(
      booking['depositAmount'] ?? booking['amount'] ?? 0,
    );

    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = _success;
        break;
      case 'pending':
        statusColor = _accent;
        break;
      case 'cancelled':
        statusColor = _danger;
        break;
      case 'completed':
        statusColor = const Color(0xFF38BDF8);
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carName,
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Mã booking: $bookingId',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Tiền cọc: ${_formatCurrency(depositAmount)}',
            style: const TextStyle(color: _accent, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Ngày tạo: ${_formatDateTime(bookingDate)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showBookingDetails(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent.withValues(alpha: 0.2),
                    foregroundColor: _accent,
                  ),
                  child: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PopupMenuButton<String>(
                  color: _card,
                  onSelected: (newStatus) {
                    if (newStatus == status) return;
                    _updateBookingStatus(docId, newStatus);
                  },
                  itemBuilder: (context) {
                    return _statusOptions
                        .map(
                          (item) => PopupMenuItem<String>(
                            value: item,
                            child: Text(
                              _statusLabel(item),
                              style: TextStyle(
                                color: item == status ? _accent : Colors.white,
                                fontWeight: item == status
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        )
                        .toList();
                  },
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Đổi trạng thái',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    final bookingDate = _extractDate(
      booking['createdAt'] ?? booking['paidAt'] ?? booking['updatedAt'],
    );
    final paidDate = _extractDate(booking['paidAt']);
    final expiryDate = _extractDate(booking['expiryDate']);

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Chi tiết booking',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Document ID',
                    (booking['docId'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Booking ID',
                    (booking['bookingId'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Trạng thái',
                    _statusLabel(_normalizeStatus(booking['status'])),
                  ),
                  _buildDetailRow(
                    'Trạng thái thanh toán',
                    (booking['paymentStatus'] ?? '').toString(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thông tin xe',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow('Xe', (booking['carName'] ?? '').toString()),
                  _buildDetailRow(
                    'Hãng',
                    (booking['carBrand'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Giá xe',
                    (booking['carPrice'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Tổng tiền',
                    (booking['totalPrice'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Tiền cọc',
                    _formatCurrency(
                      _toDouble(booking['depositAmount'] ?? booking['amount']),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thông tin khách hàng',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow('Tên', _bookingCustomerName(booking)),
                  _buildDetailRow(
                    'SĐT',
                    (booking['customerPhone'] ?? booking['userPhone'] ?? '')
                        .toString(),
                  ),
                  _buildDetailRow(
                    'Email',
                    (booking['customerEmail'] ?? booking['userEmail'] ?? '')
                        .toString(),
                  ),
                  _buildDetailRow(
                    'Địa chỉ',
                    (booking['customerAddress'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Ghi chú',
                    (booking['notes'] ?? '').toString(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thông tin showroom và giao dịch',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    'Showroom',
                    (booking['showroomName'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Địa chỉ showroom',
                    (booking['showroomAddress'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Transaction ID',
                    (booking['transactionId'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Phương thức',
                    (booking['paymentMethod'] ?? '').toString(),
                  ),
                  _buildDetailRow('Ngày tạo', _formatDateTime(bookingDate)),
                  _buildDetailRow('Ngày thanh toán', _formatDateTime(paidDate)),
                  _buildDetailRow('Hết hạn', _formatDateTime(expiryDate)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(String docId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _bookingsRef.doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật trạng thái thành ${_statusLabel(newStatus)}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể cập nhật trạng thái: $e')),
      );
    }
  }

  bool _matchesBooking(Map<String, dynamic> booking) {
    final status = _normalizeStatus(booking['status']);
    final statusMatch = _filterStatus == 'all' ? true : status == _filterStatus;
    if (!statusMatch) return false;

    if (_searchQuery.isEmpty) return true;

    final haystack = [
      booking['docId'],
      booking['bookingId'],
      booking['transactionId'],
      booking['carName'],
      booking['carBrand'],
      booking['customerName'],
      booking['customerPhone'],
      booking['customerEmail'],
      booking['userDisplayName'],
      booking['userPhone'],
      booking['userEmail'],
      booking['status'],
      booking['paymentStatus'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

    return haystack.contains(_searchQuery);
  }

  Map<String, dynamic> _computeStats(List<Map<String, dynamic>> bookings) {
    final now = DateTime.now();

    var totalCount = 0;
    var pendingCount = 0;
    var confirmedCount = 0;
    var todayCount = 0;
    var monthCount = 0;
    var yearCount = 0;

    var todayRevenue = 0.0;
    var monthRevenue = 0.0;
    var yearRevenue = 0.0;

    for (final booking in bookings) {
      totalCount += 1;

      final status = _normalizeStatus(booking['status']);
      if (status == 'pending') pendingCount += 1;
      if (status == 'confirmed') confirmedCount += 1;

      final dt = _extractDate(
        booking['createdAt'] ?? booking['paidAt'] ?? booking['updatedAt'],
      );
      if (dt == null) continue;

      final amount = _toDouble(
        booking['depositAmount'] ?? booking['amount'] ?? booking['totalPrice'],
      );

      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        todayCount += 1;
        todayRevenue += amount;
      }

      if (dt.year == now.year && dt.month == now.month) {
        monthCount += 1;
        monthRevenue += amount;
      }

      if (dt.year == now.year) {
        yearCount += 1;
        yearRevenue += amount;
      }
    }

    return {
      'totalCount': totalCount,
      'pendingCount': pendingCount,
      'confirmedCount': confirmedCount,
      'todayCount': todayCount,
      'monthCount': monthCount,
      'yearCount': yearCount,
      'todayRevenue': todayRevenue,
      'monthRevenue': monthRevenue,
      'yearRevenue': yearRevenue,
    };
  }

  String _bookingCustomerName(Map<String, dynamic> booking) {
    return (booking['customerName'] ??
            booking['userDisplayName'] ??
            booking['name'] ??
            'Khách hàng')
        .toString();
  }

  String _normalizeStatus(dynamic rawStatus) {
    return (rawStatus ?? 'pending').toString().trim().toLowerCase();
  }

  String _statusLabel(String rawStatus) {
    final status = _normalizeStatus(rawStatus);
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn tất';
      case 'all':
        return 'Tất cả';
      default:
        return status;
    }
  }

  DateTime _sortableDate(dynamic raw) {
    return _extractDate(raw) ?? DateTime(1970);
  }

  DateTime? _extractDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  double _toDouble(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }
}
