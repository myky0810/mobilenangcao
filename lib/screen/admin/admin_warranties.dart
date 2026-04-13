import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

class AdminWarrantiesScreen extends StatefulWidget {
  const AdminWarrantiesScreen({super.key});

  @override
  State<AdminWarrantiesScreen> createState() => _AdminWarrantiesScreenState();
}

class _AdminWarrantiesScreenState extends State<AdminWarrantiesScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFFFF9500);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFEF4444);

  final CollectionReference<Map<String, dynamic>> _warrantiesRef =
      FirebaseFirestore.instance.collection('warranties');
  final Query<Map<String, dynamic>> _warrantiesGroupQuery = FirebaseFirestore
      .instance
      .collectionGroup('warranties');
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'all';
  String _searchQuery = '';
  bool _isMigrating = false;

  static const List<String> _statusFilters = [
    'all',
    'pending',
    'active',
    'expired',
    'cancelled',
    'completed',
  ];

  static const List<String> _statusOptions = [
    'pending',
    'active',
    'expired',
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
            title: 'Quản lý bảo hành',
            actions: [
              OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigrateWarranties,
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
                        'Tìm theo xe, khách hàng, SĐT, VIN/biển số, mô tả...',
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
              stream: _warrantiesGroupQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không thể tải dữ liệu bảo hành: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final warranties = (snapshot.data?.docs ?? [])
                    .map(_normalizeWarrantyDoc)
                    .toList();

                final filteredWarranties =
                    warranties.where(_matchesWarranty).toList()..sort(
                      (a, b) =>
                          _sortableDate(
                            b['createdAt'] ??
                                b['updatedAt'] ??
                                b['purchaseDate'],
                          ).compareTo(
                            _sortableDate(
                              a['createdAt'] ??
                                  a['updatedAt'] ??
                                  a['purchaseDate'],
                            ),
                          ),
                    );

                final stats = _computeStats(warranties);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsSection(stats),
                        const SizedBox(height: 10),
                        Text(
                          'Hiển thị ${filteredWarranties.length}/${warranties.length} bảo hành',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filteredWarranties.isEmpty)
                          _buildEmptyState('Không có bảo hành phù hợp bộ lọc')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredWarranties.length,
                            itemBuilder: (context, index) {
                              return _buildWarrantyCard(
                                filteredWarranties[index],
                              );
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
          title: 'Tổng bảo hành',
          value: '${stats['totalCount']}',
          color: const Color(0xFF60A5FA),
        ),
        _buildStatCard(
          title: 'Chờ xử lý',
          value: '${stats['pendingCount']}',
          color: _accent,
        ),
        _buildStatCard(
          title: 'Đang hoạt động',
          value: '${stats['activeCount']}',
          color: _success,
        ),
        _buildStatCard(
          title: 'Hết hạn',
          value: '${stats['expiredCount']}',
          color: _danger,
        ),
        _buildStatCard(
          title: 'Hôm nay',
          value: '${stats['todayCount']} yêu cầu',
          color: const Color(0xFF38BDF8),
          fullWidth: true,
        ),
        _buildStatCard(
          title: 'Tháng này',
          value: '${stats['monthCount']} yêu cầu',
          color: const Color(0xFF22D3EE),
          fullWidth: true,
        ),
        _buildStatCard(
          title: 'Năm nay',
          value: '${stats['yearCount']} yêu cầu',
          color: const Color(0xFF4ADE80),
          fullWidth: true,
        ),
      ],
    );
  }

  Future<void> _runMigrateWarranties() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateWarranties();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa bảo hành xong: quét ${result['scanned']}, cập nhật ${result['updated']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuẩn hóa bảo hành thất bại: $e')),
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
            const Icon(Icons.shield, color: Colors.white24, size: 64),
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

  Widget _buildWarrantyCard(Map<String, dynamic> warranty) {
    final status = _normalizeStatus(warranty['status']);
    final carName = (warranty['carName'] ?? 'Không xác định').toString();
    final vinOrPlate = _vinOrPlate(warranty);
    final docId = (warranty['docId'] ?? '').toString();
    final createdAt = _extractDate(
      warranty['createdAt'] ??
          warranty['updatedAt'] ??
          warranty['purchaseDate'],
    );
    final matchedUser = (warranty['matchedUserId'] ?? '').toString();

    Color statusColor;
    switch (status) {
      case 'active':
        statusColor = _success;
        break;
      case 'pending':
        statusColor = _accent;
        break;
      case 'expired':
        statusColor = _danger;
        break;
      case 'completed':
        statusColor = const Color(0xFF38BDF8);
        break;
      case 'cancelled':
        statusColor = const Color(0xFF9CA3AF);
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
                      vinOrPlate,
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
            'Mã: $docId',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          if (matchedUser.isNotEmpty)
            Text(
              'User: $matchedUser',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          if (matchedUser.isNotEmpty) const SizedBox(height: 4),
          Text(
            'Ngày tạo: ${_formatDateTime(createdAt)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showWarrantyDetails(warranty),
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
                    _updateWarrantyStatus(warranty, newStatus);
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

  void _showWarrantyDetails(Map<String, dynamic> warranty) {
    final createdAt = _extractDate(warranty['createdAt']);
    final purchaseDate = _extractDate(warranty['purchaseDate']);
    final updatedAt = _extractDate(warranty['updatedAt']);
    final startDate = _extractDate(warranty['startDate']);
    final endDate = _extractDate(warranty['endDate']);

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
                    'Chi tiết bảo hành',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Document ID',
                    (warranty['docId'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Đường dẫn',
                    (warranty['docPath'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'User match',
                    (warranty['matchedUserId'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Trạng thái',
                    _statusLabel(_normalizeStatus(warranty['status'])),
                  ),
                  _buildDetailRow(
                    'Nguồn tạo',
                    (warranty['source'] ?? '').toString(),
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
                  _buildDetailRow('Xe', (warranty['carName'] ?? '').toString()),
                  _buildDetailRow(
                    'Hãng',
                    (warranty['carBrand'] ?? '').toString(),
                  ),
                  _buildDetailRow('VIN', (warranty['vin'] ?? '').toString()),
                  _buildDetailRow(
                    'VIN/biển số',
                    (warranty['vinOrPlate'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Biển số',
                    (warranty['licensePlate'] ?? '').toString(),
                  ),
                  _buildDetailRow('Ngày mua', _formatDateTime(purchaseDate)),
                  _buildDetailRow('Bắt đầu BH', _formatDateTime(startDate)),
                  _buildDetailRow('Hết hạn BH', _formatDateTime(endDate)),
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
                  _buildDetailRow('Họ tên', _ownerName(warranty)),
                  _buildDetailRow(
                    'SĐT',
                    (warranty['phone'] ?? warranty['ownerPhone'] ?? '')
                        .toString(),
                  ),
                  _buildDetailRow(
                    'Booking ID',
                    (warranty['bookingId'] ?? '').toString(),
                  ),
                  _buildDetailRow(
                    'Transaction ID',
                    (warranty['transactionId'] ?? '').toString(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mô tả sự cố và thời gian',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    'Mô tả sự cố',
                    (warranty['issueDescription'] ?? '').toString(),
                  ),
                  _buildDetailRow('Ngày tạo', _formatDateTime(createdAt)),
                  _buildDetailRow('Ngày cập nhật', _formatDateTime(updatedAt)),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
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

  Future<void> _updateWarrantyStatus(
    Map<String, dynamic> warranty,
    String newStatus,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ref = warranty['_ref'];
      if (ref is DocumentReference<Map<String, dynamic>>) {
        await ref.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (ref is DocumentReference) {
        await ref.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final docId = (warranty['docId'] ?? '').toString();
        if (docId.isEmpty) {
          throw Exception('Thiếu document ID để cập nhật trạng thái');
        }
        await _warrantiesRef.doc(docId).update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

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

  Map<String, dynamic> _normalizeWarrantyDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final path = doc.reference.path;
    final pathUserId = _extractUserIdFromPath(path);

    final ownerPhone = (data['ownerPhone'] ?? '').toString().trim();
    final phone = (data['phone'] ?? '').toString().trim();
    final normalizedOwnerPhone = ownerPhone.isNotEmpty
        ? ownerPhone
        : pathUserId;
    final normalizedPhone = phone.isNotEmpty ? phone : normalizedOwnerPhone;
    final matchedUserId = ownerPhone.isNotEmpty
        ? ownerPhone
        : (phone.isNotEmpty ? phone : pathUserId);

    return {
      ...data,
      'docId': doc.id,
      'docPath': path,
      'pathUserId': pathUserId,
      'matchedUserId': matchedUserId,
      if (normalizedOwnerPhone.isNotEmpty) 'ownerPhone': normalizedOwnerPhone,
      if (normalizedPhone.isNotEmpty) 'phone': normalizedPhone,
      '_ref': doc.reference,
    };
  }

  String _extractUserIdFromPath(String path) {
    final segments = path.split('/');
    for (var i = 0; i < segments.length - 2; i++) {
      if (segments[i] == 'users' && segments[i + 2] == 'warranties') {
        return segments[i + 1];
      }
    }
    return '';
  }

  bool _matchesWarranty(Map<String, dynamic> warranty) {
    final status = _normalizeStatus(warranty['status']);
    final statusMatch = _filterStatus == 'all' ? true : status == _filterStatus;
    if (!statusMatch) return false;

    if (_searchQuery.isEmpty) return true;

    final haystack = [
      warranty['docId'],
      warranty['docPath'],
      warranty['matchedUserId'],
      warranty['pathUserId'],
      warranty['carName'],
      warranty['carBrand'],
      warranty['fullName'],
      warranty['phone'],
      warranty['ownerPhone'],
      warranty['vin'],
      warranty['vinOrPlate'],
      warranty['licensePlate'],
      warranty['issueDescription'],
      warranty['bookingId'],
      warranty['transactionId'],
      warranty['status'],
      warranty['source'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

    return haystack.contains(_searchQuery);
  }

  Map<String, dynamic> _computeStats(List<Map<String, dynamic>> warranties) {
    final now = DateTime.now();

    var totalCount = 0;
    var pendingCount = 0;
    var activeCount = 0;
    var expiredCount = 0;
    var todayCount = 0;
    var monthCount = 0;
    var yearCount = 0;

    for (final warranty in warranties) {
      totalCount += 1;

      final status = _normalizeStatus(warranty['status']);
      if (status == 'pending') pendingCount += 1;
      if (status == 'active') activeCount += 1;
      if (status == 'expired') expiredCount += 1;

      final dt = _extractDate(
        warranty['createdAt'] ??
            warranty['updatedAt'] ??
            warranty['purchaseDate'],
      );
      if (dt == null) continue;

      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        todayCount += 1;
      }
      if (dt.year == now.year && dt.month == now.month) {
        monthCount += 1;
      }
      if (dt.year == now.year) {
        yearCount += 1;
      }
    }

    return {
      'totalCount': totalCount,
      'pendingCount': pendingCount,
      'activeCount': activeCount,
      'expiredCount': expiredCount,
      'todayCount': todayCount,
      'monthCount': monthCount,
      'yearCount': yearCount,
    };
  }

  String _ownerName(Map<String, dynamic> warranty) {
    return (warranty['fullName'] ??
            warranty['customerName'] ??
            warranty['userDisplayName'] ??
            '')
        .toString();
  }

  String _vinOrPlate(Map<String, dynamic> warranty) {
    final vin = (warranty['vin'] ?? '').toString().trim();
    final vinOrPlate = (warranty['vinOrPlate'] ?? '').toString().trim();
    final licensePlate = (warranty['licensePlate'] ?? '').toString().trim();

    if (vin.isNotEmpty) return 'VIN: $vin';
    if (vinOrPlate.isNotEmpty) return 'VIN/Biển số: $vinOrPlate';
    if (licensePlate.isNotEmpty) return 'Biển số: $licensePlate';
    return 'VIN/Biển số: -';
  }

  String _normalizeStatus(dynamic rawStatus) {
    return (rawStatus ?? 'pending').toString().trim().toLowerCase();
  }

  String _statusLabel(String rawStatus) {
    final status = _normalizeStatus(rawStatus);
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'active':
        return 'Đang hoạt động';
      case 'expired':
        return 'Hết hạn';
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
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) {
      final asDate = DateTime.tryParse(raw);
      if (asDate != null) return asDate;

      final cleaned = raw.trim();
      final parts = cleaned.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
