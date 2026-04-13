import 'package:flutter/material.dart';
import '../../navigation_observer.dart';
import '../../services/car_data_service.dart';
import '../../widgets/car_card.dart';
import '../../widgets/floating_car_bottom_nav.dart';

class TeslaScreen extends StatefulWidget {
  const TeslaScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<TeslaScreen> createState() => _TeslaScreenState();
}

class _TeslaScreenState extends State<TeslaScreen> with RouteAware {
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
  backgroundColor: const Color(0xFF1E2A47),
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
    colors: [Color(0xFF1E2A47), Color(0xFF1E2A47), Color(0xFF1E2A47)],
          ),
        ),
        child: _buildBody(),
      ),
      bottomNavigationBar: FloatingCarBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;

          final isAdmin = ModalRoute.of(context)?.settings.name == '/admin';
          if (isAdmin) {
            setState(() {});
            return;
          }

          final routes = <int, String>{
            0: '/home',
            1: '/newcar',
            2: '/mycar',
            3: '/favorite',
            4: '/profile',
          };
          final route = routes[index];
          if (route == null) return;

          Navigator.pushReplacementNamed(
            context,
            route,
            arguments: widget.phoneNumber,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teslaCars.length,
      itemBuilder: (context, index) {
        return CarCard.fromMap(
          _teslaCars[index],
          phoneNumber: widget.phoneNumber,
        );
      },
    );
  }
}
