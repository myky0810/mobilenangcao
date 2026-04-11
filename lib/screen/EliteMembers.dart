import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/firebase_helper.dart';
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

  int _activeNavIndex = 2;

  String? get _userId {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;
    return FirebaseHelper.normalizePhone(phone);
  }

  void _onBottomNavTap(int index) {
    setState(() => _activeNavIndex = index);
    switch (index) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        break;
      case 1:
        Navigator.of(context).pushNamed('/newcar');
        break;
      case 2:
        Navigator.of(context).pushNamed('/mycar');
        break;
      case 3:
        Navigator.of(context).pushNamed('/favorite');
        break;
      case 4:
        Navigator.of(context).pushNamed('/profile');
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
    final q = FirebaseFirestore.instance
        .collection('deposits')
        .where('paymentStatus', isEqualTo: 'paid');
    return q.snapshots().map((snap) {
      var sum = 0;
      Timestamp? lastPaidAt;
      String lastCarName = '';

      for (final d in snap.docs) {
        final data = d.data();
        final phone =
            (data['customerPhone'] ??
                    data['userPhone'] ??
                    data['phoneNumber'] ??
                    '')
                .toString()
                .trim();
        if (FirebaseHelper.normalizePhone(phone) != userId) continue;

        final amountRaw = data['depositAmount'] ?? data['amount'] ?? 0;
        final amount = _parseInt(amountRaw);
        sum += amount;

        final paidAtRaw =
            data['depositDate'] ?? data['paidAt'] ?? data['createdAt'];
        final ts = paidAtRaw is Timestamp ? paidAtRaw : null;
        if (ts != null &&
            (lastPaidAt == null || ts.compareTo(lastPaidAt) > 0)) {
          lastPaidAt = ts;
          lastCarName = (data['carName'] ?? data['car'] ?? '').toString();
        }
      }

      final points = (sum / 100000).floor();
      return _MemberSpendStats(
        investmentTotalVnd: sum,
        pointsBalance: points,
        lastDepositAt: lastPaidAt,
        lastDepositCarName: lastCarName,
      );
    });
  }

  static int _parseInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
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

  static const _accent = Color(0xFF2F6FED);

  static int _pointsFromVnd(int vnd) => (vnd / 100000).floor();

  Stream<List<_MemberActivity>> _streamMemberActivities(
    String userId, {
    int limit = 1,
  }) {
    final q = FirebaseFirestore.instance
        .collection('deposits')
        .where('paymentStatus', isEqualTo: 'paid');

    return q.snapshots().map((snap) {
      final out = <_MemberActivity>[];
      for (final d in snap.docs) {
        final data = d.data();
        final phone =
            (data['customerPhone'] ??
                    data['userPhone'] ??
                    data['phoneNumber'] ??
                    '')
                .toString()
                .trim();
        if (FirebaseHelper.normalizePhone(phone) != userId) continue;

        final amountRaw = data['depositAmount'] ?? data['amount'] ?? 0;
        final amountVnd = _EliteMembersScreenState._parseInt(amountRaw);
        final pts = _pointsFromVnd(amountVnd);

        final carName = (data['carName'] ?? data['car'] ?? '')
            .toString()
            .trim();
        final paidAtRaw =
            data['depositDate'] ?? data['paidAt'] ?? data['createdAt'];
        final ts = paidAtRaw is Timestamp ? paidAtRaw : null;

        out.add(
          _MemberActivity(
            title: carName.isEmpty
                ? 'Deposit Payment'
                : 'New Vehicle Acquisition',
            subtitle: carName.isEmpty ? '—' : carName,
            points: pts,
            paidAt: ts,
          ),
        );
      }

      out.sort((a, b) {
        final at = a.paidAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.paidAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });

      if (out.length > limit) return out.sublist(0, limit);
      return out;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    final ptsFmt = NumberFormat.decimalPattern('vi_VN');
    final investmentStr = moneyFmt.format(stats.investmentTotalVnd).trim();
    final tierLabelUpper = tier.label.toUpperCase();
    final nextTarget = nextTier?.minSpendVnd;
    final remaining = (nextTarget == null)
        ? 0
        : (nextTarget - stats.investmentTotalVnd).clamp(0, 1 << 31);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      physics: const BouncingScrollPhysics(),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INVESTMENT TOTAL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            investmentStr.isNotEmpty ? investmentStr : '0',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text(
                            'VND',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SquareBadge(icon: Icons.qr_code_2_rounded, onTap: () {}),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1116),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: _accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'POINTS BALANCE',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ptsFmt.format(stats.pointsBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SquareBadge(
                      icon: Icons.chevron_right_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tierLabelUpper,
                style: TextStyle(
                  color: tier.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextTier == null
                    ? 'Bạn đã đạt cấp cao nhất.'
                    : 'Còn ${moneyFmt.format(remaining).trim()} VND để lên ${nextTier!.label}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              _GoldStatusCard(
                tier: tier,
                progressToNext: progressToNext,
                nextTierName: nextTier?.label ?? 'MAX',
                nextTierTargetVnd: nextTier?.minSpendVnd ?? tier.minSpendVnd,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text(
              'ACTIVITY & REWARDS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                foregroundColor: _accent,
              ),
              child: const Text(
                'VIEW ALL',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<_MemberActivity>>(
          stream: _streamMemberActivities(userId, limit: 1),
          builder: (context, snap) {
            final list = snap.data ?? const <_MemberActivity>[];
            final a = list.isNotEmpty ? list.first : null;
            return _ActivityCard(
              title: a?.title ?? 'New Vehicle Acquisition',
              subtitle:
                  a?.subtitle ??
                  (stats.lastDepositCarName.trim().isEmpty
                      ? '—'
                      : stats.lastDepositCarName.trim()),
              points: a?.points ?? _pointsFromVnd(stats.investmentTotalVnd),
              dateHint: a?.paidAt ?? stats.lastDepositAt,
            );
          },
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _SmallRewardCard(
                icon: Icons.build_rounded,
                title: 'Full Detail\nService',
                subtitle: 'LuxeDrive Pro S1',
                points: 850,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _SmallRewardCard(
                icon: Icons.local_gas_station_rounded,
                title: 'Concierge\nFueling',
                subtitle: 'Premium 98 Octane',
                points: 120,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _ExclusiveCard(),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF10131B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MemberActivity {
  const _MemberActivity({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.paidAt,
  });
  final String title;
  final String subtitle;
  final int points;
  final Timestamp? paidAt;
}

class _SquareBadge extends StatelessWidget {
  const _SquareBadge({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1116),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: const Color(0xFF2F6FED)),
        ),
      ),
    );
  }
}

class _GoldStatusCard extends StatelessWidget {
  const _GoldStatusCard({
    required this.tier,
    required this.progressToNext,
    required this.nextTierName,
    required this.nextTierTargetVnd,
  });

  final _MemberTier tier;
  final double progressToNext;
  final String nextTierName;
  final int nextTierTargetVnd;

  @override
  Widget build(BuildContext context) {
    final moneyFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    final targetStr = moneyFmt.format(nextTierTargetVnd).trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tier.primary.withValues(alpha: 0.24),
            const Color(0xFF0F1116),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TierChip(label: tier.label, color: tier.primary),
              const SizedBox(width: 8),
              _TierChip(
                label: 'NEXT: $nextTierName • $targetStr VND',
                color: const Color(0xFFFFFFFF),
                soft: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressToNext,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(tier.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Membership Progress',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(progressToNext * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({
    required this.label,
    required this.color,
    this.soft = false,
  });
  final String label;
  final Color color;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft
            ? Colors.white.withValues(alpha: 0.06)
            : color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: soft
              ? Colors.white.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.40),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: soft ? Colors.white70 : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.points,
    this.dateHint,
  });
  final String title;
  final String subtitle;
  final int points;
  final Timestamp? dateHint;

  @override
  Widget build(BuildContext context) {
    final ptsFmt = NumberFormat.decimalPattern('vi_VN');
    final hint = dateHint;
    final dateStr = (hint == null)
        ? '—'
        : DateFormat('dd/MM/yyyy').format(hint.toDate());

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10131B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF2F6FED).withValues(alpha: 0.14),
              border: Border.all(
                color: const Color(0xFF2F6FED).withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2F6FED),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'POINTS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ptsFmt.format(points),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallRewardCard extends StatelessWidget {
  const _SmallRewardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final int points;

  @override
  Widget build(BuildContext context) {
    final ptsFmt = NumberFormat.compact(locale: 'en_US');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10131B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Text(
            '${ptsFmt.format(points)} pts',
            style: const TextStyle(
              color: Color(0xFF2F6FED),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExclusiveCard extends StatelessWidget {
  const _ExclusiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2F6FED).withValues(alpha: 0.22),
            const Color(0xFF7C6CFF).withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(
              Icons.diamond_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exclusive Experiences',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Unlock showroom events, private test drives, and concierge perks.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }
}

class _MemberSpendStats {
  const _MemberSpendStats({
    required this.investmentTotalVnd,
    required this.pointsBalance,
    required this.lastDepositAt,
    required this.lastDepositCarName,
  });

  final int investmentTotalVnd;
  final int pointsBalance;
  final Timestamp? lastDepositAt;
  final String lastDepositCarName;

  const _MemberSpendStats.zero()
    : investmentTotalVnd = 0,
      pointsBalance = 0,
      lastDepositAt = null,
      lastDepositCarName = '';
}

enum _MemberTier {
  silver('Silver', 0, Color(0xFFBFC7D5)),
  gold('Gold', 100000000, Color(0xFFF3C969)),
  diamond('Diamond', 500000000, Color(0xFF84D7FF));

  const _MemberTier(this.label, this.minSpendVnd, this.primary);

  final String label;
  final int minSpendVnd;
  final Color primary;

  static _MemberTier fromSpend(int spendVnd) {
    if (spendVnd >= _MemberTier.diamond.minSpendVnd) return _MemberTier.diamond;
    if (spendVnd >= _MemberTier.gold.minSpendVnd) return _MemberTier.gold;
    return _MemberTier.silver;
  }

  _MemberTier? get next {
    switch (this) {
      case _MemberTier.silver:
        return _MemberTier.gold;
      case _MemberTier.gold:
        return _MemberTier.diamond;
      case _MemberTier.diamond:
        return null;
    }
  }
}
