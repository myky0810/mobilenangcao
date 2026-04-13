import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerOfferData {
  final String badge;
  final String title;
  final String subtitle;
  final String image;
  final List<Color> gradientColors;
  final Color accentColor;
  final String description;
  final List<String> benefits;
  final String? productId;
  final String? carModel;
  final String? originalPrice;
  final String? discountPrice;
  final String? discountPercent;

  const BannerOfferData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.gradientColors,
    required this.accentColor,
    required this.description,
    required this.benefits,
    this.productId,
    this.carModel,
    this.originalPrice,
    this.discountPrice,
    this.discountPercent,
  });
}

class BannerOfferScreen extends StatelessWidget {
  const BannerOfferScreen({super.key, required this.offer, this.phoneNumber});

  final BannerOfferData offer;
  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0E12),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Chi tiết ưu đãi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 16),
          _buildDescriptionCard(),
          const SizedBox(height: 14),
          _buildBenefitsCard(),
          const SizedBox(height: 20),
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildOfferImage(offer.image),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.84),
                    Colors.black.withOpacity(0.18),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    offer.gradientColors.first.withOpacity(0.56),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: offer.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: offer.accentColor.withOpacity(0.6),
                      ),
                    ),
                    child: Text(
                      offer.badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    offer.title.replaceAll('\n', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    offer.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferImage(String source) {
    final isNetworkImage =
        source.startsWith('http://') || source.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageFallback(),
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImageFallback(),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFF1A2233),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_rounded,
        color: Colors.white54,
        size: 56,
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF223049)),
      ),
      child: Text(
        offer.description,
        style: const TextStyle(
          color: Color(0xFFD6DEEA),
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF223049)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quyền lợi ưu đãi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...offer.benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF4ADE80),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        color: Color(0xFFC7D2E3),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () => _handleReceiveOffer(context),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: offer.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Nhận mã ưu đãi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _handleReceiveOffer(BuildContext context) async {
    final product = await _findPromotionProduct();
    if (product == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy xe phù hợp từ banner này'),
        ),
      );
      return;
    }

    final originalPrice =
        (offer.originalPrice ?? product['price'] ?? product['carPrice'] ?? '')
            .toString()
            .trim();
    final discountedPrice = _resolveDiscountedPrice(
      originalPrice: originalPrice,
      discountPercent: offer.discountPercent,
      fallbackDiscountPrice: offer.discountPrice,
    );

    final carName =
        (product['name'] ?? product['carName'] ?? offer.carModel ?? '')
            .toString();
    final carBrand =
        (product['brand'] ?? product['brandName'] ?? product['carBrand'] ?? '')
            .toString();
    final carImage = (product['image'] ?? product['carImage'] ?? offer.image)
        .toString();

    final args = <String, dynamic>{
      ...product,
      'id': (product['id'] ?? '').toString().isNotEmpty
          ? product['id']
          : product['docId'],
      'carName': carName,
      'name': carName,
      'carBrand': carBrand,
      'brand': carBrand,
      'carImage': carImage,
      'image': carImage,
      'carPrice': discountedPrice,
      'price': discountedPrice,
      'phoneNumber': phoneNumber,
      'promoDiscountPercent': offer.discountPercent,
      'promoOriginalPrice': originalPrice,
      'promoSource': 'banner',
    };

    if (!context.mounted) return;
    Navigator.pushNamed(context, '/detailcar', arguments: args);
  }

  Future<Map<String, dynamic>?> _findPromotionProduct() async {
    final products = FirebaseFirestore.instance.collection('products');

    final productIdCandidates = _expandProductIdCandidates(offer.productId);

    for (final productId in productIdCandidates) {
      final byId = await products.doc(productId).get();
      if (byId.exists && byId.data() != null) {
        return {'docId': byId.id, ...byId.data()!};
      }
    }

    Map<String, dynamic>? firstOrNull(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return {'docId': doc.id, ...doc.data()};
    }

    for (final productId in productIdCandidates) {
      final byFieldId = await products
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();
      final byFieldIdMatch = firstOrNull(byFieldId);
      if (byFieldIdMatch != null) return byFieldIdMatch;
    }

    final imageUrl = offer.image.trim();
    final carModel = (offer.carModel ?? '').trim();

    if (imageUrl.isNotEmpty) {
      final byImage = await products
          .where('image', isEqualTo: imageUrl)
          .limit(1)
          .get();
      final byImageMatch = firstOrNull(byImage);
      if (byImageMatch != null) return byImageMatch;

      final byCarImage = await products
          .where('carImage', isEqualTo: imageUrl)
          .limit(1)
          .get();
      final byCarImageMatch = firstOrNull(byCarImage);
      if (byCarImageMatch != null) return byCarImageMatch;

      final byGallery = await products
          .where('gallery', arrayContains: imageUrl)
          .limit(1)
          .get();
      final byGalleryMatch = firstOrNull(byGallery);
      if (byGalleryMatch != null) return byGalleryMatch;
    }

    if (carModel.isNotEmpty) {
      final byName = await products
          .where('name', isEqualTo: carModel)
          .limit(1)
          .get();
      final byNameMatch = firstOrNull(byName);
      if (byNameMatch != null) return byNameMatch;

      final byCarName = await products
          .where('carName', isEqualTo: carModel)
          .limit(1)
          .get();
      final byCarNameMatch = firstOrNull(byCarName);
      if (byCarNameMatch != null) return byCarNameMatch;
    }

    final allDocs = await products.limit(300).get();
    final normalizedCarModel = _normalizeText(carModel);
    final normalizedProductIds = productIdCandidates
        .map(_normalizeText)
        .where((value) => value.isNotEmpty)
        .toSet();

    for (final doc in allDocs.docs) {
      final data = doc.data();
      final normalizedDocId = _normalizeText(doc.id);
      final normalizedDataId = _normalizeText(
        (data['id'] ?? data['productId'] ?? '').toString(),
      );

      if (normalizedProductIds.contains(normalizedDocId) ||
          normalizedProductIds.contains(normalizedDataId)) {
        return {'docId': doc.id, ...data};
      }

      final candidateName = _normalizeText(
        (data['name'] ?? data['carName'] ?? '').toString(),
      );
      if (normalizedCarModel.isNotEmpty &&
          (candidateName.contains(normalizedCarModel) ||
              normalizedCarModel.contains(candidateName))) {
        return {'docId': doc.id, ...data};
      }
    }

    return null;
  }

  List<String> _expandProductIdCandidates(String? rawProductId) {
    final raw = (rawProductId ?? '').trim();
    if (raw.isEmpty) return const [];

    final values = <String>{};

    void addCandidate(String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        values.add(trimmed);
      }
    }

    addCandidate(raw);

    final pathParts = raw
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (pathParts.isNotEmpty) {
      addCandidate(pathParts.last);
    }

    if (raw.toLowerCase().startsWith('products/')) {
      addCandidate(raw.substring('products/'.length));
    }

    return values.toList();
  }

  String _normalizeText(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _resolveDiscountedPrice({
    required String originalPrice,
    String? discountPercent,
    String? fallbackDiscountPrice,
  }) {
    final original = _parseCurrencyToInt(originalPrice);
    final percent = _parsePercent(discountPercent);

    if (original != null && percent != null && percent > 0) {
      final discounted = (original * (100 - percent) / 100).round();
      return _formatCurrency(discounted);
    }

    final fallback = (fallbackDiscountPrice ?? '').trim();
    if (fallback.isNotEmpty) return fallback;
    return originalPrice;
  }

  int? _parseCurrencyToInt(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  double? _parsePercent(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final match = RegExp(r'[0-9]+([.,][0-9]+)?').firstMatch(value);
    if (match == null) return null;
    final normalized = match.group(0)!.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatCurrency(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remain = digits.length - i - 1;
      if (remain > 0 && remain % 3 == 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }
}
