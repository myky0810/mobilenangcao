import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/firebase_helper.dart';

class InfomationScreen extends StatelessWidget {
  const InfomationScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    void showSavedSnackBar() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lưu thành công'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    void showPasswordChangedSnackBar() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đổi mật khẩu thành công'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Future<void> showDeleteAccountDialog() async {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          bool isDeleting = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 44,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Thông báo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Spartan',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sau khi xóa sẽ không xóa tài\nkhoản. Bạn sẽ không thể đăng\nnhập vào ứng dụng để sử dụng\ndịch vụ các chức năng. Hành\nđộng sẽ không hoàn tác được',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.65),
                            fontFamily: 'Spartan',
                            fontSize: 12.5,
                            height: 1.25,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: isDeleting
                                      ? null
                                      : () {
                                          Navigator.pop(dialogContext);
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: BorderSide(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text(
                                    'Hủy',
                                    style: TextStyle(
                                      fontFamily: 'Spartan',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: isDeleting
                                      ? null
                                      : () async {
                                          final phone = phoneNumber;
                                          if (phone == null ||
                                              phone.trim().isEmpty) {
                                            Navigator.pop(dialogContext);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Thiếu số điện thoại để xóa tài khoản',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          setDialogState(() {
                                            isDeleting = true;
                                          });

                                          try {
                                            await FirebaseHelper.deleteAccount(
                                              phone: phone,
                                            );
                                            if (!context.mounted) return;
                                            Navigator.pop(dialogContext);
                                            Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              '/login',
                                              (route) => false,
                                            );
                                          } catch (_) {
                                            setDialogState(() {
                                              isDeleting = false;
                                            });
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Xóa tài khoản thất bại',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text(
                                    'Xóa tài khoản',
                                    style: TextStyle(
                                      fontFamily: 'Spartan',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

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
                        'Thông tin cá nhân',
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
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFF4a4a4a),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.person_outline,
                    title: 'Thay đổi thông tin cá nhân',
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/info',
                        arguments: phoneNumber,
                      );
                      if (!context.mounted) return;
                      if (result is Map && result['saved'] == true) {
                        showSavedSnackBar();
                      }
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFF4a4a4a),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.lock_outline,
                    title: 'Thay đổi mật khẩu',
                    onTap: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/changepass',
                        arguments: phoneNumber,
                      );

                      if (!context.mounted) return;
                      if (result is Map && result['changedPassword'] == true) {
                        showPasswordChangedSnackBar();
                      }
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFF4a4a4a),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.delete_outline,
                    title: 'Xóa tài khoản',
                    onTap: showDeleteAccountDialog,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFF4a4a4a),
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
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
