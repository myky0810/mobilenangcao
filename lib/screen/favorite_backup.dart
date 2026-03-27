import 'package:flutter/material.dart';
import '../services/favorite_service.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> _favoriteCars = [];
  bool _isLoading = true;
  int _activeNavIndex = 2;

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

      setState(() {
        _favoriteCars = favorites;
        _isLoading = false;
      });
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
      await FavoriteService.removeFromFavorites(carId);

      setState(() {
        _favoriteCars.removeWhere((car) => car['id'] == carId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa khỏi danh sách yêu thích'),
            backgroundColor: Colors.orange,
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
        'Xe yêu thích',
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }

    if (_favoriteCars.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có xe yêu thích nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy thêm xe vào danh sách yêu thích',
              style: TextStyle(color: Colors.grey, fontSize: 14),
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
            'carImages': [
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car['name'] ?? 'Xe yêu thích',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    car['brand'] ?? car['subtitle'] ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    car['price'] ?? 'Liên hệ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            '/homescreen',
            arguments: {'phoneNumber': widget.phoneNumber},
          );
        } else if (index == 1) {
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: {'phoneNumber': widget.phoneNumber},
          );
        } else if (index == 3) {
          Navigator.pushReplacementNamed(
            context,
            '/profile',
            arguments: {'phoneNumber': widget.phoneNumber},
          );
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.orange : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }
}
