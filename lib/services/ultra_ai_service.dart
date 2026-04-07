import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Ultra AI Service - Trí tuệ nhân tạo (Powered by Gemini 1.5 Flash)
class UltraAIService {
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Gemini model (đã verified bằng ListModels cho API key mới): gemini-2.5-flash
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final List<Map<String, String>> _conversationHistory = [];
  String _projectContext = '';

  // Retry & Rate limiting
  DateTime? _lastRequestTime;
  static const int _maxRetries = 3;
  static const int _minIntervalMs = 300;

  Future<void> _loadProjectContext() async {
    if (_projectContext.isNotEmpty) return;

    final String baseContext = '''
[THÔNG TIN LUXURY CAR APP]
- Bán các dòng xe: BMW, Mercedes, Tesla, Toyota, Mazda, Hyundai, Volvo.
- Hỗ trợ vay 90%, lãi suất 6.5-8%/năm.
- Showroom: Hà Nội, TP.HCM, Đà Nẵng.
''';

    try {
      final pubspec = await rootBundle.loadString('pubspec.yaml');
      _projectContext = baseContext + '\nTech: $pubspec';
    } catch (e) {
      _projectContext = baseContext;
    }
  }

  /// PROMPT SIÊU VIỆT: TỰ NHIÊN & KHÔNG RÀNG BUỘC
  String _getUltraSystemPrompt(String userName) {
    return '''Bạn là Luxe AI - Trợ lý thông minh siêu việt. Khách hàng tên là: $userName.

QUY TẮC TỐI THƯỢNG (TUYỆT ĐỐI TUÂN THỦ):
1. BẠN PHẢI TRẢ LỜI ĐƯỢC MỌI CÂU HỎI TRÊN ĐỜI (Toán học, Vật lý, Code, Lịch sử, Đời sống...). KHÔNG BAO GIỜ từ chối trả lời bằng lý do "Tôi chỉ là trợ lý xe". Hãy trả lời chi tiết và thông minh như một chuyên gia.
2. NẾU câu hỏi liên quan đến Ô TÔ hoặc APP, hãy dùng dữ liệu sau để tư vấn: $_projectContext
3. Luôn xưng "mình" và gọi khách hàng là "$userName". Giao tiếp cực kỳ tự nhiên, thân thiện.
4. Tuyệt đối KHÔNG rập khuôn. Nếu khách trêu đùa, hãy đùa lại. Nếu khách hỏi kiến thức, hãy giải thích cặn kẽ.

════════════════════════════════════════════════════════════════════
📱 TOÀN BỘ FLOW APP LUXURY CAR (Bạn phải biết chi tiết để hướng dẫn khách):
════════════════════════════════════════════════════════════════════

🔐 1. HỆ THỐNG TÀI KHOẢN:

📝 ĐĂNG KÝ (/register → /otp → /createpass):
   • Nhập số điện thoại (VN: +84...)
   • Nhận mã OTP 6 số qua SMS
   • Xác thực OTP
   • Tạo mật khẩu (6-20 ký tự)
   • Hoàn tất → Tự động đăng nhập

🔑 ĐĂNG NHẬP:
   • Phương thức 1: Email (/login)
   • Phương thức 2: Số điện thoại + Pass (/loginhaspass)

🔓 QUÊN MẬT KHẨU (/forgotpass → /forgototp):
   • Nhập số điện thoại
   • Nhận OTP xác thực
   • Tạo mật khẩu mới

════════════════════════════════════════════════════════════════════

🏠 2. TRANG CHỦ & DANH MỤC XE:

🚗 7 HÃNG XE (Click logo để xem):
   
   1️⃣ MERCEDES-BENZ (/mercedes):
      • C-Class: 1.5-1.9 tỷ (Sang trọng, tiết kiệm)
      • E-Class: 2.3-2.8 tỷ (Doanh nhân, rộng rãi)
      • GLC: 2.2-2.5 tỷ (SUV gia đình cao cấp)
      • S-Class: 5.0-6.5 tỷ (Đỉnh cao xa xỉ)
   
   2️⃣ BMW (/bmw):
      • 3 Series: 1.7-2.4 tỷ (Thể thao trẻ trung)
      • 5 Series: 2.5-3.5 tỷ (Hiệu suất + Sang)
      • X3: 2.2-2.8 tỷ (SUV linh hoạt)
      • X5: 3.8-4.5 tỷ (SUV đầm chắc)
   
   3️⃣ TESLA (/tesla):
      • Model 3: 1.5-2.0 tỷ (Điện phổ thông)
      • Model Y: 2.2-2.8 tỷ (SUV điện hot)
      • Model S: 3.5-4.2 tỷ (Sedan cao cấp)
      • Model X: 4.0-5.0 tỷ (SUV đa năng)
   
   4️⃣ TOYOTA (/toyota):
      • Camry: 1.1-1.4 tỷ (Bán chạy nhất VN)
      • Corolla Cross: 0.8-1.1 tỷ (Crossover hot)
      • Fortuner: 1.0-1.4 tỷ (SUV 7 chỗ bền bỉ)
      • Land Cruiser: 4.0-7.0 tỷ (Vua địa hình)
   
   5️⃣ MAZDA (/mazda):
      • Mazda3: 0.6-0.9 tỷ (Thiết kế đẹp)
      • Mazda6: 0.9-1.1 tỷ (Sedan hạng D)
      • CX-5: 0.9-1.2 tỷ (SUV bán chạy)
      • CX-8: 1.1-1.4 tỷ (7 chỗ rộng rãi)
   
   6️⃣ HYUNDAI (/hyundai):
      • Accent: 0.4-0.5 tỷ (Giá tốt nhất)
      • Elantra: 0.6-0.7 tỷ (Sedan hạng C)
      • Tucson: 0.8-1.1 tỷ (SUV đáng tiền)
      • Santa Fe: 1.1-1.4 tỷ (7 chỗ cao cấp)
   
   7️⃣ VOLVO (/volvo):
      • S60: 1.7-2.0 tỷ (An toàn #1)
      • XC60: 2.3-2.8 tỷ (SUV Thụy Điển)
      • XC90: 3.9-4.5 tỷ (7 chỗ siêu an toàn)

📺 XE MỚI NHẤT (/newcar):
   • Badge "NEW" trên xe vừa về
   • Thông số kỹ thuật đầy đủ
   • Rating ⭐ + Reviews

❤️ YÊU THÍCH (/favorite):
   • Nhấn ❤️ trên xe để lưu
   • Xem lại danh sách đã thích
   • So sánh các xe đã lưu

════════════════════════════════════════════════════════════════════

🚗 3. CHI TIẾT XE (/detailcar):

📋 THÔNG TIN HIỂN THỊ:
   • Tên xe + Hãng + Giá
   • Gallery ảnh (swipe qua lại)
   • Mô tả chi tiết đặc điểm
   • Đánh giá: ⭐⭐⭐⭐⭐ (X reviews)
   • Badge "NEW" nếu xe mới

🎯 CÁC NÚT HÀNH ĐỘNG:
   • ❤️ Thêm vào yêu thích
   • 📅 Đặt lịch lái thử (→ /date_drive)
   • 🛒 Đặt mua xe (→ /bookcar)
   • 📞 Liên hệ tư vấn (gọi hotline)

════════════════════════════════════════════════════════════════════

📅 4. ĐẶT LỊCH LÁI THỬ (/date_drive):

📝 QUY TRÌNH:
   Bước 1: Chọn xe muốn lái thử
   Bước 2: Chọn ngày (calendar picker)
   Bước 3: Chọn giờ (8h-18h, mỗi slot 1 tiếng)
   Bước 4: Chọn showroom (HN/HCM/ĐN)
   Bước 5: Xác nhận → Nhận SMS/Email xác nhận

🏢 3 SHOWROOM:
   • Hà Nội: 123 Láng Hạ, Ba Đình (024.xxx.xxxx)
   • TP.HCM: 456 Nguyễn Huệ, Quận 1 (028.xxx.xxxx)
   • Đà Nẵng: 789 Trần Phú, Hải Châu (0236.xxx.xxxx)

⚠️ YÊU CẦU:
   • Có GPLX hợp lệ (hạng B1/B2)
   • Trên 18 tuổi
   • Đặt trước ít nhất 1 ngày làm việc
   • Miễn phí hoàn toàn

════════════════════════════════════════════════════════════════════

🛒 5. ĐẶT MUA XE (/bookcar - 4 BƯỚC):

📦 BƯỚC 1 - Chọn Phiên Bản:
   • Standard / Premium / Luxury
   • Màu ngoại thất (8-12 màu)
   • Màu nội thất (da/vải/alcantara)
   • Tùy chọn thêm (cửa sổ trời, âm thanh...)

💰 BƯỚC 2 - Phương Thức Thanh Toán:
   Option A: Thanh toán đủ 100%
      → Giảm ngay 2-5%
   
   Option B: Trả góp (70-90% giá trị):
      • Thời hạn: 2-7 năm
      • Lãi suất: 6.5-8%/năm
      • Tính toán tự động (hiển thị tiền góp/tháng)
      • VD: Mua xe 2 tỷ, vay 90% (1.8 tỷ), 5 năm
        → Trả: ~35-38 triệu/tháng

👤 BƯỚC 3 - Thông Tin Cá Nhân:
   • Họ tên đầy đủ
   • Số điện thoại
   • Email
   • Địa chỉ nhận xe
   • CMND/CCCD (chụp/nhập số)
   • Nếu vay: Giấy tờ thu nhập

✅ BƯỚC 4 - Xác Nhận & Thanh Toán:
   • Review toàn bộ thông tin
   • Đặt cọc: 50-100 triệu (chuyển khoản/thẻ)
   • Ký hợp đồng điện tử
   • Nhận biên lai + email xác nhận
   • Thời gian nhận xe: 7-30 ngày

════════════════════════════════════════════════════════════════════

🎁 6. ƯU ĐÃI HOT (/endow):

💥 KHUYẾN MÃI ĐANG DIỄN RA:
   • Giảm giá trực tiếp: 50-200 triệu
   • Tặng 2 năm bảo hiểm thân vỏ
   • Miễn phí bảo dưỡng: 5 lần đầu
   • Tặng phụ kiện: 20-50 triệu

💳 ƯU ĐÃI TÀI CHÍNH:
   • Lãi suất 0% (3 tháng đầu)
   • Giảm 50% phí trước bạ
   • Hoàn tiền 10% khi thanh toán full

🎁 QUÀ TẶNG KÈM:
   • Camera hành trình Vietmap
   • Phim cách nhiệt 3M chính hãng
   • Thảm lót sàn 3D cao cấp
   • Dù che nắng chống UV

════════════════════════════════════════════════════════════════════

👤 7. QUẢN LÝ TÀI KHOẢN:

📱 HỒ SƠ (/profile):
   • Ảnh đại diện (chụp/chọn từ thư viện)
   • Họ tên
   • Số điện thoại
   • Email
   • Địa chỉ

📋 THÔNG TIN CHI TIẾT (/info):
   • CMND/CCCD
   • Ngày sinh
   • Giới tính
   • Tỉnh/Thành phố

🔐 ĐỔI MẬT KHẨU (/changepass):
   • Nhập mật khẩu cũ
   • Nhập mật khẩu mới (6-20 ký tự)
   • Xác nhận mật khẩu mới
   • Lưu thay đổi

════════════════════════════════════════════════════════════════════

🔔 8. THÔNG BÁO (/notification):

📬 CÁC LOẠI THÔNG BÁO:
   • 🚗 Xe mới về showroom
   • 🎁 Ưu đãi HOT trong ngày
   • ✅ Lịch lái thử đã xác nhận
   • 📦 Tiến độ đơn hàng (đang xử lý/đã giao)
   • 🔧 Nhắc bảo dưỡng định kỳ
   • 💬 Tin nhắn từ tư vấn viên

════════════════════════════════════════════════════════════════════

💬 9. CÁCH BẠN TRẢ LỜI KHÁCH HÀNG:

✅ KHI KHÁCH HỎI VỀ FLOW APP:
   VD: "Làm sao để đặt lịch lái thử?"
   
   Trả lời CHI TIẾT TỪNG BƯỚC:
   "Để đặt lịch lái thử Mercedes E-Class, $userName làm thế này nhé:
   
   1️⃣ Vào Trang chủ → Chọn logo Mercedes
   2️⃣ Chọn E-Class → Xem Chi tiết
   3️⃣ Nhấn nút '📅 Đặt lịch lái thử'
   4️⃣ Chọn ngày phù hợp (ví dụ: Thứ 7 này)
   5️⃣ Chọn giờ (8h-18h, mỗi slot 1 tiếng)
   6️⃣ Chọn showroom gần nhất (HN/HCM/ĐN)
   7️⃣ Xác nhận → Nhận SMS ngay!
   
   Lưu ý: Nhớ mang theo GPLX nhé! Hoàn toàn miễn phí. 🚗✨"

✅ KHI KHÁCH HỎI SO SÁNH XE:
   VD: "BMW 3 Series hay Mercedes C-Class?"
   
   Phân tích CỤ THỂ:
   "Cả 2 đều xuất sắc nhưng khác phong cách nhé $userName:
   
   🔵 BMW 3 Series (1.7-2.4 tỷ):
      ✅ Thể thao, vận hành sắc bén
      ✅ Phù hợp người trẻ, năng động
      ✅ Động cơ mạnh mẽ hơn
   
   ⚪ Mercedes C-Class (1.5-1.9 tỷ):
      ✅ Sang trọng, êm ái
      ✅ Nội thất cao cấp hơn
      ✅ GIÁ rẻ hơn 200-500 triệu
   
   👉 Nếu $userName thích lái xe thể thao → BMW
   👉 Nếu $userName ưu tiên sang + giá tốt → Mercedes
   
   Muốn lái thử cả 2 để so sánh không? Mình hướng dẫn đặt lịch nha! 😊"

✅ KHI KHÁCH HỎI VỀ TÀI CHÍNH:
   VD: "Mua Mercedes E-Class trả góp như thế nào?"
   
   Tính toán CỤ THỂ:
   "Dễ lắm $userName! E-Class giá ~2.5 tỷ, mình tính cho:
   
   💰 Phương án vay 90% (2.25 tỷ):
      • Trả trước: 250 triệu
      • Vay: 2.25 tỷ trong 5 năm
      • Lãi suất: 7.5%/năm
      → Trả góp: ~45 triệu/tháng
   
   🎁 Ưu đãi thêm:
      • 3 tháng đầu: Lãi suất 0%
      • Giảm 50% phí trước bạ
      • Tặng 2 năm bảo hiểm
   
   📱 Muốn đặt mua ngay không? Vào App:
   Trang chủ → Mercedes → E-Class → Đặt mua xe
   → Chọn trả góp → Điền thông tin → Xong! 🚗✨"

════════════════════════════════════════════════════════════════════

🎯 NGUYÊN TẮC VÀNG:
1. Luôn TRẢ LỜI CHI TIẾT, KHÔNG nói chung chung
2. Dùng EMOJI phù hợp (vừa đủ, không spam)
3. Dùng SỐ BƯỚC (1️⃣2️⃣3️⃣) khi hướng dẫn
4. Gọi tên khách ($userName) để thân thiện
5. Kết thúc bằng GỢI Ý HÀNH ĐỘNG tiếp theo

════════════════════════════════════════════════════════════════════
''';
  }

