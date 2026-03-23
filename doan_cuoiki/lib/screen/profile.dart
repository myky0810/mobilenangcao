import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _allowFaceID = true;

  // Format số điện thoại: +84987654321 -> 0987654321
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '0123456789';
    if (phone.startsWith('+84')) {
      return '0${phone.substring(3)}';
    }
    if (phone.startsWith('84')) {
      return '0${phone.substring(2)}';
    }
    if (phone.startsWith('0')) {
      return phone;
    }
    return '0$phone';
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
                decoration: const BoxDecoration(
                  color: Color(0xFF595959),
                ),
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
                        _formatPhoneNumber(widget.phoneNumber),
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
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/info',
                                  arguments: widget.phoneNumber,
                                );
                              },
                              showArrow: true,
                            ),
                            const Divider(
                              color: Color(0xFF4a4a4a),
                              thickness: 1,
                              height: 1,
                            ),
                            // Cho phép đăng nhập Face ID
                            _buildSwitchMenuItem(
                              icon: Icons.face_outlined,
                              title: 'Cho phép đăng nhập Face ID',
                              value: _allowFaceID,
                              onChanged: (value) {
                                setState(() {
                                  _allowFaceID = value;
                                });
                              },
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
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (route) => false,
                                );
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
            left: MediaQuery.of(context).size.width / 2 - 50, // Center horizontally
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
                border: Border.all(color: Colors.white, width: 3), // Viền trắng để nổi bật
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
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
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
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
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
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.grey[600],
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
