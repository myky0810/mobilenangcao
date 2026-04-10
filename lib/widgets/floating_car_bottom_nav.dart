import 'package:flutter/material.dart';

/// Bottom nav with a raised/floating center Car button by default.
///
/// Contract:
/// - [currentIndex] in [0..4], where 2 is the center Car tab.
/// - [onTap] receives 0,1,2,3,4.
class FloatingCarBottomNav extends StatelessWidget {
  const FloatingCarBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.horizontalPadding = 18,
    this.verticalPadding = 10,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  final Color backgroundColor;
  final double horizontalPadding;
  final double verticalPadding;

  static const _activeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4AA3FF), Color(0xFF2F6FED)],
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navIconOnly(context, Icons.home_rounded, 0),
                    _navIconOnly(context, Icons.search_rounded, 1),
                    const SizedBox(width: 64),
                    _navIconOnly(context, Icons.favorite_rounded, 3),
                    _navIconOnly(context, Icons.person_rounded, 4),
                  ],
                ),
              ),
            ),
            Positioned(bottom: 34, child: _centerCarButton(context)),
          ],
        ),
      ),
    );
  }

  Widget _navIconOnly(BuildContext context, IconData icon, int index) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white10 : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white54,
          size: 24,
        ),
      ),
    );
  }

  Widget _centerCarButton(BuildContext context) {
    final isActive = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _activeGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF2F6FED).withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
          border: isActive ? Border.all(color: Colors.white24, width: 1) : null,
        ),
        child: const Icon(
          Icons.directions_car_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