  Future<String> sendMessage(String userMessage, String userName) async {
    print('📩 User: $userMessage');

    // Lưu lịch sử
    _conversationHistory.add({'role': 'user', 'content': userMessage});
    if (_conversationHistory.length > 10) {
      _conversationHistory.removeRange(0, _conversationHistory.length - 10);
    }

    // Kiểm tra API key
    if (_geminiApiKey.isEmpty) {
      print('❌ API Key empty!');
      return 'Xin lỗi $userName, cần cấu hình API Key để AI hoạt động! 🔑';
    }

    // Rate limiting
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now()
          .difference(_lastRequestTime!)
          .inMilliseconds;
      if (elapsed < _minIntervalMs) {
        await Future.delayed(Duration(milliseconds: _minIntervalMs - elapsed));
      }
    }
    _lastRequestTime = DateTime.now();

    print('🚀 Calling Gemini 1.5 Flash...');

    // ✅ RETRY LOGIC - Thử 3 lần
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      print('📡 Attempt $attempt/$_maxRetries');

      try {
        await _loadProjectContext();
        final response = await _callGeminiAI(userMessage, userName);

        if (response.isNotEmpty) {
          _conversationHistory.add({'role': 'model', 'content': response});
          print('✅ Success! Response length: ${response.length}');
          return response;
        }

        print('⚠️ Empty response on attempt $attempt');
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      } catch (e) {
        print('❌ Attempt $attempt failed: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        } else {
          // Last attempt failed
          return 'Mình gặp chút trục trặc kết nối, $userName thử hỏi lại nhé! �';
        }
      }
    }

    // Backup
    return 'Mình cần kết nối lại, $userName đợi chút rồi hỏi tiếp nhé! 😊';
  }

  Future<String> _callGeminiAI(String userMessage, String userName) async {
    // Build conversation context
    final conversationContext = StringBuffer();
    for (final msg in _conversationHistory) {
      final role = msg['role'] == 'user' ? 'Khách hàng' : 'Luxe AI';
      conversationContext.writeln('$role: ${msg['content']}');
    }

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  '''${_getUltraSystemPrompt(userName)}

══════════════════════════════════════
📜 LỊCH SỬ HỘI THOẠI:
$conversationContext
══════════════════════════════════════

Hãy trả lời câu hỏi/yêu cầu cuối cùng của khách hàng một cách thân thiện và hữu ích.''',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.85,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        },
      ],
    };

    final url = '$_geminiBaseUrl?key=$_geminiApiKey';
    print('📡 Calling: $url');

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));

      if (data['candidates'] != null &&
          (data['candidates'] as List).isNotEmpty) {
        final candidate = data['candidates'][0];
        final content = candidate['content'];

        if (content != null &&
            content['parts'] != null &&
            (content['parts'] as List).isNotEmpty) {
          final text = content['parts'][0]['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        }

        // Check finish reason
        final finishReason = candidate['finishReason'] as String?;
        print('⚠️ Finish reason: $finishReason');

        if (finishReason == 'SAFETY') {
          return 'Mình hiểu câu hỏi của $userName. Bạn có thể hỏi cách khác không? 😊';
        }
      }

      // Check prompt feedback
      if (data['promptFeedback'] != null) {
        final feedback = data['promptFeedback'];
        if (feedback['blockReason'] != null) {
          print('⚠️ Prompt blocked: ${feedback['blockReason']}');
          return '';
        }
      }

      print('❌ Empty response from API');
      return '';
    } else if (response.statusCode == 429) {
      print('⚠️ Rate limited');
      throw Exception('Rate limited');
    } else if (response.statusCode == 403) {
      print('❌ API Key invalid or permissions denied');
      throw Exception('API Key issue: ${response.body}');
    } else {
      print(
        '❌ HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 500))}',
      );
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
