import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      }
    });
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handleVerify() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 4) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isLoading = false);
          // Navigate to CreatePass screen with smooth animation
          Navigator.pushNamed(
            context,
            '/createpass',
            arguments: widget.phoneNumber,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ mã OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'OTP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── Title text ──
              Text(
                'Nhập mã xác nhận đã gửi đến số điện thoại',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              // ── Phone number ──
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // ── OTP Input Fields ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 60,
                    height: 60,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2.5,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => _onChanged(value, index),
                      onTap: () {
                        if (_controllers[index].text.isNotEmpty) {
                          _controllers[index].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _controllers[index].text.length,
                          );
                        }
                      },
                      onEditingComplete: () {
                        if (index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),

              // ── Resend code text ──
              Center(
                child: Text(
                  _countdown > 0
                      ? 'Gửi lại mã xác nhận trong ${_countdown.toString().padLeft(2, '0')}:00'
                      : 'Gửi lại mã xác nhận',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const Spacer(),

              // ── Tiếp tục button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
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
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Đăng nhập ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        decorationThickness: 1.0,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
