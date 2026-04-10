import 'dart:math' as math;
import 'package:flutter/material.dart';

class LamboLogo extends StatefulWidget {
  const LamboLogo({
    super.key,
    this.size = 140, // Tăng size một chút để tôn dáng xe dài
    this.phoneFocusNode,
    this.passwordFocusNode,
    this.onTap,
  });

  final double size;
  final FocusNode? phoneFocusNode;
  final FocusNode? passwordFocusNode;
  final VoidCallback? onTap;

  @override
  State<LamboLogo> createState() => _LamboLogoState();
}

class _LamboLogoState extends State<LamboLogo> with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _poseController;
  late final AnimationController _headlightsController;

  double _targetPoseTurns = 0.0; // 0 = mặt trước, 0.5 = mặt sau

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _poseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Tăng nhẹ để lật mượt hơn
      value: 0.0,
    );

    _headlightsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 0.0,
    );

    widget.phoneFocusNode?.addListener(_handleFocusChanged);
    widget.passwordFocusNode?.addListener(_handleFocusChanged);
    _handleFocusChanged();
  }

  @override
  void didUpdateWidget(covariant LamboLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneFocusNode != widget.phoneFocusNode) {
      oldWidget.phoneFocusNode?.removeListener(_handleFocusChanged);
      widget.phoneFocusNode?.addListener(_handleFocusChanged);
    }
    if (oldWidget.passwordFocusNode != widget.passwordFocusNode) {
      oldWidget.passwordFocusNode?.removeListener(_handleFocusChanged);
      widget.passwordFocusNode?.addListener(_handleFocusChanged);
    }
    _handleFocusChanged();
  }

  void _handleFocusChanged() {
    final phoneHasFocus = widget.phoneFocusNode?.hasFocus == true;
    final passHasFocus = widget.passwordFocusNode?.hasFocus == true;

    // Đèn pha sáng khi nhập SĐT
    if (phoneHasFocus) {
      _headlightsController.animateTo(1.0, curve: Curves.easeOut);
    } else {
      _headlightsController.animateTo(0.0, curve: Curves.easeOut);
    }

    // Quay đuôi xe khi nhập Password
    _targetPoseTurns = passHasFocus ? 0.5 : 0.0;
    _poseController.animateTo(_targetPoseTurns, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    widget.phoneFocusNode?.removeListener(_handleFocusChanged);
    widget.passwordFocusNode?.removeListener(_handleFocusChanged);
    _spinController.dispose();
    _poseController.dispose();
    _headlightsController.dispose();
    super.dispose();
  }

  Future<void> _spinOnce() async {
    if (_spinController.isAnimating) return;
    widget.onTap?.call();

    _spinController.value = 0.0;
    await _spinController.animateTo(1.05, curve: Curves.easeInOutCubic);
    if (!mounted) return;
    _spinController.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return Semantics(
      label: 'Lambo logo',
      button: true,
      child: GestureDetector(
        onTap: _spinOnce,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size * 0.6, // Tỉ lệ khung hình dẹt hơn cho Lambo
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _spinController,
              _poseController,
              _headlightsController,
            ]),
            builder: (context, _) {
              final spinTurns = _spinController.value; 
              final poseTurns = _poseController.value; 
              final totalYRotation = (spinTurns + poseTurns) * 2 * math.pi;
              final headlights = _headlightsController.value;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // Tạo độ sâu 3D (perspective)
                  ..rotateY(totalYRotation),
                child: CustomPaint(
                  painter: _LamboLogoPainter(
                    headlights: headlights,
                    rearMode: (poseTurns >= 0.25), // Đổi mặt khi quay qua 90 độ
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LamboLogoPainter extends CustomPainter {
  _LamboLogoPainter({required this.headlights, required this.rearMode});

  final double headlights;
  final bool rearMode;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(0, h * 0.1);

    // Neon edge glow 
    final neonGlow = Paint()
      ..color = const Color(0xFFB7FFF6).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.0, w * 0.03)
      ..strokeJoin = StrokeJoin.miter
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06);

    // Main outline (Góc cạnh)
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.02)
      ..strokeJoin = StrokeJoin.miter;

    // Body Fill
    final bodyFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // --- VẼ FORM LAMBO (Góc cạnh, nêm nhọn) ---
    final car = Path();
    final roof = h * 0.20;
    final hood = h * 0.50;
    final belt = h * 0.55;
    final sill = h * 0.85;

    // Bắt đầu từ mũi xe thấp
    car.moveTo(w * 0.05, hood * 1.2); 
    car.lineTo(w * 0.28, hood); // Vuốt lên mui
    car.lineTo(w * 0.45, roof); // Kính chắn gió dốc
    car.lineTo(w * 0.58, roof); // Nóc xe ngắn
    car.lineTo(w * 0.88, belt); // Lưng dốc thẳng xuống đuôi
    car.lineTo(w * 0.95, sill * 0.9); // Đuôi cắt vuông
    car.lineTo(w * 0.85, sill);
    car.lineTo(w * 0.75, sill); // Hốc bánh sau
    car.lineTo(w * 0.65, sill * 0.85); 
    car.lineTo(w * 0.55, sill * 0.85); 
    car.lineTo(w * 0.45, sill); 
    car.lineTo(w * 0.35, sill); // Hốc bánh trước
    car.lineTo(w * 0.25, sill * 0.85);
    car.lineTo(w * 0.15, sill * 0.85);
    car.lineTo(w * 0.10, sill);
    car.lineTo(w * 0.05, hood * 1.2); // Đóng path
    car.close();

    canvas.drawPath(car, bodyFill);
    canvas.drawPath(car, neonGlow);
    canvas.drawPath(car, outline);

    // --- KÍNH XE (Góc cạnh) ---
    final cabin = Path()
      ..moveTo(w * 0.32, belt * 0.9)
      ..lineTo(w * 0.46, roof * 1.1)
      ..lineTo(w * 0.57, roof * 1.1)
      ..lineTo(w * 0.75, belt * 0.9);
    canvas.drawPath(
      cabin,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, w * 0.015)
        ..strokeJoin = StrokeJoin.miter,
    );

    // --- BÁNH XE (To bản, thể thao) ---
    final wheelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;
    canvas.drawCircle(Offset(w * 0.20, sill * 0.9), w * 0.06, wheelPaint);
    canvas.drawCircle(Offset(w * 0.60, sill * 0.9), w * 0.06, wheelPaint);

    // --- ĐÈN TRƯỚC / SAU ---
    if (!rearMode) {
      // Đèn pha trước (Chữ Y hoặc tam giác sắc nhọn)
      final base = const Color(0xFF8FE9FF);
      final warm = const Color(0xFFFFFFFF);
      
      final glow = Paint()
        ..color = Color.lerp(base, warm, 0.5)!.withValues(alpha: 0.1 + 0.5 * headlights)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * (0.05 + 0.1 * headlights));
        
      final light = Paint()
        ..color = Colors.white.withValues(alpha: 0.3 + 0.7 * headlights)
        ..style = PaintingStyle.fill;

      // Vẽ đèn pha hình tam giác xếch lên
      final headlightPath = Path()
        ..moveTo(w * 0.08, hood * 1.15)
        ..lineTo(w * 0.18, hood * 0.95)
        ..lineTo(w * 0.20, hood * 1.05)
        ..close();

      canvas.drawPath(headlightPath, glow);
      canvas.drawPath(headlightPath, light);
      
      // Vẽ luồng sáng quét ra phía trước khi bật đèn
      if (headlights > 0) {
        final beamPath = Path()
          ..moveTo(w * 0.08, hood * 1.15)
          ..lineTo(-w * 0.2, h)
          ..lineTo(w * 0.2, h)
          ..close();
        canvas.drawPath(
          beamPath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.4 * headlights), Colors.transparent]
            ).createShader(Rect.fromLTWH(-w * 0.2, hood * 1.15, w * 0.6, h))
        );
      }

    } else {
      // Đèn hậu (Khe đỏ mỏng đặc trưng)
      final tail = Paint()
        ..color = const Color(0xFFFF2222).withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      final tailGlow = Paint()
        ..color = const Color(0xFFFF2222).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05);

      final tailPath = Path()
        ..moveTo(w * 0.88, belt * 0.95)
        ..lineTo(w * 0.96, belt * 1.05)
        ..lineTo(w * 0.95, belt * 1.1)
        ..lineTo(w * 0.87, belt * 1.0)
        ..close();

      canvas.drawPath(tailPath, tailGlow);
      canvas.drawPath(tailPath, tail);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LamboLogoPainter oldDelegate) {
    return oldDelegate.headlights != headlights || oldDelegate.rearMode != rearMode;
  }
}