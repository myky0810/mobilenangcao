import 'package:flutter/material.dart';
import 'package:doan_cuoiki/models/car_detail.dart';

import '../data/cars_data.dart';
import '../navigation_observer.dart';
import '../widgets/car_card.dart';

enum PriceSortOption { none, ascending, descending }

class NewCarScreen extends StatefulWidget {
  const NewCarScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<NewCarScreen> createState() => _NewCarScreenState();
}

class _NewCarScreenState extends State<NewCarScreen> with RouteAware {
  static const Color _filterSheetBackground = Color(0xFF111623);
  static const Color _filterCardBackground = Color(0xFF1A2233);
  static const Color _filterCardBorder = Color(0xFF26344D);
  static const Color _filterActivePrimary = Color(0xFF2F6FED);
  static const Color _filterActiveSecondary = Color(0xFF12C4E8);

  int _activeNavIndex = 1;
  final TextEditingController _searchController = TextEditingController();

  String _searchKeyword = '';
  String _selectedCategory = 'Tất cả';
  String _selectedSeatFilter = 'Tất cả';
  String _selectedFuelType = 'Tất cả';
  String _selectedDriveType = 'Tất cả';
  String _selectedPriceRange = 'Tất cả';
  String _selectedTransmission = 'Tất cả';
  String _selectedPowerRange = 'Tất cả';
  String _selectedPurpose = 'Tất cả';
  bool _onlyNewCars = false;
  PriceSortOption _sortOption = PriceSortOption.none;
  final Set<String> _selectedBrands = <String>{};

  List<String> get _categories {
    final categories = CarsData.getAllCategories();
    return ['Tất cả', ...categories];
  }

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

  late List<CarDetailData> _cars = CarsData.allCars;

  @override
  void initState() {
    super.initState();
  }

  List<String> get _availableBrands => CarsData.getAllBrands();

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {}

  List<CarDetailData> get _filteredCars {
    return _buildFilteredCars(
      selectedBrands: _selectedBrands,
      selectedCategory: _selectedCategory,
      selectedSeatFilter: _selectedSeatFilter,
      selectedFuelType: _selectedFuelType,
      selectedDriveType: _selectedDriveType,
      selectedPriceRange: _selectedPriceRange,
      selectedTransmission: _selectedTransmission,
      selectedPowerRange: _selectedPowerRange,
      selectedPurpose: _selectedPurpose,
      onlyNewCars: _onlyNewCars,
      sortOption: _sortOption,
      searchKeyword: _searchKeyword,
    );
  }

  List<CarDetailData> _buildFilteredCars({
    required Set<String> selectedBrands,
    required String selectedCategory,
    required String selectedSeatFilter,
    required String selectedFuelType,
    required String selectedDriveType,
    required String selectedPriceRange,
    required String selectedTransmission,
    required String selectedPowerRange,
    required String selectedPurpose,
    required bool onlyNewCars,
    required PriceSortOption sortOption,
    required String searchKeyword,
  }) {
    final keyword = _normalizeText(searchKeyword);
    final filtered = _cars.where((car) {
      final matchesCategory =
          selectedCategory == 'Tất cả' || car.category == selectedCategory;
      final matchesBrand =
          selectedBrands.isEmpty || selectedBrands.contains(car.brand);
      final matchesSeats =
          selectedSeatFilter == 'Tất cả' ||
          (car.seats != null && _seatMatches(car.seats!, selectedSeatFilter));
      final matchesFuel =
          selectedFuelType == 'Tất cả' || car.fuelType == selectedFuelType;
      final matchesDrive =
          selectedDriveType == 'Tất cả' || car.driveType == selectedDriveType;
      final matchesPrice = _matchesPriceRange(
        _extractPriceValue(car.price),
        selectedPriceRange,
      );
      final matchesTransmission =
          selectedTransmission == 'Tất cả' ||
          car.transmission == selectedTransmission;
      final matchesPower = _matchesPowerRange(
        car.horsepower ?? 0,
        selectedPowerRange,
      );
      final matchesPurpose =
          selectedPurpose == 'Tất cả' || car.purpose == selectedPurpose;
      final matchesNew = !onlyNewCars || car.isNew;

      final searchData = [
        car.name,
        car.brand,
        car.category,
        car.engine,
        car.seats ?? '',
        car.description,
        car.fuelType,
        car.driveType,
        car.transmission,
        car.purpose,
        '${car.horsepower} hp',
      ].map((item) => _normalizeText(item)).join(' ');

      final matchesKeyword = keyword.isEmpty || searchData.contains(keyword);
      return matchesCategory &&
          matchesBrand &&
          matchesSeats &&
          matchesFuel &&
          matchesDrive &&
          matchesPrice &&
          matchesTransmission &&
          matchesPower &&
          matchesPurpose &&
          matchesNew &&
          matchesKeyword;
    }).toList();

    filtered.sort((a, b) {
      final priceA = _extractPriceValue(a.price);
      final priceB = _extractPriceValue(b.price);
      switch (sortOption) {
        case PriceSortOption.ascending:
          return priceA.compareTo(priceB);
        case PriceSortOption.descending:
          return priceB.compareTo(priceA);
        case PriceSortOption.none:
          return 0;
      }
    });
    return filtered;
  }

