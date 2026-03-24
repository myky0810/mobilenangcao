import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firebase_helper.dart';
import '../services/favorite_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedBrandIndex = 0; // Mercedes được chọn mặc định
  int _currentBannerIndex = 0; // Để theo dõi banner hiện tại
  late AnimationController _bannerAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<CarBrand> _brands = [
    CarBrand(
      name: 'Mercedes',
      assetPath: 'assets/images/icons8-mercedes-benz-48.png',
    ),
    CarBrand(name: 'Tesla', assetPath: 'assets/images/icons8-tesla-48.png'),
    CarBrand(name: 'BMW', assetPath: 'assets/images/icons8-bmw-48.png'),
    CarBrand(name: 'Toyota', assetPath: 'assets/images/icons8-toyota-48.png'),
    CarBrand(name: 'Volvo', assetPath: 'assets/images/icons8-volvo-100.png'),
    // theo yêu cầu: đổi Bugatti -> Mazda
    CarBrand(name: 'Mazda', assetPath: 'assets/images/icons8-mazda-48.png'),
    CarBrand(name: 'Huyndai', assetPath: 'assets/images/icons8-hyundai-48.png'),
    CarBrand(name: 'Thêm', icon: Icons.more_horiz),
  ];

  // Banner data cho animation
  final List<BannerData> _banners = [
    BannerData(
      badge: '🚗 CAR EXPO 2026',
      title: 'Future\nDriving',
      subtitle: 'AI-Powered Smart Cars',
      buttonText: 'Khám phá ngay',
      gradientColors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF21262D)],
      accentColor: Color(0xFF3b82f6),
      subtitleColor: Color(0xFF10b981),
    ),
    BannerData(
      badge: '⚡ ELECTRIC 2026',
      title: 'Green\nRevolution',
      subtitle: 'Zero Emission Cars',
      buttonText: 'Tìm hiểu thêm',
      gradientColors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
      accentColor: Color(0xFF10b981),
      subtitleColor: Color(0xFF06d6a0),
    ),
    BannerData(
      badge: '🏎️ LUXURY 2026',
      title: 'Ultimate\nLuxury',
      subtitle: 'Premium Experience',
      buttonText: 'Xem ngay',
      gradientColors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4C1D95)],
      accentColor: Color(0xFF8B5CF6),
      subtitleColor: Color(0xFFF59E0B),
    ),
    BannerData(
      badge: '🚙 SUV 2026',
      title: 'Adventure\nReady',
      subtitle: 'Off-Road Champions',
      buttonText: 'Khởi hành',
      gradientColors: [Color(0xFF7C2D12), Color(0xFF9A3412), Color(0xFFEA580C)],
      accentColor: Color(0xFFEA580C),
      subtitleColor: Color(0xFF22C55E),
    ),
  ];

  final List<CarItem> _cars = [
    CarItem(
      name: 'Mercedes GLC',
      price: '2.001.138.556₫',
      subtitle: 'CTKM Avangarde KT2',
      image: 'assets/images/products/car1.jpg',
    ),
    CarItem(
      name: 'BMW 7',
      price: '1.690.000.000₫',
      subtitle: 'BMW',
      image: 'assets/images/products/car2.jpg',
    ),
    CarItem(
      name: 'Acura',
      price: '15.087.000.000₫',
      subtitle: 'Acura',
      image: 'assets/images/products/car3.jpg',
    ),
    CarItem(
      name: 'Toyota Camry 2025',
      price: '1.290.000.000₫',
      subtitle: 'Toyota',
      image: 'assets/images/products/car4.jpg',
    ),
  ];

  final Set<int> _favorites = {};

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    final normalized = FirebaseHelper.normalizePhone(phone);
    return FirebaseFirestore.instance.collection('users').doc(normalized);
  }

  bool _looksLikePhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return RegExp(r'^[0-9+\s()\-]+$').hasMatch(v);
  }

  String _displayNameFromData(Map<String, dynamic>? data) {
    final name = (data?['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;

    final legacyPhoneField = (data?['phone'] as String?)?.trim();
    if (legacyPhoneField != null &&
        legacyPhoneField.isNotEmpty &&
        !_looksLikePhone(legacyPhoneField) &&
        !legacyPhoneField.contains('@')) {
      return legacyPhoneField;
    }

    return 'Người dùng';
  }

  @override
  void initState() {
    super.initState();

    // Khởi tạo animation controllers
    _bannerAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Khởi tạo animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bannerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Bắt đầu animation
    _bannerAnimationController.forward();
    _slideAnimationController.forward();

    // Auto chuyển banner sau mỗi 5 giây
    _startBannerTimer();
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
        });

        // Restart animations
        _bannerAnimationController.reset();
        _slideAnimationController.reset();
        _bannerAnimationController.forward();
        _slideAnimationController.forward();

        // Continue timer
        _startBannerTimer();
      }
    });
  }

  @override
  void dispose() {
    _bannerAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content với ScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16), // Giảm từ 24 -> 16
                    // Banner hiện đại 2026
                    _buildModernBanner(),

                    const SizedBox(height: 20), // Giảm từ 24 -> 20
                    // Car brands
                    _buildBrandsGrid(),

                    const SizedBox(height: 24),

                    // Section Thịnh Hành
                    _buildThinhHanhSection(),

                    const SizedBox(height: 16),

                    // Car list
                    _buildCarList(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final userRef = _userDocRef();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/RR.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                if (userRef == null)
                  const Text(
                    'Người dùng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: userRef.snapshots(),
                    builder: (context, snapshot) {
                      final displayName = _displayNameFromData(
                        snapshot.data?.data(),
                      );
                      return Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Shopping cart icon
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1a1a1a),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),

          // Notification icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1a1a1a),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // Banner hiện đại 2026 với animation
  Widget _buildModernBanner() {
    final currentBanner = _banners[_currentBannerIndex];
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive height: giảm xuống để tránh overflow hoàn toàn
    final bannerHeight = screenHeight < 700 ? 140.0 : 160.0;

    return Column(
      children: [
        // Banner chính với animation
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: bannerHeight, // Dynamic height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: currentBanner.gradientColors,
                  stops: const [0.0, 0.6, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: currentBanner.accentColor.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 0),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _bannerAnimationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: ModernPatternPainter(
                            animationValue: _bannerAnimationController.value,
                            accentColor: currentBanner.accentColor,
                          ),
                        );
                      },
                    ),
                  ),

                  // Glowing accent - giảm kích thước
                  Positioned(
                    top: -30, // Giảm từ -50
                    right: -30, // Giảm từ -50
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      width: 100, // Giảm từ 150
                      height: 100, // Giảm từ 150
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            currentBanner.accentColor.withOpacity(0.2),
                            currentBanner.accentColor.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16), // Giảm padding còn 16
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Dàn đều thay vì center
                        children: [
                          // Top section - Badge và title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge với animation
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      currentBanner.accentColor,
                                      currentBanner.accentColor.withOpacity(
                                        0.8,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentBanner.accentColor
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  currentBanner.badge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Main title với animation
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  currentBanner.title,
                                  key: ValueKey(currentBanner.title),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24, // Giảm xuống 24
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Bottom section - Subtitle và button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subtitle with animated indicator
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: currentBanner.subtitleColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      child: Text(
                                        currentBanner.subtitle,
                                        key: ValueKey(currentBanner.subtitle),
                                        style: TextStyle(
                                          color: currentBanner.subtitleColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Action button với hover effect
                              GestureDetector(
                                onTap: () {
                                  // Handle banner tap - navigate to relevant screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Opened ${currentBanner.title.replaceAll('\n', ' ')}',
                                      ),
                                      backgroundColor:
                                          currentBanner.accentColor,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentBanner.buttonText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating car icon với pulse animation - giảm kích thước
                  Positioned(
                    right: 16, // Giảm từ 20
                    top: 16, // Giảm từ 20
                    child: AnimatedBuilder(
                      animation: _bannerAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              1.0 +
                              (_bannerAnimationController.value *
                                  0.05), // Giảm effect
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 48, // Giảm từ 60
                            height: 48, // Giảm từ 60
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  currentBanner.accentColor,
                                  currentBanner.accentColor.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: currentBanner.accentColor.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 10, // Giảm từ 15
                                  offset: const Offset(0, 3), // Giảm từ 5
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.electric_car_rounded,
                              color: Colors.white,
                              size: 22, // Giảm từ 28
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8), // Giảm từ 12 -> 8
        // Banner indicators (dots) - compact version
        Container(
          height: 20, // Fix chiều cao của dots container
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                  _bannerAnimationController.reset();
                  _slideAnimationController.reset();
                  _bannerAnimationController.forward();
                  _slideAnimationController.forward();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: index == _currentBannerIndex
                      ? 16
                      : 6, // Giảm kích thước
                  height: 6, // Giảm chiều cao
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                  ), // Giảm margin
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: index == _currentBannerIndex
                        ? _banners[_currentBannerIndex].accentColor
                        : Colors.white24,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ưu đãi đặc biệt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Grid 4x2
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            itemCount: _brands.length,
            itemBuilder: (context, index) {
              return _buildBrandItem(_brands[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrandItem(CarBrand brand, int index) {
    final isSelected = index == _selectedBrandIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBrandIndex = index;
        });

        // Navigate to brand specific pages
        if (brand.name == 'Mercedes') {
          Navigator.pushNamed(
            context,
            '/mercedes',
            arguments: widget.phoneNumber,
          );
        } else if (brand.name == 'BMW') {
          Navigator.pushNamed(context, '/bmw', arguments: widget.phoneNumber);
        } else if (brand.name == 'Volvo') {
          Navigator.pushNamed(context, '/volvo', arguments: widget.phoneNumber);
        } else if (brand.name == 'Tesla') {
          Navigator.pushNamed(context, '/tesla', arguments: widget.phoneNumber);
        } else if (brand.name == 'Toyota') {
          Navigator.pushNamed(
            context,
            '/toyota',
            arguments: widget.phoneNumber,
          );
        } else if (brand.name == 'Mazda') {
          Navigator.pushNamed(context, '/mazda', arguments: widget.phoneNumber);
        } else if (brand.name == 'Huyndai') {
          Navigator.pushNamed(
            context,
            '/hyundai',
            arguments: widget.phoneNumber,
          );
        }
        // Có thể thêm các hãng khác sau
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Khung tròn chứa logo
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF444444),
              border: isSelected
                  ? Border.all(color: const Color(0xFF3b82c8), width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF3b82c8).withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 14 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _BrandLogo(brand: brand, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Chữ ở bên ngoài (dưới khung tròn)
          Text(
            brand.name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildThinhHanhSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Thịnh Hành',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Xem tất cả',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _cars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_cars[index], index);
      },
    );
  }

  Widget _buildCarCard(CarItem car, int index) {
    final isFavorite = _favorites.contains(index);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detailcar',
          arguments: {
            'carName': car.name,
            'carBrand': car.subtitle,
            'carImage': car.image,
            'carPrice': car.price,
            'carDescription':
                'Xe ${car.name} từ ${car.subtitle} với chất lượng cao và trang bị hiện đại.',
            'carImages': [
              car.image,
              'assets/images/products/car1.jpg',
              'assets/images/products/car2.jpg',
            ],
            'rating': 4.5,
            'reviewCount': 95,
            'isNew': index == 0, // Car đầu tiên sẽ có NEW tag
            'phoneNumber': widget.phoneNumber,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image with favorite
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    color: const Color(0xFF252525),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.asset(
                      car.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.grey[700],
                            size: 80,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final carData = _cars[index].toMap();
                        carData['id'] = index.toString(); // Thêm id

                        if (isFavorite) {
                          _favorites.remove(index);
                          await FavoriteService.removeFromFavorites(
                            index.toString(),
                          );
                        } else {
                          _favorites.add(index);
                          await FavoriteService.addToFavorites(carData);
                        }
                        setState(() {});
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi khi cập nhật yêu thích: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                // NEW tag for first car
                if (index == 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Car info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    car.subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    car.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.directions_car_rounded, 1),
            _buildNavItem(Icons.favorite_rounded, 2),
            _buildNavItem(Icons.person_rounded, 3),
          ],
        ),
      ),
    );
  }

  int _activeNavIndex = 0;

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });
        // Navigate to different screens based on icon
        if (index == 1) {
          // Navigate to NewCar screen (search icon)
          Navigator.pushNamed(
            context,
            '/newcar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 2) {
          // Navigate to favorite screen (favorite icon)
          Navigator.pushNamed(
            context,
            '/favorite',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
          // Navigate to profile screen (person icon)
          Navigator.pushReplacementNamed(
            context,
            '/profile',
            arguments: widget.phoneNumber,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isActive ? 56 : 50,
        height: isActive ? 56 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(
                  colors: [const Color(0xFF3b82c8), const Color(0xFF1e5a9e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3b82c8).withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: isActive ? 28 : 26,
            ),
          ),
        ),
      ),
    );
  }
}

