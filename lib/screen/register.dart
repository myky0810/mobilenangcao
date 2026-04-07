import 'package:flutter/material.dart';

import '../services/user_service.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/otp_service.dart';
import '../data/firebase_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: RR car image ──
            Image.asset('assets/images/RR.jpg', fit: BoxFit.cover),
            // Dark overlay
            Container(color: Colors.black.withValues(alpha: 0.55)),

            // ── Foreground ──
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      // ── Mercedes logo ──
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(painter: _MercedesLogoPainter()),
                      ),
                      const SizedBox(height: 20),

                      // ── WELCOME text ──
                      const Text(
                        'WELCOME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Spartan',
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // ── Subtitle ──
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Vui lòng nhập số điện thoại',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Phone number input ──
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // +84 prefix
                            const Text(
                              '+84',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Text field
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'^0'),
                                  ),
                                ],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                cursorColor: Colors.white,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Số điện thoại',
                                  hintStyle: TextStyle(
                                    color: Color(0x99ffffff),
                                    fontSize: 14,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),

                      // ── Đăng kí button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Đăng kí',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Đăng nhập ngay ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Bạn đã có tài khoản? ',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Đăng nhập ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),

                      // ── RR Badge ──
                      Container(
                        width: 110,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'RR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Spartan',
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
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

  void _handleRegister() async {
    final phoneText = _phoneController.text.trim();
    if (phoneText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }

    // Validate phone number (should be 9-10 digits)
    if (phoneText.length < 9 || phoneText.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final fullPhoneNumber = '+84$phoneText';

    try {
      // Kiểm tra số điện thoại đã tồn tại trong Firestore chưa
      final normalizedPhone = FirebaseHelper.normalizePhone(fullPhoneNumber);
      final userDoc = await FirebaseFirestore.instance
          .collection(UserService.phoneUsersCollection)
          .doc(normalizedPhone)
          .get();

      if (userDoc.exists) {
        // Số điện thoại đã được đăng ký
        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Số điện thoại này đã được đăng ký. Vui lòng đăng nhập.',
              style: TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Số điện thoại chưa tồn tại, gửi OTP
      // Gửi OTP qua Firestore (miễn phí, không cần cấu hình Firebase Phone Auth)
      final otpCode = await OTPService.sendOTP(fullPhoneNumber);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Chuyển thẳng sang trang OTP, truyền otpCode để hiện thông báo bên đó
      Navigator.pushNamed(
        context,
        '/otp',
        arguments: {'phoneNumber': fullPhoneNumber, 'otpCode': otpCode},
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Paints the Mercedes-Benz three-pointed star logo
class _MercedesLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Outer circle
    canvas.drawCircle(
      Offset(cx, cy),
      radius - strokePaint.strokeWidth / 2,
      strokePaint,
    );

    // Three spokes: top (-90°), bottom-left (30°), bottom-right (150°)
    final spokeAnglesDeg = [-90.0, 30.0, 150.0];
    final innerRadius = radius * 0.68;

    for (final deg in spokeAnglesDeg) {
      final rad = deg * 3.14159265359 / 180.0;
      final endX =
          cx +
          innerRadius *
              (rad == -90.0 * 3.14159265359 / 180.0
                  ? 0
                  : (deg == 30.0 ? 0.866 : -0.866));
      final endY =
          cy + innerRadius * (rad == -90.0 * 3.14159265359 / 180.0 ? -1 : 0.5);
      canvas.drawLine(Offset(cx, cy), Offset(endX, endY), strokePaint);
    }

    // Center dot
    canvas.drawCircle(Offset(cx, cy), size.width * 0.04, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
