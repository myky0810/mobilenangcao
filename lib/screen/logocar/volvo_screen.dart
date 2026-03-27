import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';
import '../../widgets/car_image_slider.dart';

class VolvoScreen extends StatefulWidget {
  const VolvoScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<VolvoScreen> createState() => _VolvoScreenState();
}

class _VolvoScreenState extends State<VolvoScreen> {
  int _activeNavIndex = 0;
  List<String> _favoriteIds = [];

  final List<Map<String, dynamic>> _volvoCars = [
    {
      'id': 'volvo_1',
      'name': 'Volvo XC40 Recharge 2023',
      'brand': 'Volvo',
      'price': '2.299.000.000đ',
      'priceNote': 'Lăn bánh từ 2.6 tỷ',
      'image': 'assets/images/products/Volvo-XC40_Recharge-2023-1280-20af6e11057d63aefa0b99ee4160b33035.jpg',
      'rating': 9.0,
      'reviewCount': 142,
      'isNew': true,
      'description':
          'Volvo XC40 Recharge 2023 là SUV điện thuần túy với phạm vi 418km/lần sạc, tăng tốc 0-100km/h chỉ 4.9 giây. Thiết kế Scandinavian tinh tế, hệ thống an toàn Pilot Assist và Google Automotive Services tích hợp sẵn.',
      'gallery': <String>[
        'assets/images/products/Volvo-XC40_Recharge-2023-1280-20af6e11057d63aefa0b99ee4160b33035.jpg',
        'assets/images/products/Volvo-XC40_Recharge-2023-1280-a1bc2d0f31a3b46f38358216c1433f3db7.jpg',
        'assets/images/products/Volvo-XC40_Recharge-2023-1280-b6905ce9a2140e12548e37cb80356aad56.jpg',
        'assets/images/products/Volvo-XC40_Recharge-2023-1280-f66f58657eb01ed912e96b3bb0c48ff9d9.jpg',
        'assets/images/products/Volvo-XC40_Recharge-2023-1280-fb46f4e9c4d896858fbba5c1206c609ddf.jpg',
        'assets/images/products/Volvo-XC40_Recharge-2023-wallpaper.jpg',
      ],
    },
    {
      'id': 'volvo_2',
      'name': 'Volvo S90 2020',
      'brand': 'Volvo',
      'price': '2.690.000.000đ',
      'priceNote': 'Lăn bánh từ 3.0 tỷ',
      'image': 'assets/images/products/Volvo-S90-2020-1280-2f45f4e51bdb672a5d9d6842006b5ec994.jpg',
      'rating': 9.2,
      'reviewCount': 118,
      'isNew': false,
      'description':
          'Volvo S90 2020 – sedan hạng sang đỉnh cao mang tinh thần Bắc Âu. Nội thất Open Sky với kính panorama, ghế da Nappa cao cấp, âm thanh Bowers & Wilkins và hệ thống treo khí nén tạo nên chuyến đi hoàn hảo.',
      'gallery': <String>[
        'assets/images/products/Volvo-S90-2020-1280-2f45f4e51bdb672a5d9d6842006b5ec994.jpg',
        'assets/images/products/Volvo-S90-2020-1280-3699f617653f2ffb367790c930c623f440.jpg',
        'assets/images/products/Volvo-S90-2020-1280-4aa133bb07986a22ae36641b4238d7175c.jpg',
        'assets/images/products/Volvo-S90-2020-1280-58f915deda511ead40e9ad80a285f5dc6e.jpg',
        'assets/images/products/Volvo-S90-2020-Engine_Bay.72037744.jpg',
        'assets/images/products/Volvo-S90-2020-Front.72037744.jpg',
        'assets/images/products/Volvo-S90-2020-Interior.72037744.jpg',
        'assets/images/products/Volvo-S90-2020-Side_Profile.72037744.jpg',
      ],
    },
    {
      'id': 'volvo_3',
      'name': 'Volvo S60 T8 Polestar 2019',
      'brand': 'Volvo',
      'price': '1.999.000.000đ',
      'priceNote': 'Lăn bánh từ 2.2 tỷ',
      'image': 'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-5b69199ac83c5b4b010562dd62cf7d8702.jpg',
      'rating': 9.0,
      'reviewCount': 96,
      'isNew': false,
      'description':
          'Volvo S60 Polestar Engineered 2019 là phiên bản hiệu năng cao do Polestar tinh chỉnh. Hệ dẫn động T8 AWD PHEV 415 mã lực, tăng tốc 0-100km/h chỉ 4.4 giây. Bộ giảm chấn Öhlins điều chỉnh được và vành BBS nhẹ.',
      'gallery': <String>[
        'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-5b69199ac83c5b4b010562dd62cf7d8702.jpg',
        'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-79da1111d2bceb723da5124a32c8c39eb5.jpg',
        'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-836fd600b9a4200e3f081038f224e319c7.jpg',
        'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-a313cb768a865f5c018f8bd93246532641.jpg',
        'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-adab432b074d396a2fd74cef16cafb5e14.jpg',
        'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-c1b7444c9fe2dc46a440f34652c10e543c.jpg',
        'assets/images/products/Volvo-S60_T8_Polestar_Engineered-2019-1280-f211ce945dd3c7d1c53776b893e6787356.jpg',
      ],
    },
    {
      'id': 'volvo_4',
      'name': 'Volvo V60 Cross Country 2019',
      'brand': 'Volvo',
      'price': '1.820.000.000đ',
      'priceNote': 'Lăn bánh từ 2.1 tỷ',
      'image': 'assets/images/products/Volvo-V60_Cross_Country-2019-1280-12d164eef5d199d0ebf101b5625d52cab8.jpg',
      'rating': 8.5,
      'reviewCount': 80,
      'isNew': false,
      'description':
          'Volvo V60 Cross Country 2019 kết hợp sự thanh lịch của wagon với khả năng off-road nhẹ: gầm cao, AWD tiêu chuẩn và nhiều tính năng off-road. Không gian chứa đồ rộng rãi, nội thất tiện nghi cao cấp và hệ thống an toàn Volvo đặc trưng.',
      'gallery': <String>[
        'assets/images/products/Volvo-V60_Cross_Country-2019-1280-12d164eef5d199d0ebf101b5625d52cab8.jpg',
        'assets/images/products/Volvo-V60_Cross_Country-2019-1280-68f8eb3c18e7cea6b67bedfd80e02b7aee.jpg',
        'assets/images/products/Volvo-V60_Cross_Country-2019-1280-6bf24848a571d26e58649af5b146b457ec.jpg',
        'assets/images/products/Volvo-V60_Cross_Country-2019-1280-75a1470e8dd9c22550478f39338480b654.jpg',
        'assets/images/products/Volvo-V60_Cross_Country-2019-1280-c017aca45316971b6dbf9cca632ba9270a.jpg',
        'assets/images/products/Volvo-V60_Cross_Country-2019-1280-c6ac5bc87b4149d5670cfad6d25eccef52.jpg',
        'assets/images/products/Volvo-V60_Cross_Country-2019-Interior.03f0a97b.jpg',
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
        'VOLVO',
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
      itemCount: _volvoCars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_volvoCars[index]);
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
            'carDescription': car['description'] ?? '',
            'carImages': car['gallery'] ?? [car['image']],
            'rating': car['rating'],
            'reviewCount': car['reviewCount'] ?? 80,
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
