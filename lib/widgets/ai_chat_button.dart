import 'package:flutter/material.dart';
import 'package:doan_cuoiki/widgets/app_page_route.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screen/AIChat.dart';

class AIChatButton extends StatefulWidget {
  final String? phoneNumber;

  const AIChatButton({super.key, this.phoneNumber});

  @override
  State<AIChatButton> createState() => _AIChatButtonState();
}

class _AIChatButtonState extends State<AIChatButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() {
      _isPressed = true;
    });

    // Hiệu ứng nhấn
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });

        // Chuyển sang trang AI Chat
        pushAppRoute(
          context,
          AIChatScreen(phoneNumber: widget.phoneNumber),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return GestureDetector(
          onTap: _onTap,
          child: Transform.scale(
            scale: _isPressed ? 0.9 : _pulseAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isPressed
                      ? [const Color(0xFF4FC3F7), const Color(0xFF29B6F6)]
                      : [
                          const Color(0xFF4FC3F7).withValues(alpha: 0.6),
                          const Color(0xFF29B6F6).withValues(alpha: 0.6),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF4FC3F7,
                    ).withValues(alpha: _glowAnimation.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Hiệu ứng mờ nền
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: _isPressed ? 0.1 : 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Icon chính
                  Center(
                    child: Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white.withValues(
                        alpha: _isPressed ? 1.0 : 0.9,
                      ),
                      size: 28,
                    ),
                  ),
                  // Hiệu ứng shimmer
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.05),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AIChatBadge extends StatelessWidget {
  final String? phoneNumber;

  const AIChatBadge({super.key, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    // HomeScreen uses extendBody:true, so we must lift this badge above the
    // bottom nav + safe area to avoid it slipping under the navbar.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 100.0; // matches FloatingCarBottomNav height
    return Positioned(
      bottom: bottomInset + navBarHeight + 12,
      right: 20,
      child: Column(
        children: [
          // Chat bubble tip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'AI Assistant',
              style: GoogleFonts.leagueSpartan(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Chat button
          AIChatButton(phoneNumber: phoneNumber),
        ],
      ),
    );
  }
}
