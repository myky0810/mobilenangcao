import 'package:flutter/material.dart';
import 'package:doan_cuoiki/models/car_detail.dart';
import '../navigation_observer.dart';
import '../services/favorite_service.dart';
import '../widgets/car_card.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with RouteAware {
  int _activeNavIndex = 2; // Favorite được chọn (index 2)
  List<CarDetailData> _favoriteCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteCars();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    _loadFavoriteCars();
  }

  Future<void> _loadFavoriteCars() async {
    try {
      setState(() => _isLoading = true);

      // Lấy danh sách yêu thích từ SharedPreferences và chuyển thành CarDetailData
      final favorites = await FavoriteService.getFavorites();
      final favoriteCars = favorites.map((fav) => CarDetailData.fromMap(fav)).toList();

      if (!mounted) return;
      setState(() {
        _favoriteCars = favoriteCars;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải danh sách yêu thích: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101B28),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0E1623),
      elevation: 0,
      title: const Text(
        'Sản phẩm yêu thích',
        style: TextStyle(
          color: Color(0xFF8AACFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
              image: const DecorationImage(
                image: AssetImage('assets/images/RR.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
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
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/newcar',
                  arguments: widget.phoneNumber,
                );
              },
              icon: const Icon(Icons.directions_car_rounded),
              label: const Text('Khám phá xe ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82C8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _favoriteCars.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_favoriteCars.length} xe đã lưu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Danh sách xe bạn đã đánh dấu yêu thích',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],
          );
        }
        return CarCard(
          id: _favoriteCars[index - 1].id,
          name: _favoriteCars[index - 1].name,
          brand: _favoriteCars[index - 1].brand,
          price: _favoriteCars[index - 1].price,
          priceNote: 'Lăn bánh từ ${_favoriteCars[index - 1].price}',
          image: _favoriteCars[index - 1].image,
          gallery: _favoriteCars[index - 1].images,
          rating: _favoriteCars[index - 1].rating,
          reviewCount: _favoriteCars[index - 1].reviewCount,
          isNew: _favoriteCars[index - 1].isNew,
          description: _favoriteCars[index - 1].description,
          phoneNumber: widget.phoneNumber,
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF121B28),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 12,
              offset: Offset(0, -3),
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
            _buildNavItem(Icons.verified_user_rounded, 3),
            _buildNavItem(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        if (_activeNavIndex == index) return;
        setState(() {
          _activeNavIndex = index;
        });

        // Điều hướng tới các màn hình tương ứng.
        if (index == 0) {
          // Điều hướng về màn hình Trang chủ.
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: widget.phoneNumber,
          );
        } else if (index == 1) {
          // Điều hướng tới màn hình xe mới.
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
          // Điều hướng tới màn hình bảo hành.
          Navigator.pushReplacementNamed(
            context,
            '/warranty',
            arguments: widget.phoneNumber,
          );
        } else if (index == 4) {
          // Điều hướng tới màn hình hồ sơ.
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
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(59, 130, 200, 0.6),
                    blurRadius: 12,
                    offset: Offset(0, 4),
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
