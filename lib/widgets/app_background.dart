import 'package:flutter/material.dart';

/// Shared app background that matches the HomeScreen/DepositScreen palette.
///
/// Use this to keep backgrounds consistent across screens (Home/Favorite/MyCar/
/// NewCar and all brand logo-car pages).
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.useSafeArea = false,
    this.padding,
  });

  final Widget child;

  /// If true, wraps [child] with [SafeArea].
  /// Most screens already manage SafeArea themselves, so default is false.
  final bool useSafeArea;

  /// Optional padding around [child] when [useSafeArea] is false.
  final EdgeInsetsGeometry? padding;

  /// Base background color (same as `DepositScreen._bg`).
  static const Color base = Color(0xFF1E2A47);

  /// Gradient background used on HomeScreen.
  static const List<Color> gradient = <Color>[
    Color(0xFF2C3E5C),
    Color(0xFF253553),
    Color(0xFF1E2A47),
    Color(0xFF18233B),
  ];

  static BoxDecoration decoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradient,
        stops: [0.0, 0.35, 0.75, 1.0],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Container(decoration: decoration(), child: content);
  }
}
