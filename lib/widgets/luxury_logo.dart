import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium luxury logo widget with:
/// - Sweep gradient ring (silver → cyan-blue → silver)
/// - Glow blur effect around the ring
/// - Dark navy radial background
/// - "RR" text with blue-white shader gradient
/// - 4 diamond accent marks on the ring
class LuxuryLogo extends StatelessWidget {
  final double size;
  const LuxuryLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Ring + background (CustomPainter) ──
          CustomPaint(
            size: Size(size, size),
            painter: _LuxuryRingPainter(),
          ),

          // ── "RR" with gradient color ──
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF), // white
                Color(0xFF90CAF9), // light blue
                Color(0xFF00E5FF), // cyan
                Color(0xFF90CAF9), // light blue
                Color(0xFFFFFFFF), // white
              ],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              'RR',
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: size * 0.01,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ringRadius = radius * 0.86;

    // ── 1. Outer glow (blur layers) ──
    for (int i = 4; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = const Color(0xFF00BCD4).withValues(alpha: 0.07 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.14 + i * 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, ringRadius, glowPaint);
    }

    // ── 2. Dark navy background ──
    final bgRect = Rect.fromCircle(center: center, radius: ringRadius - 1);
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.4,
        colors: const [
          Color(0xFF1C2E45), // dark navy blue
          Color(0xFF08101E), // near black
        ],
      ).createShader(bgRect);
    canvas.drawCircle(center, ringRadius - 1, bgPaint);

    // ── 3. Sweep gradient ring ──
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.075
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [
          Color(0xFFE0E0E0), // silver
          Color(0xFF64B5F6), // steel blue
          Color(0xFF00E5FF), // bright cyan
          Color(0xFF64B5F6), // steel blue
          Color(0xFFE0E0E0), // silver
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(ringRect);
    canvas.drawCircle(center, ringRadius, ringPaint);

    // ── 4. Inner thin decorative ring ──
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.35);
    canvas.drawCircle(center, radius * 0.68, innerRingPaint);

    // ── 5. Diamond accent marks at 4 cardinal points on the ring ──
    final diamondAngles = [
      -math.pi / 2, // top
      0.0, // right
      math.pi / 2, // bottom
      math.pi, // left
    ];

    for (final angle in diamondAngles) {
      final px = center.dx + ringRadius * math.cos(angle);
      final py = center.dy + ringRadius * math.sin(angle);
      final r = radius * 0.045;

      final path = Path()
        ..moveTo(px, py - r)
        ..lineTo(px + r * 0.6, py)
        ..lineTo(px, py + r)
        ..lineTo(px - r * 0.6, py)
        ..close();

      final diamondPaint = Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF00E5FF), Color(0xFF64B5F6)],
        ).createShader(Rect.fromCenter(
          center: Offset(px, py),
          width: r * 2,
          height: r * 2,
        ));
      canvas.drawPath(path, diamondPaint);
    }

    // ── 6. Subtle horizontal sheen across the center ──
    final sheenRect = Rect.fromLTWH(
      center.dx - radius * 0.55,
      center.dy - radius * 0.08,
      radius * 1.1,
      radius * 0.16,
    );
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(sheenRect);
    canvas.drawOval(sheenRect, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
