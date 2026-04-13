import 'package:flutter/material.dart';
import 'package:doan_cuoiki/models/car_detail.dart';
import 'package:doan_cuoiki/services/favorite_service.dart';
import 'package:doan_cuoiki/services/product_review_service.dart';
import 'package:doan_cuoiki/widgets/animation_hard.dart';

enum ReviewSortOption { newest, highestRated }

class DetailCarScreen extends StatefulWidget {
  final CarDetailData car;

  const DetailCarScreen({super.key, required this.car});

  @override
  State<DetailCarScreen> createState() => _DetailCarScreenState();
}

class _DetailCarScreenState extends State<DetailCarScreen> {
  bool isFavorited = false;
  int selectedImageIndex = 0;
  bool _isLoadingReviews = true;
  List<ProductReview> _reviews = <ProductReview>[];
  ReviewSortOption _reviewSort = ReviewSortOption.newest;

  static const _bg = Color.fromARGB(255, 18, 32, 47);
  static const _card = Color.fromARGB(255, 27, 42, 59);

  ProductReviewStats get _reviewStats {
    return ProductReviewService.calculateDisplayStats(
      baseRating: widget.car.rating,
      baseReviewCount: widget.car.reviewCount,
      approvedReviews: _reviews,
    );
  }

  double get _displayRating => _reviewStats.rating;

  int get _displayReviewCount => _reviewStats.reviewCount;

  List<ProductReview> get _sortedReviews {
    final sorted = <ProductReview>[..._reviews];
    sorted.sort((a, b) {
      if (_reviewSort == ReviewSortOption.highestRated) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimationHard(
                // Màn này tự vẽ header trong content (_buildHero),
                // nên không cần SliverAppBar.
                useSafeArea: false,
                bottomReserve: 0,
                bodyPadding: EdgeInsets.zero,
                bodySlivers: [
                  SliverToBoxAdapter(child: _buildHero()),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildInfoHeader()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildStatsGrid()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildDescriptionBlock()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildReviewSection()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildSpecRows()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildVideoPreview()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(child: _buildGalleryStrip()),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  // Chừa đáy cho CTA cố định.
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomCTA()),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
    _loadReviews();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFavoriteState() async {
    final favorited = await FavoriteService.isFavorite(
      widget.car.id,
      phoneIdentifier: widget.car.phoneNumber,
    );
    if (!mounted) return;
    setState(() => isFavorited = favorited);
  }

  Future<void> _toggleFavorite() async {
    final nextState = !isFavorited;
    setState(() => isFavorited = nextState);

    if (nextState) {
      await FavoriteService.addToFavorites(
        widget.car.toRouteArguments(),
        phoneIdentifier: widget.car.phoneNumber,
      );
    } else {
      await FavoriteService.removeFromFavorites(
        widget.car.id,
        phoneIdentifier: widget.car.phoneNumber,
      );
    }
  }

  Future<void> _loadReviews() async {
    final reviews = await ProductReviewService.getPublicReviews(widget.car.id);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _isLoadingReviews = false;
    });
  }

  Future<void> _showAddReviewSheet() async {
    final nameController = TextEditingController();
    final commentController = TextEditingController();
    double selectedRating = 5;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B2A3B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Đánh giá sản phẩm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tên của bạn',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF25354A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          onPressed: () {
                            setModalState(
                              () => selectedRating = star.toDouble(),
                            );
                          },
                          icon: Icon(
                            star <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Chia sẻ cảm nhận của bạn về mẫu xe này...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF25354A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final comment = commentController.text.trim();

                          if (comment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập nội dung đánh giá',
                                ),
                              ),
                            );
                            return;
                          }

                          await ProductReviewService.addReview(
                            widget.car.id,
                            ProductReview(
                              id: ProductReviewService.createReviewId(),
                              reviewerName: name.isEmpty ? 'Người dùng' : name,
                              comment: comment,
                              rating: selectedRating,
                              createdAt: DateTime.now(),
                              status: ReviewStatus.approved,
                            ),
                          );

