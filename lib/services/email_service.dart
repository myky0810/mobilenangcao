import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Service gửi email THẬT qua Gmail SMTP
class EmailNotificationService {
  EmailNotificationService._();

  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _senderEmail = 'bn23092005@gmail.com';
  static const String _senderPassword = 'rgxwndooonudjciu';
  static const String _senderName = 'LuxeDrive';

  /// ✅ GỬI EMAIL TRỰC TIẾP ĐẾN ĐỊA CHỈ KHÁCH HÀNG NHẬP (KHÔNG LẤY TỪ FIRESTORE)
  static Future<bool> sendPaymentEmailToCustomerEmail({
    required String customerEmail,
    required String customerName,
    required String carName,
    required double amount,
    required String transactionId,
    Map<String, dynamic>? showroom,
  }) async {
    try {
      print('');
      print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
      print('┃ 📧 EMAIL SERVICE - GỬI TRỰC TIẾP ĐẾN CUSTOMER   ┃');
      print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
      print('📧 Email: $customerEmail');
      print('👤 Name: $customerName');
      print('🚗 Car: $carName');
      print('💰 Amount: ${amount.toStringAsFixed(0)} VND');
      print('🔖 Transaction: $transactionId');

      // Validate email
      if (customerEmail.isEmpty || !customerEmail.contains('@')) {
        print('❌ Email không hợp lệ!');
        return false;
      }

      print('');
      print('🔍 Chuẩn bị gửi email...');
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 7));

      // GỬI EMAIL THẬT
      final sent = await _sendSMTPEmail(
        toEmail: customerEmail,
        toName: customerName,
        carName: carName,
        amount: amount,
        transactionId: transactionId,
        depositDate: now,
        expiryDate: expiryDate,
        showroom: showroom,
      );

      print('');
      if (sent) {
        print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
        print('┃ ✅ GỬI EMAIL THÀNH CÔNG!                         ┃');
        print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
        print('📧 Email đã gửi đến: $customerEmail');
        print('💌 Kiểm tra hộp thư Inbox hoặc Spam');
      } else {
        print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
        print('┃ ❌ GỬI EMAIL THẤT BẠI!                           ┃');
        print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
      }

