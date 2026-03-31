# 🤝 Hướng Dẫn Hệ Thống Chuyển Tiếp AI → Nhân Viên

## 📋 **Tổng Quan**
Hệ thống cho phép khách hàng yêu cầu nói chuyện với nhân viên tư vấn thật thay vì AI.

---

## 🔄 **Luồng Hoạt Động**

### **1. Khách Hàng Yêu Cầu**
Khách hàng chat với AI và nói:
- "Tôi muốn nói chuyện với nhân viên"
- "Kết nối tôi với nhân viên tư vấn"
- "Tôi cần nhân viên hỗ trợ"
- "Chuyển tôi sang nhân viên"
- "Talk to human support"

### **2. AI Phát Hiện & Xử Lý**
✅ AI nhận diện yêu cầu tự động
✅ Gửi thông báo đến Admin
✅ Trả lời khách hàng:
```
✅ Yêu cầu của bạn đã được gửi đi!

🔔 Admin sẽ nhận được thông báo và phân công nhân viên tư vấn.

⏰ Vui lòng chờ trong giây lát, nhân viên sẽ liên hệ với bạn sớm nhất.
Cảm ơn bạn đã kiên nhẫn! 💙
```

### **3. Admin Nhận Thông Báo**
Hệ thống tạo document trong Firebase:

**Collection:** `admin_notifications`
```json
{
  "type": "human_handoff_request",
  "chatId": "0123456789",
  "userPhone": "0123456789",
  "userName": "Nguyễn Văn A",
  "requestMessage": "Tôi muốn nói chuyện với nhân viên",
  "status": "pending",
  "priority": "normal",
  "createdAt": "2026-03-31T10:00:00Z",
  "read": false
}
```

**Collection:** `chats/{chatId}`
```json
{
  "status": "pending_human",
  "handoffRequestedAt": "2026-03-31T10:00:00Z",
  "handoffReason": "Tôi muốn nói chuyện với nhân viên",
  "userPhone": "0123456789",
  "userName": "Nguyễn Văn A"
}
```

### **4. Admin Chấp Nhận**
Admin screen cần:
1. Hiển thị danh sách thông báo
2. Xem chi tiết yêu cầu
3. **Chấp nhận** hoặc **Từ chối**

#### **Khi Admin Chấp Nhận:**
Cập nhật Firebase:
```javascript
// Update notification status
admin_notifications/{notificationId}:
{
  "status": "approved",
  "approvedAt": FieldValue.serverTimestamp(),
  "approvedBy": "admin_id",
  "assignedStaff": "staff_id"
}

// Update chat status
chats/{chatId}:
{
  "status": "human",
  "handoffApprovedAt": FieldValue.serverTimestamp(),
  "assignedStaff": "staff_name",
  "assignedStaffId": "staff_id"
}
```

### **5. Nhân Viên Chat Thật**
Sau khi Admin chấp nhận:
- AI **NGỪNG TRẢ LỜI** tự động
- Nhân viên thật chat với khách hàng
- Tin nhắn lưu trong `chats/{chatId}/messages`

---

## 🔑 **Các Từ Khóa Kích Hoạt**

### **Tiếng Việt:**
- "nói chuyện với nhân viên"
- "kết nối nhân viên"
- "gặp nhân viên"
- "gọi nhân viên"
- "chuyển nhân viên"
- "tư vấn nhân viên"
- "nhân viên tư vấn"
- "chăm sóc khách hàng"
- "hỗ trợ trực tiếp"

### **Tiếng Anh:**
- "talk to staff"
- "talk to agent"
- "talk to human"
- "speak to staff"
- "connect support"
- "human support"
- "real person"

---

## 📊 **Firebase Collections**

### **1. admin_notifications**
```
admin_notifications/
├── {notificationId}
    ├── type: "human_handoff_request"
    ├── chatId: "user_phone_number"
    ├── userPhone: "0123456789"
    ├── userName: "Tên khách hàng"
    ├── requestMessage: "Nội dung yêu cầu"
    ├── status: "pending" | "approved" | "rejected"
    ├── priority: "normal" | "high" | "urgent"
    ├── createdAt: Timestamp
    ├── read: boolean
    └── approvedAt: Timestamp (when approved)
```

### **2. chats**
```
chats/
├── {chatId}
    ├── status: "bot" | "pending_human" | "human"
    ├── handoffRequestedAt: Timestamp
    ├── handoffReason: string
    ├── handoffApprovedAt: Timestamp
    ├── assignedStaff: string
    ├── assignedStaffId: string
    └── messages/
        ├── {messageId}
            ├── role: "user" | "assistant"
            ├── text: string
            └── createdAt: Timestamp
```

---

