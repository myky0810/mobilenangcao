import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  int _countdown = 60;
  bool _canResend = false;

  String? _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Get arguments passed from register screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        setState(() {
          _verificationId = args['verificationId'] as String?;
          _resendToken = args['resendToken'] as int?;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
          _canResend = _countdown <= 0;
        });
        return _countdown > 0;
      }
      return false;
    });
  }

  void _verifyOTP() async {
    String otp = _controllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ mã OTP (6 số)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Firebase OTP verification
    if (otp.length == 6 && _verificationId != null) {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.user != null && mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Xác thực thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          Navigator.pushNamed(
            context,
            '/createpass',
            arguments: widget.phoneNumber,
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

          String errorMessage = 'Mã OTP không đúng';
          if (e.code == 'invalid-verification-code') {
            errorMessage = 'Mã OTP không đúng. Vui lòng thử lại';
          } else if (e.code == 'session-expired') {
            errorMessage = 'Mã OTP đã hết hạn. Vui lòng gửi lại mã';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $errorMessage'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );

          // Clear OTP fields
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Có lỗi xảy ra: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập đủ 6 số mã OTP hoặc kiểm tra kết nối Firebase.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resendOTP() async {
    if (_countdown > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đợi $_countdown giây để gửi lại')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification (doesn't usually happen on most devices)
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gửi lại mã thất bại: ${e.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isLoading = false;
              _countdown = 60;
              _canResend = false;
            });
            _startCountdown();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã gửi lại mã OTP'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-resolution timed out
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 32, 47),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xác thực OTP',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Logo or Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, size: 40, color: Colors.orange),
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'Xác thực số điện thoại',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Chúng tôi đã gửi mã xác thực 6 số đến\n${widget.phoneNumber}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // OTP Input Fields - 6 individual boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return Container(
                  width: 50,
                  height: 55,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 28, 42, 58),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _focusNodes[index].hasFocus
                          ? Colors.orange
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }

                      // Auto verify when all 6 digits are entered
                      if (index == 5 && value.isNotEmpty) {
                        String fullOtp = _controllers.map((c) => c.text).join();
                        if (fullOtp.length == 6) {
                          _verifyOTP();
                        }
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Xác thực',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Không nhận được mã? ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: _canResend ? _resendOTP : null,
                  child: Text(
                    _canResend ? 'Gửi lại' : 'Gửi lại ($_countdown)',
                    style: TextStyle(
                      color: _canResend ? Colors.orange : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Firebase status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _verificationId != null
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _verificationId != null
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _verificationId != null
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _verificationId != null ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _verificationId != null
                        ? 'Firebase đã kết nối thành công!\nMã OTP đã được gửi.'
                        : 'Chưa nhận được verification ID từ Firebase.\nVui lòng kiểm tra cấu hình Firebase.',
                    style: TextStyle(
                      color: _verificationId != null
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
