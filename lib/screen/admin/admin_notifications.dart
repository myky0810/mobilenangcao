import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFF00A8FF);
  static const Color _danger = Color(0xFFEF4444);

  final CollectionReference<Map<String, dynamic>> _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');
  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _typeFilter = 'tat_ca';
  bool _isMigrating = false;

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
            title: 'Quản lý thông báo',
            subtitle: 'Theo dõi ưu đãi và thông báo gửi tới toàn hệ thống',
            actions: [
              OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigrateNotifications,
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
                onPressed: _isMigrating ? null : _showAddNotificationDialog,
                style: adminPrimaryButtonStyle(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm'),
              ),
            ],
          ),
          _buildSearchAndFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationsRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('Không có thông báo');
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final type = (data['type'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();

                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '')
                      .toString()
                      .toLowerCase();
                  final carModel = (data['carModel'] ?? '')
                      .toString()
                      .toLowerCase();
                  final bannerKey = (data['bannerKey'] ?? '')
                      .toString()
                      .toLowerCase();
                  final productId = (data['productId'] ?? '')
                      .toString()
                      .toLowerCase();
                  final searchMatch = _searchQuery.isEmpty
                      ? true
                      : title.contains(_searchQuery) ||
                            desc.contains(_searchQuery) ||
                            carModel.contains(_searchQuery) ||
                            bannerKey.contains(_searchQuery) ||
                            productId.contains(_searchQuery) ||
                            doc.id.toLowerCase().contains(_searchQuery);

                  final filterMatch = switch (_typeFilter) {
                    'uu_dai' => type == 'promotion',
                    'khac' => type.isNotEmpty && type != 'promotion',
                    _ => true,
                  };

                  return searchMatch && filterMatch;
                }).toList();

                if (docs.isEmpty) {
                  return _buildEmptyState('Không có thông báo phù hợp bộ lọc');
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final notification = doc.data();
                    return _buildNotificationCard(notification, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
              hintText: 'Tìm theo tiêu đề, nội dung, xe, mã...',
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
            children: [
              _buildFilterChip('Tất cả', 'tat_ca'),
              _buildFilterChip('Ưu đãi', 'uu_dai'),
              _buildFilterChip('Khác', 'khac'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _typeFilter == value;
    return adminFilterChip(
      label: label,
      selected: selected,
      selectedColor: kAdminPrimary,
      unselectedColor: _card,
      onTap: () => setState(() => _typeFilter = value),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white24,
            size: 64,
          ),
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

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    String docId,
  ) {
    final type = (notification['type'] ?? '').toString().toLowerCase();
    final isPromotion = type == 'promotion';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notification['title']?.toString() ?? 'N/A',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPromotion
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPromotion ? 'Ưu đãi' : 'Khác',
                  style: TextStyle(
                    color: isPromotion ? Colors.orange : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                color: _card,
                onSelected: (value) {
                  if (value == 'detail') {
                    _showNotificationDetails(notification, docId);
                  } else if (value == 'edit') {
                    _showNotificationDialog(
                      notification: notification,
                      docId: docId,
                    );
                  } else if (value == 'delete') {
                    _deleteNotification(docId);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Chi tiết', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text('Sửa', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notification['description']?.toString() ?? 'N/A',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Ngày tạo: ${_formatDate(notification['createdAt'])}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showAddNotificationDialog() {
    _showNotificationDialog();
  }

  Future<void> _runMigrateNotifications() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa thông báo xong: quét ${result['scanned']}, cập nhật ${result['updated']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuẩn hóa thông báo thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  void _showNotificationDialog({
    Map<String, dynamic>? notification,
    String? docId,
  }) {
    final isEdit = notification != null && docId != null;

    final titleController = TextEditingController(
      text: (notification?['title'] ?? '').toString(),
    );
    final descController = TextEditingController(
      text: (notification?['description'] ?? '').toString(),
    );
    final carModelController = TextEditingController(
      text: (notification?['carModel'] ?? '').toString(),
    );
    final originalPriceController = TextEditingController(
      text: (notification?['originalPrice'] ?? '').toString(),
    );
    final discountPriceController = TextEditingController(
      text: (notification?['discountPrice'] ?? '').toString(),
    );
    final discountPercentController = TextEditingController(
      text: (notification?['discountPercent'] ?? '').toString(),
    );
    final imageUrlController = TextEditingController(
      text: (notification?['imageUrl'] ?? '').toString(),
    );
    final bannerKeyController = TextEditingController(
      text: (notification?['bannerKey'] ?? '').toString(),
    );
    final bannerIndexController = TextEditingController(
      text: (notification?['bannerIndex'] ?? 0).toString(),
    );

    var selectedType = (notification?['type'] ?? 'promotion')
        .toString()
        .toLowerCase();
    var selectedProductId = (notification?['productId'] ?? '').toString();
    var isRead = notification?['isRead'] == true;
    DateTime? startDate = _parseDate(notification?['startDate']);
    DateTime? endDate = _parseDate(notification?['endDate']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _card,
              title: Text(
                isEdit ? 'Sửa thông báo' : 'Thêm thông báo',
                style: GoogleFonts.leagueSpartan(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputField('Tiêu đề', titleController),
                    _buildInputField('Mô tả', descController, maxLines: 3),
                    _buildInputField('Dòng xe', carModelController),
                    _buildInputField('Giá gốc', originalPriceController),
                    _buildInputField('Giá ưu đãi', discountPriceController),
                    _buildInputField(
                      'Phần trăm giảm',
                      discountPercentController,
                    ),
                    _buildInputField('Ảnh', imageUrlController),
                    _buildInputField('Banner key', bannerKeyController),
                    _buildInputField('Banner index', bannerIndexController),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loại thông báo',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            isExpanded: true,
                            dropdownColor: _card,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Chọn loại thông báo',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.white10,
                                ),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'promotion',
                                child: Text('Ưu đãi'),
                              ),
                              DropdownMenuItem(
                                value: 'announcement',
                                child: Text('Thông báo thường'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                selectedType = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (selectedType == 'promotion')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _productsRef.orderBy('name').snapshots(),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];

                            final options = docs.map((doc) {
                              final data = doc.data();
                              final name =
                                  (data['name'] ?? data['carName'] ?? doc.id)
                                      .toString();
                              final brand =
                                  (data['brand'] ??
                                          data['brandName'] ??
                                          data['carBrand'] ??
                                          '')
                                      .toString();
                              return {
                                'id': doc.id,
                                'name': name,
                                'brand': brand,
                                'image':
                                    (data['image'] ?? data['carImage'] ?? '')
                                        .toString(),
                                'price':
                                    (data['price'] ?? data['carPrice'] ?? '')
                                        .toString(),
                              };
                            }).toList();

                            final validSelected = options.any(
                              (e) => e['id'] == selectedProductId,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sản phẩm ưu đãi',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: validSelected
                                      ? selectedProductId
                                      : null,
                                  isExpanded: true,
                                  dropdownColor: _card,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Chọn sản phẩm ưu đãi',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white10,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.white10,
                                      ),
                                    ),
                                  ),
                                  items: options
                                      .map(
                                        (option) => DropdownMenuItem<String>(
                                          value: option['id'],
                                          child: Text(
                                            '${option['name']} ${option['brand']!.isNotEmpty ? '- ${option['brand']}' : ''}',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  selectedItemBuilder: (context) => options
                                      .map(
                                        (option) => Text(
                                          '${option['name']} ${option['brand']!.isNotEmpty ? '- ${option['brand']}' : ''}',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final selected = options.firstWhere(
                                      (e) => e['id'] == value,
                                    );

                                    setDialogState(() {
                                      selectedProductId = value;
                                      if (carModelController.text
                                          .trim()
                                          .isEmpty) {
                                        carModelController.text =
                                            selected['name'] ?? '';
                                      }
                                      if (imageUrlController.text
                                          .trim()
                                          .isEmpty) {
                                        imageUrlController.text =
                                            selected['image'] ?? '';
                                      }
                                      if (originalPriceController.text
                                          .trim()
                                          .isEmpty) {
                                        originalPriceController.text =
                                            selected['price'] ?? '';
                                      }
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked == null) return;
                              setDialogState(() {
                                startDate = picked;
                              });
                            },
                            child: Text(
                              startDate == null
                                  ? 'Chọn ngày bắt đầu'
                                  : 'Bắt đầu: ${_formatDate(startDate)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked == null) return;
                              setDialogState(() {
                                endDate = picked;
                              });
                            },
                            child: Text(
                              endDate == null
                                  ? 'Chọn ngày kết thúc'
                                  : 'Kết thúc: ${_formatDate(endDate)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isRead,
                      onChanged: (value) {
                        setDialogState(() {
                          isRead = value;
                        });
                      },
                      title: const Text(
                        'Đánh dấu đã đọc',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeThumbColor: _accent,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final title = titleController.text.trim();
                    final description = descController.text.trim();

                    if (title.isEmpty || description.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Tiêu đề và mô tả không được để trống'),
                        ),
                      );
                      return;
                    }

                    if (selectedType == 'promotion' &&
                        selectedProductId.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng chọn sản phẩm cho thông báo ưu đãi',
                          ),
                        ),
                      );
                      return;
                    }

                    final payload = <String, dynamic>{
                      'title': title,
                      'description': description,
                      'type': selectedType,
                      'productId': selectedType == 'promotion'
                          ? selectedProductId.trim()
                          : null,
                      'carModel': carModelController.text.trim(),
                      'originalPrice': originalPriceController.text.trim(),
                      'discountPrice': discountPriceController.text.trim(),
                      'discountPercent': discountPercentController.text.trim(),
                      'imageUrl': imageUrlController.text.trim(),
                      'bannerKey': bannerKeyController.text.trim(),
                      'bannerIndex':
                          int.tryParse(bannerIndexController.text.trim()) ?? 0,
                      'isRead': isRead,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (startDate != null) {
                      payload['startDate'] = Timestamp.fromDate(startDate!);
                    }
                    if (endDate != null) {
                      payload['endDate'] = Timestamp.fromDate(endDate!);
                    }

                    try {
                      if (isEdit) {
                        await _notificationsRef.doc(docId).update(payload);
                      } else {
                        final docRef = _notificationsRef.doc();
                        await docRef.set({
                          ...payload,
                          'id': docRef.id,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }

                      if (!context.mounted || !dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Cập nhật thông báo thành công'
                                : 'Thêm thông báo thành công',
                          ),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Không thể lưu thông báo: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteNotification(String notificationId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          'Xác nhận xóa',
          style: GoogleFonts.leagueSpartan(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'Bạn chắc chắn muốn xóa thông báo này?',
          style: TextStyle(color: Colors.white70),
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
                await _notificationsRef.doc(notificationId).delete();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Xóa thông báo thành công')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Không thể xóa thông báo: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _danger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> data, String docId) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    final isPromotion = type == 'promotion';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết thông báo',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoLine('Mã', docId),
                _buildInfoLine('Tiêu đề', (data['title'] ?? '').toString()),
                _buildInfoLine('Mô tả', (data['description'] ?? '').toString()),
                _buildInfoLine(
                  'Mã sản phẩm',
                  (data['productId'] ?? '').toString(),
                ),
                _buildInfoLine(
                  'Loại',
                  isPromotion
                      ? 'Ưu đãi (promotion)'
                      : (data['type'] ?? '').toString(),
                ),
                _buildInfoLine('Dòng xe', (data['carModel'] ?? '').toString()),
                _buildInfoLine(
                  'Giá gốc',
                  (data['originalPrice'] ?? '').toString(),
                ),
                _buildInfoLine(
                  'Giá ưu đãi',
                  (data['discountPrice'] ?? '').toString(),
                ),
                _buildInfoLine(
                  'Giảm giá',
                  (data['discountPercent'] ?? '').toString(),
                ),
                _buildInfoLine(
                  'Banner key',
                  (data['bannerKey'] ?? '').toString(),
                ),
                _buildInfoLine('Ảnh', (data['imageUrl'] ?? '').toString()),
                _buildInfoLine('Bắt đầu', _formatDate(data['startDate'])),
                _buildInfoLine('Kết thúc', _formatDate(data['endDate'])),
                _buildInfoLine('Ngày tạo', _formatDate(data['createdAt'])),
                _buildInfoLine(
                  'Đã đọc',
                  data['isRead'] == true ? 'Có' : 'Chưa',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showNotificationDialog(
                            notification: data,
                            docId: docId,
                          );
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _deleteNotification(docId);
                        },
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập $label',
              hintStyle: const TextStyle(color: Colors.white54),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
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

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  String _formatDate(dynamic raw) {
    final date = _parseDate(raw);
    if (date == null) return '-';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
