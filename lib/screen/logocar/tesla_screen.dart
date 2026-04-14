import 'package:flutter/material.dart';
import '../../navigation_observer.dart';
import '../../services/car_data_service.dart';
import '../../widgets/car_card.dart';
import '../../widgets/scrollview_animation.dart';

class TeslaScreen extends StatefulWidget {
  const TeslaScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<TeslaScreen> createState() => _TeslaScreenState();
}

class _TeslaScreenState extends State<TeslaScreen> with RouteAware {
  static const Color _bg = Color.fromARGB(255, 18, 32, 47);

  late List<Map<String, dynamic>> _teslaCars;

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
      _teslaCars = CarDataService().getCarsByBrand('Tesla');
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
        'Tesla',
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
          for (final car in _teslaCars)
            CarCard.fromMap(car, phoneNumber: widget.phoneNumber),
        ],
      ),
    );
  }
}
