# 📊 SƠ ĐỒ FIREBASE DATABASE - LUXEDRIVE APP

```
┌─────────────────────────────────────────────────────────────────────┐
│                      FIREBASE FIRESTORE                              │
│                   (Cloud NoSQL Database)                             │
└─────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────┐        ┌────────────────┐       ┌─────────────────┐
│  transactions │        │    deposits    │       │      users      │
│   (VietQR)    │        │ (Đặt cọc xe)   │       │  (Người dùng)   │
└───────────────┘        └────────────────┘       └─────────────────┘
        │                         │                         │
        │                         │                         │
        ▼                         ▼                         ▼
┌───────────────┐        ┌────────────────┐       ┌─────────────────┐
│ TXN_123456    │        │  DEP_789012    │       │   user_abc123   │
├───────────────┤        ├────────────────┤       ├─────────────────┤
│ status: paid  │        │ status: confirm│       │ name: John      │
│ amount: 5M    │        │ amount: 10M    │       │ email: john@... │
│ carName: BMW  │        │ method: card   │       │ balance: 5M     │
└───────────────┘        └────────────────┘       └─────────────────┘
```

---

## 🔄 FLOW THANH TOÁN VIETQR

```
┌──────────────────────────────────────────────────────────────────────┐
│                    USER JOURNEY - VIETQR                              │
└──────────────────────────────────────────────────────────────────────┘

Step 1: User vào VietQR Screen
    │
    ├─► App tạo QR code
    │
    └─► App gọi Firebase
            │
            ▼
    ┌─────────────────────────┐
    │  CREATE DOCUMENT        │
    │  Collection: transactions│
    │  ID: TXN_1712345678901  │
    │  status: "pending"      │
    │  amount: 5000000        │
    │  createdAt: now         │
    └─────────────────────────┘
            │
            ├─► Listener bắt đầu theo dõi
            │
            └─► Timer 10 giây bắt đầu
                    │
                    │ (10 seconds later...)
                    ▼
            ┌─────────────────────────┐
            │  UPDATE DOCUMENT        │
            │  status: "paid"         │
            │  paidAt: now            │
            │  autoDemo: true         │
            └─────────────────────────┘
                    │
                    ▼ (Firestore snapshots trigger)
            ┌─────────────────────────┐
            │  APP DETECTED!          │
            │  _onPaymentSuccess()    │
            │  → Show loading         │
            │  → Show success popup   │
            └─────────────────────────┘
```

---

## 🔄 FLOW ĐẶT CỌC (PAYMENT METHODS)

```
┌──────────────────────────────────────────────────────────────────────┐
│               USER JOURNEY - PAYMENT METHODS                          │
└──────────────────────────────────────────────────────────────────────┘

Step 1: User chọn xe
    │
    ├─► Chọn phương thức: Credit Card / Momo / ZaloPay / Banking
    │
    └─► Click "Thanh toán"
            │
            ▼ (2 seconds processing...)
    ┌─────────────────────────┐
    │  SIMULATE PAYMENT       │
    │  → Show loading dialog  │
    │  → Wait 2 seconds       │
    └─────────────────────────┘
            │
            ▼
    ┌─────────────────────────┐
    │  CREATE DOCUMENT        │
    │  Collection: deposits   │
    │  depositId: timestamp   │
    │  depositStatus: confirm │
    │  paymentStatus: paid    │
    │  paymentMethod: card    │
    │  amount: 10000000       │
    │  expiresAt: +7 days     │
    └─────────────────────────┘
            │
            ▼
    ┌─────────────────────────┐
    │  SHOW SUCCESS           │
    │  → Close loading        │
    │  → Success dialog       │
    │  → Navigate home        │
    └─────────────────────────┘
```

---

## 📊 FIREBASE CONSOLE VIEW

