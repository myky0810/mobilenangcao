# 📧 HƯỚNG DẪN DEBUG EMAIL NOTIFICATION

## ✅ Checklist Trước Khi Test

### 1. Kiểm Tra User Đã Đăng Nhập
- User **PHẢI** đăng nhập trước khi đặt cọc
- Kiểm tra: `FirebaseAuth.instance.currentUser != null`

### 2. Kiểm Tra User Có Email
User phải có email từ **MỘT TRONG HAI** nguồn:

#### Option A: Firestore (Ưu tiên)
```
Collection: users
Document ID: {uid} (từ FirebaseAuth)
Field: email (String)
```

**Cách thêm email vào Firestore:**
1. Mở Firebase Console
2. Vào Firestore Database
3. Vào collection `users`
4. Tìm document có ID = UID của user hiện tại
5. Thêm/Edit field `email` với giá trị là email thật của bạn

#### Option B: FirebaseAuth (Google Sign-In)
- Nếu user đăng nhập bằng Google, email tự động có sẵn
- Kiểm tra: `FirebaseAuth.instance.currentUser.email`

### 3. Kiểm Tra Gmail App Password
- Email: `myky08102003@gmail.com`
- App Password: `nftvvoqemrqrwnrw`
- **QUAN TRỌNG**: App Password KHÁC với mật khẩu Gmail thường!

**Cách tạo App Password:**
1. Vào https://myaccount.google.com/
2. Security → 2-Step Verification (BẬT NÓ!)
3. App passwords → Generate new
4. Chọn "Mail" và "Other device"
5. Copy password 16 ký tự (không có dấu cách)

---

## 🔍 Cách Debug Khi Test

### Bước 1: Chạy App với Flutter Run
```bash
cd "g:\VS CODE\mobilenangcao-main\mobilenangcao-main\doan_cuoiki"
flutter run
```

### Bước 2: Thực Hiện Flow Đặt Cọc
1. ✅ Đăng nhập (Google hoặc Phone)
2. ✅ Chọn xe muốn đặt cọc
3. ✅ Vào màn hình Deposit
4. ✅ Chọn Payment Methods
5. ✅ Chọn VietQR
6. ✅ Confirm Payment
7. ✅ Chờ 15 giây (auto payment demo)
8. ✅ Popup "Thanh toán thành công" xuất hiện
   
   👉 **ĐÚNG LÚC NÀY EMAIL SẼ ĐƯỢC GỬI!**

### Bước 3: Xem Logs
Trong console Flutter, bạn sẽ thấy logs như này:

#### ✅ Logs Thành Công:
```
════════════════════════════════════════════════════════
🎯 [VIETQR] PAYMENT SUCCESS - STARTING EMAIL NOTIFICATION
════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────┐
│ 📧 EMAIL NOTIFICATION SERVICE                        │
└─────────────────────────────────────────────────────┘
🚗 Car Name     : Mercedes S-Class
💰 Amount       : 5000000 VND
🔖 Transaction  : LD12345678

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ 📧 EMAIL SERVICE - PAYMENT NOTIFICATION          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

🔍 Step 1: Getting current user from FirebaseAuth...
✅ User found: UID = abc123xyz
   - Display Name: Test User
   - Auth Email: test@gmail.com

🔍 Step 2: Fetching user data from Firestore...
   Path: users/abc123xyz
✅ User document found in Firestore

🔍 Step 3: Looking for user email...
   - Firestore email: test@gmail.com
   - Auth email: test@gmail.com
✅ Email found: test@gmail.com

🔍 Step 4: Getting customer name...
   Customer name: Test User

🔍 Step 5: Preparing email data...

🔍 Step 6: Sending email via SMTP...
   Recipient: test@gmail.com

📤 Preparing SMTP connection...
   Host: smtp.gmail.com:587
   Sender: myky08102003@gmail.com

🚀 Sending email via SMTP...
   This may take 5-15 seconds...

✅ SMTP Send Report:
   Mail sent: myky08102003@gmail.com

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ ✅ EMAIL SENT SUCCESSFULLY!                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
📧 Email delivered to: test@gmail.com

┌─────────────────────────────────────────────────────┐
│ ✅ EMAIL SENT SUCCESSFULLY!                         │
└─────────────────────────────────────────────────────┘
```

#### ❌ Logs Lỗi Thường Gặp:

**1. User Chưa Đăng Nhập:**
```
❌ ERROR: No user logged in (FirebaseAuth.currentUser is null)
💡 User must be logged in to receive email notification
```
→ **FIX**: Đăng nhập trước khi đặt cọc!

