import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service OTP dùng Firestore — miễn phí, không cần cấu hình Firebase Phone Auth.
/// Mã OTP 6 số ngẫu nhiên được lưu vào Firestore và verify tại client.
class OTPService {
  OTPService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _otpCollection =>
      _db.collection('otp_codes');

  /// Tạo mã OTP 6 số ngẫu nhiên
  static String _generateOTP() {
    final random = Random();
    // Tạo số từ 100000 đến 999999
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Chuẩn hóa số điện thoại (dùng làm document ID)
  static String _normalizePhone(String phone) {
    var p = phone.trim().replaceAll(' ', '');
    // Giữ nguyên format +84xxx
    if (!p.startsWith('+')) {
      if (p.startsWith('0')) {
        p = '+84${p.substring(1)}';
      } else {
        p = '+84$p';
      }
    }
    return p;
  }

  /// Gửi OTP — tạo mã mới, lưu vào Firestore, trả về mã OTP
  /// Returns: mã OTP 6 số
  static Future<String> sendOTP(String phoneNumber) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    final otpCode = _generateOTP();
    final now = DateTime.now();

    // Lưu vào Firestore với thời gian hết hạn 5 phút
    await _otpCollection.doc(normalizedPhone).set({
      'otpCode': otpCode,
      'phoneNumber': normalizedPhone,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(minutes: 5))),
      'verified': false,
      'attempts': 0,
    });

    return otpCode;
  }

  /// Xác thực OTP — so sánh mã user nhập với mã trong Firestore
  /// Returns: true nếu đúng, throw exception nếu sai
  static Future<bool> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    final doc = await _otpCollection.doc(normalizedPhone).get();

    if (!doc.exists) {
      throw Exception('Không tìm thấy mã OTP. Vui lòng gửi lại mã.');
    }

    final data = doc.data()!;
    final storedOTP = data['otpCode'] as String;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    final verified = data['verified'] as bool? ?? false;
    final attempts = data['attempts'] as int? ?? 0;

    // Kiểm tra đã verify chưa
    if (verified) {
      throw Exception('Mã OTP đã được sử dụng. Vui lòng gửi lại mã mới.');
    }

    // Kiểm tra hết hạn
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.');
    }

    // Kiểm tra số lần thử (tối đa 5 lần)
    if (attempts >= 5) {
      throw Exception('Đã nhập sai quá nhiều lần. Vui lòng gửi lại mã mới.');
    }

    // So sánh mã OTP
    if (otpCode != storedOTP) {
      // Tăng số lần thử
      await _otpCollection.doc(normalizedPhone).update({
        'attempts': FieldValue.increment(1),
      });
      throw Exception('Mã OTP không đúng. Vui lòng thử lại.');
    }

    // Đánh dấu đã verify thành công
    await _otpCollection.doc(normalizedPhone).update({
      'verified': true,
      'verifiedAt': Timestamp.fromDate(DateTime.now()),
    });

    return true;
  }

  /// Gửi lại OTP — xóa mã cũ, tạo mã mới
  /// Returns: mã OTP 6 số mới
  static Future<String> resendOTP(String phoneNumber) async {
    // Gọi lại sendOTP sẽ tự động ghi đè mã cũ
    return await sendOTP(phoneNumber);
  }

  /// Xóa OTP sau khi đã dùng xong (cleanup)
  static Future<void> deleteOTP(String phoneNumber) async {
    final normalizedPhone = _normalizePhone(phoneNumber);
    try {
      await _otpCollection.doc(normalizedPhone).delete();
    } catch (_) {
      // Ignore errors
    }
  }
}
