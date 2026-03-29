import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firebase_helper.dart';

class ChangePassScreen extends StatefulWidget {
  const ChangePassScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<ChangePassScreen> createState() => _ChangePassScreenState();
}

class _ChangePassScreenState extends State<ChangePassScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isSaving = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _underlineDecoration({
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 1.2),
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
        tooltip: isVisible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveChangePassword() async {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) {
      _showMessage('Thiếu số điện thoại để đổi mật khẩu');
      return;
    }

    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (oldPass.trim().isEmpty ||
        newPass.trim().isEmpty ||
        confirm.trim().isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (newPass != confirm) {
      _showMessage('Mật khẩu xác nhận không khớp');
      return;
    }
    if (newPass.length < 6) {
      _showMessage('Mật khẩu mới tối thiểu 6 ký tự');
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseHelper.changePassword(
        phone: phone,
        oldPassword: oldPass,
        newPassword: newPass,
      );
      if (!mounted) return;
      Navigator.pop(context, {'changedPassword': true});
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showMessage(e.message ?? 'Đổi mật khẩu thất bại');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Đổi mật khẩu thất bại');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF333333),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Thay đổi mật khẩu',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Spartan',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 22),
                    TextField(
                      controller: _oldPasswordController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      obscureText: !_showOldPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: _underlineDecoration(
                        hint: 'Mật khẩu cũ',
                        isVisible: _showOldPassword,
                        onToggle: () {
                          setState(() {
                            _showOldPassword = !_showOldPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _newPasswordController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      obscureText: !_showNewPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: _underlineDecoration(
                        hint: 'Mật khẩu mới',
                        isVisible: _showNewPassword,
                        onToggle: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _confirmPasswordController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      obscureText: !_showConfirmPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: _underlineDecoration(
                        hint: 'Xác nhận mật khẩu mới',
                        isVisible: _showConfirmPassword,
                        onToggle: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
