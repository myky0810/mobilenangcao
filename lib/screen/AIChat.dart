import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../data/firebase_helper.dart';
import '../services/ultra_ai_service.dart'; // Ultra AI - Maximum Intelligence System

class AIChatScreen extends StatefulWidget {
  final String? phoneNumber;

  const AIChatScreen({super.key, this.phoneNumber});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _userName = 'Guest';

  /// When true, AI stops responding and messages are expected to be handled by staff.
  bool _humanHandoffEnabled = false;

  /// Streams/refs
  DocumentReference<Map<String, dynamic>>? _chatRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;

  /// A lightweight in-memory catalog to help AI provide consistent answers.
  late final Map<String, Map<String, dynamic>> _carIndex;

  /// Ultra AI service - Multi-AI Intelligence System
  late final UltraAIService _ultraAI; // Khởi tạo Ultra AI
  bool _useUltraAI = true; // Bật Ultra AI thông minh
  bool _aiAvailable = true; // Trạng thái AI (có thể dùng không)

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _carIndex = _buildCarIndex();
    _ultraAI = UltraAIService(); // Khởi tạo Ultra AI service
    _loadUserName();
    _initAnimations();
    _initChat();
  }

  String _normalizePhoneOrFallback() {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) {
      // Still allow the UI to work on guest mode.
      return 'guest';
    }

    // Nếu là email (Google login), dùng trực tiếp email
    if (phone.contains('@')) {
      return phone.trim().toLowerCase();
    }

    return FirebaseHelper.normalizePhone(phone);
  }

  DocumentReference<Map<String, dynamic>> _chatDocRef() {
    final chatId = _normalizePhoneOrFallback();
    return FirebaseFirestore.instance.collection('chats').doc(chatId);
  }

  CollectionReference<Map<String, dynamic>> _chatMessagesRef() {
    return _chatDocRef().collection('messages');
  }

  Future<void> _initChat() async {
    _chatRef = _chatDocRef();

    // Ensure chat doc exists (safe upsert)
    try {
      await _chatRef!.set({
        'chatId': _normalizePhoneOrFallback(),
        'userPhone': widget.phoneNumber,
        'userName': _userName,
        'status': 'bot', // bot | pending_human | human
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort: keep UI usable.
    }

    // Listen for admin approval / status changes.
    _chatSub = _chatRef!.snapshots().listen((snap) {
      final data = snap.data();
      final status = (data?['status'] as String?) ?? 'bot';
      final human = status == 'human';
      if (human != _humanHandoffEnabled && mounted) {
        setState(() {
          _humanHandoffEnabled = human;
        });
      }
    });

    // Listen for message history.
    _messagesSub = _chatMessagesRef()
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snap) {
          final items = snap.docs
              .map((d) {
                final m = d.data();
                final role = (m['role'] as String?) ?? 'user';
                final createdAt = (m['createdAt'] as Timestamp?)?.toDate();
                return ChatMessage(
                  text: (m['text'] as String?) ?? '',
                  isUser: role == 'user',
                  timestamp: createdAt ?? DateTime.now(),
                );
              })
              .where((m) => m.text.trim().isNotEmpty)
              .toList();

          if (!mounted) return;
          setState(() {
            _messages
              ..clear()
              ..addAll(items);
          });
          _scrollToBottom();
        });

    // Seed welcome message once.
    try {
      final snap = await _chatRef!.get();
      final data = snap.data();
      final seeded = (data?['seededWelcome'] as bool?) ?? false;
      if (!seeded) {
        await _chatMessagesRef().add({
          'role': 'assistant',
          'text':
              'Xin chào $_userName! 👋\n\nMình là Luxe AI, trợ lý thông minh của Luxury Car. Mình có thể giúp bạn:\n\n'
              '🚗 Tư vấn xe phù hợp với nhu cầu\n'
              '💰 Thông tin giá & ưu đãi\n'
              '🎯 Đặt lịch lái thử\n'
              '💬 Trả lời mọi thắc mắc của bạn\n\n'
              'Bạn muốn tìm hiểu điều gì hôm nay? 😊',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _chatRef!.set({
          'seededWelcome': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Ignore.
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserName() async {
    try {
      final normalizedPhone = _normalizePhoneOrFallback();
      if (normalizedPhone == 'guest') return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(normalizedPhone)
          .get();

      final data = doc.data();
      final name = data?['name'] as String?;

      if (name != null && name.trim().isNotEmpty && mounted) {
        setState(() {
          _userName = name.split(' ').first;
        });

        // Keep chat metadata in sync.
        await _chatRef?.set({
          'userName': _userName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Ignore: keep guest.
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    // Persist user message.
    _chatMessagesRef().add({
      'role': 'user',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // If we've handed off to humans, do not respond as AI.
    if (_humanHandoffEnabled) {
      return;
    }

    // Detect user intent to talk to staff.
    if (_looksLikeHumanRequest(text)) {
      _requestHumanSupport(text);
      return;
    }

    setState(() => _isTyping = true);
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _respondAsBot(text);
    });
  }

  bool _looksLikeHumanRequest(String text) {
    final t = text.toLowerCase();
    // Detect when user wants to talk to a real staff member
    return (t.contains('nói chuyện') && t.contains('nhân viên')) ||
        (t.contains('kết nối') && t.contains('nhân viên')) ||
        (t.contains('gặp') && t.contains('nhân viên')) ||
        (t.contains('gọi') && t.contains('nhân viên')) ||
        (t.contains('chuyển') && t.contains('nhân viên')) ||
        (t.contains('tư vấn') && t.contains('nhân viên')) ||
        t.contains('nhân viên tư vấn') ||
        t.contains('chăm sóc khách hàng') ||
        t.contains('hỗ trợ trực tiếp') ||
        (t.contains('talk to') &&
            (t.contains('staff') ||
                t.contains('agent') ||
                t.contains('human'))) ||
        (t.contains('speak to') &&
            (t.contains('staff') ||
                t.contains('agent') ||
                t.contains('human'))) ||
        (t.contains('connect') &&
            (t.contains('support') ||
                t.contains('staff') ||
                t.contains('human'))) ||
        t.contains('human support') ||
        t.contains('real person');
  }

  Future<void> _requestHumanSupport(String userText) async {
    try {
      setState(() => _isTyping = true);

      // 1. Update chat status to pending_human
      await _chatRef?.set({
        'status': 'pending_human',
        'handoffRequestedAt': FieldValue.serverTimestamp(),
        'handoffReason': userText,
        'userPhone': widget.phoneNumber ?? 'guest',
        'userName': _userName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Create admin notification
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type': 'human_handoff_request',
        'chatId': _normalizePhoneOrFallback(),
        'userPhone': widget.phoneNumber ?? 'guest',
        'userName': _userName,
        'requestMessage': userText,
        'status': 'pending', // pending | approved | rejected
        'priority': 'normal', // normal | high | urgent
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // 3. Send confirmation message to user
      await _chatMessagesRef().add({
        'role': 'assistant',
        'text':
            '✅ Yêu cầu của bạn đã được gửi đi!\n\n'
            '🔔 Admin sẽ nhận được thông báo và phân công nhân viên tư vấn.\n\n'
            '⏰ Vui lòng chờ trong giây lát, nhân viên sẽ liên hệ với bạn sớm nhất. '
            'Cảm ơn bạn đã kiên nhẫn! 💙',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Human support request sent successfully');
      print('📱 Chat ID: ${_normalizePhoneOrFallback()}');
      print('👤 User: $_userName');
    } catch (e) {
      print('❌ Error requesting human support: $e');

      // Fallback message if error
      await _chatMessagesRef().add({
        'role': 'assistant',
        'text':
            'Xin lỗi, có lỗi xảy ra khi gửi yêu cầu. Vui lòng thử lại hoặc liên hệ hotline: 1900-xxxx',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  Future<void> _respondAsBot(String userText) async {
    String response;

    // Use Super AI for intelligent responses
    if (_useUltraAI) {
      try {
        print('🧠 Using Ultra AI to respond...');
        response = await _ultraAI.sendMessage(
          userText,
          _userName,
        ); // Dùng Ultra AI

        // Nếu vì lý do nào đó AI trả rỗng, chỉ khi đó mới dùng rule-based.
        if (response.trim().isEmpty) {
          response = _generateAssistantResponse(userText);
        }
      } catch (e) {
        // Service đã có fallback “mềm” và vẫn trả lời có ích,
        // nên ở đây không ép rơi qua rule-based nữa (tránh bị ràng buộc câu hỏi).
        print('❌ Ultra AI hard error in UI layer: $e');
        response =
            'Mình vẫn trả lời được nhé, nhưng AI đang trục trặc nhẹ. Bạn thử gửi lại 1 lần nữa giúp mình nha.';
      }
    } else {
      // Fallback to rule-based
      response = _generateAssistantResponse(userText);
    }

    try {
      await _chatMessagesRef().add({
        'role': 'assistant',
        'text': response,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _chatRef?.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'bot',
      }, SetOptions(merge: true));
    } finally {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  String _generateAssistantResponse(String userText) {
    final t = userText.trim();
    final lower = t.toLowerCase();

    // 1. GREETING & GENERAL QUESTIONS
    if (_isGreeting(lower)) {
      return 'Chào bạn $_userName! Mình là trợ lý AI của Luxury Car. Mình có thể giúp bạn:\n\n🚗 Tư vấn về các dòng xe cao cấp\n📊 So sánh các mẫu xe\n📅 Hướng dẫn đặt lịch lái thử\n📍 Tìm showroom gần bạn\n💰 Tư vấn giá và ưu đãi\n\nBạn cần mình hỗ trợ gì ạ?';
    }

    if (_isAskingAboutApp(lower)) {
      return 'App Luxury Car giúp bạn:\n\n• Xem danh sách xe cao cấp từ các thương hiệu: BMW, Mercedes, Tesla, Toyota, Mazda, Hyundai, Volvo\n• Đặt lịch lái thử xe tại showroom gần bạn\n• Xem thông tin chi tiết, hình ảnh, giá xe\n• Nhận thông báo về ưu đãi mới\n• Lưu xe yêu thích\n• Chat với AI để được tư vấn\n\nBạn muốn khám phá tính năng nào?';
    }

    if (_isThankYou(lower)) {
      return 'Không có gì! Rất vui được hỗ trợ bạn. Nếu cần thêm thông tin gì, cứ hỏi mình nhé! 😊';
    }

    // 2. CAR COMPARISON
    if (lower.contains('so sánh') ||
        lower.contains('compare') ||
        lower.contains('khác nhau')) {
      final brands = _extractKnownBrands(lower);
      if (brands.length >= 2) {
        return _compareBrands(brands[0], brands[1]);
      }
      return 'Bạn muốn so sánh 2 hãng xe nào? Mình có thể so sánh giữa:\n• BMW\n• Mercedes\n• Tesla\n• Toyota\n• Mazda\n• Hyundai\n• Volvo\n\nVí dụ: "So sánh BMW và Mercedes" nhé!';
    }

    // 3. PRICE QUESTIONS
    if (_isAskingPrice(lower)) {
      final matched = _findBestCarMatch(lower);
      if (matched != null) {
        final name = matched['name'] as String;
        final brand = matched['brand'] as String;
        return 'Giá xe $name ($brand):\n\n💵 Giá: ${matched['price']}\n\n📞 Để biết thông tin giá chính xác và các gói ưu đãi hiện tại, bạn có thể:\n• Xem chi tiết trong app (trang chủ → chọn hãng → chọn xe)\n• Đặt lịch tư vấn tại showroom\n• Liên hệ nhân viên chăm sóc khách hàng\n\nBạn muốn xem thêm thông tin gì về xe này không?';
      }
      return 'Để xem giá xe, bạn vui lòng cho mình biết:\n• Hãng xe: BMW, Mercedes, Tesla, Toyota, Mazda, Hyundai, Volvo\n• Hoặc mẫu xe cụ thể\n\nVí dụ: "Giá BMW X3" hoặc "Giá Mercedes GLC"';
    }

    // 4. PERFORMANCE/SPECS QUESTIONS
    if (_isAskingPerformance(lower)) {
      final matched = _findBestCarMatch(lower);
      if (matched != null) {
        return _getPerformanceInfo(matched);
      }
      return 'Bạn muốn biết thông số kỹ thuật của xe nào? Vui lòng cho mình biết hãng hoặc mẫu xe cụ thể.\n\nVí dụ: "Hiệu năng BMW X3" hoặc "Thông số Tesla Model 3"';
    }

    // 5. FEATURES/INTERIOR QUESTIONS
    if (_isAskingFeatures(lower)) {
      final matched = _findBestCarMatch(lower);
      if (matched != null) {
        return _getFeaturesInfo(matched);
      }
      return 'Bạn muốn biết tính năng/nội thất của xe nào? Vui lòng cho mình biết hãng hoặc mẫu xe.\n\nVí dụ: "Tính năng Mercedes GLC" hoặc "Nội thất BMW X5"';
    }

    // 6. BOOKING/TEST DRIVE
    if (_isAskingBooking(lower)) {
      return 'Để đặt lịch lái thử xe:\n\n📱 Cách 1 (Trong app):\n1. Vào Trang chủ (Home)\n2. Bấm icon Lịch 📅 ở thanh điều hướng\n3. Chọn hãng xe bạn muốn lái thử\n4. Chọn mẫu xe cụ thể\n5. Chọn showroom gần bạn\n6. Chọn ngày giờ phù hợp\n7. Xác nhận đặt lịch\n\n☎️ Cách 2:\nNếu bạn muốn được hỗ trợ trực tiếp, mình có thể kết nối bạn với nhân viên chăm sóc khách hàng.\n\nBạn muốn đặt lịch lái thử xe nào?';
    }

    // 7. SHOWROOM/LOCATION
    if (_isAskingLocation(lower)) {
      return 'Để tìm showroom gần bạn:\n\n🗺️ Cách 1 (Xem bản đồ):\n1. Vào Trang chủ (Home)\n2. Bấm icon Bản đồ 🗺️\n3. App sẽ hiện showroom trong bán kính 300km\n4. Bấm vào showroom để xem địa chỉ chi tiết\n5. Bấm "Chỉ đường" để dẫn đường\n\n📍 Cách 2 (Xem theo hãng):\n1. Chọn hãng xe bạn quan tâm\n2. Xem danh sách showroom ủy quyền\n\nHiện tại app hỗ trợ tìm showroom của: BMW, Mercedes, Tesla, Toyota, Mazda, Hyundai, Volvo.\n\nBạn đang ở khu vực nào và quan tâm showroom hãng nào?';
    }

    // 8. RECOMMENDATIONS
    if (_isAskingRecommendation(lower)) {
      return 'Để tư vấn xe phù hợp, mình cần biết thêm về nhu cầu của bạn:\n\n💰 Ngân sách:\n• Dưới 2 tỷ\n• 2-4 tỷ\n• Trên 4 tỷ\n\n👨‍👩‍👧‍👦 Mục đích sử dụng:\n• Gia đình (7 chỗ, rộng rãi)\n• Cá nhân/Công việc\n• Thể thao/Sang trọng\n\n⚡ Ưu tiên:\n• Tiết kiệm nhiên liệu\n• Hiệu năng mạnh\n• Công nghệ hiện đại\n• An toàn\n\nBạn vui lòng cho mình biết thêm để tư vấn chính xác hơn nhé!';
    }

    // 9. BRAND-SPECIFIC QUESTIONS
    final matched = _findBestCarMatch(lower);
    if (matched != null) {
      final name = matched['name'] as String;
      final brand = matched['brand'] as String;

      // If user mentions brand but no specific question, give overview
      return 'Về $name ($brand):\n\n✨ Đặc điểm nổi bật:\n${_getBrandHighlights(brand)}\n\n💵 Giá: ${matched['price']}\n\nBạn muốn biết thêm về:\n• Giá chi tiết và ưu đãi\n• Thông số kỹ thuật\n• Tính năng nội thất\n• So sánh với hãng khác\n• Đặt lịch lái thử\n\nHãy cho mình biết nhé!';
    }

    // 10. PROMOTIONS/DEALS
    if (_isAskingPromotion(lower)) {
      return 'Để xem các ưu đãi hiện tại:\n\n🎁 Trong app:\n1. Vào Trang chủ (Home)\n2. Bấm vào mục "Ưu đãi" hoặc icon quà tặng 🎁\n3. Xem danh sách chương trình khuyến mãi\n\n📢 Các loại ưu đãi thường có:\n• Giảm giá trực tiếp\n• Hỗ trợ lãi suất 0%\n• Phụ kiện/bảo hiểm miễn phí\n• Ưu đãi trade-in (đổi xe cũ)\n\nCác chương trình ưu đãi thay đổi theo thời gian. Bạn quan tâm ưu đãi cho hãng xe nào?';
    }

    // FALLBACK - More helpful default
    return 'Mình có thể giúp bạn về:\n\n🚗 **Tư vấn xe**\n• Giá, thông số kỹ thuật\n• Tính năng, nội thất\n• Đề xuất xe phù hợp\n\n📊 **So sánh**\n• So sánh các hãng xe\n• So sánh các mẫu xe\n\n📅 **Đặt lịch**\n• Lái thử xe\n• Tư vấn tại showroom\n\n📍 **Showroom**\n• Tìm showroom gần bạn\n• Địa chỉ, giờ mở cửa\n\n💰 **Ưu đãi**\n• Chương trình khuyến mãi\n• Hỗ trợ tài chính\n\nBạn cần hỗ trợ gì cụ thể? Hoặc cho mình biết bạn quan tâm hãng xe nào: BMW, Mercedes, Tesla, Toyota, Mazda, Hyundai, Volvo?';
  }

  // Helper methods for intent detection
  bool _isGreeting(String lower) {
    return lower.contains('xin chào') ||
        lower.contains('chào') ||
        lower.contains('hello') ||
        lower.contains('hi ') ||
        lower == 'hi' ||
        lower.contains('hey');
  }

  bool _isAskingAboutApp(String lower) {
    return (lower.contains('app') &&
            (lower.contains('làm') ||
                lower.contains('chức năng') ||
                lower.contains('có thể'))) ||
        lower.contains('hướng dẫn sử dụng') ||
        (lower.contains('ứng dụng') && lower.contains('này'));
  }

  bool _isThankYou(String lower) {
    return lower.contains('cảm ơn') ||
        lower.contains('thanks') ||
        lower.contains('thank you') ||
        lower.contains('cám ơn');
  }

  bool _isAskingPrice(String lower) {
    return lower.contains('giá') ||
        lower.contains('price') ||
        lower.contains('bao nhiêu') ||
        lower.contains('chi phí') ||
        lower.contains('cost');
  }

  bool _isAskingPerformance(String lower) {
    return lower.contains('hiệu năng') ||
        lower.contains('thông số') ||
        lower.contains('công suất') ||
        lower.contains('performance') ||
        lower.contains('specs') ||
        lower.contains('tốc độ') ||
        lower.contains('speed') ||
        lower.contains('động cơ') ||
        lower.contains('engine');
  }

  bool _isAskingFeatures(String lower) {
    return lower.contains('tính năng') ||
        lower.contains('nội thất') ||
        lower.contains('features') ||
        lower.contains('interior') ||
        lower.contains('tiện nghi') ||
        lower.contains('công nghệ') ||
        lower.contains('technology');
  }

  bool _isAskingBooking(String lower) {
    return lower.contains('đặt lịch') ||
        lower.contains('lái thử') ||
        lower.contains('test drive') ||
        lower.contains('book') ||
        lower.contains('đặt hẹn') ||
        lower.contains('hẹn lái');
  }

  bool _isAskingLocation(String lower) {
    return lower.contains('showroom') ||
        lower.contains('đại lý') ||
        lower.contains('địa chỉ') ||
        lower.contains('map') ||
        lower.contains('bản đồ') ||
        lower.contains('gần') ||
        lower.contains('ở đâu') ||
        lower.contains('near') ||
        lower.contains('location');
  }

  bool _isAskingRecommendation(String lower) {
    return (lower.contains('tư vấn') && !lower.contains('nhân viên')) ||
        lower.contains('nên mua') ||
        lower.contains('nên chọn') ||
        lower.contains('recommend') ||
        lower.contains('suggest') ||
        lower.contains('phù hợp') ||
        lower.contains('đề xuất');
  }

  bool _isAskingPromotion(String lower) {
    return lower.contains('ưu đãi') ||
        lower.contains('khuyến mãi') ||
        lower.contains('khuyến mại') ||
        lower.contains('promotion') ||
        lower.contains('deal') ||
        lower.contains('giảm giá') ||
        lower.contains('discount');
  }

  String _getBrandHighlights(String brand) {
    switch (brand.toLowerCase()) {
      case 'bmw':
        return '• Thiết kế thể thao, năng động\n• Công nghệ lái tự động hàng đầu\n• Động cơ mạnh mẽ, vận hành êm ái\n• Hệ thống iDrive hiện đại';
      case 'mercedes':
        return '• Sang trọng, đẳng cấp\n• Nội thất cao cấp, tiện nghi\n• An toàn 5 sao\n• Công nghệ MBUX thông minh';
      case 'tesla':
        return '• Xe điện 100%\n• Tự lái Autopilot\n• Tăng tốc cực nhanh\n• Pin lâu, sạc nhanh';
      case 'toyota':
        return '• Độ bền cao, ít hỏng vặt\n• Tiết kiệm nhiên liệu\n• Giá trị bán lại tốt\n• Chi phí bảo dưỡng thấp';
      case 'mazda':
        return '• Thiết kế Kodo đẹp mắt\n• Công nghệ Skyactiv tiết kiệm\n• Cách âm tốt\n• An toàn i-Activsense';
      case 'hyundai':
        return '• Thiết kế hiện đại\n• Công nghệ SmartSense\n• Bảo hành dài\n• Giá cạnh tranh';
      case 'volvo':
        return '• An toàn hàng đầu thế giới\n• Thiết kế Bắc Âu tối giản\n• Nội thất sang trọng\n• Công nghệ Pilot Assist';
      default:
        return '• Chất lượng cao cấp\n• Công nghệ hiện đại\n• Thiết kế đẳng cấp';
    }
  }

  String _getPerformanceInfo(Map<String, dynamic> car) {
    final name = car['name'] as String;
    final brand = car['brand'] as String;

    return 'Thông số kỹ thuật $name:\n\n⚙️ Để biết thông số chi tiết:\n• Vào app → Chọn hãng $brand → Chọn $name\n• Xem mục "Thông số kỹ thuật"\n\n📊 Thông tin thường bao gồm:\n• Động cơ: Dung tích, công suất\n• Hiệu năng: 0-100km/h, tốc độ tối đa\n• Tiêu thụ nhiên liệu\n• Hộp số, dẫn động\n• Kích thước, trọng lượng\n\nBạn muốn biết chi tiết nào cụ thể?';
  }

  String _getFeaturesInfo(Map<String, dynamic> car) {
    final name = car['name'] as String;
    final brand = car['brand'] as String;

    return 'Tính năng $name:\n\n🎯 Để xem đầy đủ:\n• Vào app → $brand → $name → "Tính năng"\n\n✨ Thường có:\n• Nội thất: Da cao cấp, ghế chỉnh điện, điều hòa tự động\n• Công nghệ: Màn hình cảm ứng, kết nối smartphone\n• An toàn: Túi khí, cảnh báo va chạm, camera 360\n• Tiện nghi: Cốp điện, đèn LED, cảm biến áp suất lốp\n\nBạn quan tâm nhóm tính năng nào nhất?';
  }

  List<String> _extractKnownBrands(String lower) {
    final brands = <String>[];
    for (final b in [
      'bmw',
      'mercedes',
      'tesla',
      'toyota',
      'mazda',
      'hyundai',
      'volvo',
    ]) {
      if (lower.contains(b)) brands.add(b);
    }
    return brands;
  }

  String _compareBrands(String b1, String b2) {
    final a = b1.toUpperCase();
    final b = b2.toUpperCase();

    // Specific comparisons for common pairs
    if ((b1 == 'bmw' && b2 == 'mercedes') ||
        (b1 == 'mercedes' && b2 == 'bmw')) {
      return 'So sánh BMW vs Mercedes:\n\n🎨 **Thiết kế:**\n• BMW: Thể thao, năng động, trẻ trung\n• Mercedes: Sang trọng, lịch lãm, đẳng cấp\n\n🏎️ **Vận hành:**\n• BMW: Cảm giác lái thể thao, chính xác\n• Mercedes: Êm ái, thoải mái, ổn định\n\n💡 **Công nghệ:**\n• BMW: iDrive, Driving Assistant Pro\n• Mercedes: MBUX, Drive Pilot\n\n💰 **Giá:**\n• Tương đương nhau ở cùng phân khúc\n• Mercedes thường cao hơn 5-10%\n\n🔧 **Bảo dưỡng:**\n• BMW: Chi phí cao, phụ tùng đắt\n• Mercedes: Chi phí cao, network rộng hơn\n\n**Kết luận:**\n• Chọn BMW nếu: Thích lái xe thể thao, trẻ trung\n• Chọn Mercedes nếu: Ưu tiên sự thoải mái, sang trọng\n\nBạn muốn so sánh 2 mẫu xe cụ thể không?';
    }

    if ((b1 == 'tesla' && (b2 == 'bmw' || b2 == 'mercedes')) ||
        ((b1 == 'bmw' || b1 == 'mercedes') && b2 == 'tesla')) {
      final traditional = b1 == 'tesla' ? b2.toUpperCase() : b1.toUpperCase();
      return 'So sánh Tesla vs $traditional:\n\n⚡ **Động cơ:**\n• Tesla: Điện 100%, không khí thải\n• $traditional: Xăng/Diesel/Hybrid\n\n🚀 **Hiệu năng:**\n• Tesla: Tăng tốc cực nhanh (0-100 trong 3-4s)\n• $traditional: Tăng tốc ổn (5-7s)\n\n💰 **Chi phí vận hành:**\n• Tesla: Tiết kiệm (điện), ít bảo dưỡng\n• $traditional: Tốn xăng, bảo dưỡng định kỳ\n\n🔋 **Tiện lợi:**\n• Tesla: Cần trạm sạc, thời gian sạc lâu\n• $traditional: Đổ xăng nhanh, trạm nhiều\n\n🤖 **Công nghệ:**\n• Tesla: Autopilot, OTA updates\n• $traditional: Công nghệ truyền thống, đáng tin\n\n**Kết luận:**\n• Chọn Tesla: Thích công nghệ, môi trường, tiết kiệm\n• Chọn $traditional: An tâm hơn, hạ tầng sẵn có\n\nBạn cần so sánh chi tiết hơn không?';
    }

    // Generic comparison
    return 'So sánh $a vs $b:\n\n📊 Cả 2 đều là thương hiệu uy tín:\n\n**$a:**\n${_getBrandHighlights(b1)}\n\n**$b:**\n${_getBrandHighlights(b2)}\n\n💡 **Lựa chọn phụ thuộc vào:**\n• Ngân sách của bạn\n• Mục đích sử dụng\n• Sở thích cá nhân\n• Mẫu xe cụ thể\n\nBạn cho mình biết thêm về nhu cầu để tư vấn chính xác hơn nhé!\n\nHoặc bạn muốn so sánh 2 mẫu xe cụ thể? (VD: BMW X3 2024 vs Mercedes GLC 2024)';
  }

  Map<String, dynamic>? _findBestCarMatch(String lower) {
    for (final entry in _carIndex.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // brand-only match
    for (final entry in _carIndex.entries) {
      final v = entry.value;
      final brand = (v['brand'] as String).toLowerCase();
      if (lower.contains(brand)) return v;
    }
    return null;
  }

  Map<String, Map<String, dynamic>> _buildCarIndex() {
    // Expanded car database with more models and better matching
    final cars = <Map<String, dynamic>>[
      // BMW
      {
        'name': 'BMW X3',
        'brand': 'BMW',
        'price': '2.199 - 2.799 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'BMW X5',
        'brand': 'BMW',
        'price': '3.999 - 5.299 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'BMW X7',
        'brand': 'BMW',
        'price': '6.299 - 7.499 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'BMW 3 Series',
        'brand': 'BMW',
        'price': '1.799 - 2.599 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'BMW 5 Series',
        'brand': 'BMW',
        'price': '2.499 - 3.899 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'BMW 7 Series',
        'brand': 'BMW',
        'price': '5.199 - 7.999 tỷ',
        'priceNote': 'tùy phiên bản',
      },

      // Mercedes
      {
        'name': 'Mercedes GLC',
        'brand': 'Mercedes',
        'price': '2.199 - 2.999 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mercedes GLE',
        'brand': 'Mercedes',
        'price': '4.299 - 6.199 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mercedes GLS',
        'brand': 'Mercedes',
        'price': '6.299 - 8.999 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mercedes C-Class',
        'brand': 'Mercedes',
        'price': '1.699 - 2.399 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mercedes E-Class',
        'brand': 'Mercedes',
        'price': '2.299 - 3.899 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mercedes S-Class',
        'brand': 'Mercedes',
        'price': '5.499 - 12.999 tỷ',
        'priceNote': 'tùy phiên bản',
      },

      // Tesla
      {
        'name': 'Tesla Model 3',
        'brand': 'Tesla',
        'price': '1.499 - 2.199 tỷ',
        'priceNote': 'xe điện',
      },
      {
        'name': 'Tesla Model Y',
        'brand': 'Tesla',
        'price': '2.599 - 3.499 tỷ',
        'priceNote': 'xe điện',
      },
      {
        'name': 'Tesla Model S',
        'brand': 'Tesla',
        'price': '3.999 - 5.299 tỷ',
        'priceNote': 'xe điện',
      },
      {
        'name': 'Tesla Model X',
        'brand': 'Tesla',
        'price': '4.499 - 6.199 tỷ',
        'priceNote': 'xe điện',
      },

      // Toyota
      {
        'name': 'Toyota Camry',
        'brand': 'Toyota',
        'price': '1.105 - 1.445 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Toyota Fortuner',
        'brand': 'Toyota',
        'price': '1.026 - 1.434 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Toyota Vios',
        'brand': 'Toyota',
        'price': '458 - 638 triệu',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Toyota Corolla Cross',
        'brand': 'Toyota',
        'price': '820 - 905 triệu',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Toyota Veloz Cross',
        'brand': 'Toyota',
        'price': '638 - 698 triệu',
        'priceNote': 'tùy phiên bản',
      },

      // Mazda
      {
        'name': 'Mazda CX-5',
        'brand': 'Mazda',
        'price': '749 - 1.019 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mazda CX-8',
        'brand': 'Mazda',
        'price': '1.099 - 1.309 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mazda CX-30',
        'brand': 'Mazda',
        'price': '839 - 929 triệu',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Mazda3',
        'brand': 'Mazda',
        'price': '669 - 869 triệu',
        'priceNote': 'tùy phiên bản',
      },

      // Hyundai
      {
        'name': 'Hyundai Tucson',
        'brand': 'Hyundai',
        'price': '769 - 1.065 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Hyundai Santa Fe',
        'brand': 'Hyundai',
        'price': '1.069 - 1.365 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Hyundai Creta',
        'brand': 'Hyundai',
        'price': '620 - 720 triệu',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Hyundai Accent',
        'brand': 'Hyundai',
        'price': '439 - 569 triệu',
        'priceNote': 'tùy phiên bản',
      },

      // Volvo
      {
        'name': 'Volvo XC60',
        'brand': 'Volvo',
        'price': '2.599 - 3.199 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Volvo XC90',
        'brand': 'Volvo',
        'price': '3.990 - 5.290 tỷ',
        'priceNote': 'tùy phiên bản',
      },
      {
        'name': 'Volvo S90',
        'brand': 'Volvo',
        'price': '2.299 - 2.899 tỷ',
        'priceNote': 'tùy phiên bản',
      },
    ];

    final index = <String, Map<String, dynamic>>{};
    for (final c in cars) {
      final name = (c['name'] as String).toLowerCase();
      index[name] = c;

      // Also add short model names for better matching
      final parts = name.split(' ');
      if (parts.length > 1) {
        // e.g., "x3", "model 3", "cx-5"
        final shortName = parts.sublist(1).join(' ');
        if (!index.containsKey(shortName)) {
          index[shortName] = c;
        }
      }
    }
    return index;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _messagesSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Check if user has sent any messages
  bool _hasUserMessages() {
    return _messages.any((message) => message.isUser);
  }

  /// Show feedback bottom sheet when user wants to exit
  Future<void> _showFeedbackBottomSheet() async {
    // Only show if user has chatted
    if (!_hasUserMessages()) {
      Navigator.pop(context);
      return;
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Bottom Sheet Content
            Container(
              margin: const EdgeInsets.only(top: 35), // Space for robot icon
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 50), // Space for robot icon overlap
                  // Question
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Bạn thấy phản hồi của AI này có tốt không?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Feedback Buttons - NO BORDER, FLAT DESIGN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // BUỒN
                        _buildFlatFeedbackButton(
                          context: context,
                          emoji: '😞',
                          label: 'BUỒN',
                          value: 'sad',
                        ),

                        // VUI
                        _buildFlatFeedbackButton(
                          context: context,
                          emoji: '😊',
                          label: 'VUI',
                          value: 'happy',
                        ),

                        // TỐT
                        _buildFlatFeedbackButton(
                          context: context,
                          emoji: '👍',
                          label: 'TỐT',
                          value: 'good',
                        ),

                        // TUYỆT VỜI
                        _buildFlatFeedbackButton(
                          context: context,
                          emoji: '✨',
                          label: 'TUYỆT VỜI',
                          value: 'excellent',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Robot Icon - POSITIONED ON TOP CENTER
            Positioned(
              top: 0,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0A0A0A), // Match background
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF29B6F6).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),

            // Close button X at top right
            Positioned(
              top: 45,
              right: 15,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Save feedback to Firebase if provided
    if (result != null) {
      try {
        // 1. Save feedback to Firebase
        await FirebaseFirestore.instance.collection('ai_feedback').add({
          'userId': _normalizePhoneOrFallback(),
          'userName': _userName,
          'feedback': result,
          'timestamp': FieldValue.serverTimestamp(),
          'chatId': _normalizePhoneOrFallback(),
        });

        // 2. Delete chat history completely in background
        _deleteChatHistoryCompletely();

        // 3. Show thank you message briefly
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cảm ơn bạn đã đánh giá! 💙',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFF29B6F6),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              elevation: 6,
            ),
          );
        }

        // 4. Navigate back to HomeScreen immediately
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        print('Error saving feedback: $e');
        // Still navigate back even if error
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } else {
      // User closed without rating - just exit normally
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Delete chat history completely (runs in background)
  Future<void> _deleteChatHistoryCompletely() async {
    try {
      // 1. Delete all messages in this chat
      final messagesSnapshot = await _chatMessagesRef().get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 2. Delete the entire chat document
      await _chatRef?.delete();

      print('✅ Chat history deleted completely - ready for fresh start');
    } catch (e) {
      print('❌ Error deleting chat history: $e');
    }
  }

  /// Build feedback button widget
  /// Build flat feedback button widget (NO BORDER, like image)
  Widget _buildFlatFeedbackButton({
    required BuildContext context,
    required String emoji,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            // Label
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build feedback button widget (OLD - with border)
  Widget _buildFeedbackButton({
    required BuildContext context,
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _showFeedbackBottomSheet,
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Luxe AI Assistant',
              style: GoogleFonts.leagueSpartan(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              // Quick action buttons
              if (!_humanHandoffEnabled) _buildQuickActions(),

              // Input area
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF4FC3F7)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.leagueSpartan(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.5, end: 1.0),
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white54.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      '🚗 Xe nào phù hợp với tôi?',
      '💰 Ưu đãi tháng này',
      '📅 Đặt lịch lái thử',
      '🔧 So sánh Mercedes vs BMW',
      '💳 Hỗ trợ vay mua xe',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _messageController.text = actions[index];
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  actions[index],
                  style: GoogleFonts.leagueSpartan(
                    color: const Color(0xFF4FC3F7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.leagueSpartan(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe your dream drive...',
                  hintStyle: GoogleFonts.leagueSpartan(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
