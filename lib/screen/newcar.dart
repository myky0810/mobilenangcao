import 'package:flutter/material.dart';
import '../widgets/car_image_slider.dart';

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
      name: 'BMW 3 Series 2019',
      seats: '5 chỗ',
      dimensions: '4713 x 1827 x 1442',
      engine: 'TwinPower Turbo 2.0L',
      price: '1.899.000.000 đ',
      image: 'assets/images/products/BMW-3-Series-2019-1280-199cd3c9a9e4186bdafdb6442254df99de.jpg',
      category: 'Sedan',
    ),
    CarModel(
      name: 'Tesla Model Y 2025',
      seats: '5-7 chỗ',
      dimensions: '4751 x 1921 x 1624',
      engine: 'Dual Motor Electric AWD',
      price: '1.899.000.000 đ',
      image: 'assets/images/products/Tesla-Model_Y-2025-1280-2a8d0491e827a5f41c36744d8006f50ad3.jpg',
      category: 'SUV',
    ),
    CarModel(
      name: 'Toyota Land Cruiser 2021',
      seats: '8 chỗ',
      dimensions: '4985 x 1980 x 1925',
      engine: 'V6 Diesel 3.3L Twin-Turbo',
      price: '4.030.000.000 đ',
      image: 'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
      category: 'SUV',
    ),
    CarModel(
      name: 'Mercedes-Benz GLC Coupe 2024',
      seats: '5 chỗ',
      dimensions: '4756 x 1890 x 1604',
      engine: 'Mild-Hybrid 2.0L Turbo',
      price: '3.299.000.000 đ',
      image: 'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-3d89595d79f2fdc414118a494015c6d489.jpg',
      category: 'SUV',
    ),
    CarModel(
      name: 'Tesla Cybertruck 2025',
      seats: '5 chỗ',
      dimensions: '5682 x 2199 x 1790',
      engine: 'Tri Motor Electric AWD',
      price: '2.091.538.525 đ',
      image: 'assets/images/products/Tesla-Cybertruck-2025-1280-aba810131368e11e171f4658a02a79d3f2.jpg',
      category: 'Bán tải',
    ),
    CarModel(
      name: 'BMW X7 2023',
      seats: '6-7 chỗ',
      dimensions: '5151 x 2000 x 1805',
      engine: 'TwinPower Turbo V8 4.4L',
      price: '7.799.000.000 đ',
      image: 'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
      category: 'SUV',
    ),
    CarModel(
      name: 'Volvo S90 2020',
      seats: '5 chỗ',
      dimensions: '4963 x 1890 x 1443',
      engine: 'T8 PHEV AWD 390hp',
      price: '2.690.000.000 đ',
      image: 'assets/images/products/Volvo-S90-2020-1280-2f45f4e51bdb672a5d9d6842006b5ec994.jpg',
      category: 'Sedan',
    ),
    CarModel(
      name: 'Toyota Tacoma Trailhunter 2024',
      seats: '5 chỗ',
      dimensions: '5765 x 1905 x 1905',
      engine: 'i-FORCE MAX 2.4L Hybrid',
      price: '1.899.000.000 đ',
      image: 'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-adf51b971f224f050d44af15e08feaf8d0.jpg',
      category: 'Bán tải',
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
            'carBrand': car.name.split(
              ' ',
            )[0], // Lấy brand từ tên xe (TOYOTA, MAZDA, etc.)
            'carImage': car.image,
            'carPrice': car.price,
            'carDescription':
                'Xe ${car.name} với động cơ ${car.engine}, kích thước ${car.dimensions}. Thiết kế hiện đại, trang bị cao cấp và công nghệ tiên tiến.',
            'carImages': <String>[
              car.image,
            ],
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

            // Car image gallery slider
            CarImageSlider(
              images: [car.image],
              height: 160,
              borderRadius: BorderRadius.circular(12),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Car specs
                Expanded(
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
      ),
    );
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
  final String category;

  CarModel({
    required this.name,
    required this.seats,
    required this.dimensions,
    required this.engine,
    required this.price,
    required this.image,
    this.category = 'Tất cả',
  });
}