**2. User Không Có Email:**
```
❌ ERROR: No valid email found for user!
💡 Solutions:
   1. Add email field to Firestore: users/{uid}
   2. Or use Google Sign-In (has email by default)
```
→ **FIX**: Thêm email vào Firestore hoặc dùng Google login!

**3. Gmail Authentication Failed:**
```
❌ SMTP Sending Failed!
   Error: AuthenticationFailedException

💡 Authentication Error - Possible causes:
   1. Gmail App Password incorrect
   2. 2-Step Verification not enabled on Gmail
```
→ **FIX**: Kiểm tra App Password và 2-Step Verification!

**4. No Internet Connection:**
```
❌ SMTP Sending Failed!
   Error: SocketException

💡 Connection Error - Possible causes:
   1. No internet connection
   2. Firewall blocking port 587
```
→ **FIX**: Kiểm tra internet và firewall!

---

## 📧 Kiểm Tra Email Đã Nhận

### Sau khi thấy log "✅ EMAIL SENT SUCCESSFULLY":

1. **Kiểm tra Inbox** của email người nhận
   - Subject: `Xác nhận đặt cọc xe [TÊN XE] - LuxeDrive`
   - From: `LuxeDrive <myky08102003@gmail.com>`

2. **Nếu không thấy trong Inbox, kiểm tra:**
   - 📁 Spam/Junk folder
   - 📁 Promotions tab (Gmail)
   - 📁 Updates tab (Gmail)

3. **Nội dung email:**
   ```
   LuxeDrive - Premium Car Rental

   THANH TOÁN THÀNH CÔNG

   Xin chào [TÊN KHÁCH HÀNG],

   Chúng tôi đã nhận được khoản đặt cọc của bạn.

   CHI TIẾT ĐẶT CỌC
   - Xe: [TÊN XE]
   - Số tiền đặt cọc: [SỐ TIỀN] VNĐ
   - Ngày đặt cọc: [NGÀY GIỜ]
   - Hiệu lực đến: [NGÀY HẾT HẠN]
   - Mã giao dịch: [TRANSACTION_ID]

   LƯU Ý
   Xe sẽ được giữ chỗ đến hết ngày [NGÀY]. 
   Vui lòng liên hệ trước thời hạn này.

   Liên hệ LuxeDrive
   - Hotline: 1900 1234
   - Email: myky08102003@gmail.com
   ```

---

## 🛠️ Troubleshooting

### Email Không Gửi Được?

#### Check 1: User Info
```dart
// Thêm code debug vào VietQR_screen.dart
final user = FirebaseAuth.instance.currentUser;
print('Current User: ${user?.uid}');
print('User Email: ${user?.email}');
print('User Name: ${user?.displayName}');
```

#### Check 2: Firestore Data
1. Mở Firebase Console
2. Firestore Database
3. Collection: `users`
4. Tìm document có ID = user.uid
5. Kiểm tra field `email` có tồn tại không?

#### Check 3: Test SMTP Riêng
Tạo file test đơn giản:
```dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  final smtpServer = SmtpServer(
    'smtp.gmail.com',
    port: 587,
    username: 'myky08102003@gmail.com',
    password: 'nftvvoqemrqrwnrw',
    ssl: false,
    allowInsecure: true,
  );

  final message = Message()
    ..from = Address('myky08102003@gmail.com', 'Test')
    ..recipients.add('YOUR_EMAIL@gmail.com') // THAY EMAIL CỦA BẠN
    ..subject = 'Test Email'
    ..text = 'This is a test email';

  try {
    final report = await send(message, smtpServer);
    print('SUCCESS: $report');
  } catch (e) {
    print('FAILED: $e');
  }
}
```

---

## ⚡ Quick Fix Checklist

- [ ] User đã đăng nhập?
- [ ] User có email (Firestore hoặc Auth)?
- [ ] Internet đang hoạt động?
- [ ] Gmail App Password đúng?
- [ ] 2-Step Verification đã bật?
- [ ] Port 587 không bị firewall chặn?
- [ ] Đã chờ đủ 15s để popup success hiện?

---

## 📞 Support

Nếu vẫn không gửi được email sau khi check hết:
1. Xem đầy đủ logs trong console
2. Screenshot logs gửi cho dev
3. Kiểm tra Gmail "Less secure app access" settings
4. Thử tạo App Password mới
