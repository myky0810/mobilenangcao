import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'price', 'promotion', 'discount'
  final String? carModel;
  final String? originalPrice;
  final String? discountPrice;
  final String? discountPercent;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.carModel,
    this.originalPrice,
    this.discountPrice,
    this.discountPercent,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'promotion',
      carModel: json['carModel'],
      originalPrice: json['originalPrice'],
      discountPrice: json['discountPrice'],
      discountPercent: json['discountPercent'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'carModel': carModel,
      'originalPrice': originalPrice,
      'discountPrice': discountPrice,
      'discountPercent': discountPercent,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  // Tạo bản copy với thay đổi isRead
  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? carModel,
    String? originalPrice,
    String? discountPrice,
    String? discountPercent,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      carModel: carModel ?? this.carModel,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
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
      default:
        return Colors.grey;
    }
  }
}
