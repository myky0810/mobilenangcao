import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/google_phone_registration.dart';
import '../widgets/luxury_logo.dart';

class GooglePhoneRegistrationScreen extends StatefulWidget {
  const GooglePhoneRegistrationScreen({
    super.key,
    required this.firebaseUser,
  });

  final User firebaseUser;

  @override
  State<GooglePhoneRegistrationScreen> createState() =>
      _GooglePhoneRegistrationScreenState();
}

class _GooglePhoneRegistrationScreenState
    extends State<GooglePhoneRegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  late final FocusNode _phoneFocusNode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneSubmit() async {
    if (_isLoading) return;

    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }

    // ✅ Validate: phải là 9 chữ số (định dạng Vietnam: user nhập sau +84, không cần số 0)
    // VD: nhập "374854273" → sẽ convert thành "0374854273" trong system
    if (phone.length != 9) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập 9 chữ số sau +84 (ví dụ: 374854273)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Hide keyboard
    FocusScope.of(context).unfocus();

    try {
      print('📱 Registering Google+Phone with: +84$phone');

      // Use service to register Google with phone
      final registeredPhone =
          await GooglePhoneRegistration.registerGoogleWithPhone(
        firebaseUser: widget.firebaseUser,
        phone: '+84$phone',
      );

      print('✅ Registration success: $registeredPhone');

      if (!mounted) return;

      // Navigate to home with phone
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: registeredPhone,
      );
    } on FirebaseException catch (e) {
      print('❌ Firebase error: ${e.code} - ${e.message}');
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = e.message ?? 'Lỗi: không thể lưu dữ liệu';
      if (e.code == 'phone-already-used') {
        errorMsg = 'Số điện thoại này đã được sử dụng bởi tài khoản khác';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('❌ Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset('assets/images/RR.jpg', fit: BoxFit.cover),
          // Dark overlay
          Container(color: Colors.black.withValues(alpha: 0.55)),

          // Foreground
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    // Logo
                    const LuxuryLogo(size: 110),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'NHẬP SỐ ĐIỆN THOẠI',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subtitle
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Để hoàn thành đăng kí Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Phone input
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text(
                              '+84',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              enabled: !_isLoading,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handlePhoneSubmit(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Nhập sau +84 (ví dụ: 374854273)',
                                hintStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePhoneSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Text(
                                'TIẾP TỤC',
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'QUAY LẠI',
                          style: GoogleFonts.leagueSpartan(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
