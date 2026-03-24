import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firebase_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeNavIndex = 3;
  String? _displayName;

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    final normalized = FirebaseHelper.normalizePhone(phone);
    return FirebaseFirestore.instance.collection('users').doc(normalized);
  }

  Future<void> _loadProfileDisplay() async {
    final ref = _userDocRef();
    if (ref == null) return;

    try {
      final snap = await ref.get();
      final data = snap.data();
      final name = data?['name'] as String?;
      final legacyPhoneField = data?['phone'] as String?;
      if (!mounted) return;
      setState(() {
        if (name != null && name.trim().isNotEmpty) {
          _displayName = name;
        } else if (legacyPhoneField != null &&
            legacyPhoneField.trim().isNotEmpty &&
            !_looksLikePhone(legacyPhoneField) &&
            !legacyPhoneField.contains('@')) {
          _displayName = legacyPhoneField;
        } else {
          _displayName = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayName = null;
      });
    }
  }

  bool _looksLikePhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return RegExp(r'^[0-9+\s()\-]+$').hasMatch(v);
  }

  void _showFaceIdNotSupportedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('FACE ID hiện tại đang không được hỗ trợ'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showLogoutConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xác nhận',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đăng xuất tài khoản',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: BorderSide(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Đồng ý',
                            style: TextStyle(
                              fontSize: 16,
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
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Format số điện thoại: +84987654321 -> 0987654321
  String _formatPhoneNumber(String? phone) {
    final value = (phone ?? '').trim();
    if (value.isEmpty) return '';
    if (!_looksLikePhone(value)) return value;

    if (value.startsWith('+84')) {
      return '0${value.substring(3)}';
    }
    if (value.startsWith('84')) {
      return '0${value.substring(2)}';
    }
    if (value.startsWith('0')) {
      return value;
    }
    return '0$value';
  }

  @override
  void initState() {
    super.initState();
    _displayName = null;
    _loadProfileDisplay();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    // Set status bar màu sáng trên nền xám
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF595959),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Stack(
        children: [
          Column(
            children: [
              // Phần trên màu #595959 (không có avatar)
              Container(
                width: double.infinity,
                height: topPadding + 80, // Giảm height để avatar nằm giữa
                decoration: const BoxDecoration(color: Color(0xFF595959)),
              ),
              // Phần dưới màu #333333
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF333333),
                  padding: const EdgeInsets.only(top: 70), // Space cho avatar
                  child: Column(
                    children: [
                      // Số điện thoại lớn (tên hiển thị)
                      Text(
                        (_displayName != null &&
                                _displayName!.trim().isNotEmpty)
                            ? _displayName!
                            : _formatPhoneNumber(widget.phoneNumber),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Số điện thoại nhỏ mờ
                      Text(
                        _formatPhoneNumber(widget.phoneNumber),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Menu items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // Thông tin cá nhân
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: 'Thông tin cá nhân',
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/infomation',
                                  arguments: widget.phoneNumber,
                                );
                                if (!context.mounted) return;
                                await _loadProfileDisplay();
                              },
                              showArrow: true,
                            ),
                            const Divider(
                              color: Color(0xFF4a4a4a),
                              thickness: 1,
                              height: 1,
                            ),
                            // Cho phép đăng nhập Face ID (không sử dụng)
                            _buildSwitchMenuItem(
                              icon: Icons.face_outlined,
                              title: 'Cho phép đăng nhập Face ID',
                              value: false,
                              onChanged: null,
                              enabled: false,
                              onTap: _showFaceIdNotSupportedSnackBar,
                            ),
                            const Divider(
                              color: Color(0xFF4a4a4a),
                              thickness: 1,
                              height: 1,
                            ),
                            // Thông tin ứng dụng
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              title: 'Thông tin ứng dụng',
                              onTap: () {},
                              showArrow: true,
                            ),
                            const Divider(
                              color: Color(0xFF4a4a4a),
                              thickness: 1,
                              height: 1,
                            ),
                            // Đăng xuất
                            _buildMenuItem(
                              icon: Icons.logout,
                              title: 'Đăng xuất',
                              onTap: () {
                                _showLogoutConfirmDialog();
                              },
                              showArrow: false,
                            ),
                            const Divider(
                              color: Color(0xFF4a4a4a),
                              thickness: 1,
                              height: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Avatar nằm giữa 2 màu (positioned)
          Positioned(
            top: topPadding + 30, // Vị trí nằm giữa ranh giới 2 màu
            left:
                MediaQuery.of(context).size.width / 2 -
                50, // Center horizontally
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ), // Viền trắng để nổi bật
                image: const DecorationImage(
                  image: AssetImage('assets/images/RR.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.directions_car_rounded, 1),
            _buildNavItem(Icons.favorite_rounded, 2),
            _buildNavItem(Icons.person_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });

        if (index == 0) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: widget.phoneNumber,
          );
        } else if (index == 1) {
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: widget.phoneNumber,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isActive ? 56 : 50,
        height: isActive ? 56 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(
                  colors: [const Color(0xFF3b82c8), const Color(0xFF1e5a9e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3b82c8).withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: isActive ? 28 : 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showArrow,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
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
            if (showArrow)
              const Icon(Icons.chevron_right, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String title,
    required bool value,
    ValueChanged<bool>? onChanged,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final opacity = enabled ? 1.0 : 0.35;
    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
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
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.grey[600],
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[700],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