                          if (!mounted) return;
                          Navigator.pop(context);
                          await _loadReviews();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Đánh giá đã gửi thành công.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            92,
                            140,
                            255,
                          ),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Gửi đánh giá',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildDetailImage(
            widget.car.images[selectedImageIndex],
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(170, 0, 0, 0),
                  Color.fromARGB(40, 0, 0, 0),
                  Color.fromARGB(215, 18, 32, 47),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: _roundIconButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _roundIconButton(
              icon: isFavorited ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorited ? Colors.red : Colors.white,
              onTap: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.car.brand.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.car.isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            0,
                            153,
                            255,
                          ).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color.fromARGB(
                              255,
                              0,
                              153,
                              255,
                            ).withOpacity(0.35),
                          ),
                        ),
                        child: const Text(
                          'MỚI',
                          style: TextStyle(
                            color: Color.fromARGB(255, 154, 216, 255),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.car.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.car.price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(height: 2),
              Text(
                _displayRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_displayReviewCount',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    final reviews = _sortedReviews;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Đánh giá từ người dùng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showAddReviewSheet,
                icon: const Icon(Icons.rate_review_rounded, size: 16),
                label: const Text('Viết đánh giá'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 154, 216, 255),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _reviewSortChip(
                label: 'Mới nhất',
                active: _reviewSort == ReviewSortOption.newest,
                onTap: () {
                  setState(() => _reviewSort = ReviewSortOption.newest);
                },
              ),
              _reviewSortChip(
                label: 'Điểm cao',
                active: _reviewSort == ReviewSortOption.highestRated,
                onTap: () {
                  setState(() => _reviewSort = ReviewSortOption.highestRated);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text(
                '${_displayRating.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($_displayReviewCount lượt)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (reviews.isEmpty)
            Text(
              'Chưa có đánh giá nào, hãy là người đầu tiên nhận xét mẫu xe này.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 12,
              ),
            )
          else
            Column(
              children: [
                ...reviews.take(3).map(_reviewTile),
                if (reviews.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _showAllReviewsSheet(reviews),
                      child: Text(
                        'Xem tất cả ${reviews.length} đánh giá',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 154, 216, 255),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _reviewSortChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color.fromARGB(255, 92, 140, 255)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? const Color.fromARGB(255, 120, 170, 255)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _reviewTile(ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final active = index < review.rating.round();
                  return Icon(
                    active ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.comment,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatReviewTime(review.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.52),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await ProductReviewService.reportReview(
                    carId: widget.car.id,
                    reviewId: review.id,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi báo cáo đánh giá.')),
                  );
                },
                icon: const Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color: Colors.orangeAccent,
                ),
                label: Text(
                  'Báo cáo',
                  style: TextStyle(
                    color: Colors.orangeAccent.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAllReviewsSheet(List<ProductReview> reviews) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1B2A3B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tất cả đánh giá',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return _reviewTile(reviews[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatReviewTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  Widget _buildStatsGrid() {
    // Tránh GridView(shrinkWrap) vì tốn layout khi nằm trong scroll lớn.
    // Dùng Wrap + SizedBox cố định chiều rộng để layout nhẹ hơn.
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = 16.0 * 2;
    final spacing = 12.0;
    final tileWidth = (width - horizontalPadding - spacing) / 2;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: tileWidth,
          child: _statTile(
            icon: Icons.bolt_rounded,
            title: '0-100 km/h',
            value: '3.2s',
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _statTile(
            icon: Icons.speed_rounded,
            title: 'Tốc độ tối đa',
            value: '321 km/h',
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _statTile(
            icon: Icons.electric_car_rounded,
            title: 'Tầm hoạt động',
            value: '580 km',
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _statTile(
            icon: Icons.auto_graph_rounded,
            title: 'Công suất',
            value: '1050 hp',
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tuyệt phẩm kỹ thuật',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.car.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              height: 1.35,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRows() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _specRow('Hộp số', widget.car.transmission ?? 'Đang cập nhật'),
          const SizedBox(height: 10),
          _specRow('Dẫn động', widget.car.driveType ?? 'Đang cập nhật'),
          const SizedBox(height: 10),
          _specRow('Số chỗ', widget.car.seats ?? 'Đang cập nhật'),
          const SizedBox(height: 10),
          _specRow('Động cơ', widget.car.engine ?? 'Đang cập nhật'),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildDetailImage(
                widget.car.images[selectedImageIndex],
                fit: BoxFit.cover,
              ),
              Container(color: Colors.black.withOpacity(0.28)),
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.24)),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  'Hình ảnh chi tiết xe'.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryStrip() {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.car.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == selectedImageIndex;
          return InkWell(
            onTap: () => setState(() => selectedImageIndex = index),
            child: Container(
              width: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 92, 140, 255)
                      : Colors.white.withOpacity(0.10),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildDetailImage(
                  widget.car.images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailImage(String image, {BoxFit fit = BoxFit.cover}) {
    final source = image.toString();
    if (source.toLowerCase().startsWith('http')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.directions_car,
                color: Colors.white30,
                size: 60,
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      source.isNotEmpty ? source : 'assets/images/products/car1.jpg',
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.directions_car, color: Colors.white30, size: 60),
          ),
        );
      },
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Row(
            children: [
              // Button ĐĂNG KÝ LÁI THỬ
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/bookcar',
                      arguments: {
                        'carName': widget.car.name,
                        'carBrand': widget.car.brand,
                        'carImage': widget.car.image,
                        'phoneNumber': widget.car.phoneNumber,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 92, 140, 255),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ĐĂNG KÝ LÁI THỬ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Button ĐẶT CỌC NGAY
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/deposit',
                      arguments: {
                        'carName': widget.car.name,
                        'carBrand': widget.car.brand,
                        'carImage': widget.car.image,
                        'carPrice': widget.car.price,
                        'phoneNumber': widget.car.phoneNumber,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 193, 7),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ĐẶT CỌC NGAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
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

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
