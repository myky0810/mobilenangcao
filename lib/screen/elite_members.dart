import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firebase_helper.dart';
import '../services/members_stats_service.dart';
import '../widgets/floating_car_bottom_nav.dart';

class EliteMembersScreen extends StatefulWidget {
  const EliteMembersScreen({super.key, this.phoneNumber});

  static const routeName = '/elite-members';

  final String? phoneNumber;

  @override
  State<EliteMembersScreen> createState() => _EliteMembersScreenState();
}

class _EliteMembersScreenState extends State<EliteMembersScreen> {
  static const _bgTop = Color(0xFF070A12);
  static const _bgBottom = Color(0xFF050511);

  // We treat Elite Members as part of the "MyCar" area but it's a separate
  // route. Keep the center item highlighted.
  int _activeNavIndex = 2;

  String? get _userId {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    return FirebaseHelper.normalizePhone(phone);
  }

  void _onBottomNavTap(int index) {
    setState(() => _activeNavIndex = index);
    final isAdmin = ModalRoute.of(context)?.settings.name == '/admin';
    if (isAdmin) return;
    final phoneArg = widget.phoneNumber;
    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushReplacementNamed('/home', arguments: phoneArg);
        break;
      case 1:
        Navigator.of(
          context,
        ).pushReplacementNamed('/newcar', arguments: phoneArg);
        break;
      case 2:
        Navigator.of(
          context,
        ).pushReplacementNamed('/mycar', arguments: phoneArg);
        break;
      case 3:
        Navigator.of(
          context,
        ).pushReplacementNamed('/favorite', arguments: phoneArg);
        break;
      case 4:
        Navigator.of(
          context,
        ).pushReplacementNamed('/profile', arguments: phoneArg);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Elite Members',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: userId == null
            ? const _CenteredMessage(
                icon: Icons.lock_rounded,
                title: 'Chưa đăng nhập',
                subtitle: 'Bạn cần đăng nhập để xem Elite Members.',
              )
            : StreamBuilder<_MemberSpendStats>(
                stream: _streamMemberSpendStats(userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const _CenteredMessage(
                      icon: Icons.error_outline_rounded,
                      title: 'Lỗi tải dữ liệu',
                      subtitle:
                          'Không thể tải dữ liệu Elite Members. Vui lòng thử lại.',
                    );
                  }

                  final stats = snapshot.data ?? const _MemberSpendStats.zero();
                  final tier = _MemberTier.fromSpend(stats.investmentTotalVnd);
                  final nextTier = tier.next;
                  final nextTarget = nextTier?.minSpendVnd;
                  final progress =
                      (nextTier == null ||
                          nextTarget == null ||
                          nextTarget <= 0)
                      ? 1.0
                      : (stats.investmentTotalVnd / nextTarget).clamp(0.0, 1.0);

                  return _EliteDashboard(
                    stats: stats,
                    tier: tier,
                    nextTier: nextTier,
                    progressToNext: progress,
                    userId: userId,
                  );
                },
              ),
        bottomNavigationBar: FloatingCarBottomNav(
          currentIndex: _activeNavIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  Stream<_MemberSpendStats> _streamMemberSpendStats(String userId) {
    final ref = MembersStatsService.summaryRef(userId);
    return ref.snapshots().asyncMap((doc) async {
      final data = doc.data();

      // If admin summary doesn't exist yet, create it once.
      if (data == null) {
        await MembersStatsService.recomputeAndPersist(userId: userId);
        return const _MemberSpendStats(
          investmentTotalVnd: 0,
          points: 0,
          lastActiveAt: null,
          activities: [],
        );
      }

      final total = (data['totalInvestmentVnd'] is num)
          ? (data['totalInvestmentVnd'] as num).toDouble()
          : double.tryParse('${data['totalInvestmentVnd']}') ?? 0.0;
      final points = (data['points'] is num)
          ? (data['points'] as num).toInt()
          : int.tryParse('${data['points']}') ?? 0;

      final lastTs = data['lastActiveAt'] as Timestamp?;
      final last = lastTs?.toDate();

      final rawActivities = (data['recentActivities'] as List?) ?? const [];
      final activities = <_MemberActivity>[];
      for (final item in rawActivities) {
        if (item is! Map) continue;
        final ts = item['date'];
        final dt = _parseDepositDate(ts);
        if (dt == null) continue;

        final type = (item['type'] ?? '').toString();
        if (type == 'deposit') {
          final amountRaw = item['amountVnd'] ?? 0;
          final amount = (amountRaw is num)
              ? amountRaw.toDouble()
              : double.tryParse(amountRaw.toString()) ?? 0.0;
          activities.add(_MemberActivity(date: dt, amountVnd: amount));
        } else {
          // Test-drive activity.
          activities.add(_MemberActivity(date: dt, amountVnd: 0));
        }
      }

      return _MemberSpendStats(
        investmentTotalVnd: total,
        points: points,
        lastActiveAt: last,
        activities: activities.take(5).toList(),
      );
    });
  }

  DateTime? _parseDepositDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

class _EliteDashboard extends StatelessWidget {
  const _EliteDashboard({
    required this.stats,
    required this.tier,
    required this.nextTier,
    required this.progressToNext,
    required this.userId,
  });

  final _MemberSpendStats stats;
  final _MemberTier tier;
  final _MemberTier? nextTier;
  final double progressToNext;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      children: [
        _GoldStatusCard(tier: tier, userId: userId),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Tổng đầu tư',
                value: moneyFmt.format(stats.investmentTotalVnd),
                icon: Icons.account_balance_wallet_rounded,
                accent: const Color(0xFFFFC857),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Điểm',
                value: stats.points.toString(),
                icon: Icons.workspace_premium_rounded,
                accent: const Color(0xFF2F6FED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProgressCard(
          tier: tier,
          nextTier: nextTier,
          progress: progressToNext,
          totalSpendVnd: stats.investmentTotalVnd,
        ),
        const SizedBox(height: 12),
        _ActivityCard(
          lastActiveAt: stats.lastActiveAt,
          activities: stats.activities,
        ),
        const SizedBox(height: 12),
        const _PerksCard(),
      ],
    );
  }
}

class _GoldStatusCard extends StatelessWidget {
  const _GoldStatusCard({required this.tier, required this.userId});

