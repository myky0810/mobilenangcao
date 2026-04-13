import 'package:flutter/material.dart';

/// Premium bulldog logo widget.
///
/// Uses the generated bulldog image with premium effects:
/// gold rim, glow shadow, shine overlay, 3D press animation.
class LamboLogo extends StatefulWidget {
  const LamboLogo({super.key, this.size = 160, this.onTap, this.text = 'GGG'});

  final double size;
  final VoidCallback? onTap;
  final String text;

  @override
  State<LamboLogo> createState() => _LamboLogoState();
}

class _LamboLogoState extends State<LamboLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_pressCtrl.isAnimating) return;
    widget.onTap?.call();
    await _pressCtrl.forward(from: 0);
    if (!mounted) return;
    await _pressCtrl.reverse(from: 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return Semantics(
      label: '${widget.text} logo',
      button: true,
      child: GestureDetector(
        onTap: _tap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (context, child) {
            final press = Curves.easeOut.transform(_pressCtrl.value);
            final scale = 1.0 - 0.05 * press;
            final rotX = 0.04 * press;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(rotX)
                ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
              child: SizedBox(
                width: s,
                height: s,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Premium shadow glow ──
                    Positioned.fill(
                      child: Container(
                        margin: EdgeInsets.all(s * 0.05),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3A6EA5,
                              ).withValues(alpha: 0.20),
                              blurRadius: s * 0.18,
                              spreadRadius: s * 0.02,
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.10),
                              blurRadius: s * 0.12,
                              spreadRadius: s * 0.01,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Base logo image ──
                    ClipOval(
                      child: Image.asset(
                        'assets/images/bulldog_logo.png',
                        width: s,
                        height: s,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),

                    // ── Gold rim ring ──
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.45),
                            width: s * 0.012,
                          ),
                        ),
                      ),
                    ),

                    // ── Subtle shine gloss overlay ──
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.06),
                            ],
                            stops: const [0.0, 0.35, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
