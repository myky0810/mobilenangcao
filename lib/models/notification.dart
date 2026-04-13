import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'price', 'promotion', 'discount'
  // Admin có thể map campaign vào banner bằng bannerKey hoặc bannerIndex.
  final String? bannerKey;
  final int? bannerIndex;
  final String? productId;
  final String? carModel;
  final String? originalPrice;
  final String? discountPrice;
  final String? discountPercent;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;
  final DateTime? startDate; // Admin set - khi nào bắt đầu hiển thị
  final DateTime? endDate;   // Admin set - khi nào hết hiển thị

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.bannerKey,
    this.bannerIndex,
    this.productId,
    this.carModel,
    this.originalPrice,
    this.discountPrice,
    this.discountPercent,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.startDate,
    this.endDate,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'promotion',
        bannerKey: json['bannerKey'],
        bannerIndex: json['bannerIndex'] is int
          ? json['bannerIndex'] as int
          : int.tryParse('${json['bannerIndex'] ?? ''}'),
      productId: json['productId'],
      carModel: json['carModel'],
      originalPrice: json['originalPrice'],
      discountPrice: json['discountPrice'],
      discountPercent: json['discountPercent'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'bannerKey': bannerKey,
      'bannerIndex': bannerIndex,
      'productId': productId,
      'carModel': carModel,
      'originalPrice': originalPrice,
      'discountPrice': discountPrice,
      'discountPercent': discountPercent,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  // Tạo bản copy với thay đổi isRead
  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? bannerKey,
    int? bannerIndex,
    String? productId,
    String? carModel,
    String? originalPrice,
    String? discountPrice,
    String? discountPercent,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      bannerKey: bannerKey ?? this.bannerKey,
      bannerIndex: bannerIndex ?? this.bannerIndex,
      productId: productId ?? this.productId,
      carModel: carModel ?? this.carModel,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // Kiểm tra xem thông báo có đang active không
  // Nếu không có startDate/endDate → luôn active
  // Nếu có → check theo thời gian
  bool isActive() {
    final now = DateTime.now();
    
    // Nếu có startDate và chưa đến hạn → không active
    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }
    
    // Nếu có endDate và đã quá hạn → không active
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }
    
    return true; // Active
  }

  // Tính toán thời gian hiển thị
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  // Lấy icon phù hợp với type
  IconData getIcon() {
    switch (type) {
      case 'price':
        return Icons.trending_down;
      case 'promotion':
        return Icons.local_offer;
      case 'discount':
        return Icons.percent;
      case 'admin_message':
      case 'chat_approved':
      case 'human_handoff_request':
      case 'chat_rejected':
        return Icons.mark_chat_unread;
      default:
        return Icons.notifications;
    }
  }

  // Lấy màu phù hợp với type
  Color getColor() {
    switch (type) {
      case 'price':
        return Colors.blue;
      case 'promotion':
        return Colors.orange;
      case 'discount':
        return Colors.red;
      case 'admin_message':
      case 'chat_approved':
        return Colors.teal;
      case 'human_handoff_request':
        return Colors.amber;
      case 'chat_rejected':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
