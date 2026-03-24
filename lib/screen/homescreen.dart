import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firebase_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentBannerIndex = 0;
  int _selectedBrandIndex = 0; // Mercedes được chọn mặc định

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
                    const SizedBox(height: 16),

                    // Search bar
                    _buildSearchBar(),

                    const SizedBox(height: 20),

                    // Banner với dots
                    _buildBannerWithDots(),

                    const SizedBox(height: 24),

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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Colors.white38, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tìm kiếm',
              style: TextStyle(color: Colors.white38, fontSize: 15),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: const Icon(Icons.mic_none, color: Colors.white38, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerWithDots() {
    return Column(
      children: [
        // Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [const Color(0xFF1e5a9e), const Color(0xFF3b82c8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Text content
              Positioned(
                left: 20,
                top: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Ưu đãi điện thoại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '20%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ưu đãi trong tuần',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 200,
                      child: Text(
                        'Nhận ngay ưu đãi giảm giá xe mới, chỉ áp dụng trong tuần này.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Car image
              Positioned(
                right: -30,
                bottom: 10,
                child: Image.asset(
                  'assets/images/products/car1.jpg',
                  width: 200,
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.directions_car,
                      color: Colors.white30,
                      size: 100,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Dots pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            return Container(
              width: index == _currentBannerIndex ? 8 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentBannerIndex
                    ? Colors.white
                    : Colors.white24,
              ),
            );
          }),
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

    return Container(
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
                  onTap: () {
                    setState(() {
                      if (isFavorite) {
                        _favorites.remove(index);
                      } else {
                        _favorites.add(index);
                      }
                    });
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
}
