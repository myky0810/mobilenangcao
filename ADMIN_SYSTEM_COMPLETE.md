# 🎯 ADMIN MANAGEMENT SYSTEM - COMPLETE SETUP

## ✅ HOÀN TẤT: Hệ Thống Quản Lý Admin LuxeDrive

### 📋 TÓM TẮT

Đã tạo hoàn chỉnh hệ thống quản lý admin cho LuxeDrive với role-based routing tự động. Khi người dùng đăng nhập:
- Nếu **role = 'admin'** → Tự động chuyển đến **AdminScreen**
- Nếu **role = 'user'** → Tự động chuyển đến **HomeScreen**

---

## 🏗️ CẤU TRÚC HỆ THỐNG

```
lib/screen/admin/
├── admin_screen.dart           # Main admin panel với navigation
├── admin_dashboard.dart         # Dashboard: tổng quan thống kê
├── admin_users.dart             # Quản lý tài khoản
├── admin_products.dart          # Quản lý sản phẩm (xe)
├── admin_brands.dart            # Quản lý hãng xe
├── admin_deposits.dart          # Quản lý đặt cọc
├── admin_bookings.dart          # Quản lý lịch lái thử
├── admin_warranties.dart        # Quản lý bảo hành
├── admin_notifications.dart     # Quản lý thông báo
├── admin_banners.dart           # Quản lý banners
└── admin_live_chat.dart         # Chat trực tiếp admin-user

lib/widgets/
└── role_aware_home_placeholder.dart  # Role detection widget
```

---

## 🎨 TÍNH NĂNG CHI TIẾT

### 1️⃣ **DASHBOARD (admin_dashboard.dart)**
- ✅ Tổng quan hệ thống:
  - Tổng số users, sản phẩm, đặt cọc, lái thử, bảo hành, thông báo
  - Đơn chờ xử lý (pending)
  - Doanh thu tổng cộng (tính từ các đặt cọc confirmed)
- ✅ Thông tin admin:
  - Tên, email, phone, ngày tham gia

### 2️⃣ **QUẢN LÝ TÀI KHOẢN (admin_users.dart)**
- ✅ Xem danh sách tất cả users
- ✅ Xem chi tiết tài khoản
- ✅ Thêm tài khoản mới
- ✅ Nâng cấp user thành admin
- ✅ Hiển thị badge [ADMIN] cho admin accounts

### 3️⃣ **QUẢN LÝ SẢN PHẨM (admin_products.dart)**
- ✅ Xem/sửa/xóa sản phẩm
- ✅ Lọc theo hãng xe (Brand filter)
- ✅ Thêm sản phẩm mới
- ✅ Chỉnh sửa thông tin xe (tên, hãng, giá, URL hình, mô tả)

### 4️⃣ **QUẢN LÝ HÃN XE (admin_brands.dart)**
- ✅ Xem danh sách hãng xe từ product collection
- ✅ Xem chi tiết hãng (tên, số lượng xe thuộc hãng)
- ✅ Sửa tên hãng (tự động cập nhật tất cả sản phẩm)
- ✅ Xóa hãng (xóa tất cả sản phẩm của hãng)
- ✅ Tính năng thêm hãng qua thêm sản phẩm

### 5️⃣ **QUẢN LÝ ĐẶT CỌC (admin_deposits.dart)**
- ✅ Lọc theo trạng thái: All, pending, confirmed, cancelled
- ✅ Xem chi tiết đặt cọc
- ✅ Xác nhận đặt cọc (pending → confirmed)
- ✅ Hiển thị số tiền, khách hàng, thời gian

### 6️⃣ **QUẢN LÝ LÁI THỬ (admin_bookings.dart)**
- ✅ Lọc theo trạng thái
- ✅ Xem chi tiết booking
- ✅ Xác nhận yêu cầu lái thử
- ✅ Hiển thị: xe, khách hàng, ngày giờ, địa điểm

### 7️⃣ **QUẢN LÝ BẢO HÀNH (admin_warranties.dart)**
- ✅ Lọc theo trạng thái: pending, active, expired
- ✅ Xem chi tiết bảo hành (VIN, biển số, ngày mua, v.v.)
- ✅ Quản lý trạng thái bảo hành

### 8️⃣ **QUẢN LÝ THÔNG BÁO (admin_notifications.dart)**
- ✅ Xem danh sách thông báo
- ✅ Thêm thông báo mới
- ✅ Xóa thông báo
- ✅ Lưu vào collection `notifications`

### 9️⃣ **QUẢN LÝ BANNER (admin_banners.dart)**
- ✅ Xem/sửa/xóa banner
- ✅ Bật/tắt banner (isActive status)
- ✅ Lưu URL hình và tiêu đề
- ✅ Thêm banner mới

### 🔟 **CHAT TRỰC TIẾP (admin_live_chat.dart)**
- ✅ **Luồng:**
  1. User yêu cầu chat → tạo `admin_notifications` với status='pending'
  2. Admin xem danh sách pending requests
  3. Admin nhấn "Chấp Nhận" → tạo `admin_chats/{userPhone}`
  4. Admin chat với user → gửi tin nhắn vào `admin_chats/{userPhone}/messages`
  5. Mỗi tin nhắn của admin → tạo notification cho user
  6. User nhận notification → click vào → mở realtime chat với admin
  7. Chat realtime với Firestore listeners

