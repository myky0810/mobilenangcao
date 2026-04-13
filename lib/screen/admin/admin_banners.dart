import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFFFF9500);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFEF4444);

  final CollectionReference<Map<String, dynamic>> _bannersRef =
      FirebaseFirestore.instance.collection('banners');
  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterStatus = 'all';
  bool _isMigrating = false;

  static const List<String> _statusFilters = ['all', 'active', 'inactive'];

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
            title: 'Quản lý banner',
            subtitle: 'Quản lý banner hiển thị và trạng thái kích hoạt',
            actions: [
              OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigrateBanners,
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
                onPressed: _isMigrating ? null : () => _showBannerDialog(),
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
                    hintText:
                        'Tìm tiêu đề, mô tả, key, image, productId, giảm giá...',
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
                    final selected = _filterStatus == status;
                    return adminFilterChip(
                      label: _statusLabel(status),
                      selected: selected,
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
              stream: _bannersRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không thể tải banner: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final banners =
                    (snapshot.data?.docs ?? [])
                        .map((doc) => {'docId': doc.id, ...doc.data()})
                        .toList()
                      ..sort(
                        (a, b) => _extractDate(b['createdAt'] ?? b['updatedAt'])
                            .compareTo(
                              _extractDate(a['createdAt'] ?? a['updatedAt']),
                            ),
                      );

                final filteredBanners = banners.where(_matchesBanner).toList();

                if (banners.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Không có banner',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Text(
                        'Hiển thị ${filteredBanners.length}/${banners.length} banner',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredBanners.isEmpty
                          ? _buildEmptyState('Không có banner phù hợp bộ lọc')
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filteredBanners.length,
                              itemBuilder: (context, index) {
                                return _buildBannerCard(filteredBanners[index]);
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

  Widget _buildBannerCard(Map<String, dynamic> banner) {
    final docId = (banner['docId'] ?? '').toString();
    final isActive = banner['isActive'] == true;
    final title = (banner['title'] ?? 'Chưa có tiêu đề').toString();
    final badge = (banner['badge'] ?? '').toString().trim();
    final imageUrl = (banner['imageUrl'] ?? banner['image'] ?? '')
        .toString()
        .trim();
    final description = (banner['description'] ?? '').toString().trim();
    final productId = (banner['productId'] ?? '').toString().trim();
    final discountPercent = (banner['discountPercent'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _accent.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white10,
            ),
            child: _buildBannerPreview(imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badge.isNotEmpty) const SizedBox(height: 4),
                if (badge.isNotEmpty)
                  Text(
                    badge,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (productId.isNotEmpty) const SizedBox(height: 4),
                if (productId.isNotEmpty)
                  Text(
                    'Product: $productId',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (discountPercent.isNotEmpty) const SizedBox(height: 4),
                if (discountPercent.isNotEmpty)
                  Text(
                    'Giảm: $discountPercent',
                    style: const TextStyle(color: _accent, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isActive ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        onChanged: (value) => _toggleBannerStatus(docId, value),
                        activeThumbColor: _success,
                      ),
                    ),
                    Text(
                      isActive ? 'Bật' : 'Tắt',
                      style: TextStyle(
                        color: isActive ? _success : _danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: _card,
            onSelected: (value) {
              if (value == 'detail') {
                _showBannerDetailSheet(banner);
              }
              if (value == 'edit') {
                _showBannerDialog(banner: banner);
              }
              if (value == 'delete') {
                _confirmDeleteBanner(docId, title);
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'detail',
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text('Chi tiết', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Sửa', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
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
            child: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPreview(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.image_not_supported_rounded,
        color: Colors.white54,
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_rounded, color: Colors.white54),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_rounded, color: Colors.white54),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              color: Colors.white24,
              size: 56,
            ),
            const SizedBox(height: 8),
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

  void _showBannerDialog({Map<String, dynamic>? banner}) {
    final isEdit = banner != null;
    final badgeController = TextEditingController(
      text: (banner?['badge'] ?? '').toString(),
    );
    final titleController = TextEditingController(
      text: (banner?['title'] ?? '').toString(),
    );
    final subtitleController = TextEditingController(
      text: (banner?['subtitle'] ?? '').toString(),
    );
    final descriptionController = TextEditingController(
      text: (banner?['description'] ?? '').toString(),
    );
    final imageController = TextEditingController(
      text: (banner?['imageUrl'] ?? banner?['image'] ?? '').toString(),
    );
    final buttonTextController = TextEditingController(
      text: (banner?['buttonText'] ?? 'Khám phá ngay').toString(),
    );
    final sortOrderController = TextEditingController(
      text: (banner?['sortOrder'] ?? 1).toString(),
    );
    final accentColorController = TextEditingController(
      text: _formatColorForInput(banner?['accentColor']),
    );
    final subtitleColorController = TextEditingController(
      text: _formatColorForInput(banner?['subtitleColor']),
    );
    final gradientColorsController = TextEditingController(
      text: _formatGradientForInput(banner?['gradientColors']),
    );
    final benefitsController = TextEditingController(
      text: _formatBenefitsForInput(banner?['benefits']),
    );
    final originalPriceController = TextEditingController(
      text: (banner?['originalPrice'] ?? '').toString(),
    );
    final discountPriceController = TextEditingController(
      text: (banner?['discountPrice'] ?? '').toString(),
    );
    final discountPercentController = TextEditingController(
      text: (banner?['discountPercent'] ?? '').toString(),
    );
    var selectedProductId = (banner?['productId'] ?? '').toString();
    var selectedProductName = (banner?['carModel'] ?? '').toString();
    var isActive = banner?['isActive'] == true;
    if (!isEdit) isActive = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _card,
          title: Text(
            isEdit ? 'Sửa banner' : 'Thêm banner',
            style: GoogleFonts.leagueSpartan(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogInput(controller: badgeController, label: 'Nhãn'),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: titleController,
                  label: 'Tiêu đề',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: subtitleController,
                  label: 'Phụ đề',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: descriptionController,
                  label: 'Mô tả',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: imageController,
                  label: 'Ảnh (URL hoặc assets)',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: buttonTextController,
                  label: 'Chữ nút',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: sortOrderController,
                  label: 'Thứ tự hiển thị',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: accentColorController,
                  label: 'Màu nhấn (vd: 0xFF3B82F6 hoặc #3B82F6)',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: subtitleColorController,
                  label: 'Màu phụ đề (vd: 0xFF10B981 hoặc #10B981)',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: gradientColorsController,
                  label: 'Màu nền chuyển sắc (phân tách dấu phẩy)',
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _productsRef.limit(300).snapshots(),
                  builder: (context, snapshot) {
                    final options =
                        (snapshot.data?.docs ?? []).map((doc) {
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
                            'image': (data['image'] ?? data['carImage'] ?? '')
                                .toString(),
                            'price': (data['price'] ?? data['carPrice'] ?? '')
                                .toString(),
                          };
                        }).toList()..sort(
                          (a, b) =>
                              (a['name'] ?? '').compareTo(b['name'] ?? ''),
                        );

                    final hasSelected = options.any(
                      (option) => option['id'] == selectedProductId,
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
                          initialValue: hasSelected ? selectedProductId : null,
                          isExpanded: true,
                          dropdownColor: _card,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Chọn sản phẩm ưu đãi',
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
                              (option) => option['id'] == value,
                            );
                            setDialogState(() {
                              selectedProductId = value;
                              selectedProductName = (selected['name'] ?? '')
                                  .toString();
                              if (imageController.text.trim().isEmpty) {
                                imageController.text = (selected['image'] ?? '')
                                    .toString();
                              }
                              if (originalPriceController.text.trim().isEmpty) {
                                originalPriceController.text =
                                    (selected['price'] ?? '').toString();
                              }
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: originalPriceController,
                  label: 'Giá gốc',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: discountPriceController,
                  label: 'Giá ưu đãi',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: discountPercentController,
                  label: 'Phần trăm giảm (vd: 15%)',
                ),
                const SizedBox(height: 10),
                _buildDialogInput(
                  controller: benefitsController,
                  label: 'Benefits (mỗi dòng 1 quyền lợi)',
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trạng thái hiển thị',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                      activeThumbColor: _success,
                    ),
                  ],
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
                final rootMessenger = ScaffoldMessenger.of(this.context);
                final dialogNavigator = Navigator.of(dialogContext);
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  rootMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tiêu đề không được để trống'),
                    ),
                  );
                  return;
                }

                final sortOrder =
                    int.tryParse(sortOrderController.text.trim()) ?? 1;

                final accentColor = _parseColorToInt(
                  accentColorController.text.trim(),
                  fallback: 0xFF55A7FF,
                );
                final subtitleColor = _parseColorToInt(
                  subtitleColorController.text.trim(),
                  fallback: 0xFF10B981,
                );

                final gradientColors = _parseGradientColors(
                  gradientColorsController.text.trim(),
                  fallback: const [0xFF0D1117, 0xFF161B22, 0xFF21262D],
                );

                final benefits = benefitsController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final normalizedProductId = selectedProductId.trim();

                final payload = <String, dynamic>{
                  'badge': badgeController.text.trim(),
                  'title': title,
                  'subtitle': subtitleController.text.trim(),
                  'buttonText': buttonTextController.text.trim().isEmpty
                      ? 'Khám phá ngay'
                      : buttonTextController.text.trim(),
                  'sortOrder': sortOrder,
                  'accentColor': accentColor,
                  'subtitleColor': subtitleColor,
                  'gradientColors': gradientColors,
                  'description': descriptionController.text.trim(),
                  'benefits': benefits,
                  'imageUrl': imageController.text.trim(),
                  'image': imageController.text.trim(),
                  'productId': normalizedProductId,
                  'carModel': selectedProductName.trim(),
                  'originalPrice': originalPriceController.text.trim(),
                  'discountPrice': discountPriceController.text.trim(),
                  'discountPercent': discountPercentController.text.trim(),
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                try {
                  if (isEdit) {
                    final docId = (banner['docId'] ?? '').toString();
                    final cleanupPayload = <String, dynamic>{
                      ...payload,
                      'bannerKey': FieldValue.delete(),
                      'originalPrice ': FieldValue.delete(),
                      'discountPrice ': FieldValue.delete(),
                      'discountPercent ': FieldValue.delete(),
                    };
                    await _bannersRef.doc(docId).update(cleanupPayload);
                  } else {
                    payload['createdAt'] = FieldValue.serverTimestamp();
                    await _bannersRef.add(payload);
                  }

                  if (!mounted) return;
                  dialogNavigator.pop();
                  rootMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'Cập nhật banner thành công'
                            : 'Thêm banner thành công',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  rootMessenger.showSnackBar(
                    SnackBar(content: Text('Không thể lưu banner: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
              ),
              child: Text(isEdit ? 'Lưu' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogInput({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Column(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _runMigrateBanners() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateBanners();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa banner xong: quét ${result['scanned']}, cập nhật ${result['updated']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chuẩn hóa banner thất bại: $e')));
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  void _showBannerDetailSheet(Map<String, dynamic> banner) {
    final createdAt = _extractDate(banner['createdAt']);
    final updatedAt = _extractDate(banner['updatedAt']);

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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                    'Chi tiết banner',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildBannerPreview(
                        (banner['imageUrl'] ?? banner['image'] ?? '')
                            .toString()
                            .trim(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Mã tài liệu', (banner['docId'] ?? '').toString()),
                  _detailRow('Nhãn', (banner['badge'] ?? '').toString()),
                  _detailRow('Tiêu đề', (banner['title'] ?? '').toString()),
                  _detailRow('Phụ đề', (banner['subtitle'] ?? '').toString()),
                  _detailRow(
                    'Chữ nút',
                    (banner['buttonText'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Thứ tự hiển thị',
                    (banner['sortOrder'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Màu nhấn',
                    (banner['accentColor'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Màu phụ đề',
                    (banner['subtitleColor'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Màu nền chuyển sắc',
                    _formatGradientForInput(banner['gradientColors']),
                  ),
                  _detailRow('Mô tả', (banner['description'] ?? '').toString()),
                  _detailRow(
                    'Quyền lợi',
                    _formatBenefitsForInput(banner['benefits']),
                  ),
                  _detailRow(
                    'Mã sản phẩm',
                    (banner['productId'] ?? '').toString(),
                  ),
                  _detailRow('Dòng xe', (banner['carModel'] ?? '').toString()),
                  _detailRow(
                    'Giá gốc',
                    (banner['originalPrice'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Giá ưu đãi',
                    (banner['discountPrice'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Phần trăm giảm',
                    (banner['discountPercent'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Ảnh (URL)',
                    (banner['imageUrl'] ?? banner['image'] ?? '').toString(),
                  ),
                  _detailRow(
                    'Trạng thái',
                    banner['isActive'] == true ? 'Đang bật' : 'Đang tắt',
                  ),
                  _detailRow('Tạo lúc', _formatDateTime(createdAt)),
                  _detailRow('Cập nhật', _formatDateTime(updatedAt)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

  Future<void> _toggleBannerStatus(String bannerId, bool newStatus) async {
    try {
      await _bannersRef.doc(bannerId).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể đổi trạng thái: $e')));
    }
  }

  Future<void> _confirmDeleteBanner(String bannerId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc muốn xóa banner "$title"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _danger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _bannersRef.doc(bannerId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Xóa banner thành công')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể xóa banner: $e')));
    }
  }

  bool _matchesBanner(Map<String, dynamic> banner) {
    final isActive = banner['isActive'] == true;

    if (_filterStatus == 'active' && !isActive) return false;
    if (_filterStatus == 'inactive' && isActive) return false;

    if (_searchQuery.isEmpty) return true;

    final haystack = [
      banner['docId'],
      banner['title'],
      banner['subtitle'],
      banner['description'],
      banner['imageUrl'],
      banner['image'],
      banner['productId'],
      banner['carModel'],
      banner['badge'],
      banner['buttonText'],
      banner['sortOrder'],
      banner['accentColor'],
      banner['subtitleColor'],
      banner['gradientColors'],
      banner['benefits'],
      banner['originalPrice'],
      banner['discountPrice'],
      banner['discountPercent'],
    ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

    return haystack.contains(_searchQuery);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Đang bật';
      case 'inactive':
        return 'Đang tắt';
      case 'all':
        return 'Tất cả';
      default:
        return status;
    }
  }

  DateTime _extractDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime(1970);
    return DateTime(1970);
  }

  String _formatDateTime(DateTime dateTime) {
    if (dateTime.year <= 1970) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _formatColorForInput(dynamic raw) {
    if (raw is num) {
      final hex = raw.toInt().toRadixString(16).toUpperCase();
      return '0x${hex.padLeft(8, '0')}';
    }
    final text = (raw ?? '').toString().trim();
    return text;
  }

  int _parseColorToInt(String raw, {required int fallback}) {
    if (raw.isEmpty) return fallback;

    if (raw.startsWith('0x') || raw.startsWith('0X')) {
      return int.tryParse(raw.substring(2), radix: 16) ?? fallback;
    }

    if (raw.startsWith('#')) {
      final hex = raw.substring(1);
      if (hex.length == 6) {
        return int.tryParse('FF$hex', radix: 16) ?? fallback;
      }
      if (hex.length == 8) {
        return int.tryParse(hex, radix: 16) ?? fallback;
      }
      return fallback;
    }

    return int.tryParse(raw) ?? fallback;
  }

  String _formatGradientForInput(dynamic raw) {
    if (raw is List) {
      final values = raw
          .whereType<num>()
          .map(
            (e) =>
                '0x${e.toInt().toRadixString(16).toUpperCase().padLeft(8, '0')}',
          )
          .toList();
      return values.join(', ');
    }
    return '';
  }

  List<int> _parseGradientColors(String raw, {required List<int> fallback}) {
    if (raw.isEmpty) return fallback;

    final parsed = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => _parseColorToInt(e, fallback: -1))
        .where((e) => e >= 0)
        .toList();

    return parsed.isEmpty ? fallback : parsed;
  }

  String _formatBenefitsForInput(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join('\n');
    }
    return '';
  }
}
