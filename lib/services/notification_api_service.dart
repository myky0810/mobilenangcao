import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firebase_helper.dart';
import '../models/notification.dart';

class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  // Simulate API data - Trong thực tế sẽ lấy từ server
  List<NotificationModel> _notifications = [];
  bool _isInitialized = false;
  String? _currentUserPhone;
  Timer? _periodicTimer;

  // Stream controller để real-time updates
  final _notificationStreamController =
      StreamController<List<NotificationModel>>.broadcast();
  Stream<List<NotificationModel>> get notificationStream =>
      _notificationStreamController.stream;

  // Khởi tạo dữ liệu
  Future<void> initialize({
    String? userPhone,
    bool forceRefresh = false,
  }) async {
    final requestedPhone = _normalizeUserPhone(userPhone);
    final normalizedPhone = requestedPhone ?? _currentUserPhone;
    if (!forceRefresh && _isInitialized && normalizedPhone == _currentUserPhone) {
      return;
    }

    final firebaseNotifications = await _fetchFirebaseNotifications(
      userPhone: normalizedPhone,
    );
    final shouldUseSampleData = normalizedPhone == null && firebaseNotifications.isEmpty;

    _notifications = shouldUseSampleData
        ? _generateSampleData()
        : firebaseNotifications;
    _isInitialized = true;
    _currentUserPhone = normalizedPhone;
    _notificationStreamController.add(_notifications);

    // Chỉ giả lập periodical updates khi chạy chế độ demo (không có user).
    if (shouldUseSampleData) {
      _startPeriodicUpdates();
    } else {
      _stopPeriodicUpdates();
    }
  }

  String? _normalizeUserPhone(String? rawPhone) {
    final value = (rawPhone ?? '').trim();
    if (value.isEmpty) return null;
    if (value.contains('@')) return value.toLowerCase();
    return value;
  }

  String _deriveChatIdFromPhone(String phone) {
    if (phone.contains('@')) {
      return phone.toLowerCase();
    }
    return FirebaseHelper.normalizePhone(phone);
  }

  Future<List<NotificationModel>> _fetchFirebaseNotifications({
    String? userPhone,
  }) async {
    try {
      final List<NotificationModel> allNotifications = [];

      DateTime? parseFlexibleDate(dynamic value) {
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        if (value is String) return DateTime.tryParse(value);
        return null;
      }

      // Fetch promotions/deals từ collection 'notifications'
      try {
        final promoSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();

        for (var doc in promoSnapshot.docs) {
          final data = doc.data();
          final createdAtRaw = data['createdAt'];
          DateTime createdAt = DateTime.now();

          if (createdAtRaw is Timestamp) {
            createdAt = createdAtRaw.toDate();
          } else if (createdAtRaw is String) {
            createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
          }

          allNotifications.add(
            NotificationModel(
              id: (data['id'] as String?)?.trim().isNotEmpty == true
                  ? data['id'] as String
                  : doc.id,
              title: (data['title'] as String?) ?? '',
              description: (data['description'] as String?) ?? '',
              type: (data['type'] as String?) ?? 'promotion',
              bannerKey: (data['bannerKey'] as String?)?.trim(),
              bannerIndex: data['bannerIndex'] is int
                  ? data['bannerIndex'] as int
                  : int.tryParse('${data['bannerIndex'] ?? ''}'),
              productId: (data['productId'] as String?)?.trim(),
              carModel: data['carModel'] as String?,
              originalPrice: data['originalPrice'] as String?,
              discountPrice: data['discountPrice'] as String?,
              discountPercent: data['discountPercent'] as String?,
              createdAt: createdAt,
              isRead: (data['isRead'] as bool?) ?? false,
              imageUrl: data['imageUrl'] as String?,
              startDate: parseFlexibleDate(data['startDate']),
              endDate: parseFlexibleDate(data['endDate']),
            ),
          );
        }
      } catch (_) {
        // Ignore errors khi fetch promotions
      }

      // Fetch chat notifications từ collection 'admin_notifications' theo user.
      if (userPhone != null && userPhone.isNotEmpty) {
        try {
          final chatByUserSnapshot = await FirebaseFirestore.instance
              .collection('admin_notifications')
              .where('userPhone', isEqualTo: userPhone)
              .limit(200)
              .get();

          final normalizedChatId = _deriveChatIdFromPhone(userPhone);
          QuerySnapshot<Map<String, dynamic>>? chatByChatIdSnapshot;
          if (normalizedChatId.isNotEmpty && normalizedChatId != userPhone) {
            chatByChatIdSnapshot = await FirebaseFirestore.instance
                .collection('admin_notifications')
                .where('chatId', isEqualTo: normalizedChatId)
                .limit(200)
                .get();
          }

          final mergedDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
            for (final doc in chatByUserSnapshot.docs) doc.id: doc,
            if (chatByChatIdSnapshot != null)
              for (final doc in chatByChatIdSnapshot.docs) doc.id: doc,
          };

          for (final doc in mergedDocs.values) {
            final data = doc.data();
            final createdAt = parseFlexibleDate(data['createdAt']) ?? DateTime.now();
            final status = (data['status'] as String? ?? '').trim();
            final rawType = (data['type'] as String? ?? 'system').trim();
            final message = (data['message'] as String? ?? '').trim();
            final requestMessage =
                (data['requestMessage'] as String? ?? '').trim();
            final chatId =
                (data['chatId'] as String? ?? data['userPhone'] as String? ?? '')
                    .trim();
            final isRead =
                (data['read'] as bool?) ?? (data['isRead'] as bool?) ?? false;

            var type = rawType;
            var title = 'Thông báo hệ thống';
            var description = message.isNotEmpty
                ? message
                : (requestMessage.isNotEmpty
                      ? requestMessage
                      : 'Bạn có thông báo mới');

            if (rawType == 'human_handoff_request') {
              if (status == 'approved') {
                type = 'chat_approved';
                title = '✅ Nhân viên đã sẵn sàng hỗ trợ';
                description = 'Nhấn để mở chat trực tiếp với tư vấn viên.';
              } else if (status == 'rejected') {
                type = 'chat_rejected';
                title = 'ℹ️ Yêu cầu hỗ trợ đã được cập nhật';
                description = 'Yêu cầu chat trực tiếp hiện chưa khả dụng.';
              } else {
                type = 'human_handoff_request';
                title = '🕐 Đang chờ tư vấn viên';
                description = 'Yêu cầu chat trực tiếp của bạn đang chờ duyệt.';
              }
            } else if (rawType == 'admin_message') {
              type = 'admin_message';
              title = '💬 Tin nhắn từ tư vấn viên';
              description =
                  message.isNotEmpty ? message : 'Bạn có tin nhắn mới từ tư vấn viên.';
            } else if (rawType == 'chat_approved') {
              type = 'chat_approved';
              title = '✅ Nhân viên đã sẵn sàng hỗ trợ';
              description = 'Nhấn để mở chat trực tiếp với tư vấn viên.';
            }

            allNotifications.add(
              NotificationModel(
                id: doc.id,
                title: title,
                description: description,
                type: type,
                productId: null,
                carModel: null,
                originalPrice: null,
                discountPrice: null,
                discountPercent: null,
                createdAt: createdAt,
                isRead: isRead,
                imageUrl: null,
                bannerKey: chatId,
              ),
            );
          }
        } catch (_) {
          // Ignore errors khi fetch chat notifications
        }
      }

      // Sort tất cả theo thời gian (newest first)
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allNotifications;
    } catch (_) {
      return [];
    }
  }

  // Lấy tất cả thông báo
  Future<List<NotificationModel>> getAllNotifications({String? userPhone}) async {
    await initialize(userPhone: userPhone, forceRefresh: true);
    return _notifications.where((n) => n.isActive()).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Lấy thông báo theo ngày
  Future<Map<String, List<NotificationModel>>> getNotificationsByDate({
    String? userPhone,
  }) async {
    await initialize(userPhone: userPhone, forceRefresh: true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    Map<String, List<NotificationModel>> result = {
      'Hôm nay': [],
      'Hôm qua': [],
      'Cũ hơn': [],
    };

    for (var notification in _notifications) {
      // Skip notifications không active
      if (!notification.isActive()) {
        continue;
      }

      final notificationDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (notificationDate.isAtSameMomentAs(today)) {
        result['Hôm nay']!.add(notification);
      } else if (notificationDate.isAtSameMomentAs(yesterday)) {
        result['Hôm qua']!.add(notification);
      } else {
        result['Cũ hơn']!.add(notification);
      }
    }

    // Sort mỗi section theo thời gian
    result.forEach((key, value) {
      value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    return result;
  }

  // Lấy thông báo khuyến mãi hot
  Future<List<NotificationModel>> getHotPromotions({String? userPhone}) async {
    await initialize(userPhone: userPhone, forceRefresh: true);
    return _notifications
        .where((n) => n.isActive()) // Filter chỉ active
        .where((n) => n.type == 'promotion' && n.discountPercent != null)
        .where(
          (n) =>
              (int.tryParse(
                    (n.discountPercent ?? '').replaceAll('%', '').trim(),
                  ) ??
                  0) >=
              20,
        )
        .take(5)
        .toList();
  }

  // Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationStreamController.add(_notifications);
    }

    await _syncReadStateToFirestore(notificationId, isRead: true);
  }

  // Đánh dấu chưa đọc
  Future<void> markAsUnread(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _notificationStreamController.add(_notifications);
    }

    await _syncReadStateToFirestore(notificationId, isRead: false);
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead({String? userPhone}) async {
    await initialize(userPhone: userPhone, forceRefresh: true);

    bool changed = false;
    final List<String> unreadIds = [];
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (!n.isRead) {
        _notifications[i] = n.copyWith(isRead: true);
        changed = true;
        unreadIds.add(n.id);
      }
    }

    if (changed) {
      _notificationStreamController.add(_notifications);
    }

    await Future.wait(
      unreadIds.map((id) => _syncReadStateToFirestore(id, isRead: true)),
    );
  }

  // Số thông báo chưa đọc
  Future<int> getUnreadCount({String? userPhone}) async {
    await initialize(userPhone: userPhone, forceRefresh: true);
    return _notifications
        .where((n) => n.isActive() && !n.isRead) // Filter active + unread
        .length;
  }

  Future<void> _syncReadStateToFirestore(
    String notificationId, {
    required bool isRead,
  }) async {
    Future<void> tryUpdate(
      String collection,
      Map<String, dynamic> payload,
    ) async {
      try {
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(notificationId)
            .update(payload);
      } catch (_) {
        // Ignore when the document belongs to another collection.
      }
    }

    await Future.wait([
      tryUpdate('notifications', {'isRead': isRead}),
      tryUpdate('admin_notifications', {'read': isRead, 'isRead': isRead}),
    ]);
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notificationStreamController.add(_notifications);
  }

  // Tạo dữ liệu mẫu
  List<NotificationModel> _generateSampleData() {
    final now = DateTime.now();
    final random = Random();

    return [
      // Thông báo hôm nay
      NotificationModel(
        id: 'notif_1',
        title: '🔥 FLASH SALE Mercedes E-Class',
        description:
            'Giảm ngay 300 triệu cho Mercedes E-Class 2024. Chỉ còn 2 ngày!',
        type: 'promotion',
        bannerKey: 'car_expo_2026',
        bannerIndex: 0,
        carModel: 'Mercedes E-Class 2024',
        originalPrice: '2.850.000.000đ',
        discountPrice: '2.550.000.000đ',
        discountPercent: '25%',
        createdAt: now.subtract(Duration(hours: random.nextInt(5))),
        isRead: false,
        imageUrl:
            'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-00cab4cac69d4468527a0bddd73df086de.jpg',
      ),
      NotificationModel(
        id: 'notif_2',
        title: '💰 Giá xe BMW X5 giảm mạnh',
        description:
            'BMW X5 2024 giảm giá còn 3.2 tỷ, tiết kiệm 400 triệu so với giá niêm yết',
        type: 'price',
        carModel: 'BMW X5 2024',
        originalPrice: '3.600.000.000đ',
        discountPrice: '3.200.000.000đ',
        discountPercent: '11%',
        createdAt: now.subtract(Duration(hours: random.nextInt(8))),
        isRead: false,
        imageUrl: 'assets/images/products/car2.jpg',
      ),
      NotificationModel(
        id: 'notif_3',
        title: '🎁 Khuyến mãi Tesla Model 3',
        description:
            'Mua Tesla Model 3 tặng gói sạc điện 1 năm + bảo hiểm thân vỏ',
        type: 'promotion',
        bannerKey: 'luxury_2026',
        bannerIndex: 2,
        carModel: 'Tesla Model 3',
        originalPrice: '1.499.000.000đ',
        discountPrice: '1.399.000.000đ',
        discountPercent: '7%',
        createdAt: now.subtract(Duration(minutes: random.nextInt(120))),
        isRead: true,
        imageUrl:
            'assets/images/products/Tesla-Cybertruck-2025-1280-aba810131368e11e171f4658a02a79d3f2.jpg',
      ),

      // Thông báo hôm qua
      NotificationModel(
        id: 'notif_4',
        title: '⚡ Toyota Camry - Ưu đãi cuối năm',
        description:
            'Giảm ngay 150 triệu + tặng phụ kiện chính hãng trị giá 50 triệu',
        type: 'discount',
        carModel: 'Toyota Camry 2024',
        originalPrice: '1.220.000.000đ',
        discountPrice: '1.070.000.000đ',
        discountPercent: '12%',
        createdAt: now.subtract(Duration(days: 1, hours: random.nextInt(12))),
        isRead: false,
        imageUrl: 'assets/images/products/car1.jpg',
      ),
      NotificationModel(
        id: 'notif_5',
        title: '🏆 Mazda CX-5 - Deal của ngày',
        description:
            'Mazda CX-5 2024 với giá ưu đãi chỉ 850 triệu, hỗ trợ trả góp 0%',
        type: 'promotion',
        bannerKey: 'electric_2026',
        bannerIndex: 1,
        carModel: 'Mazda CX-5 2024',
        originalPrice: '920.000.000đ',
        discountPrice: '850.000.000đ',
        discountPercent: '22%',
        createdAt: now.subtract(Duration(days: 1, hours: random.nextInt(15))),
        isRead: true,
        imageUrl:
            'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
      ),

      // Thông báo cũ hơn
      NotificationModel(
        id: 'notif_6',
        title: '📢 Hyundai Santa Fe - Giá sốc',
        description:
            'Hyundai Santa Fe giảm 200 triệu, chỉ còn 1.1 tỷ. Số lượng có hạn!',
        type: 'price',
        carModel: 'Hyundai Santa Fe 2024',
        originalPrice: '1.300.000.000đ',
        discountPrice: '1.100.000.000đ',
        discountPercent: '15%',
        createdAt: now.subtract(Duration(days: 3, hours: random.nextInt(10))),
        isRead: false,
        imageUrl: 'assets/images/products/car3.jpg',
      ),
      NotificationModel(
        id: 'notif_7',
        title: '🚗 Volvo XC90 - Khuyến mãi đặc biệt',
        description:
            'Ưu đãi lên đến 500 triệu cho Volvo XC90, tặng kèm bảo dành 5 năm',
        type: 'promotion',
        bannerKey: 'adventure_2026',
        bannerIndex: 3,
        carModel: 'Volvo XC90 2024',
        originalPrice: '4.200.000.000đ',
        discountPrice: '3.700.000.000đ',
        discountPercent: '21%',
        createdAt: now.subtract(Duration(days: 5, hours: random.nextInt(8))),
        isRead: true,
        imageUrl:
            'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
      ),
    ];
  }

  // Simulate periodic updates
  void _startPeriodicUpdates() {
    if (_periodicTimer != null) return;
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _addRandomNotification();
    });
  }

  void _stopPeriodicUpdates() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  // Thêm thông báo ngẫu nhiên (giả lập từ admin)
  void _addRandomNotification() {
    final random = Random();
    final carModels = [
      'BMW X3',
      'Mercedes C-Class',
      'Tesla Model Y',
      'Toyota Corolla Cross',
      'Mazda3',
      'Hyundai Tucson',
    ];
    final titles = [
      '🔥 Giảm giá sốc',
      '⚡ Ưu đãi đặc biệt',
      '💰 Deal hấp dẫn',
      '🎁 Khuyến mãi hot',
    ];

    final carModel = carModels[random.nextInt(carModels.length)];
    final title = titles[random.nextInt(titles.length)];

    final notification = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: '$title $carModel',
      description: 'Ưu đãi mới nhất cho $carModel với giá cực kỳ hấp dẫn!',
      type: ['price', 'promotion', 'discount'][random.nextInt(3)],
      carModel: carModel,
      originalPrice: '${random.nextInt(2000) + 800}.000.000đ',
      discountPrice: '${random.nextInt(1500) + 600}.000.000đ',
      discountPercent: '${random.nextInt(30) + 5}%',
      createdAt: DateTime.now(),
      isRead: false,
      imageUrl: 'assets/images/products/car${random.nextInt(3) + 1}.jpg',
    );

    _notifications.insert(0, notification);
    _notificationStreamController.add(_notifications);
  }

  // Cleanup
  void dispose() {
    _stopPeriodicUpdates();
    _notificationStreamController.close();
  }
}
