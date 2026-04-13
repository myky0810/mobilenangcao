import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_api_service.dart';

class EndowScreen extends StatefulWidget {
  const EndowScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<EndowScreen> createState() => _EndowScreenState();
}

class _EndowScreenState extends State<EndowScreen> {
  int _activeNavIndex = 1; // Index cho Ưu đãi (index 1)
  final NotificationApiService _notificationService = NotificationApiService();
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  Map<String, List<NotificationModel>> _notificationsByDate = {};
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenToNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getNotificationsByDate(
        userPhone: widget.phoneNumber,
      );
      final unreadCount = await _notificationService.getUnreadCount(
        userPhone: widget.phoneNumber,
      );
      setState(() {
        _notificationsByDate = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _listenToNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = _notificationService.notificationStream.listen((
      notifications,
    ) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingBody() : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF333333),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: widget.phoneNumber,
        ),
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
      ),
      title: Row(
        children: [
          const Text(
            'Ưu đãi & Khuyến mãi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: _loadNotifications,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLoadingBody() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      backgroundColor: const Color(0xFF333333),
      color: Colors.orange,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Hot Promotions section
          _buildHotPromotionsSection(),

          // Notifications by date
          ..._notificationsByDate.entries.map((entry) {
            final sectionTitle = entry.key;
            final notifications = entry.value;

            if (notifications.isEmpty) return const SizedBox.shrink();

            return Column(
              children: [
                _buildSectionHeader(sectionTitle),
                ...notifications
                    .map((notification) => _buildNotificationItem(notification))
                    .toList(),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Current UI is built in _buildLoadingBody() (it already includes RefreshIndicator + sections).
    // Keep this wrapper so the Scaffold can toggle _isLoading cleanly.
    return _buildLoadingBody();
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: const Color(0xFF333333),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (title == 'Hôm nay') ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'HOT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHotPromotionsSection() {
    return FutureBuilder<List<NotificationModel>>(
      future: _notificationService.getHotPromotions(
        userPhone: widget.phoneNumber,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF333333),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ưu đãi nóng hổi 🔥',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return _buildHotPromotionCard(snapshot.data![index]);
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildHotPromotionCard(NotificationModel notification) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(notification.getIcon(), color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      notification.discountPercent ?? '0%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.flash_on, color: Colors.yellow, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.carModel ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (notification.originalPrice != null) ...[
                      Text(
                        notification.originalPrice!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (notification.discountPrice != null)
                      Text(
                        notification.discountPrice!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      color: notification.isRead
          ? const Color(0xFF333333)
          : const Color(0xFF3a3a3a),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.getColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: notification.getColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    notification.getIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.description,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (notification.carModel != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                notification.carModel!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            notification.getTimeAgo(),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (notification.discountPercent != null)
                            Text(
                              'Giảm ${notification.discountPercent}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action button
                IconButton(
                  onPressed: () => _showNotificationOptions(notification),
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.local_offer_rounded, 1), // Icon Ưu đãi Active
            _buildNavItem(Icons.directions_car_rounded, 2),
            _buildNavItem(Icons.favorite_rounded, 3),
            _buildNavItem(Icons.person_rounded, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        if (_activeNavIndex == index) return;
        setState(() {
          _activeNavIndex = index;
        });
        // Điều hướng tới các màn hình tương ứng.
        if (index == 0) {
          // Home
          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: widget.phoneNumber,
          );
        } else if (index == 2) {
          // Xe mới
          Navigator.pushReplacementNamed(
            context,
            '/newcar',
            arguments: widget.phoneNumber,
          );
        } else if (index == 3) {
          // Favorite
          Navigator.pushReplacementNamed(
            context,
            '/favorite',
            arguments: widget.phoneNumber,
          );
        } else if (index == 4) {
          // Profile
          Navigator.pushReplacementNamed(
            context,
            '/profile',
            arguments: widget.phoneNumber,
          );
        }
        // Index 1 là trang hiện tại (Endow)
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isActive ? 56 : 50,
        height: isActive ? 56 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(
                  colors: [const Color(0xFF3b82c8), const Color(0xFF1e5a9e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3b82c8).withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: isActive ? 28 : 26,
            ),
          ),
        ),
      ),
    );
  }

  // Xử lý khi nhấn vào thông báo
  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      _loadNotifications();
    }

    if (_isDirectChatNotification(notification)) {
      _openDirectChat(notification);
      return;
    }

    if (notification.type.toLowerCase() == 'promotion') {
      await _openPromotionProduct(notification);
      return;
    }

    // Hiển thị chi tiết thông báo
    _showNotificationDetails(notification);
  }

  bool _isDirectChatNotification(NotificationModel notification) {
    final type = notification.type.toLowerCase();
    return type == 'admin_message' || type == 'chat_approved';
  }

  void _openDirectChat(NotificationModel notification) {
    final chatId = (notification.bannerKey ?? '').trim();
    final fallbackPhone = (widget.phoneNumber ?? '').trim();
    final resolvedChatId = chatId.isNotEmpty ? chatId : fallbackPhone;
    if (resolvedChatId.isEmpty) return;

    Navigator.pushNamed(
      context,
      '/direct_chat',
      arguments: {
        'phoneNumber': widget.phoneNumber,
        'chatId': resolvedChatId,
        'chatTitle': 'Tư vấn viên hỗ trợ',
      },
    );
  }

  Future<void> _openPromotionProduct(NotificationModel notification) async {
    final messenger = ScaffoldMessenger.of(context);
    final product = await _findProductForPromotion(notification);

    if (product == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy xe phù hợp với thông báo ưu đãi này'),
        ),
      );
      return;
    }

    final originalPrice =
        (product['price'] ?? product['carPrice'] ?? '').toString().trim();
    final discountedPrice = _resolveDiscountedPrice(
      originalPrice: originalPrice,
      discountPercent: notification.discountPercent,
      fallbackDiscountPrice: notification.discountPrice,
    );

    final carName =
        (product['name'] ?? product['carName'] ?? notification.carModel ?? '')
            .toString();
    final carBrand =
        (product['brand'] ?? product['brandName'] ?? product['carBrand'] ?? '')
            .toString();
    final carImage =
        (product['image'] ?? product['carImage'] ?? notification.imageUrl ?? '')
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
      'phoneNumber': widget.phoneNumber,
      'promoNotificationId': notification.id,
      'promoDiscountPercent': notification.discountPercent,
      'promoOriginalPrice': originalPrice,
    };

    if (!mounted) return;
    Navigator.pushNamed(context, '/detailcar', arguments: args);
  }

  Future<Map<String, dynamic>?> _findProductForPromotion(
    NotificationModel notification,
  ) async {
    final products = FirebaseFirestore.instance.collection('products');

    final productId = (notification.productId ?? '').trim();
    if (productId.isNotEmpty) {
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

    final imageUrl = (notification.imageUrl ?? '').trim();
    final carModel = (notification.carModel ?? '').trim();

    if (imageUrl.isNotEmpty) {
      final byImage = await products.where('image', isEqualTo: imageUrl).limit(1).get();
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
      final byName = await products.where('name', isEqualTo: carModel).limit(1).get();
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

    for (final doc in allDocs.docs) {
      final data = doc.data();
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

  // Hiển thị menu tùy chọn thông báo
  void _showNotificationOptions(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF333333),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text(
                'Xem chi tiết',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDetails(notification);
              },
            ),
            ListTile(
              leading: Icon(
                notification.isRead
                    ? Icons.mark_as_unread
                    : Icons.mark_email_read,
                color: Colors.orange,
              ),
              title: Text(
                notification.isRead ? 'Đánh dấu chưa đọc' : 'Đánh dấu đã đọc',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (notification.isRead) {
                  _notificationService.markAsUnread(notification.id);
                } else {
                  _notificationService.markAsRead(notification.id);
                }
                _loadNotifications();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Xóa thông báo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _notificationService.deleteNotification(notification.id);
                _loadNotifications();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị hộp thoại chi tiết thông báo
  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    notification.getIcon(),
                    color: notification.getColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notification.description,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (notification.carModel != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin xe',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Model: ${notification.carModel}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (notification.originalPrice != null)
                        Text(
                          'Giá gốc: ${notification.originalPrice}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      if (notification.discountPrice != null)
                        Text(
                          'Giá ưu đãi: ${notification.discountPrice}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (notification.discountPercent != null)
                        Text(
                          'Giảm: ${notification.discountPercent}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    notification.getTimeAgo(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      if (_isDirectChatNotification(notification)) {
                        _openDirectChat(notification);
                        return;
                      }
                      if (notification.type.toLowerCase() == 'promotion') {
                        await _openPromotionProduct(notification);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      notification.type.toLowerCase() == 'promotion'
                          ? 'Xem xe ưu đãi'
                          : (_isDirectChatNotification(notification)
                                ? 'Mở chat trực tiếp'
                                : 'Đóng'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
