import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screen/banner_offer_screen.dart';

/// Banner management in Firestore.
///
/// Collection: `banners`
/// Document fields (recommended):
/// - isActive: bool
/// - sortOrder: number
/// - badge: string
/// - title: string
/// - subtitle: string
/// - buttonText: string
/// - image: string (asset path or url)
/// - accentColor: int (0xFFRRGGBB)
/// - subtitleColor: int (0xFFRRGGBB)
/// - gradientColors: List\<int\> (0xFFRRGGBB)
/// - description: string
/// - benefits: List\<string\>
/// - productId: string (products/{id})
/// - carModel: string (fallback matching)
/// - originalPrice, discountPrice, discountPercent: string (promotion pricing)
class BannerService {
  BannerService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('banners');

  Stream<List<Map<String, dynamic>>> watchActiveBanners() {
    return _col.where('isActive', isEqualTo: true).snapshots().map((snap) {
      final items = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      items.sort((a, b) {
        final aOrder = _sortOrderFromAny(a['sortOrder']);
        final bOrder = _sortOrderFromAny(b['sortOrder']);
        return aOrder.compareTo(bOrder);
      });
      return items;
    });
  }

  static int _sortOrderFromAny(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null) return parsed;
    }
    // Missing/invalid sortOrder goes to the end.
    return 1 << 30;
  }

  Future<void> ensureSeeded() async {
    // If empty -> seed defaults.
    final existing = await _col.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    for (final (i, item) in _defaultBannerDocs().indexed) {
      final doc = _col.doc('banner_${i + 1}');
      batch.set(doc, {...item, 'createdAt': now, 'updatedAt': now});
    }
    await batch.commit();
  }

  /// Map Firestore banner doc -> UI banner model used by HomeScreen.
  static BannerUiData toUiData(Map<String, dynamic> data) {
    final gradientRaw = (data['gradientColors'] as List?) ?? const [];
    final gradientColors = gradientRaw
        .whereType<num>()
        .map((e) => Color(e.toInt()))
        .toList();

    final accent = _colorFromAny(data['accentColor'], fallback: 0xFF55A7FF);
    final subtitleColor = _colorFromAny(
      data['subtitleColor'],
      fallback: 0xFF10B981,
    );

    return BannerUiData(
      badge: (data['badge'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      buttonText: (data['buttonText'] ?? 'Khám phá').toString(),
      image: (data['image'] ?? data['imageUrl'] ?? '').toString(),
      gradientColors: gradientColors.isNotEmpty
          ? gradientColors
          : const [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF21262D)],
      accentColor: accent,
      subtitleColor: subtitleColor,
      details: BannerOfferData(
        badge: (data['badge'] ?? '').toString(),
        title: (data['title'] ?? '').toString(),
        subtitle: (data['subtitle'] ?? '').toString(),
        image: (data['image'] ?? data['imageUrl'] ?? '').toString(),
        gradientColors:
            (gradientColors.isNotEmpty
                    ? gradientColors
                    : const [Color(0xFF55A7FF), Color(0xFF6EE7F9)])
                .toList(),
        accentColor: accent,
        description: (data['description'] ?? '').toString(),
        benefits: ((data['benefits'] as List?) ?? const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
        productId: (data['productId'] ?? '').toString().trim().isEmpty
            ? null
            : (data['productId'] ?? '').toString().trim(),
        carModel: (data['carModel'] ?? '').toString().trim().isEmpty
            ? null
            : (data['carModel'] ?? '').toString().trim(),
        originalPrice: (data['originalPrice'] ?? '').toString().trim().isEmpty
            ? null
            : (data['originalPrice'] ?? '').toString().trim(),
        discountPrice: (data['discountPrice'] ?? '').toString().trim().isEmpty
            ? null
            : (data['discountPrice'] ?? '').toString().trim(),
        discountPercent:
            (data['discountPercent'] ?? '').toString().trim().isEmpty
            ? null
            : (data['discountPercent'] ?? '').toString().trim(),
      ),
    );
  }

  static Color _colorFromAny(Object? v, {required int fallback}) {
    if (v is int) return Color(v);
    if (v is num) return Color(v.toInt());
    // allow hex string formats: "0xFF..." or "#RRGGBB" or "#AARRGGBB"
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return Color(fallback);
      try {
        if (s.startsWith('0x')) {
          return Color(int.parse(s.substring(2), radix: 16));
        }
        if (s.startsWith('#')) {
          final hex = s.substring(1);
          if (hex.length == 6) {
            return Color(int.parse('FF$hex', radix: 16));
          }
          if (hex.length == 8) {
            return Color(int.parse(hex, radix: 16));
          }
        }
      } catch (_) {
        // ignore -> fallback
      }
    }
    return Color(fallback);
  }

  static List<Map<String, dynamic>> _defaultBannerDocs() {
    // Using existing assets under assets/images/products/.
    return [
      {
        'isActive': true,
        'sortOrder': 1,
        'badge': '🚗 CAR EXPO 2026',
        'title': 'Future\nDriving',
        'subtitle': 'AI-Powered Smart Cars',
        'buttonText': 'Khám phá ngay',
        'image':
            'assets/images/products/BMW-8-Series_Gran_Coupe-2020-1280-0f678acd22736ee5d6145e8de467ff05e8.jpg',
        'gradientColors': [0xFF0D1117, 0xFF161B22, 0xFF21262D],
        'accentColor': 0xFF3B82F6,
        'subtitleColor': 0xFF10B981,
        'description':
            'Tham gia sự kiện Car Expo 2026 để nhận ưu đãi thuê xe sang với mức giá tốt nhất. Áp dụng cho số lượng giới hạn trong thời gian diễn ra chương trình.',
        'benefits': [
          'Giảm giá lên đến 20% cho lần thuê đầu tiên',
          'Tặng gói nâng cấp nội thất miễn phí',
          'Ưu tiên hỗ trợ 24/7',
        ],
        'productId': 'bmw_3_series_2019',
        'carModel': 'BMW 3 Series 2019',
        'originalPrice': '1.899.000.000đ',
        'discountPercent': '20%',
      },
      {
        'isActive': true,
        'sortOrder': 2,
        'badge': '⚡ ELECTRIC 2026',
        'title': 'Green\nRevolution',
        'subtitle': 'Zero Emission Cars',
        'buttonText': 'Tìm hiểu thêm',
        'image': 'assets/images/products/Tesla-Model-S-2020-1600-02.jpg',
        'gradientColors': [0xFF0F172A, 0xFF1E293B, 0xFF334155],
        'accentColor': 0xFF10B981,
        'subtitleColor': 0xFF06D6A0,
        'description':
            'Trải nghiệm dàn xe điện mới nhất với gói ưu đãi đặc biệt. Tiết kiệm chi phí vận hành và tận hưởng công nghệ hiện đại.',
        'benefits': [
          'Ưu đãi phí sạc tại đối tác',
          'Miễn phí kiểm tra xe trước chuyến đi',
          'Hỗ trợ kỹ thuật nhanh',
        ],
        'productId': 'tesla_cybertruck_2025',
        'carModel': 'Tesla Cybertruck 2025',
        'originalPrice': '2.091.538.525đ',
        'discountPercent': '12%',
      },
      {
        'isActive': true,
        'sortOrder': 3,
        'badge': '🏎️ LUXURY 2026',
        'title': 'Ultimate\nLuxury',
        'subtitle': 'Premium Experience',
        'buttonText': 'Xem ngay',
        'image':
            'assets/images/products/Mercedes-Benz-S-Class-2021-1600-01.jpg',
        'gradientColors': [0xFF1E1B4B, 0xFF312E81, 0xFF4C1D95],
        'accentColor': 0xFF8B5CF6,
        'subtitleColor': 0xFFF59E0B,
        'description':
            'Gói Premium mang đến trải nghiệm thuê xe cao cấp với quyền lợi ưu tiên, dịch vụ nhanh chóng và nhiều quà tặng hấp dẫn.',
        'benefits': [
          'Ưu tiên đặt xe giờ cao điểm',
          'Tặng 1 lần nâng hạng xe miễn phí/tháng',
          'Ưu đãi dịch vụ đưa đón',
        ],
        'productId': 'mercedes_amg_gt_coupe_2024',
        'carModel': 'Mercedes-Benz AMG GT Coupe 2024',
        'originalPrice': '8.500.000.000đ',
        'discountPercent': '8%',
      },
      {
        'isActive': true,
        'sortOrder': 4,
        'badge': '🚙 SUV 2026',
        'title': 'Adventure\nReady',
        'subtitle': 'Off-Road Champions',
        'buttonText': 'Khởi hành',
        'image': 'assets/images/products/Range-Rover-2022-1600-01.jpg',
        'gradientColors': [0xFF7C2D12, 0xFF9A3412, 0xFFEA580C],
        'accentColor': 0xFFEA580C,
        'subtitleColor': 0xFF22C55E,
        'description':
            'Khám phá các mẫu SUV mạnh mẽ với gói ưu đãi dành riêng cho hành trình xa. Trang bị thêm tiện ích để chuyến đi trọn vẹn.',
        'benefits': [
          'Tặng gói bảo hiểm mở rộng',
          'Miễn phí trang bị bộ cứu hộ tiêu chuẩn',
          'Giảm giá khi thuê dài ngày',
        ],
        'productId': 'toyota_land_cruiser_2021',
        'carModel': 'Toyota Land Cruiser 2021',
        'originalPrice': '4.030.000.000đ',
        'discountPercent': '10%',
      },
    ];
  }
}

/// Small UI-friendly join model for HomeScreen.
class BannerUiData {
  BannerUiData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.image,
    required this.gradientColors,
    required this.accentColor,
    required this.subtitleColor,
    required this.details,
  });

  final String badge;
  final String title;
  final String subtitle;
  final String buttonText;
  final String image;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color subtitleColor;
  final BannerOfferData details;
}