  final _MemberTier tier;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [tier.color, tier.color.withValues(alpha: 0.35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: tier.color.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _showTierDetails(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ID: $userId',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.60),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              tier.badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTierDetails(BuildContext context) {
    final moneyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF070A12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        Widget line(_MemberTier t, {required bool isCurrent}) {
          final next = t.next;
          final needsText = (next == null)
              ? 'Hạng cao nhất'
              : 'Cần ${moneyFmt.format(next.minSpendVnd)} tổng đầu tư để lên ${next.label}';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? t.color.withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      t.badge,
                      style: TextStyle(
                        color: t.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng đầu tư tối thiểu: ${moneyFmt.format(t.minSpendVnd)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        needsText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: t.color.withValues(alpha: 0.18),
                    ),
                    child: Text(
                      'HIỆN TẠI',
                      style: TextStyle(
                        color: t.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        final tiers = _MemberTier.values;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chi tiết tăng hạng',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Bấm vào ID để xem. Mốc hạng dựa trên tổng đầu tư (đặt cọc/ thanh toán).',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                for (final t in tiers) line(t, isCurrent: t == tier),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.tier,
    required this.nextTier,
    required this.progress,
    required this.totalSpendVnd,
  });

  final _MemberTier tier;
  final _MemberTier? nextTier;
  final double progress;
  final double totalSpendVnd;

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final next = nextTier;
    final nextText = next == null
        ? 'Bạn đã ở hạng cao nhất'
        : 'Còn ${moneyFmt.format((next.minSpendVnd - totalSpendVnd).clamp(0, double.infinity))} để lên ${next.label}';

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tiến độ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: tier.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(tier.color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nextText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.lastActiveAt, required this.activities});

  final DateTime? lastActiveAt;
  final List<_MemberActivity> activities;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final moneyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final lastText = lastActiveAt == null
        ? 'Chưa có giao dịch'
        : df.format(lastActiveAt!);

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                lastText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            Text(
              'Chưa có dữ liệu.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            )
          else
            ...activities.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        df.format(a.date),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      moneyFmt.format(a.amountVnd),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PerksCard extends StatelessWidget {
  const _PerksCard();

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quyền lợi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          const _PerkLine(
            icon: Icons.local_offer_rounded,
            text: 'Ưu đãi riêng theo hạng thành viên',
          ),
          const SizedBox(height: 8),
          const _PerkLine(
            icon: Icons.support_agent_rounded,
            text: 'Hỗ trợ ưu tiên 24/7',
          ),
          const SizedBox(height: 8),
          const _PerkLine(
            icon: Icons.shield_rounded,
            text: 'Bảo hành và chăm sóc cao cấp',
          ),
        ],
      ),
    );
  }
}

class _PerkLine extends StatelessWidget {
  const _PerkLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2F6FED)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Colors.white.withValues(alpha: 0.65)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.60)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberSpendStats {
  const _MemberSpendStats({
    required this.investmentTotalVnd,
    required this.points,
    required this.lastActiveAt,
    required this.activities,
  });

  const _MemberSpendStats.zero()
    : investmentTotalVnd = 0,
      points = 0,
      lastActiveAt = null,
      activities = const [];

  final double investmentTotalVnd;
  final int points;
  final DateTime? lastActiveAt;
  final List<_MemberActivity> activities;
}

class _MemberActivity {
  const _MemberActivity({required this.date, required this.amountVnd});
  final DateTime date;
  final double amountVnd;
}

enum _MemberTier {
  dong(label: 'Đồng', minSpendVnd: 0, color: Color(0xFFB87333), badge: 'Đ'),
  silver(
    label: 'Bạc',
    minSpendVnd: 5000000000,
    color: Color(0xFFB9C1CC),
    badge: 'B',
  ),
  gold(
    label: 'Vàng',
    minSpendVnd: 20000000000,
    color: Color(0xFFFFC857),
    badge: 'V',
  ),
  diamond(
    label: 'Kim Cương',
    minSpendVnd: 50000000000,
    color: Color(0xFFB38CFF),
    badge: 'K',
  );

  const _MemberTier({
    required this.label,
    required this.minSpendVnd,
    required this.color,
    required this.badge,
  });

  final String label;
  final double minSpendVnd;
  final Color color;
  final String badge;

  static _MemberTier fromSpend(double spend) {
    if (spend >= _MemberTier.diamond.minSpendVnd) return _MemberTier.diamond;
    if (spend >= _MemberTier.gold.minSpendVnd) return _MemberTier.gold;
    if (spend >= _MemberTier.silver.minSpendVnd) return _MemberTier.silver;
    return _MemberTier.dong;
  }

  _MemberTier? get next {
    switch (this) {
      case _MemberTier.dong:
        return _MemberTier.silver;
      case _MemberTier.silver:
        return _MemberTier.gold;
      case _MemberTier.gold:
        return _MemberTier.diamond;
      case _MemberTier.diamond:
        return null;
    }
  }
}
