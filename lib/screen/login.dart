import 'package:flutter/material.dart';
import '../widgets/app_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/scrollview_animation.dart';
import 'package:doan_cuoiki/widgets/supercar_logo.dart';
import 'package:doan_cuoiki/data/firebase_helper.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_phone_registration.dart';
import 'google_phone_registration_screen.dart';

class LoginEmail extends StatefulWidget {
  const LoginEmail({super.key});

  @override
  State<LoginEmail> createState() => _LoginEmailState();
}

class _LoginEmailState extends State<LoginEmail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

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

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    print('🔧 Initializing Google Sign In...');
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
    print('✅ Google Sign In initialized');
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
            // ── Background: same RR car image ──
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

                        // ── Luxury logo ──
                        const LamboLogo(size: 160),
                        const SizedBox(height: 20),

                        // ── WELCOME text ──
                        Text(
                          'WELCOME',
                          style: GoogleFonts.leagueSpartan(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 12),

                        // ── Quên mật khẩu (right-aligned) ──
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/forgotpass');
                            },
                            child: const Text(
                              'Quên mật khẩu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                decorationThickness: 1.0,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),

                        // ── Đăng nhập button ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Đăng kí ngay ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Bạn chưa có tài khoản? ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                'Đăng kí ngay',
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
                        const SizedBox(height: 60),

                        // ── Divider ──
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.3),
                                thickness: 0.8,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'hoặc',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.3),
                                thickness: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // ── Social login icons: G, Apple, F ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google
                            _SocialIconButton(
                              onTap: _isGoogleLoading
                                  ? () {}
                                  : _handleGoogleLogin,
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : _GoogleIcon(),
                            ),
                            const SizedBox(width: 50),
                            // Apple
                            _SocialIconButton(
                              onTap: () {},
                              child: const Icon(
                                Icons.apple,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 50),
                            // Facebook
                            _SocialIconButton(
                              onTap: () {},
                              child: const _FacebookIcon(),
                            ),
                          ],
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

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppSnackBar.show(context, 'Vui lòng nhập số điện thoại');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Nếu SĐT chưa đăng kí -> hiện pop-up theo đúng yêu cầu.
      final exists = await FirebaseHelper.phoneExists('+84$phone');
      if (!exists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await _showNoAccountDialog();
        return;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Chuyển sang trang loginhaspass với số điện thoại
      Navigator.pushNamed(context, '/loginhaspass', arguments: '+84$phone');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Theo yêu cầu: luôn ưu tiên hiện pop-up (không hiện thông báo Firestore).
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        await _showNoAccountDialog();
        return;
      }

      AppSnackBar.show(context, e.message ?? 'Đăng nhập thất bại');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(context, 'Đăng nhập thất bại');
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      await _ensureGoogleSignInInitialized();

      // Đăng xuất trước để hiện danh sách tài khoản
      await _googleSignIn.signOut();

      // Sign in with Google - v7.2.0 method
      print('🔐 Starting Google Sign In...');
      final googleUser = await _googleSignIn.authenticate();
      print('✅ Google user authenticated: ${googleUser.email}');

      // Get authentication details
      final googleAuth = googleUser.authentication;
      print(
        '🔑 Got authentication tokens - idToken: ${googleAuth.idToken?.substring(0, 20)}...',
      );

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      print('🎫 Created Firebase credential');

      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      print('🔥 Firebase sign in successful');
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to get user from Firebase');
      }

      final email = (user.email ?? googleUser.email).trim();
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-email',
          message: 'Không lấy được email từ tài khoản Google.',
        );
      }

      final displayName = (user.displayName ?? googleUser.displayName ?? '')
          .trim();
      final uid = user.uid.trim();

      print(
        '💾 Google authenticated: email=$email, name=$displayName, uid=$uid',
      );

      // ✅ Check if this Google account already has a phone registered
      final phoneForThisUid = await GooglePhoneRegistration.getPhoneByGoogleUid(
        uid,
      );

      if (phoneForThisUid != null) {
        // ✅ Already registered → just update lastLogin
        print('✅ Google account found with phone: $phoneForThisUid');
        await GooglePhoneRegistration.recordGoogleLogin(user);

        print('🎉 Google login successful! Navigating to home...');

        if (!mounted) return;
        setState(() => _isGoogleLoading = false);

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: phoneForThisUid,
        );
      } else {
        // ❌ First time Google login → navigate to phone registration screen
        print(
          '📱 First time Google login → navigating to phone registration screen',
        );

        if (!mounted) return;
        setState(() => _isGoogleLoading = false);

        // Navigate to phone registration screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GooglePhoneRegistrationScreen(firebaseUser: user),
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      print('❌ Google Sign In Exception: ${e.code} - ${e.description}');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }

      AppSnackBar.show(
        context,
        'Đăng nhập Google thất bại: ${e.description ?? e.code.name}',
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      AppSnackBar.show(
        context,
        e.message ?? 'Đăng nhập Google thất bại',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } catch (e, stackTrace) {
      print('❌ Unexpected error during Google Sign In: $e');
      print('📍 Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      AppSnackBar.show(
        context,
        'Đăng nhập Google thất bại: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _showNoAccountDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: const Center(
            child: Text(
              'Xác nhận',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          content: const Text(
            'Bạn chưa có tài khoản\nVui lòng đăng kí',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.pushNamed(context, '/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Đồng ý',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Social button wrapper ──
class _SocialIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _SocialIconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

// ── Google coloured "G" icon ──
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

// ── Facebook "f" icon ──
class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'f',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
