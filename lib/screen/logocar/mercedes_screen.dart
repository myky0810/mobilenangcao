import 'package:flutter/material.dart';
import '../../navigation_observer.dart';
import '../../services/car_data_service.dart';
import '../../widgets/car_card.dart';
import '../../widgets/scrollview_animation.dart';

class MercedesScreen extends StatefulWidget {
  const MercedesScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<MercedesScreen> createState() => _MercedesScreenState();
}

class _MercedesScreenState extends State<MercedesScreen> with RouteAware {
  static const List<Color> _showroomGradient = <Color>[
    Color(0xFF545454),
    Color(0xFF3A3A3A),
    Color(0xFF252525),
    Color(0xFF171717),
  ];

  static const LinearGradient _showroomBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _showroomGradient,
    stops: [0.0, 0.35, 0.75, 1.0],
  );

  late List<Map<String, dynamic>> _mercedesCars;

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
      _mercedesCars = CarDataService().getCarsByBrand('Mercedes');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _showroomBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
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
        'Mercedes',
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
          for (final car in _mercedesCars)
            CarCard.fromMap(car, phoneNumber: widget.phoneNumber),
        ],
      ),
    );
  }
}
