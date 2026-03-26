import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Development mode: true = không dùng Firebase, false = dùng Firebase thật
  static const bool kUseDevelopmentMode = false;

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

    // Development Mode: Fake OTP để test nhanh
    if (kUseDevelopmentMode) {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isLoading = false);

        // Navigate to OTP screen with fake data
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {
            'phoneNumber': fullPhoneNumber,
            'verificationId': 'dev_mode_verification_id',
            'resendToken': null,
            'isDevelopmentMode': true,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 DEV MODE: Mã OTP test là "123456"'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Production Mode: Firebase thật
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Xác thực tự động thành công')),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            String errorMessage = 'Firebase chưa được cấu hình đúng';

            if (e.code == 'invalid-phone-number') {
              errorMessage = 'Số điện thoại không hợp lệ';
            } else if (e.code == 'too-many-requests') {
              errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
            } else if (e.code == 'quota-exceeded') {
              errorMessage = 'Đã vượt quá giới hạn gửi SMS';
            } else if (e.code == 'app-not-authorized') {
              errorMessage = 'App chưa được authorize. Cần cấu hình Firebase';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          // SMS code has been sent
          if (mounted) {
            setState(() => _isLoading = false);

            Navigator.pushNamed(
              context,
              '/otp',
              arguments: {
                'phoneNumber': fullPhoneNumber,
                'verificationId': verificationId,
                'resendToken': resendToken,
              },
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mã OTP đã được gửi đến số điện thoại của bạn'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout: $verificationId');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Firebase lỗi: ${e.toString()}\n💡 Chuyển sang DEV MODE',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
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
