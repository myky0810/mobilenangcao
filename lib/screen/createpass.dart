import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firebase_helper.dart';

class CreatePassScreen extends StatefulWidget {
  const CreatePassScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<CreatePassScreen> createState() => _CreatePassScreenState();
}

class _CreatePassScreenState extends State<CreatePassScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Validation states
  bool _hasMinLength = false;
  bool _hasUpperAndLower = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      // Kiểm tra độ dài từ 8 đến 15 ký tự
      _hasMinLength = password.length >= 8 && password.length <= 15;

      // Kiểm tra có chữ hoa VÀ chữ thường VÀ chữ số
      _hasUpperAndLower =
          password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[0-9]'));

      // Kiểm tra có ít nhất 1 ký tự đặc biệt
      _hasSpecialChar = password.contains(RegExp(r'[@#$%^&*(),.?":{}|<>!]'));
    });
  }

  Future<void> _handleCreatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showModernSnackBar(
        icon: Icons.warning_amber_rounded,
        message: 'Vui lòng nhập đầy đủ thông tin',
        color: Colors.orange,
      );
      return;
    }

    if (!_hasMinLength || !_hasUpperAndLower || !_hasSpecialChar) {
      _showModernSnackBar(
        icon: Icons.warning_amber_rounded,
        message: 'Mật khẩu chưa đáp ứng đầy đủ yêu cầu',
        color: Colors.orange,
      );
      return;
    }

    if (password != confirmPassword) {
      _showModernSnackBar(
        icon: Icons.error_rounded,
        message: 'Mật khẩu xác nhận không khớp',
        color: Colors.redAccent,
      );
      return;
    }

    if (widget.phoneNumber == null || widget.phoneNumber!.trim().isEmpty) {
      _showModernSnackBar(
        icon: Icons.error_rounded,
        message: 'Thiếu số điện thoại. Vui lòng đăng kí lại',
        color: Colors.redAccent,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseHelper.register(
        phone: widget.phoneNumber!,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Hiển thị thông báo thành công
      _showModernSnackBar(
        icon: Icons.check_circle_rounded,
        message: 'Tạo tài khoản thành công!',
        color: Colors.green,
      );

      // Sau khi hiện thông báo thì quay về trang đăng nhập
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/loginhaspass',
          (route) => false,
          arguments: widget.phoneNumber,
        );
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showModernSnackBar(
        icon: Icons.error_rounded,
        message: e.message ?? 'Đăng kí thất bại',
        color: Colors.redAccent,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showModernSnackBar(
        icon: Icons.error_rounded,
        message: 'Đăng kí thất bại',
        color: Colors.redAccent,
      );
    }
  }

  /// Hiển thị thông báo hiện đại với bo tròn, icon, nền gradient
  void _showModernSnackBar({
    required IconData icon,
    required String message,
    required Color color,
    int durationSeconds = 3,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: Duration(seconds: durationSeconds),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Title ──
                const Center(
                  child: Text(
                    'Tạo mật khẩu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // ── Password input ──
                Container(
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
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            hintText: 'Nhập mật khẩu',
                            hintStyle: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ── Confirm password input ──
                Container(
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
                      Expanded(
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          cursorColor: Colors.white,
                          decoration: const InputDecoration(
                            hintText: 'Xác nhận mật khẩu',
                            hintStyle: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Password requirements ──
                _buildRequirement(
                  'Mật khẩu phải từ 8 đến 15 kí tự',
                  _hasMinLength,
                ),
                const SizedBox(height: 12),
                _buildRequirement(
                  'Bao gồm chữ số chữ viết hoa, chữ viết thường',
                  _hasUpperAndLower,
                ),
                const SizedBox(height: 12),
                _buildRequirement(
                  'Bao gồm ít nhất có một kí tự đặc biệt(@,#,...)',
                  _hasSpecialChar,
                ),
                const SizedBox(height: 80),

                // ── Cập nhật button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreatePassword,
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
                            'Cập nhật',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check,
          color: isValid
              ? const Color(0xFF4A90E2)
              : Colors.white.withValues(alpha: 0.4),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isValid
                  ? const Color(0xFF4A90E2)
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
