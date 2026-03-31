import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/otp_service.dart';
import '../data/firebase_helper.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key});

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
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

  void _handleContinue() async {
    final phoneText = _phoneController.text.trim();
    if (phoneText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }

    // Validate phone number format
    if (!RegExp(r'^\d{9,10}$').hasMatch(phoneText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final fullPhoneNumber = '+84$phoneText';

    try {
      // Check if phone number exists in database
      final phoneExists = await FirebaseHelper.phoneExists(fullPhoneNumber);
      if (!phoneExists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại chưa được đăng ký')),
        );
        return;
      }

      // Generate and send OTP
      final otpCode = await OTPService.sendOTP(fullPhoneNumber);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Navigate to OTP screen with phone number and OTP code
      Navigator.pushNamed(
        context,
        '/otp',
        arguments: {
          'phoneNumber': fullPhoneNumber,
          'otpCode': otpCode,
          'isResetPassword':
              true, // Flag to indicate this is password reset flow
        },
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
            // Background image
            Image.asset('assets/images/RR.jpg', fit: BoxFit.cover),
            // Dark overlay
            Container(color: Colors.black.withValues(alpha: 0.55)),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Top spacing to match mock
                      const SizedBox(height: 120),

                      // Title
                      const Text(
                        'Quên mật khẩu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        'Vui lòng nhập số điện thoại',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Phone number input (+84 + underline)
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
                            const Text(
                              '+84',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                    color: Color(0x99FFFFFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleContinue,
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
                                  'Tiếp tục',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 140),

                      // RR mark at bottom
                      Opacity(
                        opacity: 0.45,
                        child: Container(
                          width: 90,
                          height: 55,
                          alignment: Alignment.center,
                          child: const Text(
                            'RR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Spartan',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