```
┌────────────────────────────────────────────────────────────────────┐
│  Firebase Console > Firestore Database > transactions              │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  Document ID: TXN_1712345678901                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Field             │ Type      │ Value                        │ │
│  ├──────────────────────────────────────────────────────────────┤ │
│  │ transactionId     │ string    │ TXN_1712345678901            │ │
│  │ status           │ string    │ paid          ← KEY FIELD    │ │
│  │ amount           │ number    │ 5000000                      │ │
│  │ carName          │ string    │ BMW X7 2024                  │ │
│  │ phoneNumber      │ string    │ +84123456789                 │ │
│  │ accountNumber    │ string    │ 1026106799                   │ │
│  │ bankId           │ string    │ VCB                          │ │
│  │ transferContent  │ string    │ Dat coc BMW X7 TXN_...       │ │
│  │ paymentMethod    │ string    │ vietqr                       │ │
│  │ createdAt        │ timestamp │ Apr 7, 2026 10:30:00 AM      │ │
│  │ paidAt           │ timestamp │ Apr 7, 2026 10:30:10 AM      │ │
│  │ autoDemo         │ boolean   │ true                         │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  [Edit] [Delete] [Clone]                                           │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  Firebase Console > Firestore Database > deposits                  │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  Document ID: 1712345678901                                        │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Field             │ Type      │ Value                        │ │
│  ├──────────────────────────────────────────────────────────────┤ │
│  │ depositId         │ string    │ 1712345678901                │ │
│  │ depositStatus     │ string    │ confirmed  ← KEY FIELD       │ │
│  │ paymentStatus     │ string    │ paid       ← KEY FIELD       │ │
│  │ carName           │ string    │ Mercedes S-Class 2024        │ │
│  │ carId             │ string    │ car_mercedes_s_class         │ │
│  │ userId            │ string    │ firebase_user_uid_123        │ │
│  │ phoneNumber       │ string    │ +84987654321                 │ │
│  │ amount            │ number    │ 10000000                     │ │
│  │ paymentMethod     │ string    │ credit_card ← PHƯƠNG THỨC   │ │
│  │ depositDate       │ timestamp │ Apr 7, 2026 10:00:00 AM      │ │
│  │ expiresAt         │ timestamp │ Apr 14, 2026 10:00:00 AM     │ │
│  │ startDate         │ timestamp │ Apr 15, 2026 09:00:00 AM     │ │
│  │ endDate           │ timestamp │ Apr 18, 2026 06:00:00 PM     │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  [Edit] [Delete] [Clone]                                           │
└────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 REAL-TIME SYNC

```
┌────────────────────────────────────────────────────────────────────┐
│                    FIRESTORE REAL-TIME LISTENER                     │
└────────────────────────────────────────────────────────────────────┘

Firebase Firestore                         Mobile App (Flutter)
┌──────────────────┐                      ┌──────────────────┐
│  transactions/   │                      │  VietQR Screen   │
│  TXN_123456      │                      │                  │
│                  │                      │  _startPayment   │
│  status: pending │◄─────────────────────┤  Listener()      │
│                  │   snapshots()        │                  │
└──────────────────┘   listen to          └──────────────────┘
        │              changes                      │
        │                                           │
        │ (10 seconds later...)                     │
        │                                           │
        ▼                                           │
┌──────────────────┐                                │
│  UPDATE          │                                │
│  status: paid    │                                │
│  paidAt: now     │                                │
└──────────────────┘                                │
        │                                           │
        │ ◄─────── Firestore triggers ─────────────┤
        │          snapshot event                   │
        ▼                                           ▼
┌──────────────────┐                      ┌──────────────────┐
│  New snapshot    │                      │  Listener detects│
│  status: paid    │─────────────────────►│  change!         │
└──────────────────┘      Real-time       │                  │
                          update           │  _onPayment      │
                                           │  Success()       │
                                           │                  │
                                           │  Show popup ✅   │
                                           └──────────────────┘
```

---

## 🎮 MANUAL CONTROL FROM FIREBASE CONSOLE

```
┌────────────────────────────────────────────────────────────────────┐
│               TEST PAYMENT WITHOUT APP                              │
└────────────────────────────────────────────────────────────────────┘

Step 1: User mở app → Vào VietQR screen
        App tạo document: status = "pending"

Step 2: Thầy/cô mở Firebase Console
        ┌─────────────────────────────────────┐
        │ 1. Vào Firestore Database           │
        │ 2. Collection: transactions         │
        │ 3. Tìm document mới nhất            │
        │ 4. Click "Edit document"            │
        │ 5. Thay đổi field:                  │
        │    status: "pending" → "paid"       │
        │ 6. Thêm field:                      │
        │    paidAt: (current timestamp)      │
        │ 7. Click "Save"                     │
        └─────────────────────────────────────┘
                        │
                        ▼
        ┌─────────────────────────────────────┐
        │  FIRESTORE AUTO-SYNC                │
        │  → App listener phát hiện ngay!     │
        │  → Không cần đợi 10 giây            │
        │  → Không cần reload app             │
        │  → Success popup hiện ngay lập tức! │
        └─────────────────────────────────────┘
```

---

## 📊 STATISTICS & REPORTS

```
┌────────────────────────────────────────────────────────────────────┐
│                    QUERIES FOR ANALYTICS                            │
└────────────────────────────────────────────────────────────────────┘

1. Tổng doanh thu VietQR hôm nay:
   ┌──────────────────────────────────────┐
   │ Collection: transactions             │
   │ Filters:                             │
   │  ├─ status == "paid"                 │
   │  ├─ createdAt >= (today 00:00)       │
   │  └─ createdAt <= (today 23:59)       │
   │ Export → Sum(amount)                 │
   └──────────────────────────────────────┘

