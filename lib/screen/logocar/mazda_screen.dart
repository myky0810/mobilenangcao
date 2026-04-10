import 'package:flutter/material.dart';
import '../../navigation_observer.dart';
import '../../services/car_data_service.dart';
import '../../widgets/car_card.dart';
import '../../widgets/floating_car_bottom_nav.dart';

class MazdaScreen extends StatefulWidget {
  const MazdaScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<MazdaScreen> createState() => _MazdaScreenState();
}

class _MazdaScreenState extends State<MazdaScreen> with RouteAware {
  late List<Map<String, dynamic>> _mazdaCars;

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
      _mazdaCars = CarDataService().getCarsByBrand('Mazda');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: FloatingCarBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;

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
      backgroundColor: const Color(0xFF333333),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      title: const Text(
        'Mazda',
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
      itemCount: _mazdaCars.length,
      itemBuilder: (context, index) {
        return CarCard.fromMap(
          _mazdaCars[index],
          phoneNumber: widget.phoneNumber,
        );
      },
    );
  }
}