      print('');
      return sent;
    } catch (e, st) {
      print('');
      print('❌ LỖI: $e');
      print(st.toString());
      return false;
    }
  }

  /// Gửi email cho user đang đăng nhập
  static Future<bool> sendPaymentEmailToCurrentUser({
    required String carName,
    required double amount,
    required String transactionId,
    String? phoneIdentifier,
    Map<String, dynamic>? showroom,
  }) async {
    try {
      print('');
      print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
      print('┃ 📧 EMAIL SERVICE - GỬI EMAIL THẬT                ┃');
      print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');

      // Lấy thông tin profile từ Firestore theo provider
      print('🔍 Step 1: Đọc Firestore user profile (provider-safe)...');

      final profileRef = UserService.currentUserProfileRef(
        phoneIdentifier: phoneIdentifier,
      );

      DocumentSnapshot<Map<String, dynamic>>? userDoc;
      if (profileRef != null) {
        userDoc = await profileRef.get();
      }

      final userData = (userDoc != null && userDoc.exists)
          ? (userDoc.data() ?? {})
          : <String, dynamic>{};

      print('   Profile ref: ${profileRef?.path ?? "null"}');
      print('   Document exists: ${userDoc?.exists ?? false}');
      print('   Fields: ${userData.keys.toList()}');

      // Auth user là optional (phone-login Firestore-only có thể null)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('ℹ️ FirebaseAuth.currentUser is null (phone-login flow).');
      } else {
        print('✅ Auth UID: ${user.uid}');
        print('   Name (Auth): ${user.displayName ?? "null"}');
        print('   Email (Auth): ${user.email ?? "null"}');
      }

      // Tìm email
      print('');
      print('🔍 Step 3: Tìm email...');

      final firestoreEmail = (userData['email'] is String)
          ? (userData['email'] as String).trim()
          : null;
      print('   Firestore email: $firestoreEmail');

      final authEmail = user?.email?.trim();
      print('   Auth email: $authEmail');

      final userEmail = (firestoreEmail != null && firestoreEmail.isNotEmpty)
          ? firestoreEmail
          : (authEmail != null && authEmail.isNotEmpty)
          ? authEmail
          : null;

      if (userEmail == null || userEmail.isEmpty) {
        print('❌ Không tìm thấy email!');
        return false;
      }

      print('✅ Email tìm thấy: $userEmail');

      // Lấy tên khách hàng
      print('');
      print('🔍 Step 4: Lấy tên khách hàng...');
      String customerName = 'Khách hàng';

      if (userData['name'] is String &&
          (userData['name'] as String).isNotEmpty) {
        customerName = userData['name'];
      } else if (userData['displayName'] is String &&
          (userData['displayName'] as String).isNotEmpty) {
        customerName = userData['displayName'];
      } else if ((user?.displayName ?? '').isNotEmpty) {
        customerName = user!.displayName!;
      }

      print('   Tên: $customerName');

      // Chuẩn bị data
      print('');
      print('🔍 Step 5: Chuẩn bị nội dung email...');
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 7));

      print('   Car: $carName');
      print('   Amount: ${amount.toStringAsFixed(0)} VND');
      print('   Transaction: $transactionId');

      // GỬI EMAIL THẬT
      print('');
      print('🔍 Step 6: Gửi email qua Gmail SMTP...');
      print('   To: $userEmail');

      final sent = await _sendSMTPEmail(
        toEmail: userEmail,
        toName: customerName,
        carName: carName,
        amount: amount,
        transactionId: transactionId,
        depositDate: now,
        expiryDate: expiryDate,
        showroom: showroom,
      );

      print('');
      if (sent) {
        print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
        print('┃ ✅ GỬI EMAIL THÀNH CÔNG!                         ┃');
        print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
        print('📧 Email đã gửi đến: $userEmail');
        print('💌 Kiểm tra hộp thư Inbox hoặc Spam');
      } else {
        print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
        print('┃ ❌ GỬI EMAIL THẤT BẠI!                           ┃');
        print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
      }

      print('');
      return sent;
    } catch (e, st) {
      print('');
      print('❌ LỖI: $e');
      print(st.toString());
      return false;
    }
  }

  /// Gửi email qua SMTP THẬT
  static Future<bool> _sendSMTPEmail({
    required String toEmail,
    required String toName,
    required String carName,
    required double amount,
    required String transactionId,
    required DateTime depositDate,
    required DateTime expiryDate,
    Map<String, dynamic>? showroom,
  }) async {
    try {
      print('📤 Kết nối Gmail SMTP...');
      print('   Host: $_smtpHost:$_smtpPort');
      print('   Username: $_senderEmail');

      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _senderEmail,
        password: _senderPassword,
        ssl: false,
        allowInsecure: true,
      );

      // Format dữ liệu
      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
      final depositDateStr = dateFormatter.format(depositDate);
      final expiryDateStr = DateFormat('dd/MM/yyyy').format(expiryDate);

      final amountStr = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'VNĐ',
        decimalDigits: 0,
      ).format(amount);

      final Map<String, dynamic>? showroomMap =
          (showroom is Map<String, dynamic>) ? showroom : null;

      final showroomName = (showroomMap?['name']?.toString().trim() ?? '');
      final showroomAddress =
          (showroomMap?['address']?.toString().trim() ?? '');
      final showroomLat = showroomMap?['lat'];
      final showroomLng = showroomMap?['lng'];

      String directionsUrl = '';
      final lat = (showroomLat is num) ? showroomLat.toDouble() : null;
      final lng = (showroomLng is num) ? showroomLng.toDouble() : null;
      if (lat != null && lng != null) {
        directionsUrl =
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
      } else if (showroomAddress.isNotEmpty) {
        final encoded = Uri.encodeComponent(showroomAddress);
        directionsUrl =
            'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving';
      }

      // Nội dung email PLAIN TEXT
      final subject = 'Xác nhận đặt cọc xe $carName - LuxeDrive';
      final body =
          '''LuxeDrive - Premium Car Rental

THANH TOÁN THÀNH CÔNG

Xin chào $toName,

Chúng tôi đã nhận được khoản đặt cọc của bạn.

CHI TIẾT ĐẶT CỌC
- Xe: $carName
- Số tiền đặt cọc: $amountStr
- Ngày đặt cọc: $depositDateStr
- Hiệu lực đến: $expiryDateStr
- Mã giao dịch: $transactionId

SHOWROOM ĐÃ CHỌN
- Tên showroom: ${showroomName.isNotEmpty ? showroomName : 'N/A'}
- Địa chỉ: ${showroomAddress.isNotEmpty ? showroomAddress : 'N/A'}
${directionsUrl.isNotEmpty ? '- Chỉ đường Google Maps: $directionsUrl' : ''}

LƯU Ý
Xe sẽ được giữ chỗ đến hết ngày $expiryDateStr. Vui lòng liên hệ trước thời hạn này để hoàn tất thủ tục.

Liên hệ LuxeDrive
- Hotline: 1900 1234
- Email: $_senderEmail
''';

      print('');
      print('✉️  Tạo email...');
      print('   Subject: $subject');
      print('   Body: ${body.length} chars');

      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(toEmail)
        ..subject = subject
        ..text = body;

      print('');
      print('🚀 Đang gửi qua SMTP...');
      print('   (Có thể mất 5-15 giây)');

      final report = await send(message, smtpServer).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('SMTP timeout'),
      );

      print('');
      print('✅ SMTP Response: ${report.toString()}');
      print('   Mail sent: ${report.mail}');

      return true;
    } catch (e, st) {
      print('');
      print('❌ SMTP LỖI: $e');

      if (e.toString().contains('Authentication')) {
        print('💡 Lỗi xác thực Gmail:');
        print('   - Kiểm tra App Password');
        print('   - Kiểm tra 2-Step Verification');
      } else if (e.toString().contains('Connection') ||
          e.toString().contains('Socket')) {
        print('💡 Lỗi kết nối:');
        print('   - Kiểm tra internet');
        print('   - Kiểm tra firewall port 587');
      } else if (e.toString().contains('timeout')) {
        print('💡 Timeout:');
        print('   - Internet chậm');
        print('   - Gmail server bận');
      }

      print('');
      print('Stack trace:');
      print(st.toString().split('\n').take(10).join('\n'));

      return false;
    }
  }
}