## 🛠️ **Admin Screen Cần Làm**

### **1. Realtime Listener**
```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('admin_notifications')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    // Hiển thị danh sách thông báo
  },
)
```

### **2. Chấp Nhận Yêu Cầu**
```dart
Future<void> approveHandoff(String notificationId, String chatId) async {
  final batch = FirebaseFirestore.instance.batch();
  
  // Update notification
  batch.update(
    FirebaseFirestore.instance.collection('admin_notifications').doc(notificationId),
    {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': currentAdminId,
    },
  );
  
  // Update chat status
  batch.update(
    FirebaseFirestore.instance.collection('chats').doc(chatId),
    {
      'status': 'human',
      'handoffApprovedAt': FieldValue.serverTimestamp(),
      'assignedStaff': staffName,
      'assignedStaffId': staffId,
    },
  );
  
  // Send notification to user
  batch.set(
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(),
    {
      'role': 'assistant',
      'text': '✅ Nhân viên tư vấn đã được kết nối! Xin chào, tôi là $staffName. Tôi có thể giúp gì cho bạn?',
      'createdAt': FieldValue.serverTimestamp(),
    },
  );
  
  await batch.commit();
}
```

### **3. Từ Chối Yêu Cầu**
```dart
Future<void> rejectHandoff(String notificationId, String chatId) async {
  final batch = FirebaseFirestore.instance.batch();
  
  batch.update(
    FirebaseFirestore.instance.collection('admin_notifications').doc(notificationId),
    {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    },
  );
  
  batch.update(
    FirebaseFirestore.instance.collection('chats').doc(chatId),
    {
      'status': 'bot', // Back to AI
    },
  );
  
  // Notify user
  batch.set(
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(),
    {
      'role': 'assistant',
      'text': 'Xin lỗi, hiện tại nhân viên đang bận. AI sẽ tiếp tục hỗ trợ bạn nhé! 😊',
      'createdAt': FieldValue.serverTimestamp(),
    },
  );
  
  await batch.commit();
}
```

---

## 🎯 **Lưu Ý Quan Trọng**

### ✅ **Đã Hoàn Thành (AIChat.dart)**
- ✅ Phát hiện yêu cầu khách hàng
- ✅ Gửi thông báo đến Admin
- ✅ Cập nhật chat status
- ✅ Trả lời xác nhận cho khách hàng
- ✅ Ngừng AI khi status = "human"

### ⚠️ **Cần Làm (Admin Screen)**
- ❌ Hiển thị danh sách thông báo
- ❌ Chấp nhận/Từ chối yêu cầu
- ❌ Phân công nhân viên
- ❌ Chat interface cho nhân viên

---

## 🔍 **Test Flow**

### **Test 1: Yêu Cầu Thành Công**
1. Khách hàng chat: "Tôi muốn nói chuyện với nhân viên"
2. Kiểm tra Firebase:
   - `admin_notifications` có document mới
   - `chats/{chatId}` status = "pending_human"
3. Admin chấp nhận
4. Kiểm tra:
   - Notification status = "approved"
   - Chat status = "human"
   - Khách hàng nhận tin nhắn xác nhận

### **Test 2: AI Ngừng Trả Lời**
1. Sau khi Admin chấp nhận
2. Khách hàng chat bất kỳ nội dung
3. AI **KHÔNG** tự động trả lời
4. Chỉ nhân viên thật chat được

---

## 📱 **UI/UX Suggestions**

### **Admin Notification Badge**
```
🔔 (3) ← Badge hiển thị số thông báo pending
```

### **Notification Item**
```
┌─────────────────────────────────┐
│ 🆕 Yêu cầu kết nối nhân viên   │
│                                 │
│ 👤 Nguyễn Văn A                 │
│ 📱 0123456789                   │
│ 💬 "Tôi muốn nói chuyện với    │
│     nhân viên tư vấn"          │
│                                 │
│ ⏰ 10:30 AM - 31/03/2026        │
│                                 │
│ [✅ Chấp nhận] [❌ Từ chối]     │
└─────────────────────────────────┘
```

---

## 🚀 **Deployment Checklist**

- [x] AIChat.dart: Phát hiện yêu cầu
- [x] AIChat.dart: Gửi thông báo
- [x] AIChat.dart: Cập nhật chat status
- [x] Firebase Rules: Cho phép admin write
- [ ] Admin Screen: Hiển thị thông báo
- [ ] Admin Screen: Chấp nhận/Từ chối
- [ ] Admin Screen: Chat interface
- [ ] Test toàn bộ flow
- [ ] Deploy production

---

**Tài liệu này được tạo tự động bởi AI Assistant**
**Ngày: 31/03/2026**
