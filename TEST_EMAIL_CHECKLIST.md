# 🧪 TEST EMAIL THẬT - CHECKLIST CUỐI CÙNG

## ✅ **ĐÃ CẬP NHẬT:**
- **Gmail App Password:** `nftvvoqemrqrwnrw` ✅
- **Sender Email:** `myky08102003@gmail.com` ✅
- **App Name:** LuxeDrive Car Rental ✅

---

## 📋 **CHECKLIST TRƯỚC KHI TEST:**

### ⚠️ **BƯỚC QUAN TRỌNG: THÊM USER TEST VÀO FIRESTORE**

**BẮT BUỘC** phải có user trong Firestore để app gửi email được!

#### **Cách 1: Thêm qua Firebase Console** (NHANH NHẤT)
1. **Vào Firebase Console:**
   ```
   https://console.firebase.google.com
   → Chọn project LuxeDrive
   → Firestore Database
   → Collection "users"
   → Add document
   ```

2. **Thêm user test:**
   ```javascript
   Document ID: [Auto-ID]
   
   Fields:
   phoneNumber: "+84123456789"      // ← Số điện thoại để test
   email: "your-email@gmail.com"    // ← EMAIL THẬT CỦA BẠN để nhận test
   displayName: "Test User"         // ← Tên hiển thị
   ```

   **⚠️ LƯU Ý:** Dùng email thật của bạn để kiểm tra nhận được email không!

#### **Cách 2: Thêm qua app** (nếu có trang register)
- Đăng ký user mới với email thật
- Đảm bảo email được lưu vào Firestore

---

## 🚀 **CÁCH TEST EMAIL:**

### **Timeline test:**
```
1. Mở app → VietQR screen
2. Đợi 15 giây → Payment success  
3. App sẽ:
   - Tìm user với phone "+84123456789" 
   - Lấy email "your-email@gmail.com"
   - Gửi email thật qua Gmail SMTP
4. Check inbox email của bạn! 📧
```

### **Test với phone khác:**
- Nếu muốn test với số điện thoại khác
- Sửa số phone trong `bank_transaction_checker.dart`
- Hoặc thêm nhiều user test với phone khác nhau

---

## 👀 **LOGS ĐỂ THEO DÕI:**

Khi chạy app, xem logs để debug:

### **✅ Logs thành công:**
```
🔍 [EMAIL] Looking up user by phone: +84123456789
👤 [EMAIL] Found user: Test User  
📧 [EMAIL] User email: your-email@gmail.com
🚀 [EMAIL] Attempting to send REAL email...
🔄 Preparing to send email to: your-email@gmail.com
📧 Sending email with SMTP...
✅ Email sent successfully to: your-email@gmail.com
```

### **❌ Logs lỗi phổ biến:**
```
⚠️ [EMAIL] No user found with phone: +84123456789
→ Cần thêm user vào Firestore!

⚠️ [EMAIL] User found but no email available
→ User không có field email!

❌ [EMAIL] Error: Invalid login credentials  
→ Gmail App Password sai!

❌ [EMAIL] Error: Connection refused
→ Không có internet hoặc SMTP bị block!
```

---

## 📱 **LỆNH ĐỂ CHẠY TEST:**

```bash
# Build lại app với password mới
cd "g:\VS CODE\mobilenangcao-main\mobilenangcao-main\doan_cuoiki"
flutter build apk --debug

# Run app
flutter run

# Hoặc install APK vào điện thoại
adb install build\app\outputs\flutter-apk\app-debug.apk
```

---

## 🎯 **KẾT QUẢ MONG ĐỢI:**

### **Email bạn sẽ nhận được:**
```
📧 From: LuxeDrive Car Rental <myky08102003@gmail.com>
📧 To: your-email@gmail.com
📧 Subject: ✅ Xác nhận đặt cọc xe BMW X7 2024 - LuxeDrive

🚗 LuxeDrive - Premium Car Rental
✅ THANH TOÁN THÀNH CÔNG

Xin chào Test User,

📋 CHI TIẾT ĐẶT CỌC
🚗 Xe đã đặt: BMW X7 2024
💰 Số tiền đặt cọc: 5.000.000 VNĐ
📅 Ngày đặt cọc: 07/04/2026 15:30
⏰ Hiệu lực đến: 14/04/2026
🔖 Mã đặt cọc: TXN_1712345678901
```

---

## ⚠️ **NẾU CHƯA CÓ USER TRONG FIRESTORE:**

App sẽ báo lỗi: **"No user found with phone"**

**→ PHẢI thêm user trước khi test!**

---

## 🚀 **READY TO TEST:**

**Bạn đã cập nhật Gmail App Password thành công!**

**Giờ chỉ cần:**
1. ✅ Thêm user test vào Firestore (email thật của bạn)
2. ✅ Run app 
3. ✅ Vào VietQR screen
4. ✅ Đợi 15s → Check email inbox! 📧✨

**App sẽ gửi email thật 100%! Không còn demo nữa! 🎉**