class CarBrand {
  final String name;
  final IconData? icon;
  final String? assetPath;

  CarBrand({required this.name, this.icon, this.assetPath})
    : assert(icon != null || assetPath != null);
}

class _BrandLogo extends StatelessWidget {
  final CarBrand brand;
  final double size;
  const _BrandLogo({required this.brand, this.size = 28});

  @override
  Widget build(BuildContext context) {
    if (brand.assetPath != null) {
      return Image.asset(
        brand.assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.directions_car, color: Colors.white, size: size);
        },
      );
    }

    return Icon(brand.icon, color: Colors.white, size: size);
  }
}

class CarItem {
  final String name;
  final String price;
  final String subtitle;
  final String image;

  CarItem({
    required this.name,
    required this.price,
    required this.subtitle,
    required this.image,
  });

  // Thêm phương thức toMap
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'brand': subtitle, // Dùng subtitle làm brand
      'priceNote': 'Lăn bánh từ ${price}',
      'image': image,
      'isFavorited': true,
    };
  }
}

// Custom Painter cho background pattern hiện đại
class ModernPatternPainter extends CustomPainter {
  final double animationValue;
  final Color accentColor;

  ModernPatternPainter({
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05 * animationValue)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Tạo pattern geometric hiện đại với animation
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        final x = (size.width / 6) * i;
        final y = (size.height / 4) * j;

        // Hexagon pattern với animation
        final scale = 0.5 + (animationValue * 0.5);
        path.moveTo(x + 15 * scale, y);
        path.lineTo(x + 25 * scale, y + 5 * scale);
        path.lineTo(x + 25 * scale, y + 15 * scale);
        path.lineTo(x + 15 * scale, y + 20 * scale);
        path.lineTo(x + 5 * scale, y + 15 * scale);
        path.lineTo(x + 5 * scale, y + 5 * scale);
        path.close();
      }
    }

    canvas.drawPath(path, paint);

    // Thêm animated dots pattern
    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.1 * animationValue);

    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 5; j++) {
        final x = (size.width / 8) * i + 10;
        final y = (size.height / 5) * j + 10;
        canvas.drawCircle(Offset(x, y), 2 * animationValue, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Banner Data Model
class BannerData {
  final String badge;
  final String title;
  final String subtitle;
  final String buttonText;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color subtitleColor;

  BannerData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.gradientColors,
    required this.accentColor,
    required this.subtitleColor,
  });
}
