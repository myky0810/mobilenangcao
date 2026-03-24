import 'package:flutter/material.dart';
import '../../services/favorite_service.dart';

class MazdaScreen extends StatefulWidget {
  const MazdaScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<MazdaScreen> createState() => _MazdaScreenState();
}

class _MazdaScreenState extends State<MazdaScreen> {
  Set<String> _favorites = {};

  final List<MazdaCar> _mazdaCars = [
    MazdaCar(
      id: 'mazda_1',
      name: 'Mazda CX-5',
      price: '839.000.000đ',
      priceNote: 'Lăn bánh từ 950k',
      image: 'assets/images/products/car1.jpg',
      rating: 4.8,
    ),
    MazdaCar(
      id: 'mazda_2',
      name: 'Mazda3',
      price: '669.000.000đ',
      priceNote: 'Lăn bánh từ 750k',
      image: 'assets/images/products/car2.jpg',
      rating: 4.7,
    ),
    MazdaCar(
      id: 'mazda_3',
      name: 'Mazda6',
      price: '929.000.000đ',
      priceNote: 'Lăn bánh từ 1.05 tỷ',
      image: 'assets/images/products/car3.jpg',
      rating: 4.6,
    ),
    MazdaCar(
      id: 'mazda_4',
      name: 'Mazda CX-30',
      price: '759.000.000đ',
      priceNote: 'Lăn bánh từ 850k',
      image: 'assets/images/products/car1.jpg',
      rating: 4.5,
    ),
    MazdaCar(
      id: 'mazda_5',
      name: 'Mazda CX-8',
      price: '1.319.000.000đ',
      priceNote: 'Lăn bánh từ 1.5 tỷ',
      image: 'assets/images/products/car2.jpg',
      rating: 4.7,
    ),
    MazdaCar(
      id: 'mazda_6',
      name: 'Mazda2',
      price: '509.000.000đ',
      priceNote: 'Lăn bánh từ 580k',
      image: 'assets/images/products/car3.jpg',
      rating: 4.4,
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

    return Container(
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

  MazdaCar({
    required this.id,
    required this.name,
    required this.price,
    required this.priceNote,
    required this.image,
    required this.rating,
  });
}
