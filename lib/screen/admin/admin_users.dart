import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFF00A8FF);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _roleFilter = 'tat_ca';
  String _providerFilter = 'tat_ca';
  bool _isMigrating = false;

  final CollectionReference<Map<String, dynamic>> _usersRef = FirebaseFirestore
      .instance
      .collection('users');

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
            title: 'Quản lý tài khoản',
            subtitle: 'Quản trị vai trò và nguồn đăng nhập của người dùng',
            actions: [
              OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigrateUsers,
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
              ElevatedButton.icon(
                onPressed: _isMigrating ? null : _showAddUserDialog,
                style: adminPrimaryButtonStyle(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm'),
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
                    hintText: 'Tìm theo tên, email, số điện thoại, UID...',
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
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip('Tất cả', 'tat_ca'),
                          _buildFilterChip('Admin', 'admin'),
                          _buildFilterChip('Người dùng', 'user'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('Không có tài khoản');
                }

                final docs = snapshot.data!.docs;
                final providers = <String>{'tat_ca'};

                for (final doc in docs) {
                  final provider = (doc.data()['provider'] ?? '')
                      .toString()
                      .trim();
                  if (provider.isNotEmpty) {
                    providers.add(provider);
                  }
                }

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final user = UserModel.fromMap(data);

                  final role = (user.role ?? 'user').toLowerCase();
                  final provider = (user.provider ?? '').toLowerCase();
                  final phone = _extractPhone(data, doc.id).toLowerCase();

                  final matchesRole = _roleFilter == 'tat_ca'
                      ? true
                      : role == _roleFilter;
                  final matchesProvider = _providerFilter == 'tat_ca'
                      ? true
                      : provider == _providerFilter;

                  final searchText = [
                    (user.name ?? '').toLowerCase(),
                    (user.email ?? '').toLowerCase(),
                    phone,
                    (user.uid ?? '').toLowerCase(),
                    doc.id.toLowerCase(),
                  ].join(' ');

                  final matchesSearch = _searchQuery.isEmpty
                      ? true
                      : searchText.contains(_searchQuery);

                  return matchesRole && matchesProvider && matchesSearch;
                }).toList();

                if (_providerFilter != 'tat_ca' &&
                    !providers.contains(_providerFilter)) {
                  _providerFilter = 'tat_ca';
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: providers
                                    .map(
                                      (provider) =>
                                          _buildProviderChip(provider),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hiển thị ${filteredDocs.length}/${docs.length} tài khoản',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? _buildEmptyState('Không tìm thấy tài khoản phù hợp')
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data();
                                final user = UserModel.fromMap(data);
                                return _buildUserCard(user, doc.id, data);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _roleFilter == value;
    return adminFilterChip(
      label: label,
      selected: selected,
      selectedColor: _accent,
      unselectedColor: _card,
      onTap: () => setState(() => _roleFilter = value),
    );
  }

  Widget _buildProviderChip(String providerRaw) {
    final isAll = providerRaw == 'tat_ca';
    final selected = _providerFilter == providerRaw;
    final label = isAll ? 'Mọi nguồn' : providerRaw;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: adminFilterChip(
        label: label,
        selected: selected,
        selectedColor: Colors.white.withValues(alpha: 0.18),
        selectedTextColor: Colors.white,
        unselectedTextColor: Colors.white,
        unselectedColor: _card,
        onTap: () => setState(() => _providerFilter = providerRaw),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
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

  Widget _buildUserCard(
    UserModel user,
    String docId,
    Map<String, dynamic> rawData,
  ) {
    final role = (user.role ?? 'user').toLowerCase();
    final isAdmin = role == 'admin';
    final displayName = (user.name ?? '').trim().isEmpty
        ? 'Chưa đặt tên'
        : (user.name ?? 'Chưa đặt tên');
    final phone = _extractPhone(rawData, docId);
    final email = (user.email ?? '').trim().isEmpty
        ? 'Chưa có email'
        : user.email!;
    final provider = (user.provider ?? '').trim().isEmpty
        ? 'Không xác định'
        : user.provider!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin
              ? Colors.amber.withValues(alpha: 0.35)
              : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoField('Email', email)),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoField('Nguồn', provider)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tham gia: ${_formatDate(user.createdAt, 'dd/MM/yyyy')}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _showUserDetails(user, rawData, docId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent.withValues(alpha: 0.2),
                      foregroundColor: _accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Chi tiết',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _toggleUserRole(
                      docId: docId,
                      currentRole: isAdmin ? 'admin' : 'user',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdmin
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.2),
                      foregroundColor: isAdmin ? Colors.red : Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      isAdmin ? 'Gỡ admin' : 'Làm admin',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showUserDetails(
    UserModel user,
    Map<String, dynamic> rawData,
    String docId,
  ) {
    final phone = _extractPhone(rawData, docId);

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
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
                    'Chi tiết tài khoản',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('ID tài khoản', docId),
                  _buildDetailRow(
                    'Tên',
                    (user.name ?? '').trim().isEmpty
                        ? 'Chưa đặt tên'
                        : user.name!,
                  ),
                  _buildDetailRow(
                    'Email',
                    (user.email ?? '').isEmpty ? 'N/A' : user.email!,
                  ),
                  _buildDetailRow('Số điện thoại', phone),
                  _buildDetailRow(
                    'UID',
                    (user.uid ?? '').isEmpty ? 'N/A' : user.uid!,
                  ),
                  _buildDetailRow(
                    'Giới tính',
                    (user.gender ?? '').isEmpty ? 'N/A' : user.gender!,
                  ),
                  _buildDetailRow(
                    'Vai trò',
                    (user.role ?? 'user'),
                    valueColor: (user.role == 'admin')
                        ? Colors.amber
                        : Colors.white,
                  ),
                  _buildDetailRow(
                    'Nguồn đăng nhập',
                    (user.provider ?? '').isEmpty ? 'N/A' : user.provider!,
                  ),
                  _buildDetailRow(
                    'Ngày tạo',
                    _formatDate(user.createdAt, 'dd/MM/yyyy HH:mm'),
                  ),
                  _buildDetailRow(
                    'Cập nhật',
                    _formatDate(user.updatedAt, 'dd/MM/yyyy HH:mm'),
                  ),
                  _buildDetailRow(
                    'Đăng nhập gần nhất',
                    _formatDate(user.lastLogin, 'dd/MM/yyyy HH:mm'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserRole({
    required String docId,
    required String currentRole,
  }) async {
    final nextRole = currentRole == 'admin' ? 'user' : 'admin';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          'Xác nhận',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          nextRole == 'admin'
              ? 'Bạn muốn cấp quyền admin cho tài khoản này?'
              : 'Bạn muốn gỡ quyền admin của tài khoản này?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _usersRef.doc(docId).update({
                  'role': nextRole,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      nextRole == 'admin'
                          ? 'Đã cấp quyền admin'
                          : 'Đã gỡ quyền admin',
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Không thể cập nhật quyền: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: nextRole == 'admin' ? Colors.amber : Colors.red,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _runMigrateUsers() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa tài khoản xong: quét ${result['scanned']}, cập nhật ${result['updated']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuẩn hóa tài khoản thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final providerController = TextEditingController(text: 'admin_created');
    final uidController = TextEditingController();
    String role = 'user';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Thêm tài khoản',
            style: GoogleFonts.leagueSpartan(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField('Tên hiển thị', nameController),
                const SizedBox(height: 12),
                _buildInputField('Số điện thoại', phoneController),
                const SizedBox(height: 12),
                _buildInputField('Email (không bắt buộc)', emailController),
                const SizedBox(height: 12),
                _buildInputField('Provider', providerController),
                const SizedBox(height: 12),
                _buildInputField('UID (không bắt buộc)', uidController),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: _card,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Vai trò',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Người dùng')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      role = value ?? 'user';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(this.context);
                final phone = phoneController.text.trim();
                final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');

                if (normalizedPhone.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập số điện thoại'),
                    ),
                  );
                  return;
                }

                if (!RegExp(r'^\d{8,15}$').hasMatch(normalizedPhone)) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Số điện thoại không hợp lệ (8-15 chữ số)'),
                    ),
                  );
                  return;
                }

                final docRef = _usersRef.doc(normalizedPhone);
                final exists = await docRef.get();
                if (exists.exists) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Số điện thoại đã tồn tại')),
                  );
                  return;
                }

                try {
                  await docRef.set({
                    'phone': normalizedPhone,
                    'phoneNumber': normalizedPhone,
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'role': role,
                    'provider': providerController.text.trim().isEmpty
                        ? 'admin_created'
                        : providerController.text.trim(),
                    'uid': uidController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'lastLogin': null,
                  });

                  if (!mounted || !dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Thêm tài khoản thành công')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Không thể thêm tài khoản: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
      ),
    );
  }

  String _extractPhone(Map<String, dynamic> rawData, String docId) {
    final phone = (rawData['phone'] ?? '').toString().trim();
    final phoneNumber = (rawData['phoneNumber'] ?? '').toString().trim();
    if (phone.isNotEmpty) return phone;
    if (phoneNumber.isNotEmpty) return phoneNumber;
    return docId;
  }

  String _formatDate(DateTime? date, String pattern) {
    if (date == null) return 'N/A';
    return DateFormat(pattern).format(date);
  }
}
