import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/vietqr_service.dart';
import '../services/bank_transaction_checker.dart';
import '../services/email_service.dart';
import '../services/warranty_service.dart';
import '../services/garage_service.dart';
import '../widgets/scrollview_animation.dart';

class VietQRScreen extends StatefulWidget {
  final String carName;
  final double amount;
  final Map<String, dynamic> carData;
  final String phoneNumber;
  final String customerEmail; // ✅ Thêm email từ deposit screen

  const VietQRScreen({
    super.key,
    required this.carName,
    required this.amount,
    required this.carData,
    required this.phoneNumber,
    required this.customerEmail, // ✅ Required email
  });

  @override
  State<VietQRScreen> createState() => _VietQRScreenState();
}

class _VietQRScreenState extends State<VietQRScreen>
    with TickerProviderStateMixin {
  String? _selectedBankId; // Mặc định chưa chọn ngân hàng
  late String _transactionId;
  late String _transferContent;
  String? _qrData; // Mặc định chưa có QR
  late Timer _timer;
  StreamSubscription<DocumentSnapshot>?
  _paymentSubscription; // Firestore listener
  int _remainingSeconds = 900; // 15 phút
  bool _showDetails = false;
  bool _paymentReceived = false; // Đã nhận thanh toán
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Match DetailCar palette
  static const Color _backgroundColor = Color.fromARGB(255, 18, 32, 47);
  static const Color _cardColor = Color.fromARGB(255, 27, 42, 59);
  static const Color _primaryColor = Color(0xFF4FC3F7);
  static const Color _accentColor = Color(0xFF00E676);
  static const Color _surfaceColor = Color(0xFF151937);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _initializePayment();
    _startTimer();
    _animationController.forward();
  }

  @override
  void dispose() {
    _timer.cancel();
    _paymentSubscription?.cancel(); // Cancel Firestore listener
    _animationController.dispose();
    super.dispose();
  }

  void _initializePayment() async {
    _transactionId = VietQRService.generateTransactionId();
    _transferContent = 'Dat coc ${widget.carName} $_transactionId';
    // Tạo QR ngay với VCB mặc định để luôn có QR hiển thị
    _selectedBankId = 'VCB'; // Default bank
    _generateQRData();

    // Lưu transaction vào Firestore
    await _saveTransactionToFirestore();

    // Bắt đầu listen Firestore realtime
    _startPaymentListener();

    // 🔄 TỰ ĐỘNG DEMO SAU 15 GIÂY
    // Sau 15 giây tự động cập nhật Firestore → Listener phát hiện → Success
    AutoPaymentDemo.startAutoPayment(transactionId: _transactionId);

    print('🔄 Auto payment demo started - will complete in 15 seconds');
    print(
      '💡 Demo mode: Payment will be automatically marked as paid after 15 seconds!',
    );
  }

  void _generateQRData() {
    if (_selectedBankId == null) return;

    // Tạo VietQR data chuẩn theo spec Ngân hàng Nhà nước
    _qrData = VietQRService.generateVietQRData(
      bankId: _selectedBankId!,
      accountNumber: VietQRService.accountNumber, // 1040379709
      amount: widget.amount,
      transferContent: _transferContent,
    );

    print('Generated QR Data: $_qrData'); // Debug log
    print('Transaction: $_transactionId'); // Debug log
    print('Amount: ${widget.amount}'); // Debug log
    print('Account: ${VietQRService.accountNumber}'); // Debug log
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _showTimeoutDialog();
      }
    });
  }

  // Lưu transaction vào Firestore với đầy đủ thông tin
  Future<void> _saveTransactionToFirestore() async {
    try {
      final profileRef = UserService.currentUserProfileRef(
        phoneIdentifier: widget.phoneNumber,
      );
      final provider = UserService.currentProvider();

      // Provider-safe user info (works even when FirebaseAuth.currentUser is null)
      String userId = '';
      String userEmail = '';
      String userDisplayName = '';
      if (profileRef != null) {
        final snap = await profileRef.get();
        final data = snap.data();
        if (data != null) {
          userId = (data['uid'] ?? data['userId'] ?? '') as String;
          userEmail = (data['email'] ?? '') as String;
          userDisplayName = (data['name'] ?? '') as String;
        }
      }

      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(_transactionId)
          .set({
            // Thông tin giao dịch
            'transactionId': _transactionId,
            'status': 'pending', // pending | paid | failed | timeout
            'amount': widget.amount,
            'paymentMethod': 'vietqr',
            'transferContent': _transferContent,
            'accountNumber': VietQRService.accountNumber,
            'bankId': _selectedBankId,

            // Thông tin xe
            'carName': widget.carName,
            'carBrand': widget.carData['carBrand'] ?? '',
            'carImage': widget.carData['carImage'] ?? '',
            'carPrice': widget.carData['carPrice'] ?? '',

            // Thông tin khách hàng (từ deposit screen)
            'customerName': widget.carData['customerName'] ?? '',
            'customerPhone': widget.carData['customerPhone'] ?? '',
            'customerEmail': widget.customerEmail,
            'customerAddress': widget.carData['address'] ?? '',
            'notes': widget.carData['notes'] ?? '',

            // Thông tin showroom
            'showroom': widget.carData['showroom'],

            // Thông tin user đăng nhập
            'userId': userId,
            'userEmail': userEmail,
            'userDisplayName': userDisplayName,
            'userPhone': widget.phoneNumber,
            // Provider-safe linkage to the profile document
            'userProvider': provider,
            'userProfilePath': profileRef?.path ?? '',

            // Timestamps
            'createdAt': FieldValue.serverTimestamp(),
            'paidAt': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('');
      print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
      print('┃ ✅ TRANSACTION SAVED TO FIRESTORE                ┃');
      print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
      print('📝 Transaction ID: $_transactionId');
      print('💰 Amount: ${widget.amount}');
      print('🚗 Car: ${widget.carName}');
      print('👤 Customer: ${widget.carData['customerName']}');
      print('📧 Email: ${widget.customerEmail}');
      print('📱 Phone: ${widget.carData['customerPhone']}');
      print('🏢 Showroom: ${widget.carData['showroom']?['name'] ?? 'N/A'}');
      print('👤 User ID: ${userId.isNotEmpty ? userId : 'N/A'}');
      print('');
    } catch (e) {
      print('❌ Error saving transaction: $e');
    }
  }

  // Listen Firestore realtime để phát hiện thanh toán
  void _startPaymentListener() {
    print('🔊 Starting Firestore listener for: $_transactionId');

    _paymentSubscription = FirebaseFirestore.instance
        .collection('transactions')
        .doc(_transactionId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            if (snapshot.exists) {
              final data = snapshot.data();
              final status = data?['status'] as String?;

              print('📊 Transaction status: $status');

              if (status == 'paid' && !_paymentReceived) {
                print('✅ Payment detected! Processing...');
                _onPaymentSuccess();
              }
            }
          },
          onError: (error) {
            print('❌ Firestore listener error: $error');
          },
        );
  }

  // Khi phát hiện thanh toán thành công
  void _onPaymentSuccess() {
    if (_paymentReceived) return; // Tránh gọi nhiều lần

    setState(() {
      _paymentReceived = true;
    });

    // Cancel timer và listener
    _timer.cancel();
    _paymentSubscription?.cancel();

    // Show loading
    _showPaymentProcessing();

    // ✅ KHÔNG gửi email ở đây nữa - sẽ gửi khi popup success hiện
  }

  // Hiển thị loading khi đang xử lý thanh toán
  void _showPaymentProcessing() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_surfaceColor, _cardColor],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _accentColor],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Đang xử lý thanh toán...',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng đợi trong giây lát',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Sau 2 giây: Đóng loading → Lưu booking → Gửi email → Hiện popup success
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      Navigator.of(context).pop(); // Đóng loading

      // � LƯU BOOKING VÀO FIRESTORE KHI THANH TOÁN THÀNH CÔNG
      await _saveBookingToFirestore();

      // �📧 GỬI EMAIL NGAY TRƯỚC KHI HIỆN POPUP (CHẶN LUỒNG)
      print('');
      print('════════════════════════════════════════════════════════');
      print('🎯 [VIETQR] PAYMENT SUCCESS - STARTING EMAIL NOTIFICATION');
      print('════════════════════════════════════════════════════════');
      await _sendPaymentSuccessEmail();
      print('════════════════════════════════════════════════════════');
      print('');

      // Hiện popup success NGAY SAU KHI email được xử lý
      if (mounted) {
        _showPaymentSuccessDialog();
      }
    });
  }

  /// 💾 LƯU BOOKING VÀO FIRESTORE KHI THANH TOÁN THÀNH CÔNG
  Future<void> _saveBookingToFirestore() async {
    try {
      final bookingId = 'BK${DateTime.now().millisecondsSinceEpoch}';

      final profileRef = UserService.currentUserProfileRef(
        phoneIdentifier: widget.phoneNumber,
      );
      final provider = UserService.currentProvider();

      // Provider-safe user info (works even when FirebaseAuth.currentUser is null)
      String userId = '';
      String userEmail = '';
      String userDisplayName = '';
      if (profileRef != null) {
        final snap = await profileRef.get();
        final data = snap.data();
        if (data != null) {
          userId = (data['uid'] ?? data['userId'] ?? '') as String;
          userEmail = (data['email'] ?? '') as String;
          userDisplayName = (data['name'] ?? '') as String;
        }
      }

      final bookingData = {
        // ID
        'bookingId': bookingId,
        'transactionId': _transactionId,

        // Trạng thái
        'status':
            'confirmed', // confirmed | pending_pickup | completed | cancelled
        'paymentStatus': 'paid',

        // Thông tin xe
        'carName': widget.carName,
        'carBrand': widget.carData['carBrand'] ?? '',
        'carImage': widget.carData['carImage'] ?? '',
        'carPrice': widget.carData['carPrice'] ?? '',

        // Số tiền
        'depositAmount': widget.amount,
        'totalPrice': widget.carData['carPrice'] ?? '',

        // Thông tin khách hàng
        'customerName': widget.carData['customerName'] ?? '',
        'customerPhone': widget.carData['customerPhone'] ?? '',
        'customerEmail': widget.customerEmail,
        'customerAddress': widget.carData['address'] ?? '',
        'notes': widget.carData['notes'] ?? '',

        // Thông tin showroom
        'showroomName': widget.carData['showroom']?['name'] ?? '',
        'showroomAddress': widget.carData['showroom']?['address'] ?? '',
        'showroomLat': widget.carData['showroom']?['lat'],
        'showroomLng': widget.carData['showroom']?['lng'],

        // Thông tin user đăng nhập
        'userId': userId,
        'userEmail': userEmail,
        'userDisplayName': userDisplayName,
        'userPhone': widget.phoneNumber,
        // Provider-safe linkage to the profile document
        'userProvider': provider,
        'userProfilePath': profileRef?.path ?? '',

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Ngày hết hạn giữ xe (7 ngày)
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      };

      // ✅ ALSO SAVE A DEPOSIT RECORD for Admin panel (Admin reads `deposits` collection)
      // This fixes the case where VietQR flow only created `transactions`/`bookings`.
      final depositId = (widget.carData['depositId'] ?? '')
          .toString()
          .trim()
          .isNotEmpty
          ? (widget.carData['depositId'] ?? '').toString().trim()
          : 'DP${DateTime.now().millisecondsSinceEpoch}';

      final depositData = {
        // Stable IDs
        'depositId': depositId,
        'transactionId': _transactionId,
        'bookingId': bookingId,

        // Status
        'depositStatus': 'confirmed',
        'paymentStatus': 'paid',
        'paymentMethod': 'vietqr',

        // Car
        'carName': widget.carName,
        'carBrand': widget.carData['carBrand'] ?? '',
        'carImage': widget.carData['carImage'] ?? '',
        'carPrice': widget.carData['carPrice'] ?? '',

        // Amount
        'depositAmount': widget.amount,

        // Customer
        'customerName': widget.carData['customerName'] ?? '',
        'customerPhone': widget.carData['customerPhone'] ?? '',
        'customerEmail': widget.customerEmail,
        'address': widget.carData['address'] ?? '',
        'notes': widget.carData['notes'] ?? '',

        // Showroom (admin screen supports either a `showroom` map or separated fields)
        'showroom': widget.carData['showroom'],

        // User linkage
        'userId': userId,
        'userEmail': userEmail,
        'userDisplayName': userDisplayName,
        'userPhone': widget.phoneNumber,
        'userProvider': provider,
        'userProfilePath': profileRef?.path ?? '',

        // Timestamps for Admin sorting
        'depositDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      };

      await FirebaseFirestore.instance
          .collection('deposits')
          .doc(depositId)
          .set(depositData, SetOptions(merge: true));

      // Lưu vào collection bookings
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .set(bookingData);

      // Cập nhật transaction với bookingId
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(_transactionId)
          .update({
            'bookingId': bookingId,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // ✅ TỰ TẠO WARRANTY PENDING KHI ĐẶT CỌC THÀNH CÔNG
      final warrantyPhone = widget.phoneNumber.trim();
      if (warrantyPhone.isNotEmpty) {
        try {
          await WarrantyService.createPendingWarranty(
            userId: warrantyPhone,
            carName: widget.carName,
            carBrand: widget.carData['carBrand'] ?? '',
            carImage: widget.carData['carImage'] ?? '',
            showroomName: widget.carData['showroom']?['name'] ?? '',
            showroomAddress: widget.carData['showroom']?['address'] ?? '',
            bookingId: bookingId,
            transactionId: _transactionId,
          );
          print('✅ Pending warranty created for $warrantyPhone');
        } catch (e) {
          print('⚠️ Warranty creation failed (non-blocking): $e');
        }

        // ✅ TỰ THÊM XE VÀO GARAGE (MY CAR) KHI ĐẶT CỌC THÀNH CÔNG
        try {
          await GarageService.addPurchasedCar(
            userId: warrantyPhone,
            carName: widget.carName,
            carBrand: widget.carData['carBrand'] ?? '',
            carImage: widget.carData['carImage'] ?? '',
            bookingId: bookingId,
            showroomName: widget.carData['showroom']?['name'] ?? '',
          );
          print('✅ Car added to garage for $warrantyPhone');
        } catch (e) {
          print('⚠️ Garage add failed (non-blocking): $e');
        }
      }

      print('');
      print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
      print('┃ ✅ BOOKING SAVED TO FIRESTORE                    ┃');
      print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
      print('📝 Booking ID: $bookingId');
      print('🔗 Transaction ID: $_transactionId');
      print('🚗 Car: ${widget.carName}');
      print('👤 Customer: ${widget.carData['customerName']}');
      print('💰 Deposit: ${widget.amount} VND');
      print('🏢 Showroom: ${widget.carData['showroom']?['name'] ?? 'N/A'}');
      print('📅 Expiry: ${DateTime.now().add(const Duration(days: 7))}');
      print('');
    } catch (e) {
      print('❌ Error saving booking: $e');
    }
  }

  /// 📧 GỬI EMAIL THÔNG BÁO THANH TOÁN THÀNH CÔNG
  /// ✅ GỬI EMAIL TRỰC TIẾP ĐẾN EMAIL KHÁCH HÀNG NHẬP TRONG DEPOSIT SCREEN
  Future<void> _sendPaymentSuccessEmail() async {
    try {
      print('');
      print('┌─────────────────────────────────────────────────────┐');
      print('│ 📧 EMAIL NOTIFICATION SERVICE                        │');
      print('└─────────────────────────────────────────────────────┘');
      print('🚗 Car Name     : ${widget.carName}');
      print('💰 Amount       : ${widget.amount.toStringAsFixed(0)} VND');
      print('🔖 Transaction  : $_transactionId');
      print('� Customer Email: ${widget.customerEmail}'); // ✅ Email từ deposit
      print('');

      // ✅ GỬI EMAIL TRỰC TIẾP ĐẾN ĐỊA CHỈ KHÁCH HÀNG NHẬP
      print('🔄 Calling EmailNotificationService...');
      final bool emailSent =
          await EmailNotificationService.sendPaymentEmailToCustomerEmail(
            customerEmail: widget.customerEmail, // ✅ Email từ TextField
            customerName: widget.carData['customerName'] ?? 'Khách hàng',
            carName: widget.carName,
            amount: widget.amount,
            transactionId: _transactionId,
            showroom: (widget.carData['showroom'] is Map)
                ? Map<String, dynamic>.from(widget.carData['showroom'])
                : null,
          );

      print('');
      if (emailSent) {
        print('┌─────────────────────────────────────────────────────┐');
        print('│ ✅ EMAIL SENT SUCCESSFULLY!                         │');
        print('└─────────────────────────────────────────────────────┘');
        print('🎉 Email notification đã được gửi thành công!');
        print('📧 Khách hàng vui lòng kiểm tra hộp thư email');
        print('💌 Email có thể nằm trong Inbox hoặc Spam folder');
      } else {
        print('┌─────────────────────────────────────────────────────┐');
        print('│ ⚠️  EMAIL SENDING FAILED                            │');
        print('└─────────────────────────────────────────────────────┘');
        print('❌ Không thể gửi email - vui lòng kiểm tra:');
        print('   1️⃣  User có đăng nhập không?');
        print('   2️⃣  User có email trong profile không?');
        print('   3️⃣  Gmail SMTP credentials có đúng không?');
        print('   4️⃣  Có kết nối internet không?');
        print('');
        print('💡 Payment vẫn THÀNH CÔNG - email chỉ là thông báo phụ');
      }
    } catch (e, stackTrace) {
      print('');
      print('┌─────────────────────────────────────────────────────┐');
      print('│ ❌ EMAIL SERVICE ERROR                              │');
      print('└─────────────────────────────────────────────────────┘');
      print('💥 Exception: $e');
      print('📋 Stack trace:');
      print(stackTrace.toString().split('\n').take(5).join('\n'));
      print('');
      print('⚠️  Email notification failed nhưng payment VẪN THÀNH CÔNG');
    }
  }

  // Hiển thị popup thanh toán thành công
  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_surfaceColor, _cardColor],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _accentColor.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentColor, _accentColor.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Thanh toán thành công!',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildSuccessDetailRow('Mã giao dịch', _transactionId),
                      const SizedBox(height: 8),
                      _buildSuccessDetailRow(
                        'Số tiền',
                        '${widget.amount.toStringAsFixed(0)} VND',
                      ),
                      const SizedBox(height: 8),
                      _buildSuccessDetailRow('Xe thuê', widget.carName),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cảm ơn bạn đã sử dụng dịch vụ của LuxeDrive!',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Đóng dialog trước
                      Navigator.of(context).pop();

                      // ✅ Quay về Home nhưng phải giữ lại "ngữ cảnh đăng nhập"
                      // Nhiều nơi trong app phụ thuộc vào arguments (phoneNumber)
                      // để đọc profile hiện tại, nên không được tạo HomeScreen() trống.
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                        arguments: widget.phoneNumber,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Về trang chủ',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget cho chi tiết trong success dialog
  Widget _buildSuccessDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.leagueSpartan(
            color: _accentColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(
          'Hết thời gian thanh toán',
          style: GoogleFonts.leagueSpartan(color: Colors.white),
        ),
        content: Text(
          'Thời gian thanh toán đã hết. Vui lòng thử lại.',
          style: GoogleFonts.leagueSpartan(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: Text(
              'Đóng',
              style: GoogleFonts.leagueSpartan(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, color: _primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Giao dịch hết hạn sau',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              _formatTime(_remainingSeconds),
              style: GoogleFonts.leagueSpartan(
                color: _primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surfaceColor, _cardColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Header with VNPAY logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _accentColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'VNPAY',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  'QR',
                  style: GoogleFonts.leagueSpartan(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment method title
          Text(
            'Thanh toán qua App Ngân hàng/ Ví điện tử',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Transaction ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Text(
              'Mã giao dịch: $_transactionId',
              style: GoogleFonts.leagueSpartan(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.2),
                      _accentColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.leagueSpartan(
                        color: _accentColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'VND',
                      style: GoogleFonts.leagueSpartan(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showDetails = !_showDetails;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryColor),
                    borderRadius: BorderRadius.circular(8),
                    color: _showDetails
                        ? _primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showDetails ? Icons.visibility_off : Icons.visibility,
                        color: _primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showDetails ? 'Ẩn chi tiết' : 'Xem chi tiết',
                        style: GoogleFonts.leagueSpartan(
                          color: _primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Details section (expandable)
          if (_showDetails) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _backgroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Giá trị đơn hàng',
                    '${widget.amount.toStringAsFixed(0)} VND',
                  ),
                  _buildDetailRow('Phí giao dịch', '0 VND'),
                  _buildDetailRow('Xe thuê', widget.carName),
                  _buildDetailRow('Nhà cung cấp', 'LUXEDRIVE'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // QR Code - Luôn hiển thị
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _backgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // QR Code luôn hiển thị
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _accentColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _accentColor],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Quét mã để thanh toán',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cách thanh toán',
                        style: GoogleFonts.leagueSpartan(
                          color: _accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Quét mã QR bằng app ngân hàng bất kỳ\n2. Hoặc chọn ngân hàng bên dưới để mở app nhanh\n3. Xác nhận thanh toán ${widget.amount.toStringAsFixed(0)} VND\n4. Thông tin: STK ${VietQRService.accountNumber} - LuxeDrive',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.leagueSpartan(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.leagueSpartan(
                color: _accentColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Method to show bank app opening dialog
  void _showBankDialog(String bankId, String bankName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getBankColor(bankId),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildBankIcon(bankId),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mở $bankName',
                style: GoogleFonts.leagueSpartan(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withOpacity(0.1),
                    _accentColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.smartphone, size: 40, color: _primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    'Chuyển đến ứng dụng $bankName?',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã QR đã sẵn sàng, bạn có thể quét trực tiếp trong app ngân hàng',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Hủy',
              style: GoogleFonts.leagueSpartan(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();

              // CHỈ mở app ngân hàng, KHÔNG thay đổi QR
              _simulateOpenBankApp(bankName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getBankColor(bankId),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Mở App',
                  style: GoogleFonts.leagueSpartan(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _simulateOpenBankApp(String bankName) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Đang mở $bankName...',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Mã QR đã sẵn sàng để quét',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBankGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surfaceColor, _cardColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: _primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Mở app ngân hàng nhanh',
                style: GoogleFonts.leagueSpartan(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'QR có thể quét bằng bất kỳ app ngân hàng nào. Chọn để mở app trực tiếp:',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: VietQRService.supportedBanks.length > 18
                ? 18
                : VietQRService.supportedBanks.length,
            itemBuilder: (context, index) {
              final bank = VietQRService.supportedBanks[index];
              final isSelected = bank['id'] == _selectedBankId;

              return GestureDetector(
                onTap: () {
                  // CHỈ mở dialog để chuyển đến app, KHÔNG regenerate QR
                  _showBankDialog(bank['id']!, bank['name']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              _primaryColor.withOpacity(0.3),
                              _accentColor.withOpacity(0.3),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              _backgroundColor.withOpacity(0.3),
                              _backgroundColor.withOpacity(0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _accentColor
                          : _primaryColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Bank logo with improved design
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getBankColor(bank['id']!),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _getBankColor(
                                bank['id']!,
                              ).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildBankIcon(bank['id']!),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bank['shortName']!,
                        style: GoogleFonts.leagueSpartan(
                          color: isSelected ? _accentColor : Colors.white,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Icon(Icons.check_circle, color: _accentColor, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankIcon(String bankId) {
    // Tạo icon với chữ cái đầu của ngân hàng
    final bank = VietQRService.supportedBanks.firstWhere(
      (bank) => bank['id'] == bankId,
      orElse: () => {'shortName': 'Bank'},
    );

    return Center(
      child: Text(
        bank['shortName']![0],
        style: GoogleFonts.leagueSpartan(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getBankColor(String bankId) {
    switch (bankId) {
      case 'VCB':
        return const Color(0xFF007A33);
      case 'BIDV':
        return const Color(0xFF1E3A8A);
      case 'VTB':
        return const Color(0xFF0066CC);
      case 'AGR':
        return const Color(0xFF00A651);
      case 'TCB':
        return const Color(0xFFE31E24);
      case 'ACB':
        return const Color(0xFF1E88E5);
      case 'MB':
        return const Color(0xFF004225);
      case 'SHB':
        return const Color(0xFF1E88E5);
      case 'VPB':
        return const Color(0xFF007A33);
      case 'SCB':
        return const Color(0xFFE31E24);
      default:
        return const Color(0xFF1E88E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'VietQR Payment',
          style: GoogleFonts.leagueSpartan(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScrollViewAnimation.children(
          useSafeArea: false,
          padding: EdgeInsets.zero,
          children: [
            _buildTimerHeader(),
            _buildPaymentCard(),
            _buildBankGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
