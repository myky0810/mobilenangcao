import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';
import '../../widgets/car_image_slider.dart';

class MazdaScreen extends StatefulWidget {
  const MazdaScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<MazdaScreen> createState() => _MazdaScreenState();
}

class _MazdaScreenState extends State<MazdaScreen> {
  Set<String> _favorites = {};
  int _activeNavIndex = 0;

  final List<MazdaCar> _mazdaCars = [
    MazdaCar(
      id: 'mazda_1',
      name: 'Mazda CX-5',
      price: '839.000.000đ',
      priceNote: 'Lăn bánh từ 950k',
      image: 'assets/images/products/car1.jpg',
      rating: 4.8,
      reviewCount: 156,
      isNew: true,
      description:
          'Mazda CX-5 thế hệ mới với thiết kế KODO đẹp mắt, động cơ SKYACTIV tiết kiệm nhiên liệu và hệ thống an toàn i-ACTIVSENSE tiên tiến. SUV 5 chỗ lý tưởng cho gia đình hiện đại.',
      gallery: [
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
      ],
    ),
    MazdaCar(
      id: 'mazda_2',
      name: 'Mazda3',
      price: '669.000.000đ',
      priceNote: 'Lăn bánh từ 750k',
      image: 'assets/images/products/car2.jpg',
      rating: 4.7,
      reviewCount: 123,
      isNew: false,
      description:
          'Mazda3 sedan hạng C với thiết kế thể thao, vận hành linh hoạt và nội thất cao cấp. Sự lựa chọn hoàn hảo cho khách hàng trẻ năng động trong đô thị.',
      gallery: [
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
      ],
    ),
    MazdaCar(
      id: 'mazda_3',
      name: 'Mazda6',
      price: '929.000.000đ',
      priceNote: 'Lăn bánh từ 1.05 tỷ',
      image: 'assets/images/products/car3.jpg',
      rating: 4.6,
      reviewCount: 98,
      isNew: false,
      description:
          'Mazda6 sedan hạng D sang trọng với thiết kế thanh lịch, công nghệ hiện đại và trải nghiệm lái xe đầy cảm hứng. Dành cho những ai yêu thích sự tinh tế.',
      gallery: [
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
      ],
    ),
    MazdaCar(
      id: 'mazda_4',
      name: 'Mazda CX-30',
      price: '759.000.000đ',
      priceNote: 'Lăn bánh từ 850k',
      image: 'assets/images/products/car1.jpg',
      rating: 4.5,
      reviewCount: 87,
      isNew: false,
      description:
          'Mazda CX-30 crossover compact với thiết kế coupe thể thao, động cơ mạnh mẽ và trang thiết bị tiện nghi. Phù hợp cho lối sống năng động.',
      gallery: [
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
      ],
    ),
    MazdaCar(
      id: 'mazda_5',
      name: 'Mazda CX-8',
      price: '1.319.000.000đ',
      priceNote: 'Lăn bánh từ 1.5 tỷ',
      image: 'assets/images/products/car2.jpg',
      rating: 4.7,
      reviewCount: 134,
      isNew: false,
      description:
          'Mazda CX-8 SUV 7 chỗ cao cấp với không gian rộng rãi, thiết kế sang trọng và công nghệ an toàn tiên tiến. Lựa chọn hoàn hảo cho gia đình đông thành viên.',
      gallery: [
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
      ],
    ),
    MazdaCar(
      id: 'mazda_6',
      name: 'Mazda2',
      price: '509.000.000đ',
      priceNote: 'Lăn bánh từ 580k',
      image: 'assets/images/products/car3.jpg',
      rating: 4.4,
      reviewCount: 76,
      isNew: false,
      description:
          'Mazda2 hatchback nhỏ gọn với thiết kế trẻ trung, vận hành tiết kiệm và giá thành hợp lý. Xe đô thị lý tưởng cho người mua xe lần đầu.',
      gallery: [
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoriteService.getFavorites();
    setState(() {
      _favorites = favorites.map((car) => car['id'] as String).toSet();
    });
  }

  Future<void> _toggleFavorite(MazdaCar car) async {
    final carData = {
      'id': car.id,
      'name': car.name,
      'brand': 'Mazda',
      'price': car.price,
      'priceNote': car.priceNote,
      'image': car.image,
      'rating': car.rating,
    };

    if (_favorites.contains(car.id)) {
      await FavoriteService.removeFromFavorites(car.id);
      setState(() {
        _favorites.remove(car.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa khỏi yêu thích'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await FavoriteService.addToFavorites(carData);
      setState(() {
        _favorites.add(car.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào yêu thích'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
        'MAZDA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mazdaCars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_mazdaCars[index]);
      },
    );
  }

  Widget _buildCarCard(MazdaCar car) {
    final isFavorited = _favorites.contains(car.id);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detailcar',
          arguments: {
            'carName': car.name,
            'carBrand': 'Mazda',
            'carImage': car.image,
            'carPrice': car.price,
            'carDescription': car.description,
            'carImages': car.gallery.isNotEmpty ? car.gallery : [car.image],
            'rating': car.rating,
            'reviewCount': car.reviewCount,
            'isNew': car.isNew,
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
                  images: car.gallery.isNotEmpty ? car.gallery : [car.image],
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
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                // NEW tag
                if (car.isNew)
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          car.rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
                    car.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    car.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price note
                  Text(
                    car.priceNote,
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

// Model cho Mazda Car
class MazdaCar {
  final String id;
  final String name;
  final String price;
  final String priceNote;
  final String image;
  final double rating;
  final int reviewCount;
  final bool isNew;
  final String description;
  final List<String> gallery;

  MazdaCar({
    required this.id,
    required this.name,
    required this.price,
    required this.priceNote,
    required this.image,
    required this.rating,
    this.reviewCount = 80,
    this.isNew = false,
    this.description = '',
    this.gallery = const [],
  });
}
