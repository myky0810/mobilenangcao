import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_api_service.dart';
import '../services/notification_manager.dart';
import '../models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationApiService _notificationService = NotificationApiService();
  final NotificationManager _notificationManager = NotificationManager();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  static const Color _pageBg = Color(0xFF252525);
  static const List<Color> _pageBgGradient = [
    Color(0xFF545454),
    Color(0xFF3A3A3A),
    Color(0xFF252525),
    Color(0xFF171717),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationService.getAllNotifications(
        userPhone: widget.phoneNumber,
      );
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      // Keep the app-wide badge in sync with whatever we just loaded
      await _notificationManager.checkUnreadNotifications(
        userPhone: widget.phoneNumber,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _pageBg,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _pageBgGradient,
            stops: [0.0, 0.35, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo nào',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo mới sẽ xuất hiện ở đây',
            style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Làm mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A3A3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      backgroundColor: _pageBg,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index == 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Mới nhất',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildNotificationCard(notification),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? const Color(0xFF121212)
            : const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.14),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        if (notification.discountPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Giá: ${notification.discountPrice}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'promotion':
        return Icons.local_offer;
      case 'discount':
        return Icons.discount;
      case 'news':
        return Icons.article;
      case 'admin_message':
      case 'chat_approved':
      case 'human_handoff_request':
      case 'chat_rejected':
        return Icons.mark_chat_unread;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'promotion':
        return Colors.orange;
      case 'discount':
        return Colors.green;
      case 'news':
        return Colors.blue;
      case 'admin_message':
      case 'chat_approved':
        return Colors.tealAccent;
      case 'human_handoff_request':
        return Colors.amber;
      case 'chat_rejected':
        return Colors.redAccent;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _showNotificationDetail(NotificationModel notification) async {
    // Persist read-state so refresh won't show the red dot again
    if (!notification.isRead) {
      await _notificationManager.markAsRead(
        notification.id,
        userPhone: widget.phoneNumber,
      );
      await _loadNotifications();
      if (!mounted) return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 27, 42, 59),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.description,
                style: TextStyle(
                  color: Colors.grey.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              if (notification.discountPrice != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Giá ưu đãi: ${notification.discountPrice}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Thời gian: ${_formatTime(notification.createdAt)}',
                style: TextStyle(
                  color: Colors.grey.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            if (notification.type.toLowerCase() == 'promotion')
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openPromotionProduct(notification);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xem xe ưu đãi'),
              ),
            if (_isDirectChatNotification(notification))
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openDirectChat(notification);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mở chat trực tiếp'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationManager.markAsRead(
        notification.id,
        userPhone: widget.phoneNumber,
      );
      await _loadNotifications();
    }

    if (_isDirectChatNotification(notification)) {
      _openDirectChat(notification);
      return;
    }

    if (notification.type.toLowerCase() == 'promotion') {
      await _openPromotionProduct(notification);
      return;
    }

    await _showNotificationDetail(notification);
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
}
