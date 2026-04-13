import 'package:flutter/material.dart';

/// Widget gallery swipe cho card xe - dùng chung cho tất cả màn hình
class CarImageSlider extends StatefulWidget {
  final List<String> images;
  final double height;
  final BorderRadius? borderRadius;

  const CarImageSlider({
    super.key,
    required this.images,
    this.height = 200,
    this.borderRadius,
  });

  @override
  State<CarImageSlider> createState() => _CarImageSliderState();
}

class _CarImageSliderState extends State<CarImageSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  bool _isNetworkImage(String path) {
    final p = path.trim().toLowerCase();
    return p.startsWith('http://') || p.startsWith('https://');
  }

  Widget _buildImage(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.directions_car, color: Colors.white24, size: 60),
        ),
      );
    }

    final imageWidget = _isNetworkImage(normalized)
        ? Image.network(
            normalized,
            width: double.infinity,
            height: widget.height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.white24,
                    size: 60,
                  ),
                ),
              );
            },
          )
        : Image.asset(
            normalized,
            width: double.infinity,
            height: widget.height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.white24,
                    size: 60,
                  ),
                ),
              );
            },
          );

    return RepaintBoundary(child: imageWidget);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isNotEmpty
        ? widget.images.where((e) => e.trim().isNotEmpty).toList()
        : <String>[];
    final radius =
        widget.borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(12));

    if (_currentIndex >= images.length && images.isNotEmpty) {
      _currentIndex = 0;
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // PageView hình ảnh
          ClipRRect(
            borderRadius: radius,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _buildImage(images[index]);
              },
            ),
          ),

          // Nếu không có ảnh thì show placeholder
          if (images.isEmpty)
            ClipRRect(
              borderRadius: radius,
              child: Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.white24,
                    size: 60,
                  ),
                ),
              ),
            ),

          // Chỉ số trang (dots) ở góc dưới phải - chỉ hiện nếu có nhiều hơn 1 ảnh
          if (images.length > 1)
            Positioned(
              bottom: 10,
              right: 0,
              left: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.45),
                    ),
                  );
                }),
              ),
            ),

          // Mũi tên trái (chỉ hiện khi có nhiều hơn 1 ảnh và không phải đầu)
          if (images.length > 1 && _currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Mũi tên phải (chỉ hiện khi không phải ảnh cuối)
          if (images.length > 1 && _currentIndex < images.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
