# 🎯 HƯỚNG DẪN QUẢN LÝ PAYMENT QUA FIREBASE

## 📱 2 TRANG THANH TOÁN CHÍNH

### 1️⃣ **VietQR_screen.dart** (Thanh toán QR)
### 2️⃣ **payment_methods.dart** (Đặt cọc)

---

## 🔥 FIREBASE COLLECTIONS ĐƯỢC SỬ DỤNG

### Collection: `transactions` (cho VietQR_screen.dart)
### Collection: `deposits` (cho payment_methods.dart)

---

# 📊 CHI TIẾT QUẢN LÝ

## 1️⃣ VietQR Screen - Collection: `transactions`

### 🎯 Mục đích:
- Lưu thông tin thanh toán VietQR
- Theo dõi trạng thái thanh toán realtime
- Quản lý timeout (15 phút)

### 📝 Cấu trúc Data:

```javascript
transactions/{transactionId}
{
  // ============ THÔNG TIN GIAO DỊCH ============
  "transactionId": "TXN_1712345678901",          // ID tự động tạo
  "status": "pending",                            // pending → paid (tự động sau 10s)
  
  // ============ THÔNG TIN THANH TOÁN ============
  "amount": 5000000,                              // Số tiền (VND)
  "carName": "BMW X7 2024",                       // Tên xe đặt cọc
  "phoneNumber": "+84123456789",                  // SĐT khách hàng
  
  // ============ THÔNG TIN NGÂN HÀNG ============
  "accountNumber": "1026106799",                  // STK VCB của LuxeDrive
  "bankId": "VCB",                                // VietComBank
  "transferContent": "Dat coc BMW X7 TXN_...",    // Nội dung CK (để match)
  "paymentMethod": "vietqr",                      // Cố định
  
  // ============ TIMESTAMPS ============
  "createdAt": Timestamp(2026-04-07 10:30:00),   // Khi user vào screen
  "paidAt": Timestamp(2026-04-07 10:30:10),      // Khi thanh toán (10s sau)
  
  // ============ DEMO MODE ============
  "autoDemo": true,                               // Đánh dấu auto-demo
}
```

### 🔄 Lifecycle (Chu trình sống):

```
BƯỚC 1: User vào VietQR_screen
├─ App gọi: _saveTransactionToFirestore()
├─ Tạo document mới trong Firestore
└─ Trạng thái: status = "pending"

BƯỚC 2: App start listener + timer
├─ _startPaymentListener() - Theo dõi Firestore realtime
├─ AutoPaymentDemo.startAutoPayment() - Timer 10 giây
└─ Hiển thị QR code cho user

BƯỚC 3: Sau 10 giây
├─ Timer kích hoạt
├─ Update Firestore: status = "paid", paidAt = now
└─ Thêm field: autoDemo = true

BƯỚC 4: Firestore Listener phát hiện
├─ Firestore snapshots() bắt được thay đổi
├─ App gọi: _onPaymentSuccess()
└─ Hiển thị loading 2s → Success popup

BƯỚC 5: Hoàn thành
├─ User thấy popup "Thanh toán thành công"
├─ Transaction hoàn tất
└─ Data lưu vĩnh viễn trong Firestore
```

### 🎮 Cách kiểm soát từ Firebase Console:

#### ✅ Xem tất cả giao dịch:
1. Vào: https://console.firebase.google.com
2. Chọn project
3. Firestore Database → `transactions` collection
4. Bạn sẽ thấy list tất cả giao dịch

#### ✅ Filter giao dịch theo trạng thái:
```
Filters:
- status == "pending"  → Đang chờ thanh toán
- status == "paid"     → Đã thanh toán ✅
- status == "timeout"  → Hết thời gian ⏰
```

#### ✅ Test manual payment (KHÔNG CẦN APP):
```javascript
// Bước 1: User vào app tạo transaction
// Bước 2: Bạn vào Firebase Console
// Bước 3: Tìm transaction vừa tạo (mới nhất)
// Bước 4: Click "Edit document"
// Bước 5: Update 2 fields:

{
  "status": "paid",                    // Từ "pending" → "paid"
  "paidAt": (Click "Add timestamp")    // Thời gian hiện tại
}

// Bước 6: Save
// → App TỰ ĐỘNG hiện success ngay lập tức! ✅
```

