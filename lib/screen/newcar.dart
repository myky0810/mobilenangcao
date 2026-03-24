import 'package:flutter/material.dart';

class NewCarScreen extends StatefulWidget {
  const NewCarScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<NewCarScreen> createState() => _NewCarScreenState();
}

class _NewCarScreenState extends State<NewCarScreen> {
  int _activeNavIndex = 1; // Icon xe được chọn (index 1)
  int _selectedCategoryIndex = 0; // Tất cả được chọn mặc định

  final List<String> _categories = [
    'Tất cả',
    'SUV',
    'Sedan',
    'Hatchback',
    'Bán tải',
  ];

  final List<CarModel> _cars = [
    CarModel(
      name: 'MAZDA2',
      seats: '5 chỗ',
      dimensions: '4340 x 1695 x 1470',
      engine: 'Skyactiv-G 1.5L',
      price: '415.000.000 đ',
      image: 'assets/images/products/car1.jpg',
    ),
    CarModel(
      name: 'MAZDA2 SPORT',
      seats: '5 chỗ',
      dimensions: '4065 x 1695 x 1515',
      engine: 'Skyactiv-G 1.5L',
      price: '492.000.000 đ',
      image: 'assets/images/products/car2.jpg',
    ),
    CarModel(
      name: 'MAZDA CX-3',
      seats: '5 chỗ',
      dimensions: '4275 x 1765 x 1535',
      engine: 'Skyactiv-G 2.0L',
      price: '589.000.000 đ',
      image: 'assets/images/products/car3.jpg',
    ),
    CarModel(
      name: 'MAZDA CX-5',
      seats: '5 chỗ',
      dimensions: '4575 x 1842 x 1685',
      engine: 'Skyactiv-G 2.5L',
      price: '749.000.000 đ',
      image: 'assets/images/products/car4.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search bar với icon settings
            _buildSearchBar(),

            const SizedBox(height: 16),

            // Category tabs
            _buildCategoryTabs(),

            const SizedBox(height: 20),

            // Car list với fade effect
            Expanded(child: _buildCarList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
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
              color: Colors.grey[800],
            ),
            child: const Icon(Icons.person, color: Colors.white60, size: 24),
          ),

          const SizedBox(width: 12),

          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào ${widget.phoneNumber ?? '0903654626'},',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Mẫu xe mới',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Notification icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2a2a2a),
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
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Colors.white38, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tìm kiếm...',
              style: TextStyle(color: Colors.white38, fontSize: 15),
            ),
          ),
          // Settings icon (giống hình)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.tune, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarList() {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _cars.length,
          itemBuilder: (context, index) {
            return _buildCarCard(_cars[index]);
          },
        ),

        // Fade effect ở cuối (hiệu ứng mờ dần)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF333333).withOpacity(0.0),
                  const Color(0xFF333333).withOpacity(0.5),
                  const Color(0xFF333333).withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarCard(CarModel car) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detailcar',
          arguments: {
            'carName': car.name,
            'carBrand': car.name.split(' ')[0], // Lấy brand từ tên xe (TOYOTA, MAZDA, etc.)
            'carImage': car.image,
            'carPrice': car.price,
            'carDescription': 'Xe ${car.name} với động cơ ${car.engine}, kích thước ${car.dimensions}. Thiết kế hiện đại, trang bị cao cấp và công nghệ tiên tiến.',
            'carImages': <String>[car.image, 'assets/images/products/car1.jpg', 'assets/images/products/car2.jpg'],
            'rating': 4.6,
            'reviewCount': 120,
            'isNew': true, // Tất cả xe ở trang NewCar đều có NEW tag
            'phoneNumber': widget.phoneNumber,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(width: 8),
                // Car name
                Expanded(
                  child: Text(
                    car.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

          Row(
            children: [
              // Car image
              Expanded(
                flex: 2,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      car.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.white24,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Car specs
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecRow('${car.seats}'),
                    const SizedBox(height: 8),
                    _buildSpecRow('Kích thước (mm):'),
                    const SizedBox(height: 4),
                    Text(
                      car.dimensions,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSpecRow('Động cơ:'),
                    const SizedBox(height: 4),
                    Text(
                      car.engine,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price
          Text(
            'Giá chi tiết: ${car.price}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSpecRow(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            _buildNavItem(Icons.directions_car_rounded, 1), // Icon xe active
            _buildNavItem(Icons.favorite_rounded, 2),
            _buildNavItem(Icons.person_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });
        // Navigate to different screens
        if (index == 0) {
          // Navigate to HomeScreen
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: widget.phoneNumber,
          );
        } else if (index == 2) {
          // Navigate to favorite screen
          Navigator.pushReplacementNamed(
            context,
            '/favorite',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
          // Navigate to profile screen
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
              color: isActive ? Colors.white : Colors.white54,
              size: isActive ? 26 : 24,
            ),
          ),
        ),
      ),
    );
  }
}

class CarModel {
  final String name;
  final String seats;
  final String dimensions;
  final String engine;
  final String price;
  final String image;

  CarModel({
    required this.name,
    required this.seats,
    required this.dimensions,
    required this.engine,
    required this.price,
    required this.image,
  });
}
