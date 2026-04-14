import 'package:flutter/material.dart';
import 'package:doan_cuoiki/widgets/app_page_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../widgets/scrollview_animation.dart';

// Import VietQRScreen from correct file
import 'vietqr_screen.dart';
import '../services/warranty_service.dart';
import '../services/garage_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final double amount;
  final String carName;
  final Map<String, dynamic>? bookingData;

  const PaymentMethodsScreen({
    super.key,
    required this.amount,
    required this.carName,
    this.bookingData,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String? _selectedPaymentMethod;
  // Match DetailCar palette
  static const Color _backgroundColor = Color.fromARGB(255, 18, 32, 47);
  static const Color _cardColor = Color.fromARGB(255, 27, 42, 59);
  final Color _primaryColor = const Color(0xFF4FC3F7);
  final Color _accentColor = const Color(0xFF00E676);

  /// Safely closes the top-most route (dialog/screen) if it can.
  void _safePop() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
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
          'SECURE DEPOSIT',
          style: GoogleFonts.leagueSpartan(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: ScrollViewAnimation.children(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          // Background container for the whole top section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: _backgroundColor,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRANSACTION SUMMARY',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Car Deposit:',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.amount.toStringAsFixed(3)}',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standard Booking Fee',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Protection Active',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Payment Methods Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Method',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '3 OPTIONS AVAILABLE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ZaloPay Option
                _buildPaymentOption(
                  id: 'zalopay',
                  title: 'ZaloPay',
                  subtitle: 'Digital payment',
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0068FF), Color(0xFF00A3FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // VietQR Option
                _buildPaymentOption(
                  id: 'vietqr',
                  title: 'VietQR',
                  subtitle: 'QR code payment',
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Google Pay Option
                _buildPaymentOption(
                  id: 'googlepay',
                  title: 'Google Pay',
                  subtitle: 'Fast, safe payment',
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4285F4),
                          Color(0xFF34A853),
                          Color(0xFFFBBC05),
                          Color(0xFFEA4335),
                        ],
                        stops: [0.0, 0.33, 0.66, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Security Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.security,
                          color: _primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LuxeDrive Security Suite',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your payment information is encrypted and never stored on our servers. Protected via banking-grade SSL protocols.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedPaymentMethod != null
                        ? _confirmPayment
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      disabledBackgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm Payment',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _selectedPaymentMethod != null
                                ? Colors.black
                                : Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: _selectedPaymentMethod != null
                              ? Colors.black
                              : Colors.white54,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'ENCRYPTED BY LUXEDRIVE SECURITY SUITE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required Widget icon,
  }) {
    final bool isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? _primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment() {
    if (_selectedPaymentMethod == null) return;

    // Nếu chọn VietQR, hiển thị loading tự động rồi chuyển đến màn hình VietQR
    if (_selectedPaymentMethod == 'VietQR' ||
        _selectedPaymentMethod == 'vietqr') {
      // Hiển thị loading dialog đẹp mắt
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: _cardColor,
          content: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon VietQR với animation
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),

                // Loading indicator
                CircularProgressIndicator(color: _primaryColor, strokeWidth: 3),
                const SizedBox(height: 20),

                // Tiêu đề
                Text(
                  'Đang khởi tạo VietQR...',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Thông tin thanh toán
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Xe:',
                            style: GoogleFonts.leagueSpartan(
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.carName,
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Số tiền:',
                            style: GoogleFonts.leagueSpartan(
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.amount.toStringAsFixed(0)} VNĐ',
                            style: GoogleFonts.leagueSpartan(
                              color: _accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Thông tin tính năng
                Text(
                  '🏦 Hỗ trợ tất cả ngân hàng Việt Nam\n⏱️ Thời gian thanh toán: 15 phút\n💳 Quét QR để thanh toán nhanh chóng',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      // Tự động chuyển đến VietQR screen sau 2.5 giây
      Future.delayed(const Duration(milliseconds: 2500), () {
        Navigator.of(context).pop(); // Đóng loading dialog

        // Chuyển đến màn hình VietQR
        pushAppRoute(
          context,
          VietQRScreen(
            carName: widget.carName,
            amount: widget.amount,
            carData: widget.bookingData ?? {},
            // bookingData is built in DepositScreen and uses key 'userPhone'.
            // If we pass empty here, VietQR->Home will lose user context.
            phoneNumber:
                (widget.bookingData?['userPhone'] ??
                        widget.bookingData?['phoneNumber'] ??
                        '')
                    .toString(),
            customerEmail:
                widget.bookingData?['customerEmail'] ?? '', // ✅ Truyền email
          ),
        );
      });
      return;
    }

    // Các phương thức thanh toán khác (ZaloPay, Google Pay...)
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(height: 16),
              Text(
                'Processing Payment...',
                style: GoogleFonts.leagueSpartan(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we secure your transaction',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () async {
  // Close loading dialog (if still mounted)
  _safePop();

      try {
        // Lưu booking data vào Firestore
        if (widget.bookingData != null) {
          final now = Timestamp.now();

          final userPhone = (widget.bookingData?['userPhone'] ?? '').toString();
          if (userPhone.trim().isEmpty) {
            throw Exception('Thiếu userPhone nên không thể lưu đặt cọc.');
          }

          // Use a stable, readable doc id so admin can always load it.
          // We still store the same value in-field for cross-references.
          final depositId = (widget.bookingData?['depositId'] ?? '')
              .toString()
              .trim()
              .isNotEmpty
              ? (widget.bookingData?['depositId'] ?? '').toString().trim()
              : DateTime.now().millisecondsSinceEpoch.toString();

          final depositData = {
            ...widget.bookingData!,
            'depositId': depositId,
            'paymentMethod': _selectedPaymentMethod,
            'depositStatus': (widget.bookingData?['depositStatus'] ?? 'pending')
                .toString()
                .trim()
                .isEmpty
                ? 'pending'
                : (widget.bookingData?['depositStatus'] ?? 'pending'),
            'paymentStatus': (widget.bookingData?['paymentStatus'] ?? 'paid')
                .toString()
                .trim()
                .isEmpty
                ? 'paid'
                : (widget.bookingData?['paymentStatus'] ?? 'paid'),
            // Admin screens expect Timestamp fields for sorting.
            'depositDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            // Keep local 'now' as a fallback if serverTimestamp isn't resolved yet.
            'clientCreatedAt': now,
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(days: 7)),
            ),
          };

          final savedRef = FirebaseFirestore.instance
              .collection('deposits')
              .doc(depositId);
          await savedRef.set(depositData, SetOptions(merge: true));

          // Lưu snapshot nhanh vào profile để dễ debug + một số màn khác có thể đọc.
          try {
            final profileRef = UserService.currentUserProfileRef(
              phoneIdentifier: userPhone,
            );
            if (profileRef != null) {
              await profileRef.set({
                'lastDeposit': {
                  ...depositData,
                  'docId': savedRef.id,
                },
              }, SetOptions(merge: true));
            }
          } catch (_) {
            // Ignore profile snapshot failures.
          }

          // ✅ TỰ TẠO WARRANTY PENDING KHI ĐẶT CỌC THÀNH CÔNG
          final phone = (widget.bookingData?['userPhone'] ?? '')
              .toString()
              .trim();
          if (phone.isNotEmpty) {
            try {
              await WarrantyService.createPendingWarranty(
                userId: phone,
                carName: widget.carName,
                carBrand: widget.bookingData?['carBrand'] ?? '',
                carImage: widget.bookingData?['carImage'] ?? '',
                showroomName: widget.bookingData?['showroom']?['name'] ?? '',
                showroomAddress:
                    widget.bookingData?['showroom']?['address'] ?? '',
                bookingId: depositData['depositId'] ?? '',
                transactionId: '',
              );
            } catch (e) {
              debugPrint('⚠️ Warranty creation failed: $e');
            }

            // ✅ TỰ THÊM XE VÀO GARAGE (MY CAR)
            try {
              await GarageService.addPurchasedCar(
                userId: phone,
                carName: widget.carName,
                carBrand: widget.bookingData?['carBrand'] ?? '',
                carImage: widget.bookingData?['carImage'] ?? '',
                bookingId: depositData['depositId'] ?? '',
                showroomName: widget.bookingData?['showroom']?['name'] ?? '',
              );
            } catch (e) {
              debugPrint('⚠️ Garage add failed: $e');
            }
          }
        }

        // Show success dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _cardColor,
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment Successful!',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your car deposit has been secured.\nBooking confirmation will be sent to your email.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        debugPrint('❌ Deposit save failed: $e');

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _cardColor,
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment Failed',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Không lưu được đặt cọc: $e',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Try Again',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
  }
}