#### ✅ Xem giao dịch trong 24h qua:
```
Filters:
- createdAt >= (24 hours ago)
Order by: createdAt (descending)
```

#### ✅ Tính tổng doanh thu từ VietQR:
```javascript
// Query tất cả paid transactions
Filters:
- status == "paid"
- paymentMethod == "vietqr"

// Export CSV → Tính tổng column "amount" trong Excel
```

### 🛠️ Code Reference (VietQR_screen.dart):

```dart
// Line 130-145: Lưu vào Firestore
Future<void> _saveTransactionToFirestore() async {
  await FirebaseFirestore.instance
      .collection('transactions')  // ← Collection name
      .doc(_transactionId)
      .set({
        'transactionId': _transactionId,
        'status': 'pending',       // ← Initial status
        'amount': widget.amount,
        // ... các fields khác
      });
}

// Line 156-172: Listen realtime changes
void _startPaymentListener() {
  _paymentSubscription = FirebaseFirestore.instance
      .collection('transactions')  // ← Listen collection
      .doc(_transactionId)
      .snapshots()                 // ← Realtime updates
      .listen((snapshot) {
        if (snapshot.data()?['status'] == 'paid') {
          _onPaymentSuccess();     // ← Trigger success
        }
      });
}
```

---

## 2️⃣ Payment Methods - Collection: `deposits`

### 🎯 Mục đích:
- Lưu thông tin đặt cọc xe
- Quản lý phương thức thanh toán (Credit Card, Momo, ZaloPay, Banking)
- Tracking thời hạn đặt cọc (7 ngày)

### 📝 Cấu trúc Data:

```javascript
deposits/{depositId}
{
  // ============ THÔNG TIN ĐẶT CỌC ============
  "depositId": "1712345678901",                   // Timestamp-based ID
  "depositStatus": "confirmed",                   // confirmed | pending | cancelled
  "paymentStatus": "paid",                        // paid | pending | failed
  
  // ============ THÔNG TIN BOOKING ============
  "carName": "Mercedes S-Class 2024",             // Từ bookingData
  "carId": "car_mercedes_s_class",                // Từ bookingData
  "userId": "firebase_user_uid_123",              // Từ bookingData
  "phoneNumber": "+84987654321",                  // Từ bookingData
  "userEmail": "customer@example.com",            // Từ bookingData
  
  // ============ THÔNG TIN TIỀN ============
  "amount": 10000000,                             // Số tiền cọc (VND)
  "rentalPrice": 5000000,                         // Giá thuê/ngày
  "rentalDays": 3,                                // Số ngày thuê
  "totalRentalCost": 15000000,                    // Tổng tiền thuê
  
  // ============ PHƯƠNG THỨC THANH TOÁN ============
  "paymentMethod": "credit_card",                 // credit_card | momo | zalopay | banking
  
  // ============ TIMESTAMPS ============
  "depositDate": Timestamp(2026-04-07 10:00:00), // Ngày đặt cọc
  "expiresAt": Timestamp(2026-04-14 10:00:00),   // Hết hạn sau 7 ngày
  "startDate": Timestamp(2026-04-15 09:00:00),   // Ngày bắt đầu thuê xe
  "endDate": Timestamp(2026-04-18 18:00:00),     // Ngày trả xe
  
  // ============ ADDITIONAL INFO ============
  "pickupLocation": "123 Nguyễn Huệ, Q1, HCM",   // Địa điểm nhận xe
  "dropoffLocation": "456 Lê Lợi, Q1, HCM",      // Địa điểm trả xe
  "notes": "Cần có ghế trẻ em",                   // Ghi chú đặc biệt
}
```

### 🔄 Lifecycle:

```
BƯỚC 1: User chọn phương thức thanh toán
├─ Credit Card / Momo / ZaloPay / Banking
├─ Click "Thanh toán"
└─ App gọi: _processPayment()

BƯỚC 2: Simulate processing (2 giây)
├─ Hiển thị loading dialog
├─ Simulate payment gateway
└─ (Production: Gọi API thanh toán thật)

BƯỚC 3: Lưu vào Firestore
├─ Gọi: FirebaseFirestore.instance.collection('deposits').add(...)
├─ Tạo document mới với depositData
└─ Trạng thái: depositStatus = "confirmed", paymentStatus = "paid"

BƯỚC 4: Hiển thị success
├─ Close loading dialog
├─ Show success popup
└─ User có thể quay lại home

BƯỚC 5: Quản lý expiration
├─ expiresAt = depositDate + 7 days
├─ (Cần Cloud Function để auto-cancel nếu quá hạn)
└─ (Cần notification khi sắp hết hạn)
```

