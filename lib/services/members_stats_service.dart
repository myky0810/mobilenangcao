import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/firebase_helper.dart';

/// Aggregates Elite Members stats from Firestore and persists a compact summary.
///
/// Data sources in this repo:
/// - Deposits flow: `transactions` is the source of truth.
/// - `deposits` is treated as a legacy/projection fallback only.
/// - Test drive registration: `test_drive_bookings` collection.
///
/// Summary is stored at:
///   users/{normalizedPhone}/membersSummary/summary
///
/// So you can manage and query them easily in Firebase Console.
class MembersStatsService {
  MembersStatsService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? normalizeUserId(String? phoneNumber) {
    if (phoneNumber == null) return null;
    final id = FirebaseHelper.normalizePhone(phoneNumber);
    if (id.trim().isEmpty) return null;
    return id;
  }

  static DocumentReference<Map<String, dynamic>> summaryRef(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('membersSummary')
        .doc('summary');
  }

  /// Recompute from source collections and persist to summary doc.
  static Future<void> recomputeAndPersist({required String userId}) async {
    final normalized = normalizeUserId(userId) ?? userId;

    Future<QuerySnapshot<Map<String, dynamic>>?> safeGet(
      String collection,
    ) async {
      try {
        return await _db.collection(collection).get();
      } catch (_) {
        return null;
      }
    }

    final transactionsSnap = await safeGet('transactions');
    final depositsSnap = await safeGet('deposits');
    final testDriveSnap = await safeGet('test_drive_bookings');

    final paidFromTransactions = (transactionsSnap == null)
        ? _PaidAgg.empty()
        : _aggregatePaidTransactions(
            userId: normalized,
            snap: transactionsSnap,
          );

    final paidFromLegacyDeposits = (depositsSnap == null)
        ? _PaidAgg.empty()
        : _aggregateLegacyDeposits(
            userId: normalized,
            snap: depositsSnap,
            knownTransactionIds: paidFromTransactions.referenceIds,
          );

    final paidAgg = _PaidAgg(
      totalVnd: paidFromTransactions.totalVnd + paidFromLegacyDeposits.totalVnd,
      activities: [
        ...paidFromTransactions.activities,
        ...paidFromLegacyDeposits.activities,
      ],
      referenceIds: {
        ...paidFromTransactions.referenceIds,
        ...paidFromLegacyDeposits.referenceIds,
      },
    );

    final testDriveAgg = (testDriveSnap == null)
        ? _TestDriveAgg.empty()
        : _aggregateTestDrives(userId: normalized, snap: testDriveSnap);

    final totalInvestment = paidAgg.totalVnd;
    final pointsFromDeposits = (totalInvestment / 100000).floor();
    // Business rule: each test-drive registration counts as +1 point.
    final pointsFromTestDrives = testDriveAgg.count;
    final totalPoints = pointsFromDeposits + pointsFromTestDrives;

    final recent = <Map<String, dynamic>>[
      ...paidAgg.activities,
      ...testDriveAgg.activities,
    ];
    recent.sort((a, b) {
      final ad = (a['date'] as Timestamp?)?.toDate();
      final bd = (b['date'] as Timestamp?)?.toDate();
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    final lastActiveAt = recent.isNotEmpty ? recent.first['date'] : null;

    await summaryRef(normalized).set({
      'userId': normalized,
      'totalInvestmentVnd': totalInvestment,
      'points': totalPoints,
      'pointsFromDeposits': pointsFromDeposits,
      'pointsFromTestDrives': pointsFromTestDrives,
      'testDriveCount': testDriveAgg.count,
      'lastActiveAt': lastActiveAt,
      'recentActivities': recent.take(15).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static _PaidAgg _aggregatePaidTransactions({
    required String userId,
    required QuerySnapshot<Map<String, dynamic>> snap,
  }) {
    var total = 0.0;
    final activities = <Map<String, dynamic>>[];
    final referenceIds = <String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      if (!_isDepositTransaction(data)) continue;

      final rawPhone =
          (data['customerPhone'] ?? data['userPhone'] ?? data['phoneNumber'])
              ?.toString();
      if (rawPhone == null || rawPhone.trim().isEmpty) continue;
      if (FirebaseHelper.normalizePhone(rawPhone) != userId) continue;

      if (!_isPaid(data)) continue;

      final amountRaw = data['amount'] ?? data['depositAmount'] ?? 0;
      final amount = _toDouble(amountRaw);
      if (amount <= 0) continue;

      total += amount;

      final txId = (data['transactionId'] ?? doc.id).toString().trim();
      if (txId.isNotEmpty) {
        referenceIds.add(txId);
      }

      final ts = _bestTimestamp(data, ['paidAt', 'updatedAt', 'createdAt']);
      if (ts != null) {
        activities.add({
          'type': 'deposit',
          'refCollection': 'transactions',
          'refId': doc.id,
          'amountVnd': amount,
          'date': ts,
        });
      }
    }

    return _PaidAgg(
      totalVnd: total,
      activities: activities,
      referenceIds: referenceIds,
    );
  }

  static _PaidAgg _aggregateLegacyDeposits({
    required String userId,
    required QuerySnapshot<Map<String, dynamic>> snap,
    required Set<String> knownTransactionIds,
  }) {
    var total = 0.0;
    final activities = <Map<String, dynamic>>[];
    final referenceIds = <String>{};

    for (final doc in snap.docs) {
      final data = doc.data();

      final rawPhone =
          (data['customerPhone'] ?? data['userPhone'] ?? data['phoneNumber'])
              ?.toString();
      if (rawPhone == null || rawPhone.trim().isEmpty) continue;
      if (FirebaseHelper.normalizePhone(rawPhone) != userId) continue;

      final txId = (data['transactionId'] ?? data['depositId'] ?? '')
          .toString()
          .trim();
      if (txId.isNotEmpty && knownTransactionIds.contains(txId)) {
        continue;
      }

      if (!_isPaid(data)) continue;

      final amountRaw =
          data['depositAmount'] ?? data['amount'] ?? data['totalAmount'] ?? 0;
      final amount = _toDouble(amountRaw);
      if (amount <= 0) continue;

      total += amount;
      if (txId.isNotEmpty) {
        referenceIds.add(txId);
      }

      final ts = _bestTimestamp(data, [
        'depositDate',
        'paidAt',
        'updatedAt',
        'createdAt',
      ]);
      if (ts != null) {
        activities.add({
          'type': 'deposit',
          'refCollection': 'deposits',
          'refId': doc.id,
          'amountVnd': amount,
          'date': ts,
        });
      }
    }

    return _PaidAgg(
      totalVnd: total,
      activities: activities,
      referenceIds: referenceIds,
    );
  }

  static bool _isDepositTransaction(Map<String, dynamic> data) {
    final kind = (data['kind'] ?? data['type'] ?? data['flow'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (kind == 'deposit' || kind == 'car_deposit') return true;

    final transferContent = (data['transferContent'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (transferContent.contains('dat coc') ||
        transferContent.contains('đặt cọc')) {
      return true;
    }

    final hasCar = (data['carName'] ?? '').toString().trim().isNotEmpty;
    final hasContact = (data['customerPhone'] ?? data['userPhone'] ?? '')
        .toString()
        .trim()
        .isNotEmpty;
    final amount = _toDouble(
      data['amount'] ?? data['depositAmount'] ?? data['totalAmount'],
    );

    return hasCar && hasContact && amount > 0;
  }

  static bool _isPaid(Map<String, dynamic> data) {
    final paymentStatus =
        (data['paymentStatus'] ?? data['status'] ?? data['depositStatus'])
            .toString()
            .toLowerCase();
    return paymentStatus == 'paid' ||
        paymentStatus == 'success' ||
        paymentStatus == 'completed' ||
        paymentStatus == 'confirmed';
  }

  static double _toDouble(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  static _TestDriveAgg _aggregateTestDrives({
    required String userId,
    required QuerySnapshot<Map<String, dynamic>> snap,
  }) {
    var count = 0;
    final activities = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      final rawPhone = (data['userPhone'] ?? data['phone'])?.toString();
      if (rawPhone == null || rawPhone.trim().isEmpty) continue;
      if (FirebaseHelper.normalizePhone(rawPhone) != userId) continue;

      count += 1;

      final ts = _bestTimestamp(data, ['createdAt', 'updatedAt', 'date']);
      if (ts != null) {
        activities.add({
          'type': 'test_drive',
          'refCollection': 'test_drive_bookings',
          'refId': doc.id,
          'date': ts,
        });
      }
    }

    return _TestDriveAgg(count: count, activities: activities);
  }

  static Timestamp? _bestTimestamp(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final k in keys) {
      final v = data[k];
      final ts = _toTimestamp(v);
      if (ts != null) return ts;
    }
    return null;
  }

  static Timestamp? _toTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v;
    if (v is DateTime) return Timestamp.fromDate(v);
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    return Timestamp.fromDate(dt);
  }
}

class _PaidAgg {
  _PaidAgg({
    required this.totalVnd,
    required this.activities,
    required this.referenceIds,
  });

  factory _PaidAgg.empty() =>
      _PaidAgg(totalVnd: 0, activities: const [], referenceIds: const {});

  final double totalVnd;
  final List<Map<String, dynamic>> activities;
  final Set<String> referenceIds;
}

class _TestDriveAgg {
  _TestDriveAgg({required this.count, required this.activities});

  factory _TestDriveAgg.empty() =>
      _TestDriveAgg(count: 0, activities: const []);

  final int count;
  final List<Map<String, dynamic>> activities;
}
