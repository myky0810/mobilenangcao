import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_migration_service.dart';
import 'widgets/admin_ui.dart';

enum _PriceSortOption { none, ascending, descending }

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFF00FF88);
  static const String _draftBrandPrefix = '__draft_brand__:';

  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference<Map<String, dynamic>> _brandsRef = FirebaseFirestore
      .instance
      .collection('brands');
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isMigrating = false;

  String _selectedCategory = 'Tất cả';
  String _selectedSeatFilter = 'Tất cả';
  String _selectedFuelType = 'Tất cả';
  String _selectedDriveType = 'Tất cả';
  String _selectedPriceRange = 'Tất cả';
  String _selectedTransmission = 'Tất cả';
  String _selectedPowerRange = 'Tất cả';
  String _selectedPurpose = 'Tất cả';
  _PriceSortOption _sortOption = _PriceSortOption.none;
  final Set<String> _selectedBrands = <String>{};

  List<Map<String, dynamic>> _cachedProducts = const [];

  final List<String> _seatFilters = const [
    'Tất cả',
    '2-4 chỗ',
    '5 chỗ',
    '6-7 chỗ',
    '8+ chỗ',
  ];

  final List<String> _fuelFilters = const [
    'Tất cả',
    'Xăng',
    'Dầu',
    'Điện',
    'Hybrid',
    'Hydrogen',
  ];

  final List<String> _driveFilters = const [
    'Tất cả',
    'FWD',
    'RWD',
    'AWD',
    '4WD',
  ];

  final List<String> _priceRanges = const [
    'Tất cả',
    'Dưới 2 tỷ',
    '2 - 5 tỷ',
    '5 - 10 tỷ',
    'Trên 10 tỷ',
  ];

  final List<String> _transmissionFilters = const [
    'Tất cả',
    'Số tự động',
    'Số sàn',
    '1 cấp',
  ];

  final List<String> _powerRanges = const [
    'Tất cả',
    'Dưới 250 HP',
    '250 - 400 HP',
    'Trên 400 HP',
  ];

  final List<String> _purposeFilters = const [
    'Tất cả',
    'Gia đình',
    'Thể thao',
    'Đô thị',
    'Off-road',
    'Doanh nhân',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _syncBrandProductCounts();
      } catch (_) {
        // Keep screen usable even if sync fails.
      }
    });
  }

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
            title: 'Quản lý sản phẩm ',
            subtitle: 'Theo dõi danh sách xe và bộ lọc nâng cao',
            actions: [
              OutlinedButton.icon(
                onPressed: _isMigrating ? null : _runMigrateProducts,
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
                onPressed: _isMigrating ? null : _showAddProductDialog,
                style: adminPrimaryButtonStyle(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm'),
              ),
            ],
          ),
          _buildSearchAndAdvancedFilters(),
          Expanded(child: _buildProductsStream()),
        ],
      ),
    );
  }

  Widget _buildSearchAndAdvancedFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên xe, hãng, giá hoặc mã...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  IconButton(
                    onPressed: _openAdvancedFilterSheet,
                    icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                    tooltip: 'Lọc nâng cao',
                  ),
                ],
              ),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _productsRef.orderBy('updatedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Không thể tải dữ liệu products: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? const [];
        _cachedProducts = docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        if (docs.isEmpty) {
          return _buildEmptyState('Không có sản phẩm');
        }

        return _buildProductsList(docs);
      },
    );
  }

  Widget _buildProductsList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final keyword = _normalizeText(_searchQuery);
    final filteredDocs = docs.where((doc) {
      final data = doc.data();
      final brand = _extractBrandName(data);
      final category = (data['category'] ?? '').toString().trim();
      final seats = (data['seats'] ?? '').toString().trim();
      final fuelType = (data['fuelType'] ?? '').toString().trim();
      final driveType = (data['driveType'] ?? '').toString().trim();
      final transmission = (data['transmission'] ?? '').toString().trim();
      final purpose = (data['purpose'] ?? '').toString().trim();
      final priceValue = _extractPriceValue(
        (data['price'] ?? data['carPrice'] ?? '').toString(),
      );
      final horsepower = _extractHorsepower(data['horsepower']);

      final matchesCategory =
          _selectedCategory == 'Tất cả' || category == _selectedCategory;
      final matchesBrand =
          _selectedBrands.isEmpty || _selectedBrands.contains(brand);
      final matchesSeats =
          _selectedSeatFilter == 'Tất cả' ||
          _seatMatches(seats, _selectedSeatFilter);
      final matchesFuel =
          _selectedFuelType == 'Tất cả' || fuelType == _selectedFuelType;
      final matchesDrive =
          _selectedDriveType == 'Tất cả' || driveType == _selectedDriveType;
      final matchesPrice = _matchesPriceRange(priceValue, _selectedPriceRange);
      final matchesTransmission =
          _selectedTransmission == 'Tất cả' ||
          transmission == _selectedTransmission;
      final matchesPower = _matchesPowerRange(horsepower, _selectedPowerRange);
      final matchesPurpose =
          _selectedPurpose == 'Tất cả' || purpose == _selectedPurpose;

      final searchData = [
        doc.id,
        data['name'],
        data['carName'],
        brand,
        category,
        seats,
        fuelType,
        driveType,
        transmission,
        purpose,
        data['description'],
        data['carDescription'],
        data['price'],
        data['carPrice'],
        '$horsepower hp',
      ].map((item) => _normalizeText(item?.toString())).join(' ');

      final matchesSearch = keyword.isEmpty || searchData.contains(keyword);

      return matchesCategory &&
          matchesBrand &&
          matchesSeats &&
          matchesFuel &&
          matchesDrive &&
          matchesPrice &&
          matchesTransmission &&
          matchesPower &&
          matchesPurpose &&
          matchesSearch;
    }).toList();

    if (_sortOption != _PriceSortOption.none) {
      filteredDocs.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();
        final priceA = _extractPriceValue(
          (dataA['price'] ?? dataA['carPrice'] ?? '').toString(),
        );
        final priceB = _extractPriceValue(
          (dataB['price'] ?? dataB['carPrice'] ?? '').toString(),
        );
        if (_sortOption == _PriceSortOption.ascending) {
          return priceA.compareTo(priceB);
        }
        return priceB.compareTo(priceA);
      });
    }

    if (filteredDocs.isEmpty) {
      return _buildEmptyState('Không tìm thấy sản phẩm phù hợp bộ lọc');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final product = {'id': doc.id, ...doc.data()};
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car, color: Colors.white24, size: 64),
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    final image =
        (product['image'] ?? product['carImage'] ?? '')
            .toString()
            .trim()
            .isEmpty
        ? 'assets/images/RR.jpg'
        : (product['image'] ?? product['carImage']).toString();

    final name = (product['name'] ?? product['carName'] ?? 'Không xác định')
        .toString();
    final brand =
        (product['brandName'] ??
                product['carBrand'] ??
                product['brand'] ??
                'Chưa có hãng')
            .toString();
    final price = (product['price'] ?? product['carPrice'] ?? 'Liên hệ')
        .toString();

    final isNetworkImage =
        image.startsWith('http://') || image.startsWith('https://');

    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
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
              child: isNetworkImage
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, err, stackTrace) =>
                          const Icon(Icons.error_outline),
                    )
                  : Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, err, stackTrace) =>
                          const Icon(Icons.error_outline),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                    brand,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              color: _card,
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Chi tiết', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () => _showProductDetails(product),
                ),
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Sửa', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () => _showEditProductDialog(product),
                ),
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () => _deleteProduct(product['id'].toString()),
                ),
              ],
              child: const Icon(Icons.more_vert_rounded, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _availableBrands {
    final values = <String>{};
    for (final product in _cachedProducts) {
      final brandName = _extractBrandName(product);
      if (brandName.isNotEmpty) {
        values.add(brandName);
      }
    }

    final result = values.toList()
      ..sort((a, b) => _normalizeText(a).compareTo(_normalizeText(b)));
    return result;
  }

  List<String> get _availableCategories {
    final values = <String>{};
    for (final product in _cachedProducts) {
      final category = (product['category'] ?? '').toString().trim();
      if (category.isNotEmpty) {
        values.add(category);
      }
    }

    final result = values.toList()
      ..sort((a, b) => _normalizeText(a).compareTo(_normalizeText(b)));
    return result;
  }

  void _resetAdvancedFilters() {
    setState(() {
      _selectedCategory = 'Tất cả';
      _selectedSeatFilter = 'Tất cả';
      _selectedFuelType = 'Tất cả';
      _selectedDriveType = 'Tất cả';
      _selectedPriceRange = 'Tất cả';
      _selectedTransmission = 'Tất cả';
      _selectedPowerRange = 'Tất cả';
      _selectedPurpose = 'Tất cả';
      _selectedBrands.clear();
      _sortOption = _PriceSortOption.none;
    });
  }

  Future<void> _openAdvancedFilterSheet() async {
    var tempSelectedCategory = _selectedCategory;
    var tempSelectedSeatFilter = _selectedSeatFilter;
    var tempSelectedFuelType = _selectedFuelType;
    var tempSelectedDriveType = _selectedDriveType;
    var tempSelectedPriceRange = _selectedPriceRange;
    var tempSelectedTransmission = _selectedTransmission;
    var tempSelectedPowerRange = _selectedPowerRange;
    var tempSelectedPurpose = _selectedPurpose;
    var tempSortOption = _sortOption;
    final tempSelectedBrands = Set<String>.from(_selectedBrands);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categoryOptions = <String>{'Tất cả', ..._availableCategories};
            if (tempSelectedCategory.trim().isNotEmpty) {
              categoryOptions.add(tempSelectedCategory);
            }

            final brandOptions =
                <String>{..._availableBrands, ...tempSelectedBrands}.toList()
                  ..sort(
                    (a, b) => _normalizeText(a).compareTo(_normalizeText(b)),
                  );

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Lọc sản phẩm nâng cao',
                                      style: GoogleFonts.leagueSpartan(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        tempSelectedCategory = 'Tất cả';
                                        tempSelectedSeatFilter = 'Tất cả';
                                        tempSelectedFuelType = 'Tất cả';
                                        tempSelectedDriveType = 'Tất cả';
                                        tempSelectedPriceRange = 'Tất cả';
                                        tempSelectedTransmission = 'Tất cả';
                                        tempSelectedPowerRange = 'Tất cả';
                                        tempSelectedPurpose = 'Tất cả';
                                        tempSelectedBrands.clear();
                                        tempSortOption = _PriceSortOption.none;
                                      });
                                    },
                                    child: const Text('Đặt lại'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Hãng xe',
                                child: _buildMultiChoiceWrap(
                                  options: brandOptions,
                                  selectedOptions: tempSelectedBrands,
                                  onToggle: (brand, selected) {
                                    setModalState(() {
                                      if (selected) {
                                        tempSelectedBrands.add(brand);
                                      } else {
                                        tempSelectedBrands.remove(brand);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Loại xe',
                                child: _buildChoiceWrap(
                                  options: categoryOptions.toList()
                                    ..sort(
                                      (a, b) => _normalizeText(
                                        a,
                                      ).compareTo(_normalizeText(b)),
                                    ),
                                  selected: tempSelectedCategory,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedCategory = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Giá cả',
                                child: _buildChoiceWrap(
                                  options: _priceRanges,
                                  selected: tempSelectedPriceRange,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedPriceRange = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Số chỗ ngồi',
                                child: _buildChoiceWrap(
                                  options: _seatFilters,
                                  selected: tempSelectedSeatFilter,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedSeatFilter = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Loại nhiên liệu',
                                child: _buildChoiceWrap(
                                  options: _fuelFilters,
                                  selected: tempSelectedFuelType,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedFuelType = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Hộp số',
                                child: _buildChoiceWrap(
                                  options: _transmissionFilters,
                                  selected: tempSelectedTransmission,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedTransmission = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Công suất',
                                child: _buildChoiceWrap(
                                  options: _powerRanges,
                                  selected: tempSelectedPowerRange,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedPowerRange = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Dẫn động',
                                child: _buildChoiceWrap(
                                  options: _driveFilters,
                                  selected: tempSelectedDriveType,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedDriveType = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Mục đích sử dụng',
                                child: _buildChoiceWrap(
                                  options: _purposeFilters,
                                  selected: tempSelectedPurpose,
                                  onSelected: (value) => setModalState(
                                    () => tempSelectedPurpose = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildFilterSection(
                                title: 'Sắp xếp giá',
                                child: _buildSortChoiceWrap(
                                  selected: tempSortOption,
                                  onSelected: (value) => setModalState(
                                    () => tempSortOption = value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _resetAdvancedFilters();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Xóa lọc'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = tempSelectedCategory;
                                  _selectedSeatFilter = tempSelectedSeatFilter;
                                  _selectedFuelType = tempSelectedFuelType;
                                  _selectedDriveType = tempSelectedDriveType;
                                  _selectedPriceRange = tempSelectedPriceRange;
                                  _selectedTransmission =
                                      tempSelectedTransmission;
                                  _selectedPowerRange = tempSelectedPowerRange;
                                  _selectedPurpose = tempSelectedPurpose;
                                  _selectedBrands
                                    ..clear()
                                    ..addAll(tempSelectedBrands);
                                  _sortOption = tempSortOption;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAdminPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Áp dụng'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _showroomBase,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceWrap({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return adminFilterChip(
          label: _displayFilterLabel(option),
          selected: isSelected,
          selectedColor: kAdminPrimary,
          unselectedColor: _card,
          onTap: () => onSelected(option),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceWrap({
    required List<String> options,
    required Set<String> selectedOptions,
    required void Function(String option, bool selected) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return adminFilterChip(
          label: _displayFilterLabel(option),
          selected: isSelected,
          selectedColor: kAdminPrimary,
          unselectedColor: _card,
          onTap: () => onToggle(option, !isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildSortChoiceWrap({
    required _PriceSortOption selected,
    required ValueChanged<_PriceSortOption> onSelected,
  }) {
    final options = <MapEntry<String, _PriceSortOption>>[
      const MapEntry('Mặc định', _PriceSortOption.none),
      const MapEntry('Giá tăng dần', _PriceSortOption.ascending),
      const MapEntry('Giá giảm dần', _PriceSortOption.descending),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((entry) {
        final isSelected = selected == entry.value;
        return adminFilterChip(
          label: entry.key,
          selected: isSelected,
          selectedColor: kAdminPrimary,
          unselectedColor: _card,
          onTap: () => onSelected(entry.value),
        );
      }).toList(),
    );
  }

  String _displayFilterLabel(String option) {
    switch (option) {
      case 'Hybrid':
        return 'Lai điện';
      case 'Hydrogen':
        return 'Hydro';
      case 'Off-road':
        return 'Địa hình';
      default:
        return option;
    }
  }

  int _extractPriceValue(String price) {
    final numericString = price.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(numericString) ?? 0;
  }

  int _extractHorsepower(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final numericString = raw.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(numericString) ?? 0;
    }
    return 0;
  }

  bool _seatMatches(String seats, String filter) {
    if (seats.trim().isEmpty) return false;
    if (filter == '2-4 chỗ') return seats.contains('2') || seats.contains('4');
    if (filter == '5 chỗ') return seats.contains('5');
    if (filter == '6-7 chỗ') return seats.contains('6') || seats.contains('7');
    if (filter == '8+ chỗ') return seats.contains('8');
    return true;
  }

  bool _matchesPriceRange(int priceValue, String range) {
    switch (range) {
      case 'Dưới 2 tỷ':
        return priceValue < 2000000000;
      case '2 - 5 tỷ':
        return priceValue >= 2000000000 && priceValue <= 5000000000;
      case '5 - 10 tỷ':
        return priceValue > 5000000000 && priceValue <= 10000000000;
      case 'Trên 10 tỷ':
        return priceValue > 10000000000;
      default:
        return true;
    }
  }

  bool _matchesPowerRange(int horsepower, String range) {
    switch (range) {
      case 'Dưới 250 HP':
        return horsepower < 250;
      case '250 - 400 HP':
        return horsepower >= 250 && horsepower <= 400;
      case 'Trên 400 HP':
        return horsepower > 400;
      default:
        return true;
    }
  }

  String _normalizeText(String? value) {
    if (value == null) return '';
    var result = value.toLowerCase().trim();
    const map = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ă': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ơ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };
    map.forEach((key, value) => result = result.replaceAll(key, value));
    return result;
  }

  Future<void> _showAddProductDialog() async {
    await _syncBrandProductCounts();
    if (!mounted) return;
    _showProductDialog(null);
  }

  Future<void> _runMigrateProducts() async {
    setState(() => _isMigrating = true);
    try {
      final result = await AdminMigrationService.migrateProducts();
      await _syncBrandProductCounts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuẩn hóa sản phẩm xong: quét ${result['scanned']}, cập nhật ${result['updated']} (đã đồng bộ hãng)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuẩn hóa sản phẩm thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  Future<void> _showEditProductDialog(Map<String, dynamic> product) async {
    await _syncBrandProductCounts();
    if (!mounted) return;
    _showProductDialog(product);
  }

  void _showProductDetails(Map<String, dynamic> product) {
    final name = (product['name'] ?? product['carName'] ?? 'Không xác định')
        .toString();
    final brand =
        (product['brandName'] ??
                product['carBrand'] ??
                product['brand'] ??
                'Chưa có hãng')
            .toString();
    final price = (product['price'] ?? product['carPrice'] ?? 'Liên hệ')
        .toString();
    final description = (product['description'] ?? '').toString();
    final image =
        (product['image'] ?? product['carImage'] ?? '')
            .toString()
            .trim()
            .isEmpty
        ? 'assets/images/RR.jpg'
        : (product['image'] ?? product['carImage']).toString();

    final isNetworkImage =
        image.startsWith('http://') || image.startsWith('https://');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Chi tiết sản phẩm',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: isNetworkImage
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, err, stackTrace) => const Icon(
                              Icons.error_outline,
                              color: Colors.white54,
                            ),
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, err, stackTrace) => const Icon(
                              Icons.error_outline,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildDetailRow('Mã', product['id'].toString()),
                _buildDetailRow('Tên xe', name),
                _buildDetailRow('Hãng', brand),
                _buildDetailRow('Giá', price),
                if (description.trim().isNotEmpty)
                  _buildDetailRow('Mô tả', description),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(Map<String, dynamic>? product) {
    final nameController = TextEditingController(
      text: (product?['name'] ?? product?['carName'] ?? '').toString(),
    );
    final priceController = TextEditingController(
      text: (product?['price'] ?? product?['carPrice'] ?? '').toString(),
    );
    final imageController = TextEditingController(
      text: (product?['image'] ?? product?['carImage'] ?? '').toString(),
    );
    final descController = TextEditingController(
      text: (product?['description'] ?? '').toString(),
    );
    final priceNoteController = TextEditingController(
      text: (product?['priceNote'] ?? 'Liên hệ').toString(),
    );
    final galleryController = TextEditingController(
      text: ((product?['gallery'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .join('\n'),
    );
    final ratingController = TextEditingController(
      text: (product?['rating'] ?? 4.5).toString(),
    );
    final reviewCountController = TextEditingController(
      text: (product?['reviewCount'] ?? 0).toString(),
    );
    final categoryController = TextEditingController(
      text: (product?['category'] ?? '').toString(),
    );
    final seatsController = TextEditingController(
      text: (product?['seats'] ?? '').toString(),
    );
    final fuelTypeController = TextEditingController(
      text: (product?['fuelType'] ?? '').toString(),
    );
    final driveTypeController = TextEditingController(
      text: (product?['driveType'] ?? '').toString(),
    );
    final transmissionController = TextEditingController(
      text: (product?['transmission'] ?? '').toString(),
    );
    final horsepowerController = TextEditingController(
      text: (product?['horsepower'] ?? '').toString(),
    );
    final engineController = TextEditingController(
      text: (product?['engine'] ?? '').toString(),
    );
    final dimensionsController = TextEditingController(
      text: (product?['dimensions'] ?? '').toString(),
    );
    final purposeController = TextEditingController(
      text: (product?['purpose'] ?? '').toString(),
    );

    String selectedBrandId = (product?['brandId'] ?? '').toString();
    String selectedBrandName =
        (product?['brandName'] ??
                product?['carBrand'] ??
                product?['brand'] ??
                '')
            .toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _card,
              title: Text(
                product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
                style: GoogleFonts.leagueSpartan(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('Tên xe', nameController),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _brandsRef.snapshots(),
                      builder: (context, snapshot) {
                        final rawItems = snapshot.data?.docs ?? const [];
                        final deduped = <String, Map<String, String>>{};
                        for (final doc in rawItems) {
                          final data = doc.data();
                          final displayName =
                              (data['brandName'] ??
                                      data['name'] ??
                                      data['brand'] ??
                                      '')
                                  .toString()
                                  .trim();
                          if (displayName.isEmpty) continue;
                          final normalizedKey = displayName.toLowerCase();
                          deduped[normalizedKey] = {
                            'id': doc.id,
                            'name': displayName,
                          };
                        }

                        final selectedNameTrimmed = selectedBrandName.trim();
                        if (selectedNameTrimmed.isNotEmpty) {
                          final normalizedSelected = selectedNameTrimmed
                              .toLowerCase();
                          deduped.putIfAbsent(normalizedSelected, () {
                            final fallbackId = selectedBrandId.isNotEmpty
                                ? selectedBrandId
                                : '$_draftBrandPrefix$normalizedSelected';
                            return {
                              'id': fallbackId,
                              'name': selectedNameTrimmed,
                            };
                          });
                        }

                        final items = deduped.values.toList()
                          ..sort(
                            (a, b) => a['name']!.toLowerCase().compareTo(
                              b['name']!.toLowerCase(),
                            ),
                          );

                        if (items.isNotEmpty &&
                            selectedBrandId.isEmpty &&
                            selectedBrandName.isNotEmpty) {
                          for (final item in items) {
                            if (item['name']!.toLowerCase() ==
                                selectedBrandName.toLowerCase()) {
                              selectedBrandId = item['id']!;
                              break;
                            }
                          }
                        }

                        if (selectedBrandId.isNotEmpty &&
                            !items.any(
                              (item) => item['id'] == selectedBrandId,
                            ) &&
                            selectedBrandName.trim().isNotEmpty) {
                          for (final item in items) {
                            if (item['name']!.toLowerCase() ==
                                selectedBrandName.toLowerCase()) {
                              selectedBrandId = item['id'] ?? '';
                              break;
                            }
                          }
                        }

                        final initialId =
                            items.any((item) => item['id'] == selectedBrandId)
                            ? selectedBrandId
                            : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'brand_${initialId ?? 'none'}_${items.length}',
                            ),
                            initialValue: initialId,
                            isExpanded: true,
                            dropdownColor: _card,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Hãng xe',
                              labelStyle: const TextStyle(
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
                            items: items
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: Text(
                                      item['name'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final selectedItem = items.firstWhere(
                                (item) => item['id'] == value,
                              );
                              setDialogState(() {
                                selectedBrandId = value;
                                selectedBrandName = selectedItem['name'] ?? '';
                              });
                            },
                          ),
                        );
                      },
                    ),
                    _buildTextField('Giá', priceController),
                    _buildTextField('Ghi chú giá', priceNoteController),
                    _buildTextField(
                      'URL ảnh đại diện',
                      imageController,
                      keyboardType: TextInputType.url,
                      hintText: 'https://example.com/car.jpg',
                    ),
                    _buildTextField(
                      'Gallery URL (mỗi dòng 1 URL)',
                      galleryController,
                      maxLines: 3,
                      keyboardType: TextInputType.url,
                      hintText:
                          'https://example.com/car-1.jpg\nhttps://example.com/car-2.jpg',
                    ),
                    _buildTextField('Mô tả', descController, maxLines: 3),
                    _buildTextField('Rating (vd: 4.8)', ratingController),
                    _buildTextField('Số lượt đánh giá', reviewCountController),
                    _buildTextField(
                      'Phân khúc (vd: SUV, Sedan)',
                      categoryController,
                    ),
                    _buildTextField('Số chỗ', seatsController),
                    _buildTextField('Nhiên liệu', fuelTypeController),
                    _buildTextField('Dẫn động', driveTypeController),
                    _buildTextField('Hộp số', transmissionController),
                    _buildTextField('Mã lực', horsepowerController),
                    _buildTextField('Động cơ', engineController),
                    _buildTextField('Kích thước', dimensionsController),
                    _buildTextField('Mục đích sử dụng', purposeController),
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
                    if (nameController.text.trim().isEmpty ||
                        selectedBrandName.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên xe và chọn hãng xe'),
                        ),
                      );
                      return;
                    }

                    final imagePath = imageController.text.trim();
                    final resolvedImagePath = imagePath.isNotEmpty
                        ? imagePath
                        : (product?['image'] ?? product?['carImage'] ?? '')
                              .toString();

                    final resolvedBrandName = selectedBrandName.trim();
                    final resolvedBrandId = await _resolveBrandId(
                      selectedBrandId: selectedBrandId.trim(),
                      selectedBrandName: resolvedBrandName,
                    );
                    if (resolvedBrandId.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Không thể xác định hãng xe đã chọn'),
                        ),
                      );
                      return;
                    }

                    final existingGallery =
                        ((product?['gallery'] as List?) ??
                                (product?['images'] as List?) ??
                                (product?['carImages'] as List?) ??
                                const <dynamic>[])
                            .map((item) => item.toString())
                            .where((item) => item.isNotEmpty)
                            .toList();

                    final inputGallery = galleryController.text
                        .split('\n')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList();

                    final resolvedGallery = <String>[];
                    if (resolvedImagePath.isNotEmpty) {
                      resolvedGallery.add(resolvedImagePath);
                    }
                    for (final item in inputGallery) {
                      if (!resolvedGallery.contains(item)) {
                        resolvedGallery.add(item);
                      }
                    }
                    for (final item in existingGallery) {
                      if (!resolvedGallery.contains(item)) {
                        resolvedGallery.add(item);
                      }
                    }

                    final parsedRating = double.tryParse(
                      ratingController.text.trim().replaceAll(',', '.'),
                    );
                    final currentRating =
                        parsedRating ??
                        ((product != null && product['rating'] is num)
                            ? (product['rating'] as num).toDouble()
                            : 4.5);
                    final parsedReviewCount = int.tryParse(
                      reviewCountController.text.trim(),
                    );
                    final currentReviewCount =
                        parsedReviewCount ??
                        ((product != null && product['reviewCount'] is num)
                            ? (product['reviewCount'] as num).toInt()
                            : 0);
                    final parsedHorsepower = int.tryParse(
                      horsepowerController.text.trim(),
                    );
                    final currentHorsepower =
                        parsedHorsepower ??
                        ((product != null && product['horsepower'] is num)
                            ? (product['horsepower'] as num).toInt()
                            : 0);

                    final data = <String, dynamic>{
                      'name': nameController.text.trim(),
                      'carName': nameController.text.trim(),
                      'brand': resolvedBrandName,
                      'brandName': resolvedBrandName,
                      'brandId': resolvedBrandId,
                      'carBrand': resolvedBrandName,
                      'price': priceController.text.trim(),
                      'carPrice': priceController.text.trim(),
                      'priceNote': priceNoteController.text.trim().isEmpty
                          ? 'Liên hệ'
                          : priceNoteController.text.trim(),
                      'image': resolvedImagePath,
                      'carImage': resolvedImagePath,
                      'gallery': resolvedGallery,
                      'images': resolvedGallery,
                      'carImages': resolvedGallery,
                      'description': descController.text.trim(),
                      'carDescription': descController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                      'rating': currentRating,
                      'reviewCount': currentReviewCount,
                      'category': categoryController.text.trim(),
                      'seats': seatsController.text.trim(),
                      'fuelType': fuelTypeController.text.trim(),
                      'driveType': driveTypeController.text.trim(),
                      'transmission': transmissionController.text.trim(),
                      'horsepower': currentHorsepower,
                      'engine': engineController.text.trim(),
                      'dimensions': dimensionsController.text.trim(),
                      'purpose': purposeController.text.trim(),
                    };

                    try {
                      if (product == null) {
                        final docRef = await _productsRef.add({
                          ...data,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        await docRef.update({'id': docRef.id});
                      } else {
                        final productId = product['id'].toString();
                        await _productsRef.doc(productId).update({
                          ...data,
                          'id': productId,
                        });
                      }

                      await _syncBrandProductCounts();

                      if (!context.mounted || !dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            product == null
                                ? 'Thêm sản phẩm thành công'
                                : 'Cập nhật sản phẩm thành công',
                          ),
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Không thể lưu sản phẩm: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(product == null ? 'Thêm' : 'Cập nhật'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white10),
          ),
        ),
      ),
    );
  }

  Future<String> _resolveBrandId({
    required String selectedBrandId,
    required String selectedBrandName,
  }) async {
    final normalizedBrandName = selectedBrandName.trim();
    if (normalizedBrandName.isEmpty) return '';

    if (selectedBrandId.isNotEmpty &&
        !selectedBrandId.startsWith(_draftBrandPrefix)) {
      return selectedBrandId;
    }

    final brandDocs = await _brandsRef.get();
    for (final brandDoc in brandDocs.docs) {
      final data = brandDoc.data();
      final displayName =
          (data['brandName'] ?? data['name'] ?? data['brand'] ?? '')
              .toString()
              .trim();
      if (displayName.toLowerCase() == normalizedBrandName.toLowerCase()) {
        return brandDoc.id;
      }
    }

    final createdDoc = await _brandsRef.add({
      'brandName': normalizedBrandName,
      'name': normalizedBrandName,
      'brand': normalizedBrandName,
      'productCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return createdDoc.id;
  }

  void _deleteProduct(String productId) {
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
          'Bạn chắc chắn muốn xóa sản phẩm này?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(dialogContext);
              try {
                await _productsRef.doc(productId).delete();
                await _syncBrandProductCounts();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Xóa sản phẩm thành công')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Không thể xóa sản phẩm: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncBrandProductCounts() async {
    final productsSnapshot = await _productsRef.get();
    var brandsSnapshot = await _brandsRef.get();

    final normalizedBrandMap = <String, Map<String, String>>{};
    for (final brandDoc in brandsSnapshot.docs) {
      final brandName = _extractBrandName(brandDoc.data());
      if (brandName.isEmpty) continue;
      normalizedBrandMap[brandName.toLowerCase()] = {
        'id': brandDoc.id,
        'name': brandName,
      };
    }

    for (final productDoc in productsSnapshot.docs) {
      final data = productDoc.data();
      final brandName = _extractBrandName(data);
      if (brandName.isEmpty) continue;

      final normalized = brandName.toLowerCase();
      if (normalizedBrandMap.containsKey(normalized)) continue;

      final createdDoc = await _brandsRef.add({
        'brandName': brandName,
        'name': brandName,
        'brand': brandName,
        'slug': _slugify(brandName),
        'productCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      normalizedBrandMap[normalized] = {'id': createdDoc.id, 'name': brandName};
    }

    brandsSnapshot = await _brandsRef.get();

    final counts = <String, int>{};
    final inferredBrandNameByBrandId = <String, String>{};
    final productBatch = FirebaseFirestore.instance.batch();
    var hasProductUpdates = false;

    for (final productDoc in productsSnapshot.docs) {
      final data = productDoc.data();
      final brandName = _extractBrandName(data);
      if (brandName.isEmpty) continue;

      final mapped = normalizedBrandMap[brandName.toLowerCase()];
      if (mapped == null) continue;

      final mappedBrandId = mapped['id'] ?? '';
      final canonicalBrandName = mapped['name'] ?? brandName;
      if (mappedBrandId.isEmpty) continue;

      counts[mappedBrandId] = (counts[mappedBrandId] ?? 0) + 1;
      inferredBrandNameByBrandId.putIfAbsent(
        mappedBrandId,
        () => canonicalBrandName,
      );

      final currentBrandId = (data['brandId'] ?? '').toString().trim();
      final currentBrandName = (data['brandName'] ?? '').toString().trim();
      final currentBrand = (data['brand'] ?? '').toString().trim();
      final currentCarBrand = (data['carBrand'] ?? '').toString().trim();

      final needsPatch =
          currentBrandId != mappedBrandId ||
          currentBrandName.isEmpty ||
          currentBrand.isEmpty ||
          currentCarBrand.isEmpty;

      if (!needsPatch) continue;

      productBatch.update(productDoc.reference, {
        'brandId': mappedBrandId,
        'brandName': currentBrandName.isEmpty
            ? canonicalBrandName
            : currentBrandName,
        'brand': currentBrand.isEmpty ? canonicalBrandName : currentBrand,
        'carBrand': currentCarBrand.isEmpty
            ? canonicalBrandName
            : currentCarBrand,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasProductUpdates = true;
    }

    if (hasProductUpdates) {
      await productBatch.commit();
    }

    final brandBatch = FirebaseFirestore.instance.batch();
    for (final brandDoc in brandsSnapshot.docs) {
      final data = brandDoc.data();
      var canonicalName = _extractBrandName(data);
      if (canonicalName.isEmpty) {
        canonicalName = inferredBrandNameByBrandId[brandDoc.id] ?? '';
      }

      brandBatch.update(brandDoc.reference, {
        'productCount': counts[brandDoc.id] ?? 0,
        if ((data['brandName'] ?? '').toString().trim().isEmpty &&
            canonicalName.isNotEmpty)
          'brandName': canonicalName,
        if ((data['name'] ?? '').toString().trim().isEmpty &&
            canonicalName.isNotEmpty)
          'name': canonicalName,
        if ((data['brand'] ?? '').toString().trim().isEmpty &&
            canonicalName.isNotEmpty)
          'brand': canonicalName,
        if ((data['slug'] ?? '').toString().trim().isEmpty &&
            canonicalName.isNotEmpty)
          'slug': _slugify(canonicalName),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await brandBatch.commit();
  }

  String _extractBrandName(Map<String, dynamic> data) {
    final brandName = (data['brandName'] ?? '').toString().trim();
    final name = (data['name'] ?? '').toString().trim();
    final brand = (data['brand'] ?? '').toString().trim();
    final carBrand = (data['carBrand'] ?? '').toString().trim();

    if (brandName.isNotEmpty) return brandName;
    if (name.isNotEmpty) return name;
    if (brand.isNotEmpty) return brand;
    if (carBrand.isNotEmpty) return carBrand;
    return '';
  }

  String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp(r'-+'), '-');
  }
}
