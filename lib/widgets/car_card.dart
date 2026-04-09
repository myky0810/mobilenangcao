import 'package:flutter/material.dart';
import 'package:doan_cuoiki/models/car_detail.dart';
import '../services/favorite_service.dart';
import '../services/product_review_service.dart';
import 'car_image_slider.dart';

class CarCard extends StatefulWidget {
  final String id;
  final String name;
  final String brand;
  final String price;
  final String priceNote;
  final String image;
  final List<String> gallery;
  final double rating;
  final int reviewCount;
  final String? phoneNumber;
  final bool isNew;
  final String description;
  final VoidCallback? onTap;
  final bool showBrandBadge;

  const CarCard({
    super.key,
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.priceNote,
    required this.image,
    this.gallery = const [],
    this.rating = 4.5,
    this.reviewCount = 50,
    this.phoneNumber,
    this.isNew = false,
    this.description = '',
    this.onTap,
    this.showBrandBadge = true,
  });

  factory CarCard.fromMap(
    Map<String, dynamic> map, {
    String? phoneNumber,
    VoidCallback? onTap,
    bool showBrandBadge = true,
  }) {
    return CarCard(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String,
      price: map['price'] as String,
      priceNote: map['priceNote'] as String? ?? 'Liên hệ',
      image: map['image'] as String,
      gallery: (map['gallery'] as List<String>?) ?? [map['image'] as String],
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as int?) ?? 50,
      isNew: map['isNew'] as bool? ?? false,
      description: map['description'] as String? ?? '',
      phoneNumber: phoneNumber,
      onTap: onTap,
      showBrandBadge: showBrandBadge,
    );
  }

  @override
  State<CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<CarCard> {
  bool _isFavorite = false;
  late double _displayRating;
  late int _displayReviewCount;

  @override
  void initState() {
    super.initState();
    _displayRating = widget.rating;
    _displayReviewCount = widget.reviewCount;
    _checkFavoriteStatus();
    _loadReviewStats();
  }

  @override
  void didUpdateWidget(covariant CarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.rating != widget.rating ||
        oldWidget.reviewCount != widget.reviewCount) {
      _displayRating = widget.rating;
      _displayReviewCount = widget.reviewCount;
      _loadReviewStats();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final favorites = await FavoriteService.getFavorites(
      phoneIdentifier: widget.phoneNumber,
    );
    if (!mounted) return;

    setState(() {
      _isFavorite = favorites.any((fav) => fav['id'] == widget.id);
    });
  }

  Future<void> _loadReviewStats() async {
    final approvedReviews = await ProductReviewService.getPublicReviews(
      widget.id,
    );
    if (!mounted) return;

    final stats = ProductReviewService.calculateDisplayStats(
      baseRating: widget.rating,
      baseReviewCount: widget.reviewCount,
      approvedReviews: approvedReviews,
    );

    setState(() {
      _displayRating = stats.rating;
      _displayReviewCount = stats.reviewCount;
    });
  }

  Future<void> _toggleFavorite() async {
    try {
      final carData = {
        'id': widget.id,
        'name': widget.name,
        'brand': widget.brand,
        'price': widget.price,
        'priceNote': widget.priceNote,
        'image': widget.image,
        'gallery': widget.gallery,
        'rating': _displayRating,
        'reviewCount': _displayReviewCount,
        'isNew': widget.isNew,
        'description': widget.description,
      };

      if (_isFavorite) {
        await FavoriteService.removeFromFavorites(
          widget.id,
          phoneIdentifier: widget.phoneNumber,
        );
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          _showSnackBar('Đã xóa khỏi danh sách yêu thích');
        }
      } else {
        await FavoriteService.addToFavorites(
          carData,
          phoneIdentifier: widget.phoneNumber,
        );
        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
          _showSnackBar('Đã thêm vào danh sách yêu thích');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi khi cập nhật yêu thích: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, [Color backgroundColor = Colors.green]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleTap() async {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      final detailData = CarDetailData(
        id: widget.id,
        name: widget.name,
        brand: widget.brand,
        image: widget.image,
        price: widget.price,
        description: widget.description.isNotEmpty
            ? widget.description
            : 'Xe ${widget.name} từ ${widget.brand} với chất lượng cao và trang bị hiện đại.',
        images: widget.gallery.isNotEmpty ? widget.gallery : [widget.image],
        reviewCount: _displayReviewCount,
        rating: _displayRating,
        isNew: widget.isNew,
        phoneNumber: widget.phoneNumber,
      );

      await Navigator.pushNamed(context, '/detailcar', arguments: detailData);

      // Refresh state when returning from detail (favorite + latest reviews).
      await _checkFavoriteStatus();
      await _loadReviewStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with overlay
            Stack(
              children: [
                // Car image slider
                CarImageSlider(
                  images: widget.gallery.isNotEmpty
                      ? widget.gallery
                      : [widget.image],
                  height: 200,
                ),

                // Gradient overlay
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color.fromRGBO(0, 0, 0, 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Brand badge (optional)
                if (widget.showBrandBadge)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        widget.brand.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Favorite button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Rating badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _displayRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, color: Colors.orange, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          '($_displayReviewCount)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // New badge
                if (widget.isNew)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Car info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Brand name (if brand badge is hidden)
                  if (!widget.showBrandBadge)
                    Text(
                      widget.brand,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),

                  if (!widget.showBrandBadge) const SizedBox(height: 8),

                  // Price
                  Text(
                    widget.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Price note
                  Text(
                    widget.priceNote,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
