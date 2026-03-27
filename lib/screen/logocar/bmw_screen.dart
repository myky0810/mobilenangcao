import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';
import '../../widgets/car_image_slider.dart';

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
      'name': 'BMW 3 Series 2019',
      'brand': 'BMW',
      'price': '1.899.000.000đ',
      'priceNote': 'Lăn bánh từ 2.1 tỷ',
      'image': 'assets/images/products/BMW-3-Series-2019-1280-199cd3c9a9e4186bdafdb6442254df99de.jpg',
      'rating': 8.5,
      'reviewCount': 128,
      'isNew': true,
      'description':
          'BMW 3 Series 2019 là sedan hạng sang mang ADN thể thao BMW đặc trưng. Động cơ TwinPower Turbo, hệ thống treo thích ứng và cảm giác lái chính xác cùng nội thất cao cấp tạo nên trải nghiệm lý tưởng cho người yêu xe.',
      'gallery': <String>[
        'assets/images/products/BMW-3-Series-2019-1280-199cd3c9a9e4186bdafdb6442254df99de.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-262e22c0f5ff5d0bb5e9edb3f2158fb2b5.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-910360cae38e49661529df4963594c9f1a.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-c7d9ede0564a4798c28f1cfee053f7ba1b.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-f337b44e6f1581d4771a85e301ef1d9f9b.jpg',
        'assets/images/products/BMW-3-Series-2019-Rear_Three-Quarter.2693abe9.jpg',
      ],
    },
    {
      'id': 'bmw_2',
      'name': 'BMW 6 Series Gran Turismo 2021',
      'brand': 'BMW',
      'price': '3.699.000.000đ',
      'priceNote': 'Lăn bánh từ 4.1 tỷ',
      'image': 'assets/images/products/BMW-6-Series_Gran_Turismo-2021-1280-0fd5ee1b64aecc867412e9e7c24160601b.jpg',
      'rating': 9.0,
      'reviewCount': 96,
      'isNew': false,
      'description':
          'BMW 6 Series Gran Turismo 2021 là sự kết hợp hoàn hảo giữa sedan hạng sang và SUV: khoang hành khách rộng rãi 4/5 chỗ, đường nét thiết kế mềm mại nhưng đầy sức mạnh. Động cơ 6 xi-lanh mạnh mẽ cùng hệ thống xDrive toàn cầu.',
      'gallery': <String>[
        'assets/images/products/BMW-6-Series_Gran_Turismo-2021-1280-0fd5ee1b64aecc867412e9e7c24160601b.jpg',
        'assets/images/products/BMW-6-Series_Gran_Turismo-2021-1280-312256a94532de4e7672bee186765a81fc.jpg',
        'assets/images/products/BMW-6-Series_Gran_Turismo-2021-1280-518dea6a50154882358cc6bf43c0ce8c24.jpg',
        'assets/images/products/BMW-6-Series_Gran_Turismo-2021-1280-a460491b37a0fb90bed3649f4124c9cee4.jpg',
        'assets/images/products/BMW-6-Series_Gran_Turismo-2021-1280-c2ca482dcba7997796a2b99e8243e167a7.jpg',
        'assets/images/products/BMW-6-Series_Gran_Turismo-2021-Rear_Three-Quarter.dd906a93.jpg',
      ],
    },
    {
      'id': 'bmw_3',
      'name': 'BMW 8 Series Gran Coupe 2020',
      'brand': 'BMW',
      'price': '6.499.000.000đ',
      'priceNote': 'Lăn bánh từ 7.2 tỷ',
      'image': 'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-008f2e70e0d5d41c5bac8eaad69069d746.jpg',
      'rating': 9.5,
      'reviewCount': 72,
      'isNew': false,
      'description':
          'BMW 8 Series Gran Coupe 2020 – siêu phẩm 4 cửa hạng sang với thiết kế coupe quyến rũ. Động cơ V8/V12 TwinPower Turbo, M Sport Package, nội thất Merino leather thủ công và công nghệ thông minh tiên tiến nhất của BMW.',
      'gallery': <String>[
        'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-008f2e70e0d5d41c5bac8eaad69069d746.jpg',
        'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg',
        'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-25e73bf74312e623ef8e57cb41bd0f0065.jpg',
        'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-b5db26d294bf4540381d03852a44309071.jpg',
        'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-c64f5a11804cc05c42d8741a9573e16e25.jpg',
        'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-e13e8705d6efb353c8a45e27477b0c9e89.jpg',
      ],
    },
    {
      'id': 'bmw_4',
      'name': 'BMW X7 2023',
      'brand': 'BMW',
      'price': '7.799.000.000đ',
      'priceNote': 'Lăn bánh từ 8.5 tỷ',
      'image': 'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
      'rating': 9.2,
      'reviewCount': 88,
      'isNew': true,
      'description':
          'BMW X7 2023 – SUV đỉnh cao hạng sang 6/7 chỗ. Mặt ca-lăng đôi lớn và táo bạo, nội thất rộng rãi sang trọng với 3 hàng ghế thoải mái, hệ thống giải trí màn hình đôi cong 14.9 inch và đầy đủ công nghệ hỗ trợ lái.',
      'gallery': <String>[
        'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
        'assets/images/products/BMW-X7-2023-1280-297ea50aea9d6f4fb52a4cca5a5718131f.jpg',
        'assets/images/products/BMW-X7-2023-1280-528da416a6f27c502b174cf3c931e7fe73.jpg',
        'assets/images/products/BMW-X7-2023-1280-664e52a5958bfe61899dc501d95ab720bb.jpg',
        'assets/images/products/BMW-X7-2023-1280-9263bf2a78ef49c7e8752a9d49d7c571d5.jpg',
        'assets/images/products/BMW-X7-2023-1280-eb0880478b2b938f9ecb766e3902ccd5a7.jpg',
        'assets/images/products/BMW-X7-2023-1280-f06e1865b7babd08a7c8baaae989ebd58b.jpg',
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
