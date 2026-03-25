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

  Future<void> checkUnreadNotifications() async {
    try {
      final notifications = await _notificationService.getAllNotifications();
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

  void markAsRead(String notificationId) {
    // This would normally update the backend/database
    // For now, we'll just refresh the count
    checkUnreadNotifications();
  }

  void markAllAsRead() {
    _hasUnread = false;
    _unreadCount = 0;
    notifyListeners();
  }
}