2. Top phương thức thanh toán:
   ┌──────────────────────────────────────┐
   │ Collection: deposits                 │
   │ Filters:                             │
   │  └─ paymentStatus == "paid"          │
   │ Group by: paymentMethod              │
   │ ├─ credit_card: 50 bookings          │
   │ ├─ momo: 30 bookings                 │
   │ ├─ zalopay: 15 bookings              │
   │ └─ banking: 5 bookings               │
   └──────────────────────────────────────┘

3. Đặt cọc sắp hết hạn:
   ┌──────────────────────────────────────┐
   │ Collection: deposits                 │
   │ Filters:                             │
   │  ├─ expiresAt <= (2 days from now)   │
   │  └─ depositStatus == "confirmed"     │
   │ Order by: expiresAt (asc)            │
   │ → Send notification to users         │
   └──────────────────────────────────────┘
```

---

## 🔐 SECURITY ARCHITECTURE

```
┌────────────────────────────────────────────────────────────────────┐
│                    FIRESTORE SECURITY RULES                         │
└────────────────────────────────────────────────────────────────────┘

User Authentication (Firebase Auth)
        │
        ├─► Authenticated Users
        │   ├─ Can READ own transactions
        │   ├─ Can CREATE transactions
        │   ├─ Can UPDATE own transactions
        │   └─ Can READ own deposits
        │
        └─► Anonymous Users
            └─ DENIED (no access)

Admin (Firebase Console)
        ├─ Can READ all data
        ├─ Can WRITE all data
        ├─ Can DELETE all data
        └─ Can EXPORT all data

Rules Example:
┌──────────────────────────────────────────────┐
│ match /transactions/{transactionId} {        │
│   allow read: if request.auth != null &&     │
│      request.auth.token.phone_number ==      │
│      resource.data.phoneNumber;              │
│                                              │
│   allow create: if request.auth != null;     │
│   allow update: if request.auth != null;     │
│ }                                            │
└──────────────────────────────────────────────┘
```

---

## 🛠️ MAINTENANCE WORKFLOW

```
┌────────────────────────────────────────────────────────────────────┐
│                    AUTO CLEANUP (Cloud Functions)                   │
└────────────────────────────────────────────────────────────────────┘

Every 24 hours:
    │
    ├─► Cleanup Old Transactions (>30 days)
    │   ┌──────────────────────────────────┐
    │   │ Query: createdAt < 30 days ago   │
    │   │ Action: Delete documents         │
    │   │ Result: Free up storage          │
    │   └──────────────────────────────────┘
    │
    ├─► Cancel Expired Deposits
    │   ┌──────────────────────────────────┐
    │   │ Query: expiresAt < now           │
    │   │ Action: Update status='cancelled'│
    │   │ Result: Auto-cancel outdated     │
    │   └──────────────────────────────────┘
    │
    └─► Send Expiration Notifications
        ┌──────────────────────────────────┐
        │ Query: expiresAt in 2 days       │
        │ Action: Send push notification   │
        │ Result: Remind users             │
        └──────────────────────────────────┘
```

---

## 📱 APP ↔ FIREBASE CONNECTION

```
┌────────────────────────────────────────────────────────────────────┐
│                    FILES & FIREBASE INTEGRATION                     │
└────────────────────────────────────────────────────────────────────┘

VietQR_screen.dart
    │
    ├─► _saveTransactionToFirestore()
    │   └─► FirebaseFirestore.instance.collection('transactions').doc().set()
    │
    ├─► _startPaymentListener()
    │   └─► FirebaseFirestore.instance.collection('transactions').doc().snapshots()
    │
    └─► AutoPaymentDemo.startAutoPayment()
        └─► Timer(10s) → Update Firestore

payment_methods.dart
    │
    └─► _processPayment()
        └─► FirebaseFirestore.instance.collection('deposits').add()

bank_transaction_checker.dart
    │
    └─► AutoPaymentDemo.startAutoPayment()
        └─► Timer(10s) → Update Firestore.collection('transactions')
```

---

## 🎯 KEY POINTS FOR DEMO

```
✅ 2 Collections chính:
   ├─ transactions  (VietQR payments)
   └─ deposits      (Booking deposits)

✅ Real-time sync:
   ├─ App listen Firestore changes
   └─ Update UI ngay lập tức

✅ Manual control:
   ├─ Edit từ Firebase Console
   └─ App tự động detect

✅ Auto-demo mode:
   ├─ 10 giây tự động paid
   └─ Perfect cho presentation

✅ Production-ready:
   ├─ Có thể kết nối API ngân hàng thật
   └─ Chỉ cần thay AutoPaymentDemo
```

---

**Tạo bởi:** LuxeDrive Development Team  
**Ngày:** April 7, 2026  
**Mục đích:** Giúp quản lý Firebase Database dễ dàng hơn
