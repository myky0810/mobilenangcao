import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class DetailCarScreen extends StatefulWidget {
  final String carName;
  final String carBrand;
  final String carImage;
  final String carPrice;
  final String carDescription;
  final List<String> carImages;
  final double rating;
  final int reviewCount;
  final bool isNew;
  final String? phoneNumber;

  const DetailCarScreen({
    super.key,
    required this.carName,
    required this.carBrand,
    required this.carImage,
    required this.carPrice,
    required this.carDescription,
    required this.carImages,
    required this.rating,
    required this.reviewCount,
    required this.isNew,
    this.phoneNumber,
  });

  @override
  State<DetailCarScreen> createState() => _DetailCarScreenState();
}

class _DetailCarScreenState extends State<DetailCarScreen> {
  bool isFavorited = false;
  int selectedImageIndex = 0;

  static const _bg = Color.fromARGB(255, 18, 32, 47);
  static const _card = Color.fromARGB(255, 27, 42, 59);

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _videoAsset;
  bool _isVideoReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildInfoHeader(),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatsGrid(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildDescriptionBlock(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSpecRows(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildVideoPreview(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildGalleryStrip(),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
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
    _initVideo();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    final asset = _brandToVideoAsset(widget.carBrand);
    if (asset == null) return;

    // Only enable the player if the asset exists in the bundle.
    final exists = await _assetExists(asset);
    if (!exists) return;

    final controller = VideoPlayerController.asset(asset);
    try {
      await controller.initialize();
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: true,
        showControlsOnInitialize: false,
        allowFullScreen: true,
        allowMuting: true,
      );

      if (!mounted) {
        chewie.dispose();
        controller.dispose();
        return;
      }

      setState(() {
        _videoAsset = asset;
        _videoController = controller;
        _chewieController = chewie;
        _isVideoReady = true;
      });
    } catch (_) {
      controller.dispose();
    }
  }

  String? _brandToVideoAsset(String brand) {
    // Temporary demo mode: you only added 1 video file.
    // So we map ALL brands to a single video to ensure the demo always plays.
    final b = brand.trim();
    if (b.isEmpty) return null;
    return 'assets/videos/mercedes.mp4';
  }

  Future<bool> _assetExists(String asset) async {
    try {
      await rootBundle.load(asset);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildHero() {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.carImages[selectedImageIndex], fit: BoxFit.cover),
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
              onTap: () => setState(() => isFavorited = !isFavorited),
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
                      widget.carBrand.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.isNew)
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
                          'NEW',
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
                  widget.carName.toUpperCase(),
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
                  widget.carPrice,
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
                widget.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.reviewCount}',
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

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.9,
      children: [
        _statTile(icon: Icons.bolt_rounded, title: '0-100 km/h', value: '3.2s'),
        _statTile(
          icon: Icons.speed_rounded,
          title: 'Tốc độ tối đa',
          value: '321 km/h',
        ),
        _statTile(
          icon: Icons.electric_car_rounded,
          title: 'Tầm hoạt động',
          value: '580 km',
        ),
        _statTile(
          icon: Icons.auto_graph_rounded,
          title: 'Công suất',
          value: '1050 hp',
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
            'The Engineering Marvel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.carDescription,
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
          _specRow('Transmission', 'Single-speed Direct Drive'),
          const SizedBox(height: 10),
          _specRow('Drive Type', 'All-Wheel Drive (AWD)'),
          const SizedBox(height: 10),
          _specRow('Seating Capacity', '4 Adults'),
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
          child: _isVideoReady && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.carImages[selectedImageIndex],
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    if (_videoAsset == null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Text(
                          'Chưa có video demo (thêm MP4 vào assets/videos)'
                              .toUpperCase(),
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
        itemCount: widget.carImages.length,
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
                child: Image.asset(widget.carImages[index], fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
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
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/bookcar',
                arguments: {
                  'carName': widget.carName,
                  'carBrand': widget.carBrand,
                  'carImage': widget.carImage,
                  'phoneNumber': widget.phoneNumber,
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
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
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
