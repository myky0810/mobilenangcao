import 'package:flutter/material.dart';
import 'package:doan_cuoiki/models/car_detail.dart';
import '../navigation_observer.dart';
import '../services/favorite_service.dart';
import '../widgets/car_card.dart';
import '../widgets/floating_car_bottom_nav.dart';
import '../widgets/scrollview_animation.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with RouteAware {
  // (Background gradient removed; screen now matches DetailCar dark background.)

  List<CarDetailData> _favoriteCars = [];
  int _activeNavIndex = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
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
    _loadFavorites();
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoriteService.getFavorites(
      phoneIdentifier: widget.phoneNumber,
    );
    if (!mounted) return;
    setState(() {
      _favoriteCars = favorites
          .map((m) => CarDetailData.fromMap(m))
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 32, 47),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'YÊU THÍCH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ScrollViewAnimation.children(
      // SafeArea đã được bọc ở ngoài (_build trong Scaffold body)
      useSafeArea: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Column(
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
        ),
        for (final car in _favoriteCars)
          CarCard(
            id: car.id,
            name: car.name,
            brand: car.brand,
            price: car.price,
            priceNote: 'Lăn bánh từ ${car.price}',
            image: car.image,
            gallery: car.images,
            rating: car.rating,
            reviewCount: car.reviewCount,
            isNew: car.isNew,
            description: car.description,
            phoneNumber: widget.phoneNumber,
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return FloatingCarBottomNav(
      currentIndex: _activeNavIndex,
      onTap: (index) {
        if (_activeNavIndex == index) return;
        setState(() => _activeNavIndex = index);

        // Nếu là admin, chỉ đổi tab, không điều hướng
        final isAdmin = ModalRoute.of(context)?.settings.name == '/admin';
        if (isAdmin) return;

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
            '/mycar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
          // already on Favorite
        } else if (index == 4) {
          Navigator.pushReplacementNamed(
            context,
            '/profile',
            arguments: widget.phoneNumber,
          );
        }
      },
    );
  }
}
