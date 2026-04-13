import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

class AdminDepositsScreen extends StatefulWidget {
  const AdminDepositsScreen({super.key});

  @override
  State<AdminDepositsScreen> createState() => _AdminDepositsScreenState();
}

class _AdminDepositsScreenState extends State<AdminDepositsScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFFFF9500);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF22C55E);

  final CollectionReference<Map<String, dynamic>> _depositsRef =
      FirebaseFirestore.instance.collection('deposits');
  final CollectionReference<Map<String, dynamic>> _transactionsRef =
      FirebaseFirestore.instance.collection('transactions');
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'all';
  String _searchQuery = '';
  bool _isMigrating = false;

  static const List<String> _statusFilters = [
    'all',
    'pending',
    'confirmed',
    'cancelled',
  ];

  static const List<String> _statusOptions = [
    'pending',
    'confirmed',
    'cancelled',
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
            title: 'Quản lý đặt cọc',
            actions: [
              OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigrateDeposits,
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
                    hintText: 'Tìm theo xe, khách hàng, SĐT, email, mã...',
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
              stream: _depositsRef.snapshots(),
              builder: (context, depositsSnapshot) {
                if (depositsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (depositsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không thể tải dữ liệu đặt cọc: ${depositsSnapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _transactionsRef.snapshots(),
                  builder: (context, transactionsSnapshot) {
                    if (transactionsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _accent),
                      );
                    }

                    if (transactionsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Không thể tải dữ liệu giao dịch: ${transactionsSnapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final deposits = (depositsSnapshot.data?.docs ?? [])
                        .map((doc) => {'docId': doc.id, ...doc.data()})
                        .toList();

                    final transactions = (transactionsSnapshot.data?.docs ?? [])
                        .map((doc) => {'docId': doc.id, ...doc.data()})
                        .toList();

                    final filteredDeposits =
                        deposits.where(_matchesDeposit).toList()..sort(
                          (a, b) =>
                              _extractDate(
                                b['depositDate'] ??
                                    b['createdAt'] ??
                                    b['updatedAt'],
                              ).compareTo(
                                _extractDate(
                                  a['depositDate'] ??
                                      a['createdAt'] ??
                                      a['updatedAt'],
                                ),
                              ),
                        );

                    final stats = _computeStats(
                      deposits: deposits,
                      filteredDeposits: filteredDeposits,
                      transactions: transactions,
                    );

                    final transactionByDocId = <String, Map<String, dynamic>>{};
                    final transactionByTxId = <String, Map<String, dynamic>>{};

                    for (final tx in transactions) {
                      final docId = (tx['docId'] ?? '').toString();
                      if (docId.isNotEmpty) {
                        transactionByDocId[docId] = tx;
                      }

                      final txId = (tx['transactionId'] ?? '')
                          .toString()
                          .trim();
                      if (txId.isNotEmpty &&
                          !transactionByTxId.containsKey(txId)) {
                        transactionByTxId[txId] = tx;
                      }
                    }

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsSection(stats),
                            const SizedBox(height: 10),
                            Text(
                              'Hiển thị ${filteredDeposits.length}/${deposits.length} đơn đặt cọc',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (filteredDeposits.isEmpty)
                              _buildEmptyState(
                                'Không có đặt cọc phù hợp bộ lọc',
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredDeposits.length,
                                itemBuilder: (context, index) {
                                  final deposit = filteredDeposits[index];
                                  return _buildDepositCard(
                                    deposit,
                                    transactionByDocId,
                                    transactionByTxId,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
          title: 'Tổng đơn đặt cọc',
          value: '${stats['totalDeposits']}',
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
          title: 'Doanh thu giao dịch',
          value: _formatCurrency(stats['paidTransactionsRevenue'] as double),
          color: const Color(0xFF38BDF8),
          fullWidth: true,
        ),
        _buildStatCard(
          title: 'Tổng đặt cọc đã xác nhận',
          value: _formatCurrency(stats['confirmedDepositRevenue'] as double),
          color: const Color(0xFF4ADE80),
          fullWidth: true,
        ),
      ],
    );
  }

  Future<void> _runMigrateDeposits() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateDeposits();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa đặt cọc xong: quét ${result['scanned']}, cập nhật ${result['updated']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chuẩn hóa đặt cọc thất bại: $e')));
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
            const Icon(Icons.receipt_long, color: Colors.white24, size: 64),
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

  Widget _buildDepositCard(
    Map<String, dynamic> deposit,
    Map<String, Map<String, dynamic>> transactionByDocId,
    Map<String, Map<String, dynamic>> transactionByTxId,
  ) {
    final status = _normalizeStatus(deposit['depositStatus']);
    final amount = _toDouble(deposit['depositAmount']);
    final carName = (deposit['carName'] ?? 'Không xác định').toString();
    final customerName = (deposit['customerName'] ?? 'Khách hàng').toString();
    final docId = (deposit['docId'] ?? '').toString();
    final linkedTransaction = _findLinkedTransaction(
      deposit,
      transactionByDocId,
      transactionByTxId,
    );
    final date = _extractDate(
      deposit['depositDate'] ?? deposit['createdAt'] ?? deposit['updatedAt'],
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
                      customerName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
          Text(
            'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          if (linkedTransaction != null) ...[
            const SizedBox(height: 4),
            Text(
              'Giao dịch: ${(linkedTransaction['transactionId'] ?? linkedTransaction['docId'] ?? '-').toString()}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showDepositDetails(deposit, linkedTransaction),
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
                    _updateDepositStatus(docId, newStatus);
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

  void _showDepositDetails(
    Map<String, dynamic> deposit,
    Map<String, dynamic>? transaction,
  ) {
    final depositDate = _extractDate(
      deposit['depositDate'] ?? deposit['createdAt'] ?? deposit['updatedAt'],
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chi tiết đặt cọc',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow('Mã đặt cọc', (deposit['docId'] ?? '').toString()),
              _detailRow('Xe', (deposit['carName'] ?? '').toString()),
              _detailRow('Hãng', (deposit['carBrand'] ?? '').toString()),
              _detailRow(
                'Số tiền đặt cọc',
                _formatCurrency(_toDouble(deposit['depositAmount'])),
              ),
              _detailRow(
                'Trạng thái',
                _statusLabel(_normalizeStatus(deposit['depositStatus'])),
              ),
              _detailRow(
                'Khách hàng',
                (deposit['customerName'] ?? '').toString(),
              ),
              _detailRow('SĐT', (deposit['customerPhone'] ?? '').toString()),
              _detailRow('Email', (deposit['customerEmail'] ?? '').toString()),
              _detailRow(
                'Địa chỉ',
                (deposit['address'] ?? deposit['customerAddress'] ?? '')
                    .toString(),
              ),
              _detailRow(
                'Ngày đặt cọc',
                DateFormat('dd/MM/yyyy HH:mm').format(depositDate),
              ),
              _detailRow(
                'Mã giao dịch liên kết',
                (deposit['transactionId'] ?? '').toString(),
              ),
              if ((deposit['paymentMethod'] ?? '').toString().isNotEmpty)
                _detailRow(
                  'Phương thức thanh toán',
                  (deposit['paymentMethod'] ?? '').toString(),
                ),
              if ((deposit['paymentStatus'] ?? '').toString().isNotEmpty)
                _detailRow(
                  'Trạng thái thanh toán',
                  (deposit['paymentStatus'] ?? '').toString(),
                ),
              if ((deposit['notes'] ?? '').toString().isNotEmpty)
                _detailRow('Ghi chú', (deposit['notes'] ?? '').toString()),
              const SizedBox(height: 16),
              Text(
                'Thông tin giao dịch',
                style: GoogleFonts.leagueSpartan(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (transaction == null)
                const Text(
                  'Chưa tìm thấy giao dịch liên kết.',
                  style: TextStyle(color: Colors.white54),
                )
              else ...[
                _detailRow(
                  'Transaction ID',
                  (transaction['transactionId'] ?? transaction['docId'] ?? '')
                      .toString(),
                ),
                _detailRow(
                  'Số tiền giao dịch',
                  _formatCurrency(
                    _toDouble(
                      transaction['amount'] ?? transaction['depositAmount'],
                    ),
                  ),
                ),
                _detailRow(
                  'Trạng thái giao dịch',
                  (transaction['paymentStatus'] ?? transaction['status'] ?? '')
                      .toString(),
                ),
                _detailRow(
                  'Ngày thanh toán',
                  DateFormat('dd/MM/yyyy HH:mm').format(
                    _extractDate(
                      transaction['paidAt'] ??
                          transaction['createdAt'] ??
                          transaction['updatedAt'],
                    ),
                  ),
                ),
                if ((transaction['paymentMethod'] ?? '').toString().isNotEmpty)
                  _detailRow(
                    'Phương thức',
                    (transaction['paymentMethod'] ?? '').toString(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDepositStatus(String docId, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _depositsRef.doc(docId).update({
        'depositStatus': newStatus,
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

  bool _matchesDeposit(Map<String, dynamic> deposit) {
    final status = _normalizeStatus(deposit['depositStatus']);
    final statusMatch = _filterStatus == 'all' ? true : status == _filterStatus;

    if (!statusMatch) return false;

    if (_searchQuery.isEmpty) return true;

    final haystack = [
      deposit['docId'],
      deposit['depositId'],
      deposit['transactionId'],
      deposit['carName'],
      deposit['carBrand'],
      deposit['customerName'],
      deposit['customerPhone'],
      deposit['customerEmail'],
      deposit['paymentStatus'],
      deposit['paymentMethod'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

    return haystack.contains(_searchQuery);
  }

  Map<String, dynamic> _computeStats({
    required List<Map<String, dynamic>> deposits,
    required List<Map<String, dynamic>> filteredDeposits,
    required List<Map<String, dynamic>> transactions,
  }) {
    var pendingCount = 0;
    var confirmedCount = 0;
    var cancelledCount = 0;
    var confirmedDepositRevenue = 0.0;

    for (final deposit in deposits) {
      final status = _normalizeStatus(deposit['depositStatus']);
      if (status == 'pending') pendingCount += 1;
      if (status == 'confirmed') {
        confirmedCount += 1;
        confirmedDepositRevenue += _toDouble(deposit['depositAmount']);
      }
      if (status == 'cancelled') cancelledCount += 1;
    }

    var paidTransactionsRevenue = 0.0;
    for (final tx in transactions) {
      final paymentStatus = (tx['paymentStatus'] ?? tx['status'] ?? '')
          .toString()
          .toLowerCase();
      if (paymentStatus == 'paid' ||
          paymentStatus == 'success' ||
          paymentStatus == 'completed' ||
          paymentStatus == 'confirmed') {
        paidTransactionsRevenue += _toDouble(
          tx['amount'] ?? tx['depositAmount'] ?? tx['totalAmount'],
        );
      }
    }

    return {
      'totalDeposits': deposits.length,
      'filteredCount': filteredDeposits.length,
      'pendingCount': pendingCount,
      'confirmedCount': confirmedCount,
      'cancelledCount': cancelledCount,
      'confirmedDepositRevenue': confirmedDepositRevenue,
      'paidTransactionsRevenue': paidTransactionsRevenue,
    };
  }

  Map<String, dynamic>? _findLinkedTransaction(
    Map<String, dynamic> deposit,
    Map<String, Map<String, dynamic>> transactionByDocId,
    Map<String, Map<String, dynamic>> transactionByTxId,
  ) {
    final txId = (deposit['transactionId'] ?? '').toString().trim();
    if (txId.isNotEmpty) {
      if (transactionByDocId.containsKey(txId)) {
        return transactionByDocId[txId];
      }
      if (transactionByTxId.containsKey(txId)) {
        return transactionByTxId[txId];
      }
    }

    final depositId = (deposit['depositId'] ?? '').toString().trim();
    if (depositId.isNotEmpty && transactionByTxId.containsKey(depositId)) {
      return transactionByTxId[depositId];
    }

    return null;
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
      case 'all':
        return 'Tất cả';
      default:
        return status;
    }
  }

  String _normalizeStatus(dynamic rawStatus) {
    return (rawStatus ?? 'pending').toString().trim().toLowerCase();
  }

  DateTime _extractDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime(1970);
    return DateTime(1970);
  }

  double _toDouble(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final normalized = raw.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized) ?? 0;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }
}