### 🎮 Cách kiểm soát từ Firebase Console:

#### ✅ Xem tất cả đặt cọc:
```
Collection: deposits
Order by: depositDate (descending)
```

#### ✅ Filter theo trạng thái:
```javascript
// Đặt cọc thành công
Filters:
- depositStatus == "confirmed"
- paymentStatus == "paid"

// Đang chờ xử lý
Filters:
- depositStatus == "pending"

// Đã hủy
Filters:
- depositStatus == "cancelled"
```

#### ✅ Filter theo phương thức thanh toán:
```javascript
Filters:
- paymentMethod == "credit_card"  → Thanh toán thẻ
- paymentMethod == "momo"         → Momo
- paymentMethod == "zalopay"      → ZaloPay
- paymentMethod == "banking"      → Chuyển khoản
```

#### ✅ Tìm đặt cọc theo user:
```javascript
Filters:
- userId == "firebase_user_uid_123"
Order by: depositDate (descending)
```

#### ✅ Đặt cọc sắp hết hạn (trong 2 ngày):
```javascript
Filters:
- expiresAt <= (2 days from now)
- depositStatus == "confirmed"
Order by: expiresAt (ascending)
```

#### ✅ Tính doanh thu theo phương thức:
```javascript
// Credit Card
Filters:
- paymentMethod == "credit_card"
- paymentStatus == "paid"
→ Sum "amount" column

// Momo
Filters:
- paymentMethod == "momo"
- paymentStatus == "paid"
→ Sum "amount" column
```

### 🛠️ Code Reference (payment_methods.dart):

```dart
// Line 660-676: Lưu deposit vào Firestore
if (widget.bookingData != null) {
  final depositData = {
    ...widget.bookingData!,            // Spread booking data
    'paymentMethod': _selectedPaymentMethod,
    'depositId': DateTime.now().millisecondsSinceEpoch.toString(),
    'depositStatus': 'confirmed',
    'paymentStatus': 'paid',
    'depositDate': FieldValue.serverTimestamp(),
    'expiresAt': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 7)),
    ),
  };

  await FirebaseFirestore.instance
      .collection('deposits')         // ← Collection name
      .add(depositData);              // Auto-generate document ID
}
```

---

## 🎓 DEMO CHO THẦY/CÔ

### Scenario 1: Test VietQR Payment
```
1. Mở app → Chọn xe → Đặt cọc VietQR
2. Vào Firebase Console → Collection "transactions"
3. Thấy document mới với status = "pending"
4. Đợi 10 giây → status tự động = "paid" ✅
5. App hiện success popup
```

### Scenario 2: Test Payment Methods
```
1. Mở app → Chọn xe → Đặt cọc
2. Chọn phương thức: Credit Card
3. Click thanh toán
4. Vào Firebase Console → Collection "deposits"
5. Thấy document mới với:
   - depositStatus = "confirmed"
   - paymentStatus = "paid"
   - paymentMethod = "credit_card" ✅
```

### Scenario 3: Manual Control (Từ Firebase)
```
1. User vào VietQR screen (tạo transaction)
2. Thầy/cô vào Firebase Console
3. Edit document → Đổi status = "paid"
4. App TỰ ĐỘNG detect → Success ngay lập tức! ✅
   (Không cần reload app, không cần đợi 10s)
```

---

## 📊 REPORTS & ANALYTICS

### Báo cáo doanh thu VietQR:
```javascript
Collection: transactions
Filters:
- status == "paid"
- createdAt >= (start_date)
- createdAt <= (end_date)

Export → Excel → =SUM(amount)
```

### Báo cáo đặt cọc theo phương thức:
```javascript
Collection: deposits
Filters:
- paymentStatus == "paid"
- depositDate >= (start_date)
- depositDate <= (end_date)

Group by: paymentMethod
Count: Number of deposits
Sum: Total amount
```

### Top xe được đặt cọc nhiều nhất:
```javascript
Collection: deposits
Filters:
- depositStatus == "confirmed"

Export → Excel → Pivot Table by "carName"
```

---

## 🔐 SECURITY (Quan trọng!)

### Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Transactions - User chỉ thấy của mình
    match /transactions/{transactionId} {
      allow read: if request.auth != null && 
                     request.auth.token.phone_number == resource.data.phoneNumber;
      allow create: if request.auth != null;
      allow update: if request.auth != null; // Cho phép app update status
    }
    
    // Deposits - User chỉ thấy của mình
    match /deposits/{depositId} {
      allow read: if request.auth != null && 
                     request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.userId;
    }
  }
}
```

### ⚠️ CHÚ Ý:
- Hiện tại rules có thể đang set `allow read, write: if true` (public)
- Nên update lại như trên để bảo mật
- Admin có thể đọc/ghi tất cả từ Firebase Console

---

## 🛠️ MAINTENANCE TASKS

### 1. Cleanup transactions cũ (mỗi 30 ngày):
```javascript
// Cloud Function (nên setup)
const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
  new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
);

await db.collection('transactions')
  .where('createdAt', '<', thirtyDaysAgo)
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => doc.ref.delete());
  });
```

### 2. Auto-cancel expired deposits:
```javascript
// Cloud Function chạy mỗi giờ
const now = admin.firestore.Timestamp.now();

await db.collection('deposits')
  .where('expiresAt', '<', now)
  .where('depositStatus', '==', 'confirmed')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      doc.ref.update({ depositStatus: 'cancelled' });
    });
  });
```

### 3. Send notification 2 ngày trước hết hạn:
```javascript
// Cloud Function chạy mỗi ngày
const twoDaysLater = admin.firestore.Timestamp.fromDate(
  new Date(Date.now() + 2 * 24 * 60 * 60 * 1000)
);

await db.collection('deposits')
  .where('expiresAt', '<=', twoDaysLater)
  .where('depositStatus', '==', 'confirmed')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      // Send push notification to user
      sendNotification(doc.data().userId, 
        'Đặt cọc sắp hết hạn!', 
        'Đặt cọc của bạn sẽ hết hạn sau 2 ngày'
      );
    });
  });
```

---

## ✅ CHECKLIST QUẢN LÝ HÀNG NGÀY

### Mỗi sáng:
- [ ] Check transactions mới (status = "paid")
- [ ] Check deposits mới (depositStatus = "confirmed")
- [ ] Xem deposits sắp hết hạn (expiresAt trong 2 ngày)

### Mỗi tuần:
- [ ] Export báo cáo doanh thu VietQR
- [ ] Export báo cáo đặt cọc theo phương thức
- [ ] Cleanup transactions cũ (>30 ngày)

### Mỗi tháng:
- [ ] Tổng doanh thu
- [ ] Top xe được đặt nhiều nhất
- [ ] Phân tích phương thức thanh toán phổ biến
- [ ] Review security rules

---

## 📞 TROUBLESHOOTING

### ❌ Lỗi: Transaction không tự động paid sau 10s
```
Kiểm tra:
1. Internet connection của device
2. Firebase Firestore enabled?
3. Console có báo lỗi không? (Check logs)
4. Timer có chạy không? (Check console.log)
```

### ❌ Lỗi: App không detect khi edit từ Firebase Console
```
Kiểm tra:
1. Firestore Listener có đang chạy không?
2. Check _startPaymentListener() được gọi chưa?
3. Internet connection
4. Firestore rules có block request không?
```

### ❌ Lỗi: Deposit không lưu vào Firestore
```
Kiểm tra:
1. widget.bookingData có null không?
2. Firebase initialized chưa? (main.dart)
3. Firestore security rules
4. Check exception trong try-catch
```

---

## 🎯 KẾT LUẬN

### 2 trang thanh toán hoàn toàn dựa trên Firebase:
- ✅ **VietQR_screen.dart** → Collection `transactions`
- ✅ **payment_methods.dart** → Collection `deposits`

### Bạn có thể kiểm soát 100% từ Firebase Console:
- ✅ Xem realtime data
- ✅ Edit/Update/Delete documents
- ✅ Filter, search, export
- ✅ Test payment manually (không cần app)

### Auto-sync realtime:
- ✅ Firestore Listener tự động detect thay đổi
- ✅ App update UI ngay lập tức
- ✅ Không cần reload app

---

**Tạo bởi:** LuxeDrive Development Team  
**Cập nhật:** April 7, 2026  
**Version:** 1.0  
**Dành cho:** Quản lý và Demo cho giảng viên
