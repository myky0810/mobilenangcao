import 'package:flutter/material.dart';
import '../widgets/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/otp_service.dart';
import '../widgets/scrollview_animation.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _countdown = 60;
  bool _showOtpNotification = false;
  String _currentOtpCode = '';
  bool _isResetPassword = false;

  late AnimationController _notificationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Animation controller cho notification
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: _notificationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Lấy otpCode từ arguments và hiện thông báo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['otpCode'] != null) {
        setState(() {
          _currentOtpCode = args['otpCode'] as String;
          _showOtpNotification = true;
          _isResetPassword = args['isResetPassword'] == true;
        });
        _notificationController.forward();
        // Tự động ẩn thông báo sau 5 giây
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _hideNotification();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _hideNotification() {
    if (_showOtpNotification) {
      _notificationController.reverse().then((_) {
        if (mounted) {
          setState(() => _showOtpNotification = false);
        }
      });
    }
  }

  void _startCountdown() {
    _countdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
        });
        return _countdown > 0;
      }
      return false;
    });
  }

  void _verifyOTP() async {
    String otp = _controllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showModernSnackBar(
        icon: Icons.warning_amber_rounded,
        message: 'Vui lòng nhập đầy đủ mã OTP (6 số)',
        color: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = await OTPService.verifyOTP(
        phoneNumber: widget.phoneNumber,
        otpCode: otp,
      );

      if (isValid && mounted) {
        setState(() => _isLoading = false);

        _showModernSnackBar(
          icon: Icons.check_circle_rounded,
          message: 'Xác thực thành công!',
          color: Colors.green,
        );

        Navigator.pushNamed(
          context,
          '/createpass',
          arguments: {
            'phoneNumber': widget.phoneNumber,
            'isResetPassword': _isResetPassword,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        _showModernSnackBar(
          icon: Icons.error_rounded,
          message: e.toString().replaceAll('Exception: ', ''),
          color: Colors.redAccent,
        );

        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  void _resendOTP() async {
    setState(() => _isLoading = true);

    try {
      final newOtpCode = await OTPService.resendOTP(widget.phoneNumber);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentOtpCode = newOtpCode;
          _showOtpNotification = true;
        });

        // Clear OTP fields cũ
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();

        // Reset countdown
        _startCountdown();

        // Show notification with animation
        _notificationController.forward();
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _hideNotification();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showModernSnackBar(
          icon: Icons.error_rounded,
          message: 'Có lỗi xảy ra: ${e.toString()}',
          color: Colors.redAccent,
        );
      }
    }
  }

  /// Hiển thị thông báo hiện đại với bo tròn, icon, nền gradient
  void _showModernSnackBar({
    required IconData icon,
    required String message,
    required Color color,
    int durationSeconds = 3,
  }) {
    AppSnackBar.showModern(
      context,
      icon: icon,
      message: message,
      color: color,
      durationSeconds: durationSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background giống HomeScreen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
            ),
          ),

          SafeArea(
            child: ScrollViewAnimation.children(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Column(
                  children: [
                    const SizedBox(height: 80),

                    // Success icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title với font Spartan
                    Text(
                      'Xác thực số điện thoại',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle với font Spartan
                    Text(
                      'Vui lòng nhập mã OTP gồm 6 chữ số đã được\ngửi đến số điện thoại của bạn',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // OTP input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => _buildOtpBox(index)),
                    ),

                    const SizedBox(height: 30),

                    // Countdown text (bỏ dấu chấm)
                    if (_countdown > 0)
                    Text(
                      'Xác thực số điện thoại',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle với font Spartan
                    Text(
                      'Vui lòng nhập mã OTP gồm 6 chữ số đã được\ngửi đến số điện thoại của bạn',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // OTP input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => _buildOtpBox(index),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Countdown text (bỏ dấu chấm)
                    if (_countdown > 0)
                      Text(
                        'Mã OTP sẽ hết hạn trong ${_countdown.toString().padLeft(2, '0')}:${(0).toString().padLeft(2, '0')}',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Verify button (black text)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: const Color(
                            0xFF4A90E2,
                          ).withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'Xác thực',
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Resend OTP text (always clickable)
                    GestureDetector(
                      onTap: _resendOTP,
                      child: Text.rich(
                        TextSpan(
                          text: 'Bạn không nhận được mã?\n',
                          style: GoogleFonts.leagueSpartan(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: 'GỬI LẠI MÃ OTP',
                              style: GoogleFonts.leagueSpartan(
                                color: const Color(0xFF4A90E2),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF4A90E2),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),

          // Notification từ trên xuống với SlideTransition
          if (_showOtpNotification)
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSnackBar.radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mã OTP đã được gửi',
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Mã xác thực: $_currentOtpCode',
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _hideNotification,
                      child: const Icon(
                        Icons.close,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSnackBar.radius),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? const Color(0xFF4A90E2)
              : Colors.white.withValues(alpha: 0.2),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].selection = TextSelection.fromPosition(
              TextPosition(offset: _controllers[index - 1].text.length),
            );
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.leagueSpartan(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          cursorColor: const Color(0xFF4A90E2),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.length == 1) {
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else {
                _focusNodes[index].unfocus();
              }
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
