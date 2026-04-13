import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doan_cuoiki/widgets/supercar_logo.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  late final AnimationController _sparkleController;
  late final Animation<double> _sparkleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _scrollController.addListener(() {
      final next = _scrollController.offset;
      if (next == _scrollOffset) return;
      setState(() => _scrollOffset = next);
    });

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _sparkleAnim = CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeOutCubic,
    );

    // Auto navigate to login after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: full-screen car image with dark overlay ──
            Image.asset('assets/images/RR.jpg', fit: BoxFit.cover),
            // Dark overlay to darken the image
            Container(color: Colors.black.withValues(alpha: 0.50)),

            // ── Foreground content ──
            NotificationListener<ScrollNotification>(
              onNotification: (_) => false,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: [
                      // ── TOP: RR logo + WELCOME text (upper half) ──
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Subtle scroll effects
                            Builder(
                              builder: (_) {
                                final t = (_scrollOffset / 220.0).clamp(
                                  0.0,
                                  1.0,
                                );
                                final dy = -8.0 * t;
                                final scale = 1.0 - 0.03 * t;

                                return AnimatedBuilder(
                                  animation: _sparkleAnim,
                                  builder: (context, child) {
                                    final spark = _sparkleAnim.value;
                                    return Transform.translate(
                                      offset: Offset(0, dy),
                                      child: Transform.scale(
                                        scale: scale,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFB7FFF6)
                                                    .withValues(
                                                      alpha:
                                                          0.05 + 0.35 * spark,
                                                    ),
                                                blurRadius: 10 + 24 * spark,
                                                spreadRadius: 1 + 2 * spark,
                                              ),
                                            ],
                                          ),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: LamboLogo(
                                    size: 160,
                                    onTap: () {
                                      // quick blink/glow in addition to the built-in spin
                                      _sparkleController.forward(from: 0.0);
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'WELCOME',
                              style: GoogleFonts.leagueSpartan(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── BOTTOM: RR logo badge ──
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 48),
                            child: Container(
                              width: 110,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.70),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'RR',
                                style: GoogleFonts.leagueSpartan(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
