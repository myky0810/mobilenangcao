import 'package:flutter/material.dart';

/// App-wide modern transition.
///
/// Tiny contract:
/// - Input: destination [page]
/// - Output: a [PageRoute] with a consistent, smooth animation
/// - Safe defaults: short duration, subtle fade + slide, no bouncing
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 260),
    Duration reverseDuration = const Duration(milliseconds: 220),
  }) : super(
          settings: settings,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
            final slide = Tween<Offset>(
              begin: const Offset(0.06, 0.02),
              end: Offset.zero,
            ).animate(curve);

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}

/// Convenience helper.
Future<T?> pushAppRoute<T>(BuildContext context, Widget page,
    {RouteSettings? settings}) {
  return Navigator.of(context).push<T>(
    AppPageRoute<T>(page: page, settings: settings),
  );
}
