import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'widgets/admin_ui.dart';

class AdminMigrationLogsScreen extends StatefulWidget {
  const AdminMigrationLogsScreen({super.key});

  @override
  State<AdminMigrationLogsScreen> createState() =>
      _AdminMigrationLogsScreenState();
}

class _AdminMigrationLogsScreenState extends State<AdminMigrationLogsScreen> {
  static const Color _bg = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFF00A8FF);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _onlyFailed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Logs cập nhật', style: kAdminHeaderTitleStyle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                    hintText: 'Tìm theo collection, người chạy, trạng thái...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    adminFilterChip(
                      label: 'Tất cả',
                      selected: !_onlyFailed,
                      selectedColor: kAdminPrimary,
                      unselectedColor: _card,
                      onTap: () => setState(() => _onlyFailed = false),
                    ),
                    adminFilterChip(
                      label: 'Chỉ lỗi',
                      selected: _onlyFailed,
                      selectedColor: kAdminPrimary,
                      unselectedColor: _card,
                      onTap: () => setState(() => _onlyFailed = true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('admin_migration_logs')
                  .orderBy('createdAt', descending: true)
                  .limit(300)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không thể tải logs: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmpty('Chưa có logs cập nhật');
                }

                final filtered = docs.where((doc) {
                  final data = doc.data();
                  final success = data['success'] == true;
                  if (_onlyFailed && success) {
                    return false;
                  }

                  final haystack = [
                    (data['mode'] ?? '').toString().toLowerCase(),
                    (data['collection'] ?? '').toString().toLowerCase(),
                    (data['triggeredByPhone'] ?? '').toString().toLowerCase(),
                    (data['triggeredByUid'] ?? '').toString().toLowerCase(),
                    success ? 'thành công' : 'thất bại',
                    doc.id.toLowerCase(),
                  ].join(' ');

                  return _searchQuery.isEmpty ||
                      haystack.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmpty('Không có log phù hợp bộ lọc');
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    return _buildLogCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history, color: Colors.white24, size: 64),
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
    );
  }

  Widget _buildLogCard(String docId, Map<String, dynamic> data) {
    final success = data['success'] == true;
    final mode = (data['mode'] ?? '').toString();
    final collection = (data['collection'] ?? '').toString();
    final scanned = data['scanned'] ?? 0;
    final updated = data['updated'] ?? 0;
    final failedCollections = data['failedCollections'] ?? 0;
    final durationMs = data['durationMs'] ?? 0;
    final createdAt = _formatDateTime(data['createdAt']);

    final title = mode == 'all'
        ? 'Chuẩn hóa toàn bộ'
        : 'Chuẩn hóa ${collection.isEmpty ? 'dữ liệu' : collection}';

    return InkWell(
      onTap: () => _showLogDetail(docId, data),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: success
                ? Colors.green.withValues(alpha: 0.35)
                : Colors.red.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: success ? Colors.greenAccent : Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quét: $scanned | Cập nhật: $updated | Lỗi collection: $failedCollections',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Thời gian chạy: ${durationMs}ms | $createdAt',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetail(String docId, Map<String, dynamic> data) {
    final details = data['details'] as Map<String, dynamic>? ?? const {};
    final failures = data['failures'] as Map<String, dynamic>? ?? const {};

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết log cập nhật',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _line('ID', docId),
              _line('Mode', (data['mode'] ?? '').toString()),
              _line('Collection', (data['collection'] ?? '').toString()),
              _line('Thành công', data['success'] == true ? 'Có' : 'Không'),
              _line('Quét', '${data['scanned'] ?? 0}'),
              _line('Cập nhật', '${data['updated'] ?? 0}'),
              _line('Số collection lỗi', '${data['failedCollections'] ?? 0}'),
              _line('Thời gian chạy', '${data['durationMs'] ?? 0}ms'),
              _line('SĐT chạy', (data['triggeredByPhone'] ?? '').toString()),
              _line('UID chạy', (data['triggeredByUid'] ?? '').toString()),
              _line('Tạo lúc', _formatDateTime(data['createdAt'])),
              const SizedBox(height: 12),
              Text(
                'Chi tiết theo collection',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (details.isEmpty)
                const Text(
                  'Không có dữ liệu chi tiết',
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...details.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '- ${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Collection lỗi',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (failures.isEmpty)
                const Text(
                  'Không có lỗi',
                  style: TextStyle(color: Colors.greenAccent),
                )
              else
                ...failures.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '- ${entry.key}: ${entry.value}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic raw) {
    DateTime? value;
    if (raw is Timestamp) {
      value = raw.toDate();
    } else if (raw is DateTime) {
      value = raw;
    } else if (raw is String) {
      value = DateTime.tryParse(raw);
    }

    if (value == null) {
      return '-';
    }

    return DateFormat('dd/MM/yyyy HH:mm:ss').format(value);
  }
}