- ✅ **Firestore Collections:**
  ```
  admin_notifications/
  ├── {docId}
  │   ├── type: "human_handoff_request"
  │   ├── userPhone: "0123456789"
  │   ├── status: "pending" | "approved" | "rejected"
  │   ├── createdAt: Timestamp
  │   └── ...

  admin_chats/
  ├── {userPhone}
  │   ├── userPhone: "0123456789"
  │   ├── adminPhone: "0987654321"
  │   ├── status: "active" | "closed"
  │   ├── startedAt: Timestamp
  │   ├── messages/
  │   │   └── {docId}
  │   │       ├── from: "admin" | "user"
  │   │       ├── message: "nội dung"
  │   │       ├── timestamp: Timestamp
  │   │       └── ...
  ```

---

## 🔐 ROLE-BASED ROUTING

### **Quy Trình Tự Động:**

```
User đăng nhập
     ↓
Điểm kiểm tra: /home
     ↓
RoleAwareHomePlaceholder kiểm tra role trong Firestore
     ↓
┌─────────────────────────────────────┐
│ Role = 'admin'?                     │
├─────────────────────┬───────────────┤
│ YES                 │ NO            │
│ ↓                   │ ↓             │
│ /admin              │ /home         │
│ (AdminScreen)       │ (HomeScreen)  │
└─────────────────────┴───────────────┘
```

### **Cách Hoạt Động:**

1. **main.dart**: Route '/home' sử dụng `RoleAwareHomePlaceholder`
2. **role_aware_home_placeholder.dart**: 
   - Gọi `UserService.get(phoneNumber)` 
   - Lấy UserModel từ Firestore
   - Kiểm tra `userModel.isAdmin()`
   - Chuyển hướng tới /admin hoặc /home

---

## 📱 GỬI NOTIFICATION TỪ USER → ADMIN

### **User-side (AIChat.dart - khi muốn chat với tư vấn viên):**

```dart
// Khi user click "Connect with Consultant":
await FirebaseFirestore.instance
    .collection('admin_notifications')
    .add({
  'type': 'human_handoff_request',
  'userPhone': userPhone,
  'userName': userName,
  'requestMessage': 'Tôi muốn nói chuyện với nhân viên',
  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
  'read': false,
});
```

### **Admin-side (admin_live_chat.dart - when accepting request):**

```dart
// Admin nhấn "Chấp Nhận":
_acceptChat(String notificationId, String userPhone) {
  // 1. Cập nhật status Admin Notification
  FirebaseFirestore.instance
      .collection('admin_notifications')
      .doc(notificationId)
      .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

  // 2. Tạo Admin Chat document
  FirebaseFirestore.instance
      .collection('admin_chats')
      .doc(userPhone)
      .set({
        'userPhone': userPhone,
        'adminPhone': widget.adminPhone,
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
```

---

## 💬 REALTIME CHAT FLOW

### **Admin gửi tin nhắn:**
```dart
_sendMessage(String chatId) {
  // 1. Lưu tin nhắn vào admin_chats/{chatId}/messages
  FirebaseFirestore.instance
      .collection('admin_chats')
      .doc(chatId)
      .collection('messages')
      .add({
        'from': 'admin',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'adminPhone': widget.adminPhone,
      });

  // 2. Gửi notification cho user
  FirebaseFirestore.instance
      .collection('admin_notifications')
      .add({
        'type': 'admin_message',
        'userPhone': chatId,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
}
```

### **User nhận tin nhắn & chat realtime:**
- User nhấn vào notification
- Mở realtime chat với admin
- Cả hai được StreamBuilder từ `admin_chats/{userPhone}/messages`
- Chat realtime tức thì

---

## 🎯 CÁC ĐIỂM QUAN TRỌNG

### **1. Firestore Collections được sử dụng:**
- `users` - user profiles với role field
- `products` - danh sách xe
- `deposits` - đặt cọc
- `test_drive_bookings` - lịch lái thử
- `warranties` - bảo hành
- `notifications` - thông báo chung
- `banners` - quảng cáo banner
- `admin_notifications` - thông báo cho admin (chat requests)
- `admin_chats` - lưu trữ cuộc chat admin-user

### **2. Màu sắc thống nhất:**
```dart
_bg = Color(0xFF0B0F1A)              // Đen xám
_card = Color(0xFF121A2B)            // Xám tối
_accent = Color(0xFF00A8FF)          // Xanh dương (tùy màn)
```

### **3. Layout & UX:**
- Bottom navigation bar cho 9 sections
- StreamBuilder realtime từ Firestore
- Modal dialogs cho add/edit
- Status badges & color indicators
- Floating action buttons cho thêm mới

---

## 🚀 SETUP & DEPLOYMENT

### **1. Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null || request.auth.token.admin == true;
    }
    match /admin_notifications/{document=**} {
      allow read, write: if request.auth.token.admin == true;
    }
    match /admin_chats/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### **2. Làm admin cho user:**
```
Firestore Console
  → users collection
  → Chọn user document
  → Edit: role = 'admin'
```

Hoặc dùng admin UI:
```
Admin Panel → Users → Chọn user → Làm Admin
```

### **3. Test Chat:**
1. User login → AIChat screen → "Connect with Consultant"
2. Admin login → admin/chat section → Nhấn "Chấp Nhận"
3. Admin gửi tin nhắn
4. User nhận notification & reply

---

## 📝 NOTES

- ✅ Tất cả screens đã tích hợp realtime Firestore
- ✅ Role-based routing tự động & seamless
- ✅ Chat system hoàn chỉnh với notifications
- ✅ UI đẹp, hiện đại, đồng bộ với user app
- ✅ Responsive layout cho tất cả screens
- ⚠️ Chưa có search/sort advanced (có thể thêm sau)
- ⚠️ Chưa có analytics/reports chi tiết (có thể mở rộng)

---

## 🎉 HOÀN TẤT!

Admin system đã sẵn sàng để sử dụng!
Chỉ cần set role='admin' cho user trong Firestore là có thể truy cập admin panel.
