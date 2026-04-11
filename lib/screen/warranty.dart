import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/firebase_helper.dart';
import '../services/warranty_service.dart';
import '../widgets/floating_car_bottom_nav.dart';

class WarrantyScreen extends StatefulWidget {
  final String? phoneNumber;

  const WarrantyScreen({super.key, this.phoneNumber});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  // ── Colors ──
  // Use Deposit palette
  static const _bg = Color(0xFF1E2A47);
  static const _card = Color(0xFF141822);
  static const _accent = Color(0xFF3B82F6);
  static const _cardSurface = Color(0xFF14161B);

  String? get _userId {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    return FirebaseHelper.normalizePhone(phone);
  }

  // ─── Activate a pending warranty ────────────────────────────────────
  void _showActivatePendingDialog(Map<String, dynamic> warranty) {
    final vinCtrl = TextEditingController();
    final odoCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    DateTime? date;
    final pendingId = (warranty['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kích hoạt bảo hành',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (warranty['carName'] ?? '').toString(),
                style: const TextStyle(
                  color: _accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _buildSheetField(
                vinCtrl,
                'VIN (17 ký tự)',
                TextInputType.text,
                maxLength: 17,
                enforceUppercase: true,
                onlyAlnum: true,
              ),
              const SizedBox(height: 10),
              _buildSheetField(
                plateCtrl,
                'Biển số (tuỳ chọn)',
                TextInputType.text,
              ),
              const SizedBox(height: 10),
              _buildSheetField(odoCtrl, 'Số ODO (km)', TextInputType.number),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date ?? now,
                    firstDate: DateTime(now.year - 10),
                    lastDate: now,
                    builder: (c, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: _accent,
                          surface: _card,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setSheetState(() => date = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    date == null
                        ? 'Chọn ngày mua/nhận xe'
                        : DateFormat('dd/MM/yyyy').format(date!),
                    style: TextStyle(
                      color: date == null ? Colors.white30 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final vin = vinCtrl.text.trim().toUpperCase();
                    final odoText = odoCtrl.text.trim();

                    // Validate required fields.
                    // Theo yêu cầu: nếu thiếu input fields -> hiển thị đúng message chung.
                    if (vin.isEmpty || odoText.isEmpty || date == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('Vui lòng nhập đầy đủ thông tin'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    if (vin.length != 17) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('VIN phải đủ 17 ký tự'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    final userId = _userId;
                    if (userId == null) return;

                    await WarrantyService.activatePendingWarranty(
                      userId: userId,
                      pendingDocId: pendingId,
                      vin: vin,
                      purchaseDate: DateFormat('yyyy-MM-dd').format(date!),
                      odoAtActivation: odoText,
                      licensePlate: plateCtrl.text.trim(),
                    );

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Kích hoạt bảo hành thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'KÍCH HOẠT',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(
    TextEditingController ctrl,
    String hint,
    TextInputType type, {
    int? maxLength,
    bool enforceUppercase = false,
    bool onlyAlnum = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        if (onlyAlnum)
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        if (enforceUppercase) _upperCaseTextFormatter(),
      ],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF1A1F2E),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  /// Formatter: auto upper-case while typing.
  /// (Used for VIN input)
  ///
  /// Note: This doesn't validate VIN rules; only normalizes casing.
  static TextInputFormatter _upperCaseTextFormatter() =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        final upper = newValue.text.toUpperCase();
        return newValue.copyWith(
          text: upper,
          selection: newValue.selection,
          composing: TextRange.empty,
        );
      });

  // ─── Warranty details (full-screen modal) ───────────────────────────
  void _showWarrantyDetails(Map<String, dynamic> w) {
    final explicitImg = (w['imageUrl'] ?? w['carImage'] ?? '').toString();
    final carBrand = (w['carBrand'] ?? '').toString();
    final headerImg = _resolveWarrantyHeaderImage(
      explicit: explicitImg,
      brand: carBrand,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        pageBuilder: (ctx, anim, _) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: _WarrantyDetailsSheet(warranty: w, headerImage: headerImg),
          );
        },
      ),
    );
  }

  // _buildInfoRow removed (details UI moved to a dedicated full-screen sheet)

  // ─── BUILD ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'BẢO HÀNH XE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildWarrantyList(),
      bottomNavigationBar: FloatingCarBottomNav(
        currentIndex: -1,
        onTap: (index) {
          final phone = widget.phoneNumber;
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home', arguments: phone);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(
              context,
              '/newcar',
              arguments: phone,
            );
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/mycar', arguments: phone);
          } else if (index == 3) {
            Navigator.pushReplacementNamed(
              context,
              '/favorite',
              arguments: phone,
            );
          } else if (index == 4) {
            Navigator.pushReplacementNamed(
              context,
              '/profile',
              arguments: phone,
            );
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WARRANTY LIST
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildWarrantyList() {
    final userId = _userId;
    if (userId == null) {
      return const Center(
        child: Text(
          'Bạn cần đăng nhập để xem bảo hành.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: WarrantyService.streamWarranties(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _accent));
        }

        final warranties = snapshot.data ?? [];
        if (warranties.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, color: Colors.white24, size: 64),
                const SizedBox(height: 14),
                const Text(
                  'Chưa có bảo hành nào',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hãy đặt cọc mua xe để tự động nhận bảo hành',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          itemCount: warranties.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final w = warranties[index];
            return _buildWarrantyCard(w);
          },
        );
      },
    );
  }

  // ─── Warranty card ──────────────────────────────────────────────────
  Widget _buildWarrantyCard(Map<String, dynamic> w) {
    final status = (w['status'] ?? 'pending').toString();
    final carName = (w['carName'] ?? '').toString();
    final vin = (w['vin'] ?? '').toString();
    final carBrand = (w['carBrand'] ?? '').toString();

    // Data binding: ưu tiên field warranty, nếu thiếu fallback theo schema garageVehicles.
    // warranty fields: odoAtActivation, showroomName
    // garage vehicles fields: odometerValue / showroom (nếu có)
    final odo = ((w['odoAtActivation'] ?? w['odometerValue']) ?? '').toString();
    final showroomName = ((w['showroomName'] ?? w['showroom']) ?? '')
        .toString();
    final showroomAddress = ((w['showroomAddress'] ?? '') ?? '').toString();

    // Image binding (từ DB). Nếu không có thì dùng fallback theo brand để tránh 2 xe khác nhau bị trùng ảnh.
    final imageUrl = (w['imageUrl'] ?? w['carImage'] ?? '').toString();
    final headerImage = _resolveWarrantyHeaderImage(
      explicit: imageUrl,
      brand: carBrand,
    );

    final isPending = status == 'pending';
    final isActive = status == 'active';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isActive) {
      statusColor = Colors.green;
      statusLabel = 'Đang hoạt động';
      statusIcon = Icons.check_circle_rounded;
    } else if (isPending) {
      statusColor = Colors.orange;
      statusLabel = 'Chờ kích hoạt';
      statusIcon = Icons.hourglass_bottom_rounded;
    } else {
      statusColor = Colors.red;
      statusLabel = 'Hết hạn';
      statusIcon = Icons.cancel_rounded;
    }

    // End date
    String endDateStr = '--';
    final endDateRaw = w['endDate'];
    if (endDateRaw is Timestamp) {
      endDateStr = DateFormat('dd/MM/yyyy').format(endDateRaw.toDate());
    }

    // UI theo thiết kế ảnh: image header + status pill + tiles + expiry + button
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPending
            ? () => _showActivatePendingDialog(w)
            : () => _showWarrantyDetails(w),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: _cardSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 210,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.92,
                          child: headerImage.startsWith('assets/')
                              ? Image.asset(
                                  headerImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _fallbackHeaderImage(),
                                )
                              : (headerImage.isNotEmpty
                                    ? Image.network(
                                        headerImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _fallbackHeaderImage(),
                                      )
                                    : _fallbackHeaderImage()),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.78),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            // Tăng độ tương phản để nhìn rõ hơn trên nền tối
                            color: statusColor.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.90),
                              width: 1.3,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                color: Colors.white.withValues(alpha: 0.98),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.98),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (vin.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'VIN: $vin',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1116),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Icon(
                          Icons.verified_rounded,
                          color: _accent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.speed_rounded,
                          label: 'ODOMETER',
                          value: odo.isNotEmpty ? odo : '--',
                          suffix: odo.isNotEmpty ? ' km' : '',
                          accent: _accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.store_mall_directory_rounded,
                          label: 'SHOWROOM',
                          value: showroomName.isNotEmpty ? showroomName : '--',
                          subValue: showroomAddress.isNotEmpty
                              ? showroomAddress
                              : '',
                          accent: const Color(0xFF7C6CFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HẾT HẠN BẢO HÀNH',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              endDateStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => _showWarrantyDetails(w),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F6FED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'CHI TIẾT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackHeaderImage() {
    return Image.asset(
      'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg',
      fit: BoxFit.cover,
    );
  }

  String _resolveWarrantyHeaderImage({
    required String explicit,
    required String brand,
  }) {
    final cleaned = explicit.trim();
    if (cleaned.isNotEmpty) return cleaned;

    final b = brand.toLowerCase().trim();
    if (b.contains('bmw')) {
      return 'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg';
    }
    if (b.contains('mercedes') || b.contains('benz')) {
      return 'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-038bcbee2f3dd71d41f1185ec519c69811.jpg';
    }
    if (b.contains('toyota')) {
      return 'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg';
    }
    if (b.contains('tesla')) {
      return 'assets/images/products/Tesla-Model_3-2024-1280-3f2af9ab7a564be8488ad85f205963fdf3.jpg';
    }
    if (b.contains('volvo')) {
      return 'assets/images/products/Volvo-XC40_Recharge-2023-1280-20af6e11057d63aefa0b99ee4160b33035.jpg';
    }
    if (b.contains('hyundai')) {
      return 'assets/images/products/Honda-HR-V-2022-1280-0d18f82a2522a27da20b770cf282f814e9.jpg';
    }
    if (b.contains('mazda')) {
      return 'assets/images/products/Honda-Civic_Type_R-2023-1280-0a7fadf5d63cbc17ac4879b01396aa6be2.jpg';
    }

    // fallback cuối cùng
    return 'assets/images/RR.jpg';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.subValue = '',
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final String suffix;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1116),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: accent.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (suffix.isNotEmpty)
                  TextSpan(
                    text: suffix,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          if (subValue.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WarrantyDetailsSheet extends StatelessWidget {
  const _WarrantyDetailsSheet({
    required this.warranty,
    required this.headerImage,
  });

  final Map<String, dynamic> warranty;
  final String headerImage;

  static const _bg = Color(0xFF0B0F1A);
  static const _card = Color(0xFF121A2B);
  static const _accent = Color(0xFF2F6FED);

  @override
  Widget build(BuildContext context) {
    final status = (warranty['status'] ?? 'pending').toString();
    final vinRaw = (warranty['vin'] ?? '').toString();
    final vinMasked = _maskVin(vinRaw);

    final bookingId = (warranty['bookingId'] ?? '').toString().trim();
    final transactionId = (warranty['transactionId'] ?? '').toString().trim();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadDepositOverlay(
        bookingId: bookingId,
        transactionId: transactionId,
      ),
      builder: (context, snap) {
        final overlay = snap.data;

        final carName =
            overlay?['carName']?.toString() ??
            (warranty['carName'] ?? '').toString();
        final carBrand =
            overlay?['carBrand']?.toString() ??
            (warranty['carBrand'] ?? '').toString();
        final carImage =
            overlay?['carImage']?.toString() ??
            overlay?['imageUrl']?.toString() ??
            (warranty['imageUrl'] ?? warranty['carImage'] ?? '').toString();

        final resolvedHeader = carImage.trim().isNotEmpty
            ? carImage.trim()
            : headerImage;

        final carModelYear =
            (overlay?['carModelYear'] ?? warranty['carModelYear'] ?? '')
                .toString();
        final edition =
            (overlay?['edition'] ??
                    overlay?['carEdition'] ??
                    warranty['edition'] ??
                    warranty['carEdition'] ??
                    '')
                .toString();

        final odo = _stringOrEmpty(
          warranty['odoAtActivation'] ?? warranty['odometerValue'],
        );

        final showroomName = _pickShowroomName(overlay, warranty);
        final showroomAddress = _pickShowroomAddress(overlay, warranty);

        final expStr = _formatDate(
          warranty['endDate'],
          fallback: (warranty['expiryDate'] ?? '').toString(),
          fmt: 'dd/MM/yyyy',
        );

        final title = _joinTitle(carBrand, carName, carModelYear);
        final subtitle = edition.isNotEmpty ? edition : ' ';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Material(
                color: _bg,
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _HeaderImage(image: resolvedHeader),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              height: 1.08,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _StatusPill(status: status),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DetailsTile(
                                        label: 'SỐ VIN',
                                        value: vinMasked.isNotEmpty
                                            ? vinMasked
                                            : '--',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DetailsTile(
                                        label: 'SỐ KM (ODO)',
                                        value: odo.isNotEmpty ? odo : '--',
                                        subValue: odo.isNotEmpty ? 'km' : '',
                                        alignEnd: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DetailsTile(
                                        label: 'SHOWROOM',
                                        value: showroomName.isNotEmpty
                                            ? showroomName
                                            : '--',
                                        subValue: showroomAddress,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DetailsTile(
                                        label: 'HẾT HẠN',
                                        value: expStr,
                                        valueColor: const Color(0xFF55A7FF),
                                        alignEnd: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Hạng mục bảo hành',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        foregroundColor: _accent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: const Text(
                                        'Xem điều khoản',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _CoverageItem(
                                  icon: Icons.settings_suggest_rounded,
                                  title: 'Động cơ & truyền động',
                                  subtitle:
                                      'Bảo hành đầy đủ cho các bộ phận cơ khí chính',
                                ),
                                const SizedBox(height: 10),
                                _CoverageItem(
                                  icon: Icons.bolt_rounded,
                                  title: 'Hệ thống điện',
                                  subtitle:
                                      'Cảm biến, dây điện và hệ thống ắc quy',
                                ),
                                const SizedBox(height: 10),
                                _CoverageItem(
                                  icon: Icons.health_and_safety_rounded,
                                  title: 'Hỗ trợ cứu hộ',
                                  subtitle: 'Hỗ trợ 24/7 và hỗ trợ khẩn cấp',
                                ),
                                const SizedBox(height: 10),
                                _CoverageItem(
                                  icon: Icons.format_paint_rounded,
                                  title: 'Chống gỉ & sơn',
                                  subtitle:
                                      'Bảo hành chống gỉ thủng lên đến 12 năm',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _TopBackButton(
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _stringOrEmpty(Object? v) => v == null ? '' : v.toString();

  static String _formatDate(
    Object? raw, {
    required String fallback,
    required String fmt,
  }) {
    if (raw is Timestamp) {
      return DateFormat(fmt).format(raw.toDate());
    }
    if (raw is DateTime) {
      return DateFormat(fmt).format(raw);
    }
    final f = fallback.trim();
    if (f.isNotEmpty) return f;
    return '--';
  }

  static String _joinTitle(String brand, String name, String year) {
    final b = brand.trim();
    final n = name.trim();
    final y = year.trim();
    final base = [b, n].where((e) => e.isNotEmpty).join(' ');
    if (y.isEmpty) return base.isNotEmpty ? base : 'Chi tiết bảo hành';
    return base.isNotEmpty ? '$base\n$y' : y;
  }

  static String _maskVin(String vin) {
    final v = vin.trim();
    if (v.isEmpty) return '';
    // style: ABC123XYZ456 (short masked look) OR keep 17 chars and mask middle
    if (v.length <= 12) return v;
    if (v.length == 17) {
      final start = v.substring(0, 3);
      final end = v.substring(14);
      return '$start••••••••••$end';
    }
    final start = v.substring(0, 3);
    final end = v.substring(v.length - 3);
    return '$start••••••$end';
  }

  /// Load deposit data to keep banner + car info consistent with Deposit pages.
  ///
  /// Priority:
  /// 1) If bookingId exists: try find `deposits` where depositId == bookingId OR bookingId == bookingId.
  /// 2) If transactionId exists: try find `deposits` where transactionId == transactionId.
  ///
  /// Returns null if nothing found.
  static Future<Map<String, dynamic>?> _loadDepositOverlay({
    required String bookingId,
    required String transactionId,
  }) async {
    final db = FirebaseFirestore.instance;
    final deps = db.collection('deposits');

    Future<Map<String, dynamic>?> firstMatch(
      Query<Map<String, dynamic>> q,
    ) async {
      final snap = await q.limit(1).get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    }

    if (bookingId.isNotEmpty) {
      // some flows store bookingId in depositId
      final byDepositId = await firstMatch(
        deps.where('depositId', isEqualTo: bookingId),
      );
      if (byDepositId != null) return byDepositId;

      final byBookingId = await firstMatch(
        deps.where('bookingId', isEqualTo: bookingId),
      );
      if (byBookingId != null) return byBookingId;
    }

    if (transactionId.isNotEmpty) {
      final byTxn = await firstMatch(
        deps.where('transactionId', isEqualTo: transactionId),
      );
      if (byTxn != null) return byTxn;
    }

    return null;
  }

  static String _pickShowroomName(
    Map<String, dynamic>? deposit,
    Map<String, dynamic> warranty,
  ) {
    final d = deposit;
    final fromMap = d != null && d['showroom'] is Map
        ? (d['showroom'] as Map)['name']?.toString()
        : null;
    return (fromMap ?? d?['showroomName'] ?? warranty['showroomName'] ?? '')
        .toString();
  }

  static String _pickShowroomAddress(
    Map<String, dynamic>? deposit,
    Map<String, dynamic> warranty,
  ) {
    final d = deposit;
    final fromMap = d != null && d['showroom'] is Map
        ? (d['showroom'] as Map)['address']?.toString()
        : null;
    return (fromMap ??
            d?['showroomAddress'] ??
            warranty['showroomAddress'] ??
            '')
        .toString();
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final img = image.trim();
    Widget child;
    if (img.startsWith('http://') || img.startsWith('https://')) {
      child = Image.network(img, fit: BoxFit.cover);
    } else {
      child = Image.asset(img, fit: BoxFit.cover);
    }

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBackButton extends StatelessWidget {
  const _TopBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();
    final isActive = s == 'active';
    final bg = isActive
        ? const Color(0xFF0B7F5E).withValues(alpha: 0.94)
        : const Color(0xFFB45309).withValues(alpha: 0.92);
    final border = isActive
        ? const Color(0xFF16D6A5).withValues(alpha: 0.55)
        : const Color(0xFFFFC06B).withValues(alpha: 0.55);

    final text = _statusToVi(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : Icons.hourglass_bottom_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  static String _statusToVi(String status) {
    switch (status) {
      case 'active':
        return 'ĐANG HIỆU LỰC';
      case 'pending':
        return 'ĐANG CHỜ';
      case 'expired':
        return 'HẾT HẠN';
      case 'cancelled':
      case 'canceled':
        return 'ĐÃ HỦY';
      default:
        return status.isEmpty ? 'KHÔNG RÕ' : status.toUpperCase();
    }
  }
}

class _DetailsTile extends StatelessWidget {
  const _DetailsTile({
    required this.label,
    required this.value,
    this.subValue = '',
    this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final String subValue;
  final Color? valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _WarrantyDetailsSheet._card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          if (subValue.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subValue,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverageItem extends StatelessWidget {
  const _CoverageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _WarrantyDetailsSheet._card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _WarrantyDetailsSheet._accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _WarrantyDetailsSheet._accent.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icon, color: _WarrantyDetailsSheet._accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
