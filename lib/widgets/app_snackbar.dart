import 'package:flutter/material.dart';

/// Centralized SnackBar styling to keep the whole app consistent.
///
/// Notes:
/// - We keep it "floating" so radius is visible.
/// - Use [AppSnackBar.show] for typical messages.
/// - Use [AppSnackBar.showModern] to match the gradient style used in OTP/CreatePass/Bookcar.
class AppSnackBar {
  /// Standard radius for SnackBars across the app.
  ///
  /// Picked to match existing UI components (many already use 12).
  static const double radius = 14;

  static ShapeBorder get shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
    EdgeInsetsGeometry? margin,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: shape,
          margin: margin,
          action: action,
        ),
      );
  }

  /// "Modern" snackbar style (transparent SnackBar + gradient container).
  static void showModern(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
    int durationSeconds = 3,
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 0, 16, 20),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: Duration(seconds: durationSeconds),
          margin: margin,
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
