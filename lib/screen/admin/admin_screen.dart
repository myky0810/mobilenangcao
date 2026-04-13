import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'admin_dashboard.dart';
import 'admin_users.dart';
import 'admin_products.dart';
import 'admin_brands.dart';
import 'admin_deposits.dart';
import 'admin_bookings.dart';
import 'admin_live_chat.dart';
import 'admin_notifications.dart';
import 'admin_banners.dart';
import 'admin_warranties.dart';
import 'admin_migration_logs_screen.dart';
import '../../services/admin_migration_service.dart';

class AdminScreen extends StatefulWidget {
  final String? phoneNumber;
  const AdminScreen({super.key, this.phoneNumber});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final List<int> _navigationStack = [0];
  UserModel? _adminUser;
  bool _isLoading = true;
  int _unreadChats = 0;
  bool _isMigratingAll = false;

  static const Color _bg = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF00A8FF);

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
    _listenToUnreadChats();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final phoneNumber = widget.phoneNumber;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final userModel = await UserService.get(phoneNumber);
      if (mounted) {
        setState(() {
          _adminUser = userModel;
          _isLoading = false;
        });
      }

      if (userModel == null || !userModel.isAdmin()) {
        if (mounted) {
          // Nếu không phải admin, có thể show dialog hoặc pop màn hình, KHÔNG tự push về HomeScreen ở đây!
          // Navigator.pushReplacementNamed(context, '/home', arguments: widget.phoneNumber);
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _listenToUnreadChats() {
    FirebaseFirestore.instance
        .collection('admin_notifications')
        .where('status', isEqualTo: 'pending')
        .count()
        .get()
        .then((value) {
          if (mounted) {
            setState(() => _unreadChats = value.count ?? 0);
          }
        });
  }

  void _logout() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
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
                          Navigator.pop(dialogContext);
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
                          FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(dialogContext, '/');
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
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboard(
          phoneNumber: widget.phoneNumber,
          adminUser: _adminUser,
        );
      case 1:
        return const AdminUsersScreen();
      case 2:
        return _buildAdminProfile();
      case 3:
        return const AdminProductsScreen();
      case 4:
        return const AdminBrandsScreen();
      case 5:
        return const AdminDepositsScreen();
      case 6:
        return const AdminBookingsScreen();
      case 7:
        return const AdminWarrantiesScreen();
      case 8:
        return const AdminNotificationsScreen();
      case 9:
        return AdminLiveChatScreen(adminPhone: widget.phoneNumber);
      case 10:
        return const AdminBannersScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAdminProfile() {
    final topPadding = MediaQuery.of(context).padding.top;
    const bgColor = Color(0xFF1E2A47);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgColor, bgColor, bgColor],
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: topPadding + 80),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(
                    children: [
                      Text(
                        _adminUser?.name ?? 'Administrator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _adminUser?.phone ?? 'N/A',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildAdminMenuItem(
                              icon: Icons.person_outline,
                              title: 'Thông tin cá nhân',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/infomation',
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
                            _buildAdminMenuItem(
                              icon: Icons.info_outline,
                              title: 'Thông tin ứng dụng',
                              onTap: () {
                                Navigator.pushNamed(context, '/appinfo');
                              },
                              showArrow: true,
                            ),
                            const Divider(
                              color: Color(0xFF4a4a4a),
                              thickness: 1,
                              height: 1,
                            ),
                            _buildAdminMenuItem(
                              icon: Icons.history_rounded,
                              title: 'Xem logs cập nhật',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminMigrationLogsScreen(),
                                  ),
                                );
                              },
                              showArrow: true,
                            ),
                            const Divider(
                              color: Color(0xFF4a4a4a),
                              thickness: 1,
                              height: 1,
                            ),
                            _buildAdminMenuItem(
                              icon: Icons.logout,
                              title: 'Đăng xuất',
                              onTap: _logout,
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
          Positioned(
            top: topPadding + 30,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: DecorationImage(
                  image: _adminUser?.avatarUrl != null && _adminUser!.avatarUrl!.isNotEmpty
                      ? NetworkImage(_adminUser!.avatarUrl!)
                      : const AssetImage('assets/images/RR.jpg') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuItem({
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

  void _showMoreOptions() {
    showModalBottomSheet<int>(
      context: context,
      backgroundColor: _card,
      barrierColor: Colors.black38,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return MoreOptionsModal(
          backgroundColor: _card,
          accentColor: _accent,
        );
      },
    ).then((selectedIndex) {
      if (selectedIndex != null && mounted && _selectedIndex != selectedIndex) {
        _navigationStack.add(selectedIndex);
        setState(() => _selectedIndex = selectedIndex);
      }
    });
  }

  Future<void> _runMigrateAll() async {
    if (_isMigratingAll) {
      return;
    }

    final shouldRun = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Chạy chuẩn hóa toàn bộ?'),
            content: const Text(
              'Hệ thống sẽ quét và chuẩn hóa tất cả collection quản lý. Tiếp tục?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Chạy ngay'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRun || !mounted) {
      return;
    }

    setState(() => _isMigratingAll = true);
    try {
      final result = await AdminMigrationService.migrateAllCollections(
        triggeredByPhone: widget.phoneNumber,
        triggeredByUid: FirebaseAuth.instance.currentUser?.uid,
      );

      if (!mounted) {
        return;
      }

      final scanned = result['scanned'] ?? 0;
      final updated = result['updated'] ?? 0;
      final failedCollections = result['failedCollections'] ?? 0;

      final message = failedCollections == 0
          ? 'Chuẩn hóa toàn bộ xong: quét $scanned, cập nhật $updated.'
          : 'Chuẩn hóa toàn bộ xong: quét $scanned, cập nhật $updated, lỗi $failedCollections collection.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chuẩn hóa toàn bộ thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMigratingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    return PopScope(
      canPop: _navigationStack.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _navigationStack.length > 1) {
          _navigationStack.removeLast();
          setState(() => _selectedIndex = _navigationStack.last);
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: _selectedIndex == 0
            ? AppBar(
                backgroundColor: _bg,
                elevation: 0,
                toolbarHeight: 80,
                title: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                        image: DecorationImage(
                          image: _adminUser?.avatarUrl != null && _adminUser!.avatarUrl!.isNotEmpty
                              ? NetworkImage(_adminUser!.avatarUrl!)
                              : const AssetImage('assets/images/RR.jpg') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Xin chào,',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _adminUser?.name ?? 'Administrator',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed: _isMigratingAll ? null : _runMigrateAll,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isMigratingAll
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 16),
                      label: Text(
                        _isMigratingAll
                            ? 'Đang chuẩn hóa...'
                            : 'Chuẩn hóa toàn bộ',
                      ),
                    ),
                  ),
                ],
              )
            : null,
        body: _buildContent(),
        bottomNavigationBar: _buildFloatingBottomNav(),
      ),
    );
  }

  Widget _buildFloatingBottomNav() {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navItem(0, Icons.home_rounded, 'Dashboard'),
                    _navItem(1, Icons.people_rounded, 'Users'),
                    const SizedBox(width: 64),
                    _navItem(9, Icons.chat_rounded, 'Chat',
                        showBadge: _unreadChats > 0,
                        badgeCount: _unreadChats),
                    _navItem(2, Icons.person_rounded, 'Profile'),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 34,
              child: GestureDetector(
                onTap: _showMoreOptions,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label,
      {bool showBadge = false, int badgeCount = 0}) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          _navigationStack.add(index);
          setState(() => _selectedIndex = index);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white10 : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: isActive ? _accent : Colors.white54,
              size: 24,
            ),
          ),
          if (showBadge && badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Separate StatelessWidget for modal - avoid context conflicts
class MoreOptionsModal extends StatelessWidget {
  final Color backgroundColor;
  final Color accentColor;

  const MoreOptionsModal({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (sheetContext, scrollController) => Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Quản Lý Khác',
              style: GoogleFonts.leagueSpartan(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.count(
                controller: scrollController,
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  MoreOptionItem(
                    icon: Icons.local_car_wash_rounded,
                    label: 'Xe',
                    index: 3,
                    accentColor: accentColor,
                  ),
                  MoreOptionItem(
                    icon: Icons.local_offer_rounded,
                    label: 'Hãng xe',
                    index: 4,
                    accentColor: accentColor,
                  ),
                  MoreOptionItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Đặt Cọc',
                    index: 5,
                    accentColor: accentColor,
                  ),
                  MoreOptionItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Đặt Lịch',
                    index: 6,
                    accentColor: accentColor,
                  ),
                  MoreOptionItem(
                    icon: Icons.shield_rounded,
                    label: 'Bảo Hành',
                    index: 7,
                    accentColor: accentColor,
                  ),
                  MoreOptionItem(
                    icon: Icons.notifications_rounded,
                    label: 'Thông Báo',
                    index: 8,
                    accentColor: accentColor,
                  ),
                  MoreOptionItem(
                    icon: Icons.image_rounded,
                    label: 'Banner',
                    index: 10,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Separate StatelessWidget for each option item
class MoreOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final Color accentColor;

  const MoreOptionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.index,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, index); // chỉ trả về index
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.leagueSpartan(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
