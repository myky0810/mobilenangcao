import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';
import '../../widgets/car_image_slider.dart';

class MercedesScreen extends StatefulWidget {
  const MercedesScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<MercedesScreen> createState() => _MercedesScreenState();
}

class _MercedesScreenState extends State<MercedesScreen> {
  int _activeNavIndex = 0;
  List<String> _favoriteIds = [];

  final List<Map<String, dynamic>> _mercedesCars = [
    {
      'id': 'mercedes_1',
      'name': 'Mercedes-Benz AMG GT Coupe 2024',
      'brand': 'Mercedes',
      'price': '8.500.000.000đ',
      'priceNote': 'Lăn bánh từ 9.2 tỷ',
      'image': 'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-00cab4cac69d4468527a0bddd73df086de.jpg',
      'rating': 9.5,
      'reviewCount': 210,
      'isNew': true,
      'description':
          'Mercedes-Benz AMG GT Coupe 2024 là siêu xe thể thao đỉnh cao với động cơ V8 twin-turbo 4.0L, sản sinh 577 mã lực. Thiết kế thuần thể thao với nội thất AMG Performance cao cấp, hệ thống treo thích ứng và chế độ lái đa dạng giúp xe chinh phục mọi cung đường.',
      'gallery': <String>[
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-00cab4cac69d4468527a0bddd73df086de.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-0af94a1f278f934636c462f62623fc4b76.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-421ec0ae85aedddd995507af718580eb0f.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-69b33067617647b278192eaa4d4cf713cb.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-8bd412930d690a0d314d4a59497b92606a.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-Rear.91ad5a3f.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-Side_Profile.91ad5a3f.jpg',
      ],
    },
    {
      'id': 'mercedes_2',
      'name': 'Mercedes-Benz G63 AMG 2025',
      'brand': 'Mercedes',
      'price': '11.900.000.000đ',
      'priceNote': 'Lăn bánh từ 13 tỷ',
      'image': 'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-038bcbee2f3dd71d41f1185ec519c69811.jpg',
      'rating': 9.8,
      'reviewCount': 185,
      'isNew': false,
      'description':
          'Mercedes-Benz G63 AMG 2025 - biểu tượng SUV hạng sang với động cơ V8 biturbo 4.0L, 585 mã lực. Khung gầm cứng cáp kết hợp nội thất siêu sang, hệ thống khóa vi sai điện tử 3 trục cho phép chinh phục mọi địa hình. Đây là biểu tượng của sức mạnh và đẳng cấp.',
      'gallery': <String>[
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-038bcbee2f3dd71d41f1185ec519c69811.jpg',
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-1ddc9ab31d0d53254e3a3a3e4438d93308.jpg',
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-72c6d26197b4b244f3677a97514e19e04e.jpg',
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-769aa742caf3f44036ee9931eb310892b3.jpg',
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-b2e6d172ce6819c7ea13d9b476511448cf.jpg',
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-Front.0b7c7887.jpg',
      ],
    },
    {
      'id': 'mercedes_3',
      'name': 'Mercedes-Benz GLC Coupe 2024',
      'brand': 'Mercedes',
      'price': '3.299.000.000đ',
      'priceNote': 'Lăn bánh từ 3.7 tỷ',
      'image': 'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-3d89595d79f2fdc414118a494015c6d489.jpg',
      'rating': 8.8,
      'reviewCount': 156,
      'isNew': false,
      'description':
          'Mercedes-Benz GLC Coupe 2024 – SUV Coupe sang trọng kết hợp phong cách thể thao và tính thực dụng. Nội thất MBUX thế hệ mới với màn hình 11.9 inch, ghế leather cao cấp và hệ thống âm thanh Burmester. Động cơ mild-hybrid tiết kiệm nhiên liệu mà vẫn đảm bảo vận hành mạnh mẽ.',
      'gallery': <String>[
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-3d89595d79f2fdc414118a494015c6d489.jpg',
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-63e36b654c72694284f49bc4a81b901da4.jpg',
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-6bc76a472d634a29a2dd9880e5c2828b1b.jpg',
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-7ad6bd42ca87a97a7d108de74775485b99.jpg',
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-93626637264fd0b80cfb3cad73550130ea.jpg',
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-Front.9d58c872.jpg',
      ],
    },
    {
      'id': 'mercedes_4',
      'name': 'Mercedes-Benz S-Class Maybach 2027',
      'brand': 'Mercedes',
      'price': '19.800.000.000đ',
      'priceNote': 'Lăn bánh từ 22 tỷ',
      'image': 'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-15bf9ddb7f519fa58e9c6f2320574c02a2.jpg',
      'rating': 10.0,
      'reviewCount': 98,
      'isNew': true,
      'description':
          'Mercedes-Maybach S-Class 2027 là đỉnh cao của đẳng cấp và xa xỉ. Khoang hành khách rộng rãi với ghế massage, màn hình giải trí riêng, hệ thống treo chủ động E-Active Body Control và âm thanh Burmester 4D. Đây là xe limousine hạng sang dành cho những ai muốn trải nghiệm sự hoàn hảo tuyệt đối.',
      'gallery': <String>[
        'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-15bf9ddb7f519fa58e9c6f2320574c02a2.jpg',
        'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-2f8b520f893056338912b56af08cf38838.jpg',
        'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-3160f741148982f4bf0f60bbb124192071.jpg',
        'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-4761c7b617fd0d3a40e1e134d0c6b41395.jpg',
        'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-92cf8c6006e10525f260e14771f327143b.jpg',
        'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-b533dd88b1bad9f4d4dfedf3300bfb7967.jpg',
        'assets/images/products/Mercedes-Benz-S-Class_Maybach-2027-1280-d8b4ddef32f544094f5defc900bd335e39.jpg',
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
        'Mercedes',
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
      itemCount: _mercedesCars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_mercedesCars[index]);
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
