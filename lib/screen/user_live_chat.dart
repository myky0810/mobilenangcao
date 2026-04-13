import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/firebase_helper.dart';

class UserLiveChatScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? chatId;
  final String? chatTitle;

  const UserLiveChatScreen({
    super.key,
    this.phoneNumber,
    this.chatId,
    this.chatTitle,
  });

  @override
  State<UserLiveChatScreen> createState() => _UserLiveChatScreenState();
}

class _UserLiveChatScreenState extends State<UserLiveChatScreen> {
  static const Color _bg = Color(0xFF111827);
  static const Color _card = Color(0xFF1F2937);
  static const Color _accent = Color(0xFF00E676);

  late final TextEditingController _messageController;
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _chatId = _resolveChatId();
    _ensureChatThread();
    _markRelevantNotificationsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _resolveChatId() {
    final rawChatId = (widget.chatId ?? '').trim();
    if (rawChatId.isNotEmpty) {
      return rawChatId;
    }

    final phone = (widget.phoneNumber ?? '').trim();
    if (phone.isEmpty) {
      return 'guest';
    }

    if (phone.contains('@')) {
      return phone.toLowerCase();
    }

    return FirebaseHelper.normalizePhone(phone);
  }

  Future<void> _ensureChatThread() async {
    await FirebaseFirestore.instance.collection('admin_chats').doc(_chatId).set({
      'chatId': _chatId,
      'userPhone': _chatId,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markRelevantNotificationsRead() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_notifications')
          .where('userPhone', isEqualTo: _chatId)
          .limit(200)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      var changed = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = (data['type'] as String? ?? '').trim();
        if (type != 'admin_message' && type != 'chat_approved') {
          continue;
        }

        final alreadyRead =
            (data['read'] as bool?) ?? (data['isRead'] as bool?) ?? false;
        if (!alreadyRead) {
          batch.update(doc.reference, {'read': true, 'isRead': true});
          changed = true;
        }
      }

      if (changed) {
        await batch.commit();
      }
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('admin_chats')
        .doc(_chatId)
        .collection('messages')
        .add({
          'from': 'user',
          'message': text,
          'timestamp': FieldValue.serverTimestamp(),
          'userPhone': widget.phoneNumber,
        });

    await FirebaseFirestore.instance.collection('admin_chats').doc(_chatId).set({
      'chatId': _chatId,
      'userPhone': _chatId,
      'status': 'active',
      'lastMessage': text,
      'lastMessageFrom': 'user',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: Text(widget.chatTitle ?? 'Tư vấn trực tiếp'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('admin_chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn. Hãy bắt đầu cuộc trò chuyện.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final from = (data['from'] as String? ?? '').trim();
                    final isUser = from == 'user';
                    final message = (data['message'] as String? ?? '').trim();
                    final timestamp = data['timestamp'] as Timestamp?;

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isUser ? _accent : _card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                color: isUser ? Colors.black : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(timestamp),
                              style: TextStyle(
                                color: isUser ? Colors.black54 : Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: _card,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                    color: _accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
