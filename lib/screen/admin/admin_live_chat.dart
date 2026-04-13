import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'widgets/admin_ui.dart';

class AdminLiveChatScreen extends StatefulWidget {
  final String? adminPhone;

  const AdminLiveChatScreen({super.key, this.adminPhone});

  @override
  State<AdminLiveChatScreen> createState() => _AdminLiveChatScreenState();
}

class _AdminLiveChatScreenState extends State<AdminLiveChatScreen> {
  static const Color _showroomBase = Color(0xFF1E2A47);
  static const Color _card = Color(0xFF121A2B);
  static const Color _accent = Color(0xFF00FF88);

  String? _selectedChatId;
  late TextEditingController _messageController;
  late TextEditingController _searchController;
  String _requestFilter = 'pending'; // all | pending | approved | rejected

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _acceptChat(
    String notificationId,
    Map<String, dynamic> notification,
  ) async {
    final userPhone = (notification['userPhone'] as String? ?? '').trim();
    final chatId = (notification['chatId'] as String? ?? userPhone).trim();

    if (chatId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy chatId hợp lệ.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(notificationId)
        .update({
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': widget.adminPhone,
          'chatId': chatId,
        });

    await FirebaseFirestore.instance.collection('admin_chats').doc(chatId).set({
      'chatId': chatId,
      'userPhone': userPhone.isNotEmpty ? userPhone : chatId,
      'adminPhone': widget.adminPhone,
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Đồng bộ trạng thái handoff cho AI chat hiện tại.
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'chatId': chatId,
      'userPhone': userPhone.isNotEmpty ? userPhone : chatId,
      'status': 'human',
      'approvedBy': widget.adminPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Gửi thông báo cho user biết có thể vào chat trực tiếp.
    await FirebaseFirestore.instance.collection('admin_notifications').add({
      'type': 'chat_approved',
      'chatId': chatId,
      'userPhone': userPhone.isNotEmpty ? userPhone : chatId,
      'adminPhone': widget.adminPhone,
      'message': 'Nhân viên đã sẵn sàng hỗ trợ bạn trực tiếp.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    if (!mounted) return;
    setState(() => _selectedChatId = chatId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã chấp nhận yêu cầu chat')));
  }

  Future<void> _rejectChat(String notificationId, String chatId) async {
    await FirebaseFirestore.instance
        .collection('admin_notifications')
        .doc(notificationId)
        .update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': widget.adminPhone,
        });

    if (chatId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'status': 'bot',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu chat')));
  }

  Future<void> _sendMessage(String chatId) async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Add message to Firestore
    await FirebaseFirestore.instance
        .collection('admin_chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'from': 'admin',
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'adminPhone': widget.adminPhone,
        });

    final chatDoc = await FirebaseFirestore.instance
        .collection('admin_chats')
        .doc(chatId)
        .get();
    final threadUserPhone = (chatDoc.data()?['userPhone'] as String? ?? '')
        .trim();
    final targetUserPhone = threadUserPhone.isNotEmpty
        ? threadUserPhone
        : chatId;

    // Update last message
    await FirebaseFirestore.instance.collection('admin_chats').doc(chatId).set({
      'chatId': chatId,
      'userPhone': targetUserPhone,
      'adminPhone': widget.adminPhone,
      'status': 'active',
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageFrom': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Send notification to user
    await FirebaseFirestore.instance.collection('admin_notifications').add({
      'type': 'admin_message',
      'chatId': chatId,
      'userPhone': targetUserPhone,
      'adminPhone': widget.adminPhone,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChatId == null) {
      return Scaffold(
        backgroundColor: _showroomBase,
        body: Column(
          children: [
            Padding(
              padding: adminHeaderPadding(context, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat trực tiếp', style: kAdminHeaderTitleStyle),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo SĐT/email/nội dung...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('pending', 'Đang chờ'),
                        _buildFilterChip('approved', 'Đã duyệt'),
                        _buildFilterChip('rejected', 'Đã từ chối'),
                        _buildFilterChip('all', 'Tất cả'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('admin_notifications')
                    .where('type', isEqualTo: 'human_handoff_request')
                    .limit(300)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accent),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final keyword = _searchController.text.trim().toLowerCase();

                  final filtered =
                      docs.where((doc) {
                        final data = doc.data();
                        final status = (data['status'] as String? ?? 'pending')
                            .toLowerCase();
                        final userPhone = (data['userPhone'] as String? ?? '')
                            .toLowerCase();
                        final requestMessage =
                            (data['requestMessage'] as String? ?? '')
                                .toLowerCase();
                        final chatId = (data['chatId'] as String? ?? '')
                            .toLowerCase();

                        final statusOk =
                            _requestFilter == 'all' || status == _requestFilter;
                        final searchOk =
                            keyword.isEmpty ||
                            userPhone.contains(keyword) ||
                            requestMessage.contains(keyword) ||
                            chatId.contains(keyword);
                        return statusOk && searchOk;
                      }).toList()..sort((a, b) {
                        final aTs = a.data()['createdAt'] as Timestamp?;
                        final bTs = b.data()['createdAt'] as Timestamp?;
                        final aMs = aTs?.millisecondsSinceEpoch ?? 0;
                        final bMs = bTs?.millisecondsSinceEpoch ?? 0;
                        return bMs.compareTo(aMs);
                      });

                  if (filtered.isEmpty) {
                    return Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat,
                                  color: Colors.white24,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không có yêu cầu phù hợp',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 16,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildActiveChatList(),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            final notification = doc.data();
                            return _buildChatRequestCard(notification, doc.id);
                          },
                        ),
                      ),
                      _buildActiveChatList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _showroomBase,
      appBar: AppBar(
        backgroundColor: _showroomBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() => _selectedChatId = null);
          },
        ),
        title: Text(
          '$_selectedChatId',
          style: kAdminHeaderTitleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_chats')
                  .doc(_selectedChatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;

                    final isAdmin = message['from'] == 'admin';

                    return Align(
                      alignment: isAdmin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin ? _accent : _card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              message['message']?.toString() ?? '',
                              style: TextStyle(
                                color: isAdmin ? Colors.black : Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['timestamp'] != null
                                  ? DateFormat('HH:mm').format(
                                      (message['timestamp'] as Timestamp)
                                          .toDate(),
                                    )
                                  : '',
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.black54
                                    : Colors.white54,
                                fontSize: 10,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _card,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    await _sendMessage(_selectedChatId!);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRequestCard(
    Map<String, dynamic> notification,
    String notificationId,
  ) {
    final userPhone = notification['userPhone']?.toString() ?? 'Unknown';
    final avatarLetter = userPhone.isNotEmpty
        ? userPhone[0].toUpperCase()
        : '?';
    final chatId =
        (notification['chatId']?.toString().trim().isNotEmpty ?? false)
        ? notification['chatId'].toString().trim()
        : userPhone;
    final message =
        notification['requestMessage']?.toString() ??
        'Muốn chat với tư vấn viên';
    final timestamp = notification['createdAt'] as Timestamp?;
    final status = (notification['status'] as String? ?? 'pending')
        .toLowerCase();

    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved':
        statusColor = Colors.greenAccent;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusText = 'Đã từ chối';
        break;
      default:
        statusColor = Colors.orangeAccent;
        statusText = 'Đang chờ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userPhone,
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (timestamp != null)
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: status == 'pending'
                      ? () async {
                          await _acceptChat(notificationId, notification);
                        }
                      : () {
                          setState(() => _selectedChatId = chatId);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    status == 'pending' ? 'Chấp Nhận' : 'Mở Chat',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: status == 'rejected'
                      ? null
                      : () async {
                          await _rejectChat(notificationId, chatId);
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Từ Chối', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _requestFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: adminFilterChip(
        label: label,
        selected: selected,
        selectedColor: kAdminPrimary,
        unselectedColor: _card,
        onTap: () => setState(() => _requestFilter = value),
      ),
    );
  }

  Widget _buildActiveChatList() {
    final keyword = _searchController.text.trim().toLowerCase();
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('admin_chats')
            .orderBy('lastMessageTime', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final filtered = docs.where((doc) {
            final data = doc.data();
            final userPhone = (data['userPhone'] as String? ?? doc.id)
                .toLowerCase();
            final chatId = (data['chatId'] as String? ?? doc.id).toLowerCase();
            final lastMessage = (data['lastMessage'] as String? ?? '')
                .toLowerCase();
            if (keyword.isEmpty) return true;
            return userPhone.contains(keyword) ||
                chatId.contains(keyword) ||
                lastMessage.contains(keyword);
          }).toList();

          if (filtered.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text(
                  'Cuộc trò chuyện đang hoạt động',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final chatId = (data['chatId'] as String? ?? doc.id).trim();
                    final userPhone = (data['userPhone'] as String? ?? chatId)
                        .trim();
                    final lastMessage = (data['lastMessage'] as String? ?? '')
                        .trim();

                    return ListTile(
                      dense: true,
                      title: Text(
                        userPhone,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        lastMessage.isEmpty ? 'Chưa có tin nhắn' : lastMessage,
                        style: const TextStyle(color: Colors.white54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                      onTap: () {
                        if (chatId.isNotEmpty) {
                          setState(() => _selectedChatId = chatId);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
