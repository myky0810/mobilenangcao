import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/scrollview_animation.dart';

class ForgotOtpScreen extends StatefulWidget {
  const ForgotOtpScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<ForgotOtpScreen> createState() => _ForgotOtpScreenState();
}

class _ForgotOtpScreenState extends State<ForgotOtpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  static const int _otpLength = 4;
  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;

  Timer? _timer;
  static const int _initialSeconds = 59;
  int _secondsLeft = _initialSeconds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _startTimer();

    // Focus first OTP box when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _otpFocusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _initialSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _otpValue => _otpControllers.map((e) => e.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      // If user pasted, keep last digit.
      _otpControllers[index].text = value.characters.last;
      _otpControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _otpControllers[index].text.length),
      );
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    }
  }

  KeyEventResult _onOtpKey(int index, FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].selection = TextSelection.fromPosition(
        TextPosition(offset: _otpControllers[index - 1].text.length),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleContinue() {
    if (_otpValue.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 4 số OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Prototype: sau OTP quên mật khẩu, quay về màn tạo mật khẩu hoặc màn khác tùy dự án.
      // Hiện tại đưa về tạo mật khẩu để flow khép kín.
      Navigator.pushNamed(context, '/createpass');
    });
  }

  void _handleResend() {
    if (_secondsLeft > 0) return;
    _startTimer();
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      child: Focus(
        onKeyEvent: (node, event) => _onOtpKey(index, node, event),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            counterText: '',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.2,
              ),
            ),
          ),
          onChanged: (v) => _onOtpChanged(index, v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScrollViewAnimation.children(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          children: [
            Column(
              children: [
                const SizedBox(height: 140),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nhập mã xác nhận đã gửi đến số điện thoại\n${widget.phoneNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // OTP boxes (underline)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_otpLength, _buildOtpBox),
                ),
                const SizedBox(height: 34),

                GestureDetector(
                  onTap: _handleResend,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Gửi lại mã xác nhận trong ${_formatTime(_secondsLeft)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),

                const Spacer(),

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
                const SizedBox(height: 22),

                GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Đăng nhập với mật khẩu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
