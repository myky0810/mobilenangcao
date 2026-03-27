import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';
import '../../widgets/car_image_slider.dart';

class TeslaScreen extends StatefulWidget {
  const TeslaScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<TeslaScreen> createState() => _TeslaScreenState();
}

class _TeslaScreenState extends State<TeslaScreen> {
  int _activeNavIndex = 0;
  List<String> _favoriteIds = [];

  final List<Map<String, dynamic>> _teslaCars = [
    {
      'id': 'tesla_cybertruck',
      'name': 'Tesla Cybertruck 2025',
      'brand': 'Tesla',
      'price': '2.091.538.525đ',
      'priceNote': 'Lăn bánh từ 2.5 tỷ',
      'image':
          'assets/images/products/Tesla-Cybertruck-2025-1280-16e1b7f3835967587c752ccbc071af69c5.jpg',
      'rating': 9.2,
      'reviewCount': 240,
      'isNew': true,
      'description':
          'Tesla Cybertruck 2025 là mẫu bán tải điện cách mạng với thân xe thép không gỉ đột phá. Phạm vi lên đến 500km/lần sạc, tăng tốc 0-100km/h chỉ 2.9 giây và sức kéo lên đến 11.3 tấn. Buồng lái tương lai với màn hình 18.5 inch và công nghệ Autopilot tiên tiến.',
      'gallery': <String>[
        'assets/images/products/Tesla-Cybertruck-2025-1280-16e1b7f3835967587c752ccbc071af69c5.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-4c154b2d57ac41a915b7ad60624ed73dc1.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-67757d6a7424872b2630bb000107939a2f.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-74abae0a38fbfbc768688f443081944f8f.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-7ca3be8dc288bd177f33cdb0d03ecaa027.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-aba810131368e11e171f4658a02a79d3f2.jpg',
      ],
    },
    {
      'id': 'tesla_1',
      'name': 'Tesla Model 3 2024',
      'brand': 'Tesla',
      'price': '1.599.000.000đ',
      'priceNote': 'Lăn bánh từ 1.8 tỷ',
      'image':
          'assets/images/products/Tesla-Model_3-2024-1280-3f2af9ab7a564be8488ad85f205963fdf3.jpg',
      'rating': 8.8,
      'reviewCount': 160,
      'isNew': false,
      'description':
          'Tesla Model 3 2024 – sedan điện hạng sang bán chạy nhất thế giới. Thiết kế mới hoàn toàn với nội thất trôi nổi sang trọng, màn hình 15.4 inch trung tâm, phầm mềm cập nhật OTA và phạm vi di chuyển lên đến 629km.',
      'gallery': <String>[
        'assets/images/products/Tesla-Model_3-2024-1280-3f2af9ab7a564be8488ad85f205963fdf3.jpg',
        'assets/images/products/Tesla-Model_3-2024-1280-7020760cdd5c40f8fc3cb613b07644362f.jpg',
        'assets/images/products/Tesla-Model_3-2024-1280-a164cce1c500599270877d58b0dd6248ec.jpg',
        'assets/images/products/Tesla-Model_3-2024-1280-bbdbe6148d9e2a2853f72e6db073c8525b.jpg',
        'assets/images/products/Tesla-Model_3-2024-1280-e60d1b86b83f8a74d1bd388b50d9995b91.jpg',
        'assets/images/products/Tesla-Model_3-2024-1280-f4e2f306a7b7e7b9b962b3efb0d46167bb.jpg',
      ],
    },
    {
      'id': 'tesla_2',
      'name': 'Tesla Model Y 2025',
      'brand': 'Tesla',
      'price': '1.899.000.000đ',
      'priceNote': 'Lăn bánh từ 2.1 tỷ',
      'image':
          'assets/images/products/Tesla-Model_Y-2025-1280-2a8d0491e827a5f41c36744d8006f50ad3.jpg',
      'rating': 9.0,
      'reviewCount': 132,
      'isNew': false,
      'description':
          'Tesla Model Y 2025 là SUV điện bán chạy số 1 toàn cầu. Không gian 5/7 chỗ linh hoạt, khoảng sáng gầm tốt, phạm vi 533km/lần sạc, tăng tốc ấn tượng và hệ thống Autopilot hiện đại giúp mọi chuyến đi đều an toàn và thú vị.',
      'gallery': <String>[
        'assets/images/products/Tesla-Model_Y-2025-1280-2a8d0491e827a5f41c36744d8006f50ad3.jpg',
        'assets/images/products/Tesla-Model_Y-2025-1280-64ba33f4b38f781a64a0272a506f43cb78.jpg',
        'assets/images/products/Tesla-Model_Y-2025-1280-8a4835fad6014a5880615b12f016fbcb75.jpg',
        'assets/images/products/Tesla-Model_Y-2025-1280-ab5d6a99cf44c76d3b2f2057001641a144.jpg',
        'assets/images/products/Tesla-Model_Y-2025-1280-d948a430156bb417fbef28d8708f70b499.jpg',
        'assets/images/products/Tesla-Model_Y-2025-Front_Three-Quarter.af8e4bcb.jpg',
      ],
    },
    {
      'id': 'tesla_3',
      'name': 'Tesla Model Y Performance 2026',
      'brand': 'Tesla',
      'price': '2.499.000.000đ',
      'priceNote': 'Lăn bánh từ 2.8 tỷ',
      'image':
          'assets/images/products/Tesla-Model_Y_Performance-2026-1280-30d6907df0e364e47154761690e6267dfc.jpg',
      'rating': 9.5,
      'reviewCount': 118,
      'isNew': true,
      'description':
          'Tesla Model Y Performance 2026 – phiên bản hiệu năng cao của Model Y với động cơ kép AWD, tăng tốc 0-100km/h chỉ 3.5 giây. Phanh hiệu suất cao, vành 21 inch thể thao và tất cả tiện ích cao cấp của Model Y.',
      'gallery': <String>[
        'assets/images/products/Tesla-Model_Y_Performance-2026-1280-30d6907df0e364e47154761690e6267dfc.jpg',
        'assets/images/products/Tesla-Model_Y_Performance-2026-1280-605c58d5eefcdb8d97ac1fe520128b8cb2.jpg',
        'assets/images/products/Tesla-Model_Y_Performance-2026-1280-860ca1d81f9c8482c37873ef803c2ba63d.jpg',
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
    final String carId = car['id'] as String;
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
        'Tesla',
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
      itemCount: _teslaCars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_teslaCars[index]);
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
            'carImages':
                (car['gallery'] as List<String>?) ??
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
            // Car gallery slider
            Stack(
              children: [
                CarImageSlider(
                  images:
                      (car['gallery'] as List<String>?) ??
                      [car['image'] as String],
                  height: 200,
                ),
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
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
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
                        const Icon(Icons.star, color: Colors.orange, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    car['price'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    car['priceNote'] as String,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });

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
