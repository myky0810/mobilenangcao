import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';

class BMWScreen extends StatefulWidget {
  const BMWScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<BMWScreen> createState() => _BMWScreenState();
}

class _BMWScreenState extends State<BMWScreen> {
  int _activeNavIndex = 0;
  List<String> _favoriteIds = [];

  final List<Map<String, dynamic>> _bmwCars = [
    {
      'id': 'bmw_1',
      'name': 'BMW M3',
      'brand': 'BMW',
      'price': '2.499.000.000đ',
      'priceNote': 'Lăn bánh từ 2.8 tỷ',
      'image': 'assets/images/products/car1.jpg',
      'rating': 7.0,
      'reviewCount': 128,
      'isNew': true,
      'description':
          'BMW M3 là mẫu sedan hiệu năng cao mang ADN xe đua M Performance. Thiết kế khí động học, hệ thống treo tinh chỉnh cho cảm giác lái chính xác và ổn định ở tốc độ cao. Khoang lái tập trung người lái, vật liệu cao cấp và hệ thống giải trí hiện đại giúp trải nghiệm hàng ngày vẫn thoải mái nhưng luôn sẵn sàng bùng nổ khi bạn tăng ga.',
      'gallery': <String>[
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
      ],
    },
    {
      'id': 'bmw_2',
      'name': 'BMW M4',
      'brand': 'BMW',
      'price': '3.000.000.000đ',
      'priceNote': 'Lăn bánh từ 3.4 tỷ',
      'image': 'assets/images/products/car2.jpg',
      'rating': 7.0,
      'reviewCount': 96,
      'isNew': false,
      'description':
          'BMW M4 coupe đem lại trải nghiệm thể thao thuần chất với trọng tâm thấp, thân xe cứng vững và phản hồi vô-lăng trực tiếp. Nội thất tối giản nhưng sang trọng, ghế ôm sát và cụm đồng hồ thể thao. Phù hợp cho người thích cảm giác lái mạnh mẽ nhưng vẫn muốn sự tinh tế trong từng chi tiết hoàn thiện.',
      'gallery': <String>[
        'assets/images/products/car2.jpg',
        'assets/images/products/car1.jpg',
        'assets/images/products/car3.jpg',
      ],
    },
    {
      'id': 'bmw_3',
      'name': 'BMW 4 Series Convertible',
      'brand': 'BMW',
      'price': '2.890.000.000đ',
      'priceNote': 'Lăn bánh từ 3.2 tỷ',
      'image': 'assets/images/products/car3.jpg',
      'rating': 7.0,
      'reviewCount': 72,
      'isNew': false,
      'description':
          'BMW 4 Series Convertible là lựa chọn cho phong cách sống năng động: mui xếp linh hoạt, cảm giác lái cân bằng và khả năng cách âm tốt khi đóng mui. Khoang lái hiện đại, nhiều công nghệ hỗ trợ lái và tiện nghi cao cấp. Thích hợp cho các chuyến đi dạo phố cuối tuần hoặc du lịch đường dài đầy cảm hứng.',
      'gallery': <String>[
        'assets/images/products/car3.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car1.jpg',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoriteService.getFavorites();
    setState(() {
      _favoriteIds = favorites.map((fav) => fav['id'] as String).toList();
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> car) async {
    final String carId = car['id'];
    final bool isFavorite = _favoriteIds.contains(carId);

    if (isFavorite) {
      await FavoriteService.removeFromFavorites(carId);
      setState(() {
        _favoriteIds.remove(carId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa khỏi danh sách yêu thích'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      await FavoriteService.addToFavorites(car);
      setState(() {
        _favoriteIds.add(carId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào danh sách yêu thích'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF333333),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      title: const Text(
        'BMW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBody() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bmwCars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_bmwCars[index]);
      },
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final bool isFavorite = _favoriteIds.contains(car['id']);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detailcar',
          arguments: {
            'carName': car['name'],
            'carBrand': car['brand'],
            'carImage': car['image'],
            'carPrice': car['price'],
      'carDescription': (car['description'] as String?) ?? '',
      'carImages': (car['gallery'] as List<String>?) ??
        <String>[car['image'] as String],
      'rating': (car['rating'] as num).toDouble(),
      'reviewCount': (car['reviewCount'] as int?) ?? 80,
      'isNew': car['isNew'] == true,
            'phoneNumber': widget.phoneNumber,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car Image with heart icon
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[900],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    car['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.white30,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Heart icon
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(car),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              // Rating
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${car['rating']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Car Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car name
                Text(
                  car['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Price
                Text(
                  car['price'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Price note
                Text(
                  car['priceNote'],
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
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
              color: Colors.black.withOpacity(0.3),
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

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });
        
        // Navigate to different screens
        if (index == 0) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: widget.phoneNumber,
          );
        } else if (index == 1) {
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 2) {
          Navigator.pushReplacementNamed(
            context,
            '/favorite',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
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
              ? const LinearGradient(
                  colors: [Color(0xFF3b82c8), Color(0xFF1e5a9e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3b82c8).withOpacity(0.6),
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
