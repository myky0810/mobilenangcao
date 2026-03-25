import 'package:flutter/material.dart';
import '../services/notification_manager.dart';

class NotificationIcon extends StatefulWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  const NotificationIcon({
    super.key,
    this.onTap,
    this.iconColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _notificationManager.checkUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ListenableBuilder(
        listenable: _notificationManager,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Main notification icon
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.notifications_outlined,
                  color: widget.iconColor,
                  size: widget.iconSize,
                ),
              ),
              // Notification badge
              if (_notificationManager.unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: AnimatedScale(
                    scale: _notificationManager.unreadCount > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676), // Màu xanh lá như trong hình
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          _notificationManager.unreadCount > 99 ? '99+' : _notificationManager.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Simple version with dot indicator
class SimpleNotificationIcon extends StatefulWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  const SimpleNotificationIcon({
    super.key,
    this.onTap,
    this.iconColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  State<SimpleNotificationIcon> createState() => _SimpleNotificationIconState();
}

class _SimpleNotificationIconState extends State<SimpleNotificationIcon> {
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _notificationManager.checkUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ListenableBuilder(
        listenable: _notificationManager,
        builder: (context, child) {
          return Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1a1a1a),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main notification icon
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: widget.iconColor,
                    size: widget.iconSize,
                  ),
                ),
                // Simple notification dot
                if (_notificationManager.hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: AnimatedScale(
                      scale: _notificationManager.hasUnread ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676), // Màu xanh lá như trong hình
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.5),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
