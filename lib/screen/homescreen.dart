import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:doan_cuoiki/widgets/floating_car_bottom_nav.dart';

import '../data/cars_data.dart';
import '../widgets/notification_icon.dart';
import '../widgets/ai_chat_button.dart';
import '../widgets/car_card.dart';

import 'banner_offer_screen.dart';
import '../services/banner_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.phoneNumber});
  final String? phoneNumber;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with RouteAware, TickerProviderStateMixin {
  // Background is the original dark theme.

  // Match `InfomationScreen` background.
  static const List<Color> _showroomGradient = [
    Color(0xFF545454),
    Color(0xFF3A3A3A),
    Color(0xFF252525),
    Color(0xFF171717),
  ];

  // Match `EliteMembersScreen` background direction + stops.
  static const LinearGradient _showroomBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _showroomGradient,
    stops: [0.0, 0.35, 0.75, 1.0],
  );

  final BannerService _bannerService = BannerService();
  bool _bannerSeeded = false;

  // Prevent booking success notification from showing multiple times.
  bool _hasShownNotification = false;

  // Brands grid state.
  int _selectedBrandIndex = 0;
  late final List<CarBrand> _brands = <CarBrand>[
    CarBrand(name: 'BMW', assetPath: 'assets/images/icons8-bmw-48.png'),
    CarBrand(
      name: 'Mercedes',
      assetPath: 'assets/images/icons8-mercedes-benz-48.png',
    ),
    CarBrand(name: 'Mazda', assetPath: 'assets/images/icons8-mazda-48.png'),
    CarBrand(name: 'Hyundai', assetPath: 'assets/images/icons8-hyundai-48.png'),
    CarBrand(name: 'Tesla', assetPath: 'assets/images/icons8-tesla-48.png'),
    CarBrand(name: 'Toyota', assetPath: 'assets/images/icons8-toyota-48.png'),
    CarBrand(name: 'Volvo', assetPath: 'assets/images/icons8-volvo-100.png'),
    CarBrand(name: 'More', icon: Icons.more_horiz_rounded),
  ];

  // Banner/animation state (used by the modern banner section).
  int _currentBannerIndex = 0;
  late final List<BannerData> _banners = _bannerData;
  late AnimationController _bannerAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static final List<BannerOfferData> _offers = [
    const BannerOfferData(
      badge: 'ƯU ĐÃI ĐẶC BIỆT',
      title: 'Car Expo 2026',
      subtitle: 'Ưu đãi giới hạn cho khách hàng mới',
      image:
          'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      accentColor: Color(0xFF55A7FF),
      description:
          'Tham gia sự kiện Car Expo 2026 để nhận ưu đãi thuê xe sang với mức giá tốt nhất. Áp dụng cho số lượng giới hạn trong thời gian diễn ra chương trình.',
      benefits: [
        'Giảm giá lên đến 20% cho lần thuê đầu tiên',
        'Tặng gói nâng cấp nội thất miễn phí',
        'Ưu tiên hỗ trợ 24/7',
      ],
    ),
    const BannerOfferData(
      badge: 'XE ĐIỆN 2026',
      title: 'Green Revolution',
      subtitle: 'Trải nghiệm xe điện - phí sạc ưu đãi',
      image: 'assets/images/products/Tesla-Model-S-2020-1600-02.jpg',
      gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
      accentColor: Color(0xFF10B981),
      description:
          'Trải nghiệm dàn xe điện mới nhất với gói ưu đãi đặc biệt. Tiết kiệm chi phí vận hành và tận hưởng công nghệ hiện đại.',
      benefits: [
        'Ưu đãi phí sạc tại đối tác',
        'Miễn phí kiểm tra xe trước chuyến đi',
        'Hỗ trợ kỹ thuật nhanh',
      ],
    ),
    const BannerOfferData(
      badge: 'TRẢI NGHIỆM HẠNG SANG',
      title: 'Ultimate Luxury',
      subtitle: 'Gói Premium cho khách hàng thân thiết',
      image: 'assets/images/products/Mercedes-Benz-S-Class-2021-1600-01.jpg',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      accentColor: Color(0xFF8B5CF6),
      description:
          'Gói Premium mang đến trải nghiệm thuê xe cao cấp với quyền lợi ưu tiên, dịch vụ nhanh chóng và nhiều quà tặng hấp dẫn.',
      benefits: [
        'Ưu tiên đặt xe giờ cao điểm',
        'Tặng 1 lần nâng hạng xe miễn phí/tháng',
        'Ưu đãi dịch vụ đưa đón',
      ],
    ),
    const BannerOfferData(
      badge: 'DÀNH CHO SUV',
      title: 'Adventure Ready',
      subtitle: 'Sẵn sàng cho mọi hành trình',
      image: 'assets/images/products/Range-Rover-2022-1600-01.jpg',
      gradientColors: [Color(0xFFEA580C), Color(0xFFF97316)],
      accentColor: Color(0xFFEA580C),
      description:
          'Khám phá các mẫu SUV mạnh mẽ với gói ưu đãi dành riêng cho hành trình xa. Trang bị thêm tiện ích để chuyến đi trọn vẹn.',
      benefits: [
        'Tặng gói bảo hiểm mở rộng',
        'Miễn phí trang bị bộ cứu hộ tiêu chuẩn',
        'Giảm giá khi thuê dài ngày',
      ],
    ),
  ];
  static final List<BannerData> _bannerData = [
    BannerData(
      badge: '🚗 CAR EXPO 2026',
      title: 'Future\nDriving',
      subtitle: 'AI-Powered Smart Cars',
      buttonText: 'Khám phá ngay',
      gradientColors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF21262D)],
      accentColor: Color(0xFF3b82f6),
      subtitleColor: Color(0xFF10b981),
    ),
  ];

  bool _looksLikePhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return RegExp(r'^[0-9+\s()\-]+$').hasMatch(v);
  }

  String _displayNameFromData(Map<String, dynamic>? data) {
    print('');
    print('👤 [HOME] _displayNameFromData called');
    print('   Data: $data');

    final name = (data?['name'] as String?)?.trim();
    print('   name field: "$name"');

    if (name != null && name.isNotEmpty) {
      print('   ✅ Returning name: "$name"');
      return name;
    }

    final legacyPhoneField = (data?['phone'] as String?)?.trim();
    if (legacyPhoneField != null &&
        legacyPhoneField.isNotEmpty &&
        !_looksLikePhone(legacyPhoneField) &&
        !legacyPhoneField.contains('@')) {
      print('   ⚠️ Returning legacy phone field: "$legacyPhoneField"');
      return legacyPhoneField;
    }

    print('   ❌ No name found - returning default');
    return 'Người dùng';
  }

  @override
  void initState() {
    super.initState();

    _ensureBannersSeeded();

    // Khởi tạo animation controllers
    _bannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _bannerAnimationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bannerAnimationController.forward();
    _slideAnimationController.forward();
    _startBannerTimer();
  }

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final phone = widget.phoneNumber?.trim();
    if (phone == null || phone.isEmpty) return null;
    return FirebaseFirestore.instance.collection('users').doc(phone);
  }

  void _ensureBannersSeeded() {
    if (_bannerSeeded) return;
    _bannerSeeded = true;
    // Current implementation seeds from the static fallback list.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Kiểm tra nếu có arguments từ booking
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> &&
        args['showBookingNotification'] == true &&
        !_hasShownNotification) {
      _hasShownNotification = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBookingSuccessNotification();
      });
    }
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
        });

        // Restart animations
        _bannerAnimationController.reset();
        _slideAnimationController.reset();
        _bannerAnimationController.forward();
        _slideAnimationController.forward();

        // Continue timer
        _startBannerTimer();
      }
    });
  }

  @override
  void dispose() {
    _bannerAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  // Hiển thị notification từ trên xuống như tin nhắn điện thoại
  void _showBookingSuccessNotification() {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _BookingNotificationWidget(
        onDismiss: () {
          overlayEntry.remove();
        },
        onTap: () {
          overlayEntry.remove();
          // Chuyển đến trang profile để xem lịch
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: widget.phoneNumber,
          );
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Tự động ẩn sau 5 giây
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with a diagonal gradient like `EliteMembersScreen`.
    return Container(
      decoration: const BoxDecoration(gradient: _showroomBgGradient),
      child: Scaffold(
        // Let the background show through behind the bottom nav.
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Main content
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildModernBanner()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  _buildBrandsSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(child: _buildThinhHanhSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildCarListSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),

            // AI Chat Button - floating trên navbar
            AIChatBadge(phoneNumber: widget.phoneNumber),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    final userRef = _userDocRef();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),

          // Greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xin chào',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                if (userRef == null)
                  const Text(
                    'Người dùng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: userRef.snapshots(),
                    builder: (context, snapshot) {
                      final displayName = _displayNameFromData(
                        snapshot.data?.data(),
                      );
                      return Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Calendar icon (giống notification icon)
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/date_drive',
                arguments: widget.phoneNumber,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1a1a1a),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/calendar.png',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Notification icon with badge
          SimpleNotificationIcon(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/notification',
                arguments: widget.phoneNumber,
              );
            },
            iconColor: Colors.white,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // Banner hiện đại 2026 với animation
  Widget _buildModernBanner() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bannerService.watchActiveBanners(),
      builder: (context, snapshot) {
        final docs = snapshot.data ?? const [];
        final uiBanners = docs.map(BannerService.toUiData).toList();

        if (uiBanners.isNotEmpty) {
          if (_currentBannerIndex >= uiBanners.length) {
            _currentBannerIndex = 0;
          }
          final current = uiBanners[_currentBannerIndex];
          final currentBanner = BannerData(
            badge: current.badge,
            title: current.title,
            subtitle: current.subtitle,
            buttonText: current.buttonText,
            gradientColors: current.gradientColors,
            accentColor: current.accentColor,
            subtitleColor: current.subtitleColor,
          );
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BannerOfferScreen(
                    offer: current.details,
                    phoneNumber: widget.phoneNumber,
                  ),
                ),
              );
            },
            child: _buildModernBannerBody(currentBanner),
          );
        }

        // Fallback local
        final currentBanner = _banners[_currentBannerIndex];
        final offer = _offers[_currentBannerIndex % _offers.length];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BannerOfferScreen(
                  offer: offer,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          },
          child: _buildModernBannerBody(currentBanner),
        );
      },
    );
  }

  Widget _buildModernBannerBody(BannerData currentBanner) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Responsive height: giảm xuống để tránh overflow hoàn toàn
    final bannerHeight = screenHeight < 700 ? 140.0 : 160.0;

    return Column(
      children: [
        // Banner chính với animation
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: bannerHeight, // Dynamic height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: currentBanner.gradientColors,
                  stops: const [0.0, 0.6, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: currentBanner.accentColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 0),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _bannerAnimationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: ModernPatternPainter(
                            animationValue: _bannerAnimationController.value,
                            accentColor: currentBanner.accentColor,
                          ),
                        );
                      },
                    ),
                  ),

                  // Glowing accent - giảm kích thước
                  Positioned(
                    top: -30, // Giảm từ -50
                    right: -30, // Giảm từ -50
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      width: 100, // Giảm từ 150
                      height: 100, // Giảm từ 150
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            currentBanner.accentColor.withValues(alpha: 0.2),
                            currentBanner.accentColor.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16), // Giảm padding còn 16
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Dàn đều thay vì center
                        children: [
                          // Top section - Badge và title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge với animation
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      currentBanner.accentColor,
                                      currentBanner.accentColor.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentBanner.accentColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  currentBanner.badge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Main title với animation
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  currentBanner.title,
                                  key: ValueKey(currentBanner.title),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24, // Giảm xuống 24
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Bottom section - Subtitle và button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subtitle with animated indicator
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: currentBanner.subtitleColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      child: Text(
                                        currentBanner.subtitle,
                                        key: ValueKey(currentBanner.subtitle),
                                        style: TextStyle(
                                          color: currentBanner.subtitleColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Action button với hover effect
                              GestureDetector(
                                onTap: () {
                                  final offer =
                                      _offers[_currentBannerIndex %
                                          _offers.length];
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BannerOfferScreen(
                                        offer: offer,
                                        phoneNumber: widget.phoneNumber,
                                      ),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentBanner.buttonText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating car icon với pulse animation - giảm kích thước
                  Positioned(
                    right: 16, // Giảm từ 20
                    top: 16, // Giảm từ 20
                    child: AnimatedBuilder(
                      animation: _bannerAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale:
                              1.0 +
                              (_bannerAnimationController.value *
                                  0.05), // Giảm effect
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            width: 48, // Giảm từ 60
                            height: 48, // Giảm từ 60
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  currentBanner.accentColor,
                                  currentBanner.accentColor.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: currentBanner.accentColor.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 10, // Giảm từ 15
                                  offset: const Offset(0, 3), // Giảm từ 5
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.electric_car_rounded,
                              color: Colors.white,
                              size: 22, // Giảm từ 28
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8), // Giảm từ 12 -> 8
        // Banner indicators (dots) - compact version
        Container(
          height: 20, // Fix chiều cao của dots container
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                  _bannerAnimationController.reset();
                  _slideAnimationController.reset();
                  _bannerAnimationController.forward();
                  _slideAnimationController.forward();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: index == _currentBannerIndex
                      ? 16
                      : 6, // Giảm kích thước
                  height: 6, // Giảm chiều cao
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                  ), // Giảm margin
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: index == _currentBannerIndex
                        ? _banners[_currentBannerIndex].accentColor
                        : Colors.white24,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  SliverPadding _buildBrandsSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ưu đãi đặc biệt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildBrandItem(_brands[index], index);
            }, childCount: _brands.length),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandItem(CarBrand brand, int index) {
    final isSelected = index == _selectedBrandIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBrandIndex = index;
        });

        // Navigate to brand specific pages
        if (brand.name == 'Mercedes') {
          Navigator.pushNamed(
            context,
            '/mercedes',
            arguments: widget.phoneNumber,
          );
        } else if (brand.name == 'BMW') {
          Navigator.pushNamed(context, '/bmw', arguments: widget.phoneNumber);
        } else if (brand.name == 'Volvo') {
          Navigator.pushNamed(context, '/volvo', arguments: widget.phoneNumber);
        } else if (brand.name == 'Tesla') {
          Navigator.pushNamed(context, '/tesla', arguments: widget.phoneNumber);
        } else if (brand.name == 'Toyota') {
          Navigator.pushNamed(
            context,
            '/toyota',
            arguments: widget.phoneNumber,
          );
        } else if (brand.name == 'Mazda') {
          Navigator.pushNamed(context, '/mazda', arguments: widget.phoneNumber);
        } else if (brand.name == 'Hyundai') {
          Navigator.pushNamed(
            context,
            '/hyundai',
            arguments: widget.phoneNumber,
          );
        }
        // Có thể thêm các hãng khác sau
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Khung tròn chứa logo
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF444444),
              border: isSelected
                  ? Border.all(color: const Color(0xFF3b82c8), width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF3b82c8).withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 14 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _BrandLogo(brand: brand, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Chữ ở bên ngoài (dưới khung tròn)
          Text(
            brand.name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildThinhHanhSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Thịnh hành',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Xem tất cả',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildCarListSliver() {
    final cars = CarsData.allCars;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (final car in cars)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CarCard.fromMap(
                  {
                    'id': car.id,
                    'name': car.name,
                    'brand': car.brand,
                    'price': car.price,
                    'priceNote': 'Liên hệ',
                    'image': car.image,
                    'gallery': car.images,
                    'rating': car.rating,
                    'reviewCount': car.reviewCount,
                    'isNew': car.isNew,
                    'description': car.description,
                  },
                  phoneNumber: widget.phoneNumber,
                  showBrandBadge: false,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return FloatingCarBottomNav(
      currentIndex: _activeNavIndex,
      onTap: (index) {
        if (_activeNavIndex == index) return;
        setState(() => _activeNavIndex = index);

        if (index == 0) {
          // already on Home
        } else if (index == 1) {
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 2) {
          Navigator.pushReplacementNamed(
            context,
            '/mycar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
          Navigator.pushReplacementNamed(
            context,
            '/favorite',
            arguments: widget.phoneNumber,
          );
        } else if (index == 4) {
          Navigator.pushReplacementNamed(
            context,
            '/profile',
            arguments: widget.phoneNumber,
          );
        }
      },
    );
  }

  int _activeNavIndex = 0;
}

class CarBrand {
  final String name;
  final IconData? icon;
  final String? assetPath;

  CarBrand({required this.name, this.icon, this.assetPath})
    : assert(icon != null || assetPath != null);
}

class _BrandLogo extends StatelessWidget {
  final CarBrand brand;
  final double size;
  const _BrandLogo({required this.brand, this.size = 28});

  @override
  Widget build(BuildContext context) {
    if (brand.assetPath != null) {
      return Image.asset(
        brand.assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.directions_car, color: Colors.white, size: size);
        },
      );
    }

    return Icon(brand.icon, color: Colors.white, size: size);
  }
}

// Custom Painter cho background pattern hiện đại
class ModernPatternPainter extends CustomPainter {
  final double animationValue;
  final Color accentColor;

  ModernPatternPainter({
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05 * animationValue)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Tạo pattern geometric hiện đại với animation
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 4; j++) {
        final x = (size.width / 6) * i;
        final y = (size.height / 4) * j;

        // Hexagon pattern với animation
        final scale = 0.5 + (animationValue * 0.5);
        path.moveTo(x + 15 * scale, y);
        path.lineTo(x + 25 * scale, y + 5 * scale);
        path.lineTo(x + 25 * scale, y + 15 * scale);
        path.lineTo(x + 15 * scale, y + 20 * scale);
        path.lineTo(x + 5 * scale, y + 15 * scale);
        path.lineTo(x + 5 * scale, y + 5 * scale);
        path.close();
      }
    }

    canvas.drawPath(path, paint);

    // Thêm animated dots pattern
    final dotPaint = Paint()
      ..color = accentColor.withOpacity(0.1 * animationValue);

    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 5; j++) {
        final x = (size.width / 8) * i + 10;
        final y = (size.height / 5) * j + 10;
        canvas.drawCircle(Offset(x, y), 2 * animationValue, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Widget hiển thị notification từ trên xuống
class _BookingNotificationWidget extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _BookingNotificationWidget({
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_BookingNotificationWidget> createState() =>
      _BookingNotificationWidgetState();
}

class _BookingNotificationWidgetState extends State<_BookingNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F9D58), Color(0xFF34A853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Đăng ký lái thử thành công!',
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bấm để xem lịch hẹn trong thông tin cá nhân',
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    IconButton(
                      onPressed: _dismiss,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Banner Data Model
class BannerData {
  final String badge;
  final String title;
  final String subtitle;
  final String buttonText;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color subtitleColor;

  BannerData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.gradientColors,
    required this.accentColor,
    required this.subtitleColor,
  });
}
