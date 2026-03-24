import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: Column(
          children: [
            // Header với back button và heart icon
            _buildHeader(),
            
            // Main content scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main car image
                    _buildMainImage(),
                    
                    // Card info + gallery (giống ảnh)
                    _buildInfoCard(),
                    
                    // Bottom spacing
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Bottom price and buy button
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
  color: const Color(0xFF2f2f2f),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const Spacer(),
          
          // Heart button
          IconButton(
            onPressed: () {
              setState(() {
                isFavorited = !isFavorited;
              });
            },
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(widget.carImages[selectedImageIndex]),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2f2f2f),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + brand icon circle
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    widget.carName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3a3a3a),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.carBrand.isNotEmpty ? widget.carBrand[0] : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // NEW + rating row
            Row(
              children: [
                if (widget.isNew)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (widget.isNew) const SizedBox(width: 10),
                const Icon(Icons.star, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${widget.rating} (${widget.reviewCount} đánh giá)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Text(
              'Mô tả chi tiết',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.carDescription,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Thư viện ảnh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.carImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImageIndex = index;
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 70,
                        height: 60,
                        child: Image.asset(
                          widget.carImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
    color: const Color(0xFF2f2f2f),
        boxShadow: [
          BoxShadow(
      color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Giá',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.carPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Buy button
          SizedBox(
            width: 120,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Handle buy action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đặt mua ${widget.carName} thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Đặt mua',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
