import 'package:flutter/material.dart';
import '../widgets/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  PackageInfo? _packageInfo;

  // Match DetailCar background
  static const Color _bg = Color.fromARGB(255, 18, 32, 47);
  static const List<Color> _bgGradient = [_bg, _bg, _bg, _bg];

  // Premium accent (modern car-app vibe)
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _accent2 = Color(0xFF22D3EE);

  // Card surfaces tuned to the new bg
  static const Color _surface = Color(0xFF0F1C2E);
  static const Color _surface2 = Color(0xFF12263F);
  static const Color _divider = Color(0xFF3A4F74);

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final packageName = _packageInfo?.packageName ?? 'com.example.doanCuoiki';
    final appName = _packageInfo?.appName ?? 'Luxury Car Rental';
    final version = _packageInfo?.version ?? '1.0.0';
    final buildNumber = _packageInfo?.buildNumber ?? '1';

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _bgGradient,
                    stops: const [0.0, 0.35, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  pinned: true,
                  centerTitle: true,
                  title: const Text(
                    'Thông tin ứng dụng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _BackPill(onTap: () => Navigator.pop(context)),
                  ),
                  actions: const [SizedBox(width: 10)],
                  flexibleSpace: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.22),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 4),
                      _buildLuxuryHeader(appName: appName, version: version),
                      const SizedBox(height: 16),
                      _buildPremiumSection(
                        title: 'Phiên bản',
                        child: Column(
                          children: [
                            _SettingRow(
                              icon: Icons.system_update_alt_rounded,
                              title: 'Phiên bản',
                              value: version,
                              showTrailingIcon: false,
                            ),
                            const _SectionDivider(),
                            _SettingRow(
                              icon: Icons.build_circle_rounded,
                              title: 'Số bản dựng',
                              value: buildNumber,
                              showTrailingIcon: false,
                            ),
                            const _SectionDivider(),
                            _SettingRow(
                              icon: Icons.apps_rounded,
                              title: 'Gói ứng dụng',
                              value: packageName,
                              showTrailingIcon: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumSection(
                        title: 'Điểm nổi bật',
                        child: Column(
                          children: [
                            _BulletRow(
                              icon: Icons.verified_user_rounded,
                              title: 'Bảo mật & đăng nhập',
                              description: 'OTP nhanh, an toàn và ổn định',
                            ),
                            const SizedBox(height: 10),
                            _BulletRow(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Trải nghiệm cao cấp',
                              description: 'Giao diện tối sang, thao tác mượt',
                            ),
                            const SizedBox(height: 10),
                            _BulletRow(
                              icon: Icons.tune_rounded,
                              title: 'Tối ưu & sửa lỗi',
                              description: 'Giảm lag, cuộn mượt và ổn định hơn',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumSection(
                        title: 'Hỗ trợ',
                        child: Column(
                          children: [
                            _SettingRow(
                              icon: Icons.email_rounded,
                              title: 'Email',
                              value: 'support@luxurycarrental.com',
                              onTap: () => _copy(
                                context,
                                'Email',
                                'support@luxurycarrental.com',
                              ),
                            ),
                            const _SectionDivider(),
                            _SettingRow(
                              icon: Icons.phone_rounded,
                              title: 'Hotline',
                              value: '+84 123 456 789',
                              onTap: () =>
                                  _copy(context, 'Hotline', '+84 123 456 789'),
                            ),
                            const _SectionDivider(),
                            _SettingRow(
                              icon: Icons.public_rounded,
                              title: 'Website',
                              value: 'www.luxurycarrental.com',
                              onTap: () => _copy(
                                context,
                                'Website',
                                'www.luxurycarrental.com',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildPremiumSection(
                        title: 'Nhà phát triển',
                        child: _buildDeveloperCompact(),
                      ),
                      const SizedBox(height: 16),
                      _buildPrimaryActions(context),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryHeader({
    required String appName,
    required String version,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.025),
            Colors.black.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAppBadge(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trải nghiệm đặt xe cao cấp',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PillTag(
                      icon: Icons.verified_rounded,
                      text: 'Giao diện chuẩn',
                    ),
                    _PillTag(icon: Icons.shield_rounded, text: 'Bảo mật'),
                    _PillTag(
                      icon: Icons.auto_awesome_rounded,
                      text: 'Phiên bản $version',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBadge() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, _accent2],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_car_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPremiumSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [_accent, _accent2],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDeveloperCompact() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  _accent.withValues(alpha: 0.28),
                  _accent2.withValues(alpha: 0.14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mobile Development Team',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cập nhật: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryButton(
            icon: Icons.bug_report_rounded,
            label: 'Báo lỗi',
            onTap: () => _showSupportDialog(context, 'Báo lỗi'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PrimaryButton(
            icon: Icons.help_outline_rounded,
            label: 'Hỗ trợ',
            onTap: () => _showSupportDialog(context, 'Hỗ trợ'),
          ),
        ),
      ],
    );
  }

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    AppSnackBar.show(
      context,
      'Đã sao chép $label: $value',
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      duration: const Duration(seconds: 2),
    );
  }

  // Legacy builders removed in favor of premium sections.

  void _showSupportDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              type == 'Báo lỗi' ? Icons.bug_report : Icons.help_outline,
              color: _accent,
            ),
            const SizedBox(width: 8),
            Text(type, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'Báo lỗi'
                  ? 'Để báo lỗi, vui lòng liên hệ với chúng tôi qua:'
                  : 'Để được hỗ trợ, vui lòng liên hệ qua:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _SupportContactItem(
              label: 'Email',
              value: 'support@luxurycarrental.com',
              icon: Icons.email_rounded,
            ),
            const SizedBox(height: 8),
            _SupportContactItem(
              label: 'Hotline',
              value: '+84 123 456 789',
              icon: Icons.phone_rounded,
            ),
            const SizedBox(height: 8),
            _SupportContactItem(
              label: 'Website',
              value: 'www.luxurycarrental.com',
              icon: Icons.public_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;

  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: _AppInfoScreenState._divider.withValues(alpha: 0.7),
    );
  }
}

class _PillTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PillTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.86)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool showTrailingIcon;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _AppInfoScreenState._surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, color: _AppInfoScreenState._accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (showTrailingIcon)
              Icon(
                Icons.copy_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.55),
              ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BulletRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, size: 18, color: _AppInfoScreenState._accent),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_AppInfoScreenState._accent, _AppInfoScreenState._accent2],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportContactItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SupportContactItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã sao chép $label: $value'),
            backgroundColor: Colors.black.withValues(alpha: 0.92),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: _AppInfoScreenState._accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