  int _extractPriceValue(String price) {
    // Tách giá trị số từ chuỗi giá, ví dụ "1.899.000.000đ".
    final numericString = price.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(numericString) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050511),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0C0E12), Color(0xFF050511)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildSearchAndFilterBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Text(
                  'Đội xe Obsidian',
                  style: TextStyle(
                    color: Colors.blue.shade100,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildCarList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Liên Kết Obsidian',
            style: TextStyle(
              color: Colors.blue.shade100,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF2C3451)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCT4ZZfsLPa0hOLo3RLiKUtTUxbtBpCoCWrlPr_mvck0be5-wK9VADsh5zhiSMdCWS3VjdLpBfI7BPralJnmFLFVhhuo-BLmO4lByw5AkH-_CxnhEVE4nWe4G0IQhfq2yCI6Yu3AGyGHW3WFb5faOUZ0MfebRNW4MjzmHdtEBxf3EqH3YKgoxEbaRRd3GIsFgpYpQcGJIs6qcW-hxxAnJ7759hUJaXe9qY8muAcv4td7-bZV9kCRDclZngS1nFoQJbiGYPnERQPgtI',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF202938),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111318),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2E3B52)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF8AACFF), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchKeyword = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Tìm kiếm siêu xe của bạn...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchKeyword.trim().isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchKeyword = '');
                },
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2B48),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: _openFilterSheet,
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF8AACFF),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarList() {
    final cars = _filteredCars;
    if (cars.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy mẫu xe phù hợp',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        return CarCard.fromMap({
          'id': car.id,
          'name': car.name,
          'brand': car.brand,
          'price': car.price,
          'priceNote': 'Lăn bánh từ ${car.price}',
          'image': car.image,
          'gallery': car.images,
          'rating': car.rating,
          'reviewCount': car.reviewCount,
          'isNew': car.isNew,
          'description': car.description,
        }, phoneNumber: widget.phoneNumber);
      },
    );
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: _filterSheetBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
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
                                  const Expanded(
                                    child: Text(
                                      'Tìm kiếm nâng cao',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setModalState(() {
                                        _selectedCategory = 'Tất cả';
                                        _selectedSeatFilter = 'Tất cả';
                                        _selectedFuelType = 'Tất cả';
                                        _selectedDriveType = 'Tất cả';
                                        _selectedPriceRange = 'Tất cả';
                                        _selectedTransmission = 'Tất cả';
                                        _selectedPowerRange = 'Tất cả';
                                        _selectedPurpose = 'Tất cả';
                                        _selectedBrands.clear();
                                        _onlyNewCars = false;
                                        _sortOption = PriceSortOption.none;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF66D9FF),
                                    ),
                                    child: const Text('Đặt lại'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Hãng xe',
                                icon: Icons.factory_rounded,
                                child: _buildMultiChoiceWrap(
                                  options: _availableBrands,
                                  selectedOptions: _selectedBrands,
                                  onToggle: (brand, selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedBrands.add(brand);
                                      } else {
                                        _selectedBrands.remove(brand);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Loại xe',
                                icon: Icons.directions_car_filled_rounded,
                                child: _buildChoiceWrap(
                                  options: _categories,
                                  selected: _selectedCategory,
                                  onSelected: (value) => setModalState(
                                    () => _selectedCategory = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Giá cả',
                                icon: Icons.attach_money_rounded,
                                child: _buildChoiceWrap(
                                  options: _priceRanges,
                                  selected: _selectedPriceRange,
                                  onSelected: (value) => setModalState(
                                    () => _selectedPriceRange = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Số chỗ ngồi',
                                icon: Icons.people_rounded,
                                child: _buildChoiceWrap(
                                  options: _seatFilters,
                                  selected: _selectedSeatFilter,
                                  onSelected: (value) => setModalState(
                                    () => _selectedSeatFilter = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Loại nhiên liệu',
                                icon: Icons.local_gas_station_rounded,
                                child: _buildChoiceWrap(
                                  options: _fuelFilters,
                                  selected: _selectedFuelType,
                                  onSelected: (value) => setModalState(
                                    () => _selectedFuelType = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Hộp số',
                                icon: Icons.settings_rounded,
                                child: _buildChoiceWrap(
                                  options: _transmissionFilters,
                                  selected: _selectedTransmission,
                                  onSelected: (value) => setModalState(
                                    () => _selectedTransmission = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Công suất',
                                icon: Icons.bolt_rounded,
                                child: _buildChoiceWrap(
                                  options: _powerRanges,
                                  selected: _selectedPowerRange,
                                  onSelected: (value) => setModalState(
                                    () => _selectedPowerRange = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Dẫn động',
                                icon: Icons.directions_car_rounded,
                                child: _buildChoiceWrap(
                                  options: _driveFilters,
                                  selected: _selectedDriveType,
                                  onSelected: (value) => setModalState(
                                    () => _selectedDriveType = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Mục đích sử dụng',
                                icon: Icons.flag_rounded,
                                child: _buildChoiceWrap(
                                  options: _purposeFilters,
                                  selected: _selectedPurpose,
                                  onSelected: (value) => setModalState(
                                    () => _selectedPurpose = value,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Sắp xếp giá',
                                icon: Icons.sort_rounded,
                                child: _buildSortChoiceWrap(
                                  selected: _sortOption,
                                  onSelected: (value) =>
                                      setModalState(() => _sortOption = value),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFilterSection(
                                title: 'Tùy chọn nhanh',
                                icon: Icons.auto_awesome_rounded,
                                child: _buildToggleTile(
                                  title: 'Chỉ hiển thị xe mới',
                                  value: _onlyNewCars,
                                  onChanged: (value) =>
                                      setModalState(() => _onlyNewCars = value),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setModalState(() {
                                          _selectedCategory = 'Tất cả';
                                          _selectedSeatFilter = 'Tất cả';
                                          _selectedFuelType = 'Tất cả';
                                          _selectedDriveType = 'Tất cả';
                                          _selectedPriceRange = 'Tất cả';
                                          _selectedTransmission = 'Tất cả';
                                          _selectedPowerRange = 'Tất cả';
                                          _selectedPurpose = 'Tất cả';
                                          _selectedBrands.clear();
                                          _onlyNewCars = false;
                                          _sortOption = PriceSortOption.none;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                        side: const BorderSide(
                                          color: _filterCardBorder,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        elevation: 0,
                                        backgroundColor: _filterActivePrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Áp dụng',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
        return InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => onSelected(option),
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.98,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_filterActivePrimary, _filterActiveSecondary],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF0F172A),
                border: Border.all(
                  color: isSelected ? Colors.transparent : _filterCardBorder,
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(_displayFilterLabel(option)),
              ),
            ),
          ),
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
        return InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => onToggle(option, !isSelected),
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.98,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [_filterActivePrimary, _filterActiveSecondary],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF0F172A),
                border: Border.all(
                  color: isSelected ? Colors.transparent : _filterCardBorder,
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(_displayFilterLabel(option)),
              ),
            ),
          ),
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

  Widget _buildSortChoiceWrap({
    required PriceSortOption selected,
    required ValueChanged<PriceSortOption> onSelected,
  }) {
    final options = <MapEntry<String, PriceSortOption>>[
      const MapEntry('Mặc định', PriceSortOption.none),
      const MapEntry('Giá tăng dần', PriceSortOption.ascending),
      const MapEntry('Giá giảm dần', PriceSortOption.descending),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((entry) {
        final isSelected = selected == entry.value;
        return InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => onSelected(entry.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [_filterActivePrimary, _filterActiveSecondary],
                    )
                  : null,
              color: isSelected ? null : const Color(0xFF0F172A),
              border: Border.all(
                color: isSelected ? Colors.transparent : _filterCardBorder,
              ),
            ),
            child: Text(
              entry.key,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _filterCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _filterActiveSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _filterCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _filterCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildSheetTitle(title, icon), child],
      ),
    );
  }

  Widget _buildSheetTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF66D9FF)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFB5C6E0),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  bool _seatMatches(String seats, String filter) {
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

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.directions_car_rounded, 1),
            _buildNavItem(Icons.favorite_rounded, 2),
            _buildNavItem(Icons.verified_user_rounded, 3),
            _buildNavItem(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (_activeNavIndex == index) return;
        setState(() => _activeNavIndex = index);
        Future.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          if (index == 0) {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: widget.phoneNumber,
            );
          } else if (index == 1) {
            // Đang ở màn hình xe mới, không cần điều hướng.
          } else if (index == 2) {
            Navigator.pushReplacementNamed(
              context,
              '/favorite',
              arguments: widget.phoneNumber,
            );
          } else if (index == 3) {
            Navigator.pushReplacementNamed(
              context,
              '/warranty',
              arguments: widget.phoneNumber,
            );
          } else if (index == 4) {
            Navigator.pushReplacementNamed(
              context,
              '/profile',
              arguments: widget.phoneNumber,
            );
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: isActive ? 56 : 50,
        height: isActive ? 56 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF3B82C8), Color(0xFF1E5A9E)],
                )
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white54,
          size: isActive ? 26 : 24,
        ),
      ),
    );
  }
}
