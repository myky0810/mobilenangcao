import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';
import '../../widgets/car_image_slider.dart';

class ToyotaScreen extends StatefulWidget {
  const ToyotaScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<ToyotaScreen> createState() => _ToyotaScreenState();
}

class _ToyotaScreenState extends State<ToyotaScreen> {
  int _activeNavIndex = 0;
  List<String> _favoriteIds = [];

  final List<Map<String, dynamic>> _toyotaCars = [
    {
      'id': 'toyota_1',
      'name': 'Toyota Camry 2021',
      'brand': 'Toyota',
      'price': '1.320.000.000đ',
      'priceNote': 'Lăn bánh từ 1.5 tỷ',
      'image': 'assets/images/products/Toyota-Camry-2021-1280-064ad2cc20466b8915c514999074418bde.jpg',
      'rating': 8.5,
      'reviewCount': 155,
      'isNew': true,
      'description':
          'Toyota Camry 2021 nổi tiếng với sự bền bỉ, vận hành êm và cách âm xuất sắc. Thiết kế Dynamic Force Engine 2.5L, nội thất rộng rãi tiện nghi đầy đủ, hệ thống an toàn Toyota Safety Sense. Lựa chọn lý tưởng cho gia đình và doanh nhân.',
      'gallery': <String>[
        'assets/images/products/Toyota-Camry-2021-1280-064ad2cc20466b8915c514999074418bde.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-32243d6b4b7278beb0aab08ce0d373d49f.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-7103cc843047ebe56d6a7d6fb095c35419.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-8671f0b512ac1f70c2a1bc4c60c8d28092.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-8d5933ff56455450044ab1183050f61fae.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-cc5fc213cb86e36bea6be48360ab721695.jpg',
      ],
    },
    {
      'id': 'toyota_2',
      'name': 'Toyota Avalon 2019',
      'brand': 'Toyota',
      'price': '1.580.000.000đ',
      'priceNote': 'Lăn bánh từ 1.8 tỷ',
      'image': 'assets/images/products/Toyota-Avalon-2019-1280-20fbb15d19ae58440ccb4e41c3cfef6a36.jpg',
      'rating': 8.2,
      'reviewCount': 132,
      'isNew': false,
      'description':
          'Toyota Avalon 2019 là sedan flagship cao cấp của Toyota với thiết kế sang trọng độc đáo. Động cơ V6 3.5L mạnh mẽ, không gian nội thất rộng rãi hạng sang, âm thanh JBL 14 loa và các tính năng an toàn tiên tiến.',
      'gallery': <String>[
        'assets/images/products/Toyota-Avalon-2019-1280-20fbb15d19ae58440ccb4e41c3cfef6a36.jpg',
        'assets/images/products/Toyota-Avalon-2019-1280-3b41933023cc364c5afb1b8a006b538f89.jpg',
        'assets/images/products/Toyota-Avalon-2019-1280-85fc19c80d671e7c49928514a16fbf542e.jpg',
        'assets/images/products/Toyota-Avalon-2019-1280-a3ad76434fc21e6b2b0be27df24764ce95.jpg',
        'assets/images/products/Toyota-Avalon-2019-1280-ca35fb60156b3fcad14a028c30351f11a3.jpg',
        'assets/images/products/Toyota-Avalon-2019-1280-d627c2e659b137bba505ad71c105f84c80.jpg',
        'assets/images/products/Toyota-Avalon-2019-1280-f9661a2f029868e4eab7e14a82a01db926.jpg',
      ],
    },
    {
      'id': 'toyota_3',
      'name': 'Toyota Land Cruiser 2021',
      'brand': 'Toyota',
      'price': '4.030.000.000đ',
      'priceNote': 'Lăn bánh từ 4.5 tỷ',
      'image': 'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
      'rating': 9.3,
      'reviewCount': 88,
      'isNew': false,
      'description':
          'Toyota Land Cruiser 2021 – biểu tượng SUV địa hình cao cấp số 1 thế giới. Động cơ dầu V6 3.3L twin-turbo, khung gầm GA-F platform thế hệ mới, khả năng off-road huyền thoại và nội thất 8 chỗ sang trọng. Phù hợp cho cả đô thị lẫn địa hình khắc nghiệt.',
      'gallery': <String>[
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-4efc18483995a822f3ece39367d5d155ed.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-58ff0f9258d235b970aa7e53956b659206.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-65c2c3d0838faad869e880c9a7595acf5e.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-ad9dfa54745f3df21a0d2914f429c8f94e.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-b36fb92915e4d339ab24b315f0d78e9d67.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-f3049447d164609d97e40ac527c2d83b53.jpg',
      ],
    },
    {
      'id': 'toyota_4',
      'name': 'Toyota Tacoma Trailhunter 2024',
      'brand': 'Toyota',
      'price': '1.899.000.000đ',
      'priceNote': 'Lăn bánh từ 2.1 tỷ',
      'image': 'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-adf51b971f224f050d44af15e08feaf8d0.jpg',
      'rating': 8.8,
      'reviewCount': 76,
      'isNew': true,
      'description':
          'Toyota Tacoma Trailhunter 2024 – phiên bản bán tải off-road cực đỉnh. Trang bị mặc định bộ lift nâng gầm, lốp BFGoodrich, đèn ARB và nhiều phụ kiện off-road cao cấp. Phù hợp cho những ai yêu thích khám phá thiên nhiên và địa hình khó.',
      'gallery': <String>[
        'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-adf51b971f224f050d44af15e08feaf8d0.jpg',
        'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-53c66cccf9e58cc440c7508ff175738e03.jpg',
        'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-99133bdfbb1f4d71cef5c8d261d7e27f9e.jpg',
        'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-b22a0a7dc532e8f54149c694e16463678f.jpg',
        'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-d4380c95e39cfdd7218ea909c12de66bc4.jpg',
        'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-d7a09e06dc673115a0358a3e61faf95221.jpg',
        'assets/images/products/Toyota-Tacoma_Trailhunter-2024-1280-df47e0962b8953060319f5271286c50713.jpg',
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
        'Toyota',
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
      itemCount: _toyotaCars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_toyotaCars[index]);
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
                  images: (car['gallery'] as List<String>?) ?? [car['image'] as String],
                  height: 200,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                        const Icon(Icons.star, color: Colors.orange, size: 12),
                      ],
                    ),
                  ),
                ),
                // NEW tag
                if (car['isNew'] == true)
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
