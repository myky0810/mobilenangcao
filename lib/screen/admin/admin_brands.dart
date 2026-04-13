import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFF00A8FF);
  static const Color _success = Color(0xFF4ADE80);
  static const Color _danger = Color(0xFFEF4444);

  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference<Map<String, dynamic>> _brandsRef = FirebaseFirestore
      .instance
      .collection('brands');

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterMode = 'tat_ca';
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _productsRef.snapshots(),
        builder: (context, productsSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _brandsRef.snapshots(),
            builder: (context, brandsSnapshot) {
              if (productsSnapshot.connectionState == ConnectionState.waiting ||
                  brandsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                  ),
                );
              }

              if (productsSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Không thể tải dữ liệu sản phẩm: ${productsSnapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              if (brandsSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Không thể tải dữ liệu hãng: ${brandsSnapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final products = productsSnapshot.data?.docs ?? [];
              final brandDocs = brandsSnapshot.data?.docs ?? [];
              final brandMap = _buildBrandMap(products, brandDocs);

              final filteredBrands =
                  brandMap.values.where((brand) {
                    final matchesSearch = _searchQuery.isEmpty
                        ? true
                        : brand.displayName.toLowerCase().contains(
                            _searchQuery,
                          );

                    final matchesFilter = switch (_filterMode) {
                      'co_san_pham' => brand.productCount > 0,
                      'chua_co_san_pham' => brand.productCount == 0,
                      _ => true,
                    };

                    return matchesSearch && matchesFilter;
                  }).toList()..sort((a, b) {
                    final countCompare = b.productCount.compareTo(
                      a.productCount,
                    );
                    if (countCompare != 0) return countCompare;
                    return a.displayName.toLowerCase().compareTo(
                      b.displayName.toLowerCase(),
                    );
                  });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'Quản lý hãng xe',
                    subtitle: 'Quản lý danh sách hãng và số lượng sản phẩm',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: _isMigrating ? null : _runMigrateBrands,
                        style: adminOutlineButtonStyle(),
                        icon: _isMigrating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_alt_rounded, size: 16),
                        label: const Text('Chuẩn hóa'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isMigrating ? null : _showAddBrandDialog,
                        style: adminPrimaryButtonStyle(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm hãng'),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildSearchAndFilter(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      'Tổng ${filteredBrands.length} hãng (${brandMap.length} hãng toàn hệ thống)',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredBrands.isEmpty
                        ? _buildEmptyState('Không tìm thấy hãng phù hợp')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: filteredBrands.length,
                            itemBuilder: (context, index) {
                              final brand = filteredBrands[index];
                              final primaryId = brand.primaryBrandDocId;
                              return GestureDetector(
                                onTap: () => _showBrandDetailsModal(brand),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _accent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.directions_car,
                                            color: _accent,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              brand.displayName,
                                              style: GoogleFonts.leagueSpartan(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${brand.productCount} sản phẩm',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (primaryId.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'ID: $primaryId',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white54,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
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
            hintText: 'Tìm theo tên hãng...',
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
            _buildFilterChip('Có sản phẩm', 'co_san_pham'),
            _buildFilterChip('Chưa có sản phẩm', 'chua_co_san_pham'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filterMode == value;
    return adminFilterChip(
      label: label,
      selected: selected,
      selectedColor: _accent,
      unselectedColor: _card,
      onTap: () => setState(() => _filterMode = value),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.directions_car, size: 64, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, _BrandAggregate> _buildBrandMap(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> productDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> brandDocs,
  ) {
    final result = <String, _BrandAggregate>{};

    for (final doc in productDocs) {
      final data = doc.data();
      final name = _extractBrandName(data);
      if (name.isEmpty) continue;

      final normalized = _normalizeBrand(name);
      result.putIfAbsent(
        normalized,
        () => _BrandAggregate(
          normalizedName: normalized,
          displayName: name,
          productCount: 0,
          productDocIds: <String>[],
          relatedBrandDocIds: <String>[],
        ),
      );

      final item = result[normalized]!;
      item.productCount += 1;
      item.productDocIds.add(doc.id);
    }

    for (final doc in brandDocs) {
      final data = doc.data();
      final brandName = (data['brandName'] ?? '').toString().trim();
      if (brandName.isEmpty) continue;

      final normalized = _normalizeBrand(brandName);
      result.putIfAbsent(
        normalized,
        () => _BrandAggregate(
          normalizedName: normalized,
          displayName: brandName,
          productCount: 0,
          productDocIds: <String>[],
          relatedBrandDocIds: <String>[],
        ),
      );

      final item = result[normalized]!;
      if (!item.relatedBrandDocIds.contains(doc.id)) {
        item.relatedBrandDocIds.add(doc.id);
      }
      if (item.displayName.trim().isEmpty) {
        item.displayName = brandName;
      }
    }

    return result;
  }

  String _extractBrandName(Map<String, dynamic> data) {
    final brandName = (data['brandName'] ?? '').toString().trim();
    final brand = (data['brand'] ?? '').toString().trim();
    final carBrand = (data['carBrand'] ?? '').toString().trim();

    if (brandName.isNotEmpty) return brandName;
    if (brand.isNotEmpty) return brand;
    if (carBrand.isNotEmpty) return carBrand;
    return '';
  }

  String _normalizeBrand(String input) {
    return input.trim().toLowerCase();
  }

  void _showBrandDetailsModal(_BrandAggregate brand) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết hãng',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoBox('Tên hãng', brand.displayName),
                const SizedBox(height: 12),
                _buildInfoBox(
                  'ID hãng (document ID)',
                  brand.relatedBrandDocIds.isEmpty
                      ? 'Chưa có brand document hợp lệ'
                      : brand.relatedBrandDocIds.join('\n'),
                ),
                const SizedBox(height: 12),
                _buildInfoBox('Số lượng sản phẩm', '${brand.productCount} xe'),
                const SizedBox(height: 20),
                if (brand.productCount > 0)
                  FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: _productsRef
                        .where(
                          Filter.or(
                            Filter('brandName', isEqualTo: brand.displayName),
                            Filter('brand', isEqualTo: brand.displayName),
                            Filter('carBrand', isEqualTo: brand.displayName),
                          ),
                        )
                        .limit(6)
                        .get(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Một số sản phẩm thuộc hãng',
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...docs.map((doc) {
                            final data = doc.data();
                            final name =
                                (data['name'] ?? data['carName'] ?? doc.id)
                                    .toString();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• $name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 18),
                        ],
                      );
                    },
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditBrandDialog(brand);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteBrandDialog(brand);
                        },
                        icon: const Icon(Icons.delete),
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

  Widget _buildInfoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _showroomBase,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBrandDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Thêm hãng mới',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập tên hãng',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: _showroomBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final brandName = controller.text.trim();
                if (brandName.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tên hãng không được để trống'),
                    ),
                  );
                  return;
                }

                final existingProducts = await _productsRef
                    .where('brandName', isEqualTo: brandName)
                    .limit(1)
                    .get();
                final existingProductsByBrand = await _productsRef
                    .where('brand', isEqualTo: brandName)
                    .limit(1)
                    .get();
                final existingProductsByCarBrand = await _productsRef
                    .where('carBrand', isEqualTo: brandName)
                    .limit(1)
                    .get();

                if (existingProducts.docs.isNotEmpty ||
                    existingProductsByBrand.docs.isNotEmpty ||
                    existingProductsByCarBrand.docs.isNotEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Hãng xe này đã tồn tại trong sản phẩm'),
                    ),
                  );
                  return;
                }

                final existingBrandDocs = await _brandsRef
                    .where('brandName', isEqualTo: brandName)
                    .limit(1)
                    .get();

                if (existingBrandDocs.docs.isEmpty) {
                  await _brandsRef.add({
                    'brandName': brandName,
                    'name': brandName,
                    'brand': brandName,
                    'slug': _slugify(brandName),
                    'productCount': 0,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã thêm hãng. Hãng sẽ hiện có sản phẩm khi bạn thêm xe ở Quản lý sản phẩm.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runMigrateBrands() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateBrands();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa hãng xe xong: quét ${result['scanned']}, cập nhật ${result['updated']}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chuẩn hóa hãng xe thất bại: $e')));
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  void _showEditBrandDialog(_BrandAggregate brand) {
    final controller = TextEditingController(text: brand.displayName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Sửa tên hãng',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập tên hãng mới',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: _showroomBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final newName = controller.text.trim();
                if (newName.isEmpty || newName == brand.displayName) {
                  Navigator.pop(context);
                  return;
                }

                final duplicateByBrandName = await _productsRef
                    .where('brandName', isEqualTo: newName)
                    .limit(1)
                    .get();
                final duplicateByBrand = await _productsRef
                    .where('brand', isEqualTo: newName)
                    .limit(1)
                    .get();
                final duplicateByCarBrand = await _productsRef
                    .where('carBrand', isEqualTo: newName)
                    .limit(1)
                    .get();

                final hasDuplicateInProducts =
                    duplicateByBrandName.docs.any(
                      (doc) => !brand.productDocIds.contains(doc.id),
                    ) ||
                    duplicateByBrand.docs.any(
                      (doc) => !brand.productDocIds.contains(doc.id),
                    ) ||
                    duplicateByCarBrand.docs.any(
                      (doc) => !brand.productDocIds.contains(doc.id),
                    );

                if (hasDuplicateInProducts) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tên hãng mới đã tồn tại')),
                  );
                  return;
                }

                final batch = FirebaseFirestore.instance.batch();

                for (final productId in brand.productDocIds) {
                  final ref = _productsRef.doc(productId);
                  batch.update(ref, {
                    'brandName': newName,
                    'brand': newName,
                    'carBrand': newName,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }

                for (final brandDocId in brand.relatedBrandDocIds) {
                  batch.update(_brandsRef.doc(brandDocId), {
                    'brandName': newName,
                    'name': newName,
                    'brand': newName,
                    'slug': _slugify(newName),
                    'productCount': brand.productCount,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }

                await batch.commit();

                if (!context.mounted) return;
                Navigator.pop(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã cập nhật hãng "${brand.displayName}" thành "$newName"',
                    ),
                    backgroundColor: _success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteBrandDialog(_BrandAggregate brand) {
    final hasProducts =
        brand.productCount > 0 || brand.productDocIds.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _card,
          title: Text(
            'Xóa hãng xe',
            style: GoogleFonts.leagueSpartan(
              color: _danger,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            hasProducts
                ? 'Hãng "${brand.displayName}" đang có ${brand.productCount} sản phẩm. Bạn phải xóa hoặc chuyển toàn bộ sản phẩm sang hãng khác trước khi xóa hãng.'
                : 'Bạn chắc chắn muốn xóa hãng "${brand.displayName}"?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: hasProducts
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final batch = FirebaseFirestore.instance.batch();

                      if (brand.productCount > 0 ||
                          brand.productDocIds.isNotEmpty) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Không thể xóa hãng "${brand.displayName}" vì vẫn còn sản phẩm liên quan',
                            ),
                          ),
                        );
                        return;
                      }

                      for (final brandDocId in brand.relatedBrandDocIds) {
                        batch.delete(_brandsRef.doc(brandDocId));
                      }

                      await batch.commit();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Đã xóa hãng "${brand.displayName}"'),
                          backgroundColor: _success,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
  }
}

class _BrandAggregate {
  _BrandAggregate({
    required this.normalizedName,
    required this.displayName,
    required this.productCount,
    required this.productDocIds,
    required this.relatedBrandDocIds,
  });

  final String normalizedName;
  String displayName;
  int productCount;
  final List<String> productDocIds;
  final List<String> relatedBrandDocIds;

  String get primaryBrandDocId =>
      relatedBrandDocIds.isNotEmpty ? relatedBrandDocIds.first : '';
}
