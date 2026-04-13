import 'package:flutter/material.dart';
import '../services/notification_api_service.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationApiService _notificationService = NotificationApiService();
  bool _hasUnread = false;
  int _unreadCount = 0;

  bool get hasUnread => _hasUnread;
  int get unreadCount => _unreadCount;

  Future<void> checkUnreadNotifications({String? userPhone}) async {
    try {
      final notifications = await _notificationService.getAllNotifications(
        userPhone: userPhone,
      );
      final unreadList = notifications.where((n) => !n.isRead).toList();

      _hasUnread = unreadList.isNotEmpty;
      _unreadCount = unreadList.length;

      notifyListeners();
    } catch (e) {
      _hasUnread = false;
      _unreadCount = 0;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId, {String? userPhone}) async {
    // Persist then refresh count
    await _notificationService.markAsRead(notificationId);
    await checkUnreadNotifications(userPhone: userPhone);
  }

  Future<void> markAllAsRead({String? userPhone}) async {
    await _notificationService.markAllAsRead(userPhone: userPhone);
    await checkUnreadNotifications(userPhone: userPhone);
  }
}
