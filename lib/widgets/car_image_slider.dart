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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isNotEmpty ? widget.images : [''];
    final radius =
        widget.borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(12));

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
                return Image.asset(
                  images[index],
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
              },
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
