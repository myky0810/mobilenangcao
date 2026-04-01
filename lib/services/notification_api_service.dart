import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  // Simulate API data - Trong thực tế sẽ lấy từ server
  List<NotificationModel> _notifications = [];
  bool _isInitialized = false;

  // Stream controller để real-time updates
  final _notificationStreamController =
      StreamController<List<NotificationModel>>.broadcast();
  Stream<List<NotificationModel>> get notificationStream =>
      _notificationStreamController.stream;

  // Khởi tạo dữ liệu mẫu
  Future<void> initialize() async {
    if (_isInitialized) return;

    final firebaseNotifications = await _fetchFirebaseNotifications();
    _notifications =
        firebaseNotifications.isNotEmpty
        ? firebaseNotifications
        : _generateSampleData();
    _isInitialized = true;
    _notificationStreamController.add(_notifications);

    // Chỉ giả lập update khi chưa có dữ liệu thật từ Firebase.
    if (firebaseNotifications.isEmpty) {
      _startPeriodicUpdates();
    }
  }

  Future<List<NotificationModel>> _fetchFirebaseNotifications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAtRaw = data['createdAt'];
        DateTime createdAt = DateTime.now();

        if (createdAtRaw is Timestamp) {
          createdAt = createdAtRaw.toDate();
        } else if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
        }

        return NotificationModel(
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
          carModel: data['carModel'] as String?,
          originalPrice: data['originalPrice'] as String?,
          discountPrice: data['discountPrice'] as String?,
          discountPercent: data['discountPercent'] as String?,
          createdAt: createdAt,
          isRead: (data['isRead'] as bool?) ?? false,
          imageUrl: data['imageUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Lấy tất cả thông báo
  Future<List<NotificationModel>> getAllNotifications() async {
    await initialize();
    return List.from(_notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Lấy thông báo theo ngày
  Future<Map<String, List<NotificationModel>>> getNotificationsByDate() async {
    await initialize();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    Map<String, List<NotificationModel>> result = {
      'Hôm nay': [],
      'Hôm qua': [],
      'Cũ hơn': [],
    };

    for (var notification in _notifications) {
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
  Future<List<NotificationModel>> getHotPromotions() async {
    await initialize();
    return _notifications
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
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        description: _notifications[index].description,
        type: _notifications[index].type,
        bannerKey: _notifications[index].bannerKey,
        bannerIndex: _notifications[index].bannerIndex,
        carModel: _notifications[index].carModel,
        originalPrice: _notifications[index].originalPrice,
        discountPrice: _notifications[index].discountPrice,
        discountPercent: _notifications[index].discountPercent,
        createdAt: _notifications[index].createdAt,
        isRead: true,
        imageUrl: _notifications[index].imageUrl,
      );
      _notificationStreamController.add(_notifications);
    }
  }

  // Đánh dấu chưa đọc
  Future<void> markAsUnread(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _notificationStreamController.add(_notifications);
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead() async {
    await initialize();

    bool changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (!n.isRead) {
        _notifications[i] = n.copyWith(isRead: true);
        changed = true;
      }
    }

    if (changed) {
      _notificationStreamController.add(_notifications);
    }
  }

  // Số thông báo chưa đọc
  Future<int> getUnreadCount() async {
    await initialize();
    return _notifications.where((n) => !n.isRead).length;
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
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _addRandomNotification();
    });
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
    _notificationStreamController.close();
  }
}
