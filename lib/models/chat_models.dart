import 'package:cloud_firestore/cloud_firestore.dart';

/// Models for Firestore chat collections used in `AIChat.dart`.
/// Collections:
/// - `chats/{chatId}`
/// - `chats/{chatId}/messages/{messageId}`
/// - `admin_notifications` (handoff requests)
/// - `ai_feedback`

class ChatThread {
  final String id;
  final String? userPhone;
  final String userName;
  final String status; // bot | pending_human | human
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatThread({
    required this.id,
    this.userPhone,
    this.userName = 'Guest',
    this.status = 'bot',
    this.createdAt,
    this.updatedAt,
  });

  factory ChatThread.fromFirestore(Map<String, dynamic> map, String id) {
    DateTime? parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      return null;
    }

    return ChatThread(
      id: id,
      userPhone: (map['userPhone'] as String?)?.trim(),
      userName: (map['userName'] as String?) ?? 'Guest',
      status: (map['status'] as String?) ?? 'bot',
      createdAt: parseTs(map['createdAt']),
      updatedAt: parseTs(map['updatedAt']),
    );
  }

  factory ChatThread.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ChatThread.fromFirestore(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    return {
      'chatId': id,
      'userPhone': userPhone,
      'userName': userName,
      'status': status,
      if (includeTimestamps) 'updatedAt': FieldValue.serverTimestamp(),
      if (includeTimestamps && createdAt == null)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatMessageModel {
  final String id;
  final String role; // user | model | admin
  final String text;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessageModel.fromFirestore(Map<String, dynamic> map, String id) {
    DateTime parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatMessageModel(
      id: id,
      role: (map['role'] as String?) ?? 'user',
      text: (map['text'] as String?) ?? '',
      createdAt: parseTs(map['createdAt']),
    );
  }

  factory ChatMessageModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ChatMessageModel.fromFirestore(
      doc.data() ?? <String, dynamic>{},
      doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AiFeedbackModel {
  final String? id;
  final String chatId;
  final String? userPhone;
  final String feedback;
  final int? rating;
  final DateTime createdAt;

  const AiFeedbackModel({
    this.id,
    required this.chatId,
    this.userPhone,
    required this.feedback,
    this.rating,
    required this.createdAt,
  });

  factory AiFeedbackModel.fromFirestore(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    DateTime parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    int? parseInt(Object? raw) {
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw);
      return null;
    }

    return AiFeedbackModel(
      id: documentId,
      chatId: (map['chatId'] as String?) ?? '',
      userPhone: (map['userPhone'] as String?)?.trim(),
      feedback: (map['feedback'] as String?) ?? (map['text'] as String?) ?? '',
      rating: parseInt(map['rating']),
      createdAt: parseTs(map['createdAt']),
    );
  }

  factory AiFeedbackModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AiFeedbackModel.fromFirestore(
      doc.data() ?? <String, dynamic>{},
      documentId: doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'userPhone': userPhone,
      'feedback': feedback,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
