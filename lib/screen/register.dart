import 'package:flutter/material.dart';
import '../widgets/app_snackbar.dart';

import '../widgets/scrollview_animation.dart';
import 'package:doan_cuoiki/widgets/supercar_logo.dart';

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
  final FocusNode _phoneFocusNode = FocusNode();
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
    _phoneFocusNode.dispose();
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
              child: ScrollViewAnimation.children(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),

                        // ── Supercar logo ──
                        const LamboLogo(size: 160),
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
                                  focusNode: _phoneFocusNode,
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
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
                ],
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
      AppSnackBar.show(context, 'Vui lòng nhập số điện thoại');
      return;
    }

    // Validate phone number (should be 9-10 digits)
    if (phoneText.length < 9 || phoneText.length > 10) {
      AppSnackBar.show(context, 'Số điện thoại không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    final fullPhoneNumber = '+84$phoneText';

    try {
      // Kiểm tra số điện thoại đã tồn tại trong Firestore chưa
      final normalizedPhone = FirebaseHelper.normalizePhone(fullPhoneNumber);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(normalizedPhone)
          .get();

      if (userDoc.exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppSnackBar.show(
          context,
          'Số điện thoại này đã được đăng ký. Vui lòng đăng nhập.',
          backgroundColor: Colors.white,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      // Số điện thoại chưa tồn tại, gửi OTP
      final otpCode = await OTPService.sendOTP(fullPhoneNumber);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushNamed(
        context,
        '/otp',
        arguments: {'phoneNumber': fullPhoneNumber, 'otpCode': otpCode},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(
        context,
        'Lỗi: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
