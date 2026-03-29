import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doan_cuoiki/widgets/luxury_logo.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

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
            Column(
              children: [
                // ── TOP: RR logo + WELCOME text (upper half) ──
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Luxury logo ──
                      const LuxuryLogo(size: 120),
                      const SizedBox(height: 18),
                      // WELCOME text
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
          ],
        ),
      ),
    );
  }
}
