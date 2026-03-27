import 'package:flutter/material.dart';
import '../services/favorite_service.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int _activeNavIndex = 2; // Favorite được chọn (index 2)
  List<Map<String, dynamic>> _favoriteCars = [];
  bool _isLoading = true;

  // Sample data cho test (sẽ thay thế bằng data từ Firebase)
  final List<FavoriteCarModel> _sampleCars = [
    FavoriteCarModel(
      id: '1',
      name: 'C 200 Avantgarde (VỊ)',
      brand: 'Mercedes',
      price: '1.599.000.000đ',
      priceNote: 'Lăn bánh từ 1.8 tỷ',
      image: 'assets/images/products/car1.jpg',
      isFavorited: true,
    ),
    FavoriteCarModel(
      id: '2',
      name: 'Toyota Camry 2026',
      brand: 'Toyota',
      price: '1.220.000.000đ',
      priceNote: 'Lăn bánh từ 1.4 tỷ',
      image: 'assets/images/products/car2.jpg',
      isFavorited: true,
    ),
    FavoriteCarModel(
      id: '3',
      name: 'BMW 3 Series',
      brand: 'BMW',
      price: '1.899.000.000đ',
      priceNote: 'Lăn bánh từ 2.1 tỷ',
      image: 'assets/images/products/car3.jpg',
      isFavorited: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavoriteCars();
  }

  Future<void> _loadFavoriteCars() async {
    try {
      setState(() => _isLoading = true);

      // Lấy danh sách yêu thích từ SharedPreferences
      final favorites = await FavoriteService.getFavorites();

      if (favorites.isNotEmpty) {
        setState(() {
          _favoriteCars = favorites;
          _isLoading = false;
        });
      } else {
        // Nếu chưa có favorite nào, tạm thời dùng sample data
        setState(() {
          _favoriteCars = _sampleCars.map((car) => car.toMap()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách yêu thích: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(String carId) async {
    try {
      // Xóa từ SharedPreferences
      await FavoriteService.removeFromFavorites(carId);

      // Cập nhật UI
      setState(() {
        _favoriteCars.removeWhere((car) => car['id'] == carId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa khỏi danh sách yêu thích'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildBody(),
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
        'Sản phẩm yêu thích',
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
    if (_favoriteCars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có sản phẩm yêu thích',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm những chiếc xe bạn yêu thích',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteCars.length,
      itemBuilder: (context, index) {
        return _buildFavoriteCarCard(_favoriteCars[index]);
      },
    );
  }

  Widget _buildFavoriteCarCard(Map<String, dynamic> car) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detailcar',
          arguments: {
            'carName': car['name'] ?? 'Xe yêu thích',
            'carBrand': car['brand'] ?? car['subtitle'] ?? 'Unknown',
            'carImage': car['image'] ?? 'assets/images/products/car1.jpg',
            'carPrice': car['price'] ?? 'Liên hệ',
            'carDescription':
                'Xe ${car['name'] ?? 'yêu thích'} với thiết kế hiện đại và trang bị cao cấp. Đã được thêm vào danh sách yêu thích.',
            'carImages': <String>[
              car['image'] ?? 'assets/images/products/car1.jpg',
              'assets/images/products/car2.jpg',
              'assets/images/products/car3.jpg',
            ],
            'rating': (car['rating'] as num?)?.toDouble() ?? 4.5,
            'reviewCount': car['reviewCount'] ?? 95,
            'isNew': car['isNew'] ?? false,
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
                      car['image'] ?? 'assets/images/products/car1.jpg',
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
                    onTap: () => _removeFromFavorites(car['id'] ?? ''),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.6),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 22,
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
                    car['name'] ?? 'Unknown Car',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Brand
                  Text(
                    car['brand'] ?? 'Unknown Brand',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Text(
                    car['price'] ?? '0đ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price note
                  Text(
                    car['priceNote'] ?? '',
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
            _buildNavItem(Icons.favorite_rounded, 2), // Active
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
        } else if (index == 1) {
          // Navigate to NewCar
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
          // Navigate to Profile
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

// Model cho car yêu thích
class FavoriteCarModel {
  final String id;
  final String name;
  final String brand;
  final String price;
  final String priceNote;
  final String image;
  final bool isFavorited;

  FavoriteCarModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.priceNote,
    required this.image,
    this.isFavorited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'priceNote': priceNote,
      'image': image,
      'isFavorited': isFavorited,
    };
  }

  factory FavoriteCarModel.fromMap(Map<String, dynamic> map) {
    return FavoriteCarModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      price: map['price'] ?? '',
      priceNote: map['priceNote'] ?? '',
      image: map['image'] ?? '',
      isFavorited: map['isFavorited'] ?? false,
    );
  }
}
