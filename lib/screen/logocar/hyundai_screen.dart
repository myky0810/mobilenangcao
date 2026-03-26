import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';

class HyundaiScreen extends StatefulWidget {
  const HyundaiScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<HyundaiScreen> createState() => _HyundaiScreenState();
}

class _HyundaiScreenState extends State<HyundaiScreen> {
  Set<String> _favorites = {};
  int _activeNavIndex = 0;

  final List<HyundaiCar> _hyundaiCars = [
    HyundaiCar(
      id: 'hyundai_1',
      name: 'Hyundai Santa Fe',
      price: '1.329.000.000đ',
      priceNote: 'Lăn bánh từ 1.5 tỷ',
      image: 'assets/images/products/car1.jpg',
      rating: 4.7,
      reviewCount: 145,
      isNew: false,
      description:
          'Hyundai Santa Fe SUV 7 chỗ cao cấp với thiết kế mạnh mẽ, động cơ Turbo mạnh mẽ và trang bị an toàn hiện đại. Lựa chọn lý tưởng cho gia đình lớn và những chuyến du lịch dài.',
      gallery: [
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
      ],
    ),
    HyundaiCar(
      id: 'hyundai_2',
      name: 'Hyundai Tucson',
      price: '799.000.000đ',
      priceNote: 'Lăn bánh từ 900k',
      image: 'assets/images/products/car2.jpg',
      rating: 4.6,
      reviewCount: 128,
      isNew: true,
      description:
          'Hyundai Tucson thế hệ mới với thiết kế táo bạo, công nghệ SmartSense và nội thất sang trọng. SUV compact hoàn hảo cho cuộc sống đô thị năng động.',
      gallery: [
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
      ],
    ),
    HyundaiCar(
      id: 'hyundai_3',
      name: 'Hyundai Accent',
      price: '529.000.000đ',
      priceNote: 'Lăn bánh từ 600k',
      image: 'assets/images/products/car3.jpg',
      rating: 4.4,
      reviewCount: 94,
      isNew: false,
      description:
          'Hyundai Accent sedan hạng B thông minh với thiết kế trẻ trung, vận hành tiết kiệm nhiên liệu và giá thành phù hợp. Lựa chọn thông minh cho khách hàng lần đầu mua xe.',
      gallery: [
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
      ],
    ),
    HyundaiCar(
      id: 'hyundai_4',
      name: 'Hyundai Elantra',
      price: '699.000.000đ',
      priceNote: 'Lăn bánh từ 790k',
      image: 'assets/images/products/car1.jpg',
      rating: 4.5,
      reviewCount: 112,
      isNew: false,
      description:
          'Hyundai Elantra sedan hạng C với thiết kế coupe thể thao, động cơ mạnh mẽ và trang bị công nghệ hiện đại. Phù hợp cho những ai yêu thích sự năng động và phong cách.',
      gallery: [
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
      ],
    ),
    HyundaiCar(
      id: 'hyundai_5',
      name: 'Hyundai Kona',
      price: '679.000.000đ',
      priceNote: 'Lăn bánh từ 770k',
      image: 'assets/images/products/car2.jpg',
      rating: 4.3,
      reviewCount: 87,
      isNew: false,
      description:
          'Hyundai Kona crossover nhỏ gọn với thiết kế cá tính, vận hành linh hoạt trong đô thị và tiết kiệm nhiên liệu. SUV đô thị hoàn hảo cho giới trẻ hiện đại.',
      gallery: [
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
      ],
    ),
    HyundaiCar(
      id: 'hyundai_6',
      name: 'Hyundai Creta',
      price: '659.000.000đ',
      priceNote: 'Lăn bánh từ 750k',
      image: 'assets/images/products/car3.jpg',
      rating: 4.5,
      reviewCount: 106,
      isNew: false,
      description:
          'Hyundai Creta SUV 5 chỗ với thiết kế hiện đại, khoang cabin rộng rãi và trang bị tiện nghi đầy đủ. Lựa chọn cân bằng giữa tính thực dụng và phong cách.',
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

  Future<void> _toggleFavorite(HyundaiCar car) async {
    final carData = {
      'id': car.id,
      'name': car.name,
      'brand': 'Hyundai',
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
        'HYUNDAI',
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
      itemCount: _hyundaiCars.length,
      itemBuilder: (context, index) {
        return _buildCarCard(_hyundaiCars[index]);
      },
    );
  }

  Widget _buildCarCard(HyundaiCar car) {
    final isFavorited = _favorites.contains(car.id);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detailcar',
          arguments: {
            'carName': car.name,
            'carBrand': 'Hyundai',
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
                      car.image,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    car.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 0),
          _buildNavItem(Icons.directions_car, 1),
          _buildNavItem(Icons.favorite_border, 2),
          _buildNavItem(Icons.person_outline, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () {
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[500],
          size: 24,
        ),
      ),
    );
  }
}

// Model cho Hyundai Car
class HyundaiCar {
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

  HyundaiCar({
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
