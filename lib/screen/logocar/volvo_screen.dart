import 'package:flutter/material.dart';
import '../../navigation_observer.dart';
import '../../services/car_data_service.dart';
import '../../widgets/car_card.dart';
import '../../widgets/scrollview_animation.dart';

class VolvoScreen extends StatefulWidget {
  const VolvoScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<VolvoScreen> createState() => _VolvoScreenState();
}

class _VolvoScreenState extends State<VolvoScreen> with RouteAware {
  static const Color _bg = Color.fromARGB(255, 18, 32, 47);

  late List<Map<String, dynamic>> _volvoCars;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(
      this,
      ModalRoute.of(context)! as PageRoute<dynamic>,
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadCars();
  }

  void _loadCars() {
    setState(() {
      _volvoCars = CarDataService().getCarsByBrand('Volvo');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      forceMaterialTransparency: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      title: const Text(
        'Volvo',
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
    return SafeArea(
      child: ScrollViewAnimation.children(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          for (final raw in _volvoCars) ...[
            // Defensive mapping: Firestore/local data may omit keys or contain nulls.
            CarCard.fromMap(<String, dynamic>{
              ...raw,
              'id': (raw['id'] ?? '').toString(),
              'name': (raw['name'] ?? 'Volvo').toString(),
              'brand': (raw['brand'] ?? 'Volvo').toString(),
              'price': (raw['price'] ?? 'Liên hệ').toString(),
              'priceNote': (raw['priceNote'] ?? 'Liên hệ').toString(),
              'image': (raw['image'] ?? '').toString(),
              'rating': (raw['rating'] as num?)?.toDouble(),
              'reviewCount':
                  (raw['reviewCount'] as int?) ??
                  (raw['reviewCount'] as num?)?.toInt(),
              'isNew': raw['isNew'] as bool? ?? false,
              'description': (raw['description'] ?? '').toString(),
              // CarCard.fromMap expects `gallery` not `images`.
              'gallery':
                  (raw['gallery'] as List?) ??
                  (raw['images'] as List?) ??
                  const <dynamic>[],
            }, phoneNumber: widget.phoneNumber),
          ],
        ],
      ),
    );
  }
}
