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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    if (!_hasMinLength || !_hasUpperAndLower || !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu chưa đáp ứng đầy đủ yêu cầu')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    if (widget.phoneNumber == null || widget.phoneNumber!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiếu số điện thoại. Vui lòng đăng kí lại'),
        ),
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

      // Hiển thị thông báo nhỏ bo tròn (như hình bạn gửi)
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            elevation: 0,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.fromLTRB(80, 0, 80, 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            content: const Center(
              heightFactor: 1,
              child: Text(
                'Tạo tài khoản thành công',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Đăng kí thất bại')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng kí thất bại')));
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
