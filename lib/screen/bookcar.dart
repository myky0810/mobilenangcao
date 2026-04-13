import 'package:flutter/material.dart';
import '../widgets/app_snackbar.dart';
import 'package:doan_cuoiki/widgets/scrollview_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'map_screen.dart';

import '../services/user_service.dart';

class BookCarScreen extends StatefulWidget {
  final Map<String, dynamic> carData;

  const BookCarScreen({super.key, required this.carData});

  @override
  State<BookCarScreen> createState() => _BookCarScreenState();
}

class _BookCarScreenState extends State<BookCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedLocation;

  // Nền đồng bộ với DetailCarScreen (detailcar.dart)
  static const _bg = Color.fromARGB(255, 18, 32, 47);
  static const _card = Color.fromARGB(255, 27, 42, 59);
  // Input như lúc đầu: dùng màu card (sáng hơn nền, dễ nhìn)
  static const _fieldFill = _card;
  static const _primaryColor = Color(0xFF5C8CFF);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final minimumDate = DateTime(2026, 1, 1);
    final maximumDate = DateTime(2027, 12, 31);

    DateTime tempSelected = _selectedDate ?? DateTime.now();
    if (tempSelected.isAfter(maximumDate)) tempSelected = maximumDate;
    if (tempSelected.isBefore(minimumDate)) tempSelected = minimumDate;

    int tempDay = tempSelected.day;
    int tempMonth = tempSelected.month;
    int tempYear = tempSelected.year;

    int maxDayFor(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    final dayController = FixedExtentScrollController(
      initialItem: (tempDay - 1).clamp(0, 30),
    );
    final monthController = FixedExtentScrollController(
      initialItem: (tempMonth - 1).clamp(0, 11),
    );
    final yearController = FixedExtentScrollController(
      initialItem: (tempYear - 2026).clamp(0, 2027 - 2026),
    );

    final DateTime? confirmed = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void clampDayIfNeeded() {
              final maxDay = maxDayFor(tempYear, tempMonth);
              if (tempDay > maxDay) {
                tempDay = maxDay;
                dayController.jumpToItem(tempDay - 1);
              }
            }

            return SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: dayController,
                                  itemExtent: 36,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      tempDay = index + 1;
                                      clampDayIfNeeded();
                                    });
                                  },
                                  children: List.generate(31, (i) {
                                    final day = i + 1;
                                    return Center(
                                      child: Text(
                                        '$day',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: CupertinoPicker(
                                  scrollController: monthController,
                                  itemExtent: 36,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      tempMonth = index + 1;
                                      clampDayIfNeeded();
                                    });
                                  },
                                  children: List.generate(12, (i) {
                                    final month = i + 1;
                                    return Center(
                                      child: Text(
                                        'tháng $month',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: yearController,
                                  itemExtent: 36,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      tempYear = 2026 + index;
                                      clampDayIfNeeded();
                                    });
                                  },
                                  children: List.generate(2027 - 2026 + 1, (i) {
                                    final year = 2026 + i;
                                    return Center(
                                      child: Text(
                                        '$year',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                          Center(
                            child: Container(
                              height: 36,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                child: const Text(
                                  'Hủy',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  final maxDay = maxDayFor(tempYear, tempMonth);
                                  final day = tempDay.clamp(1, maxDay);
                                  Navigator.pop(
                                    ctx,
                                    DateTime(tempYear, tempMonth, day),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Đồng ý',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != null) {
      setState(() {
        _selectedDate = confirmed;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'SELECT DATE';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildCarInfoCard() {
    // Debug log để kiểm tra URL
    debugPrint('Car Image URL: ${widget.carData['image']}');

    // Kiểm tra xem có phải network image không
    final carImage = widget.carData['image'] ?? 'assets/images/RR.jpg';
    final isNetworkImage =
        carImage.startsWith('http://') || carImage.startsWith('https://');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 200,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Hình xe
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isNetworkImage
                ? Image.network(
                    carImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error');
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: _card,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Không thể tải hình',
                              style: GoogleFonts.leagueSpartan(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: _card,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: _primaryColor,
                          ),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    carImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading asset image: $error');
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: _card,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Không thể tải hình',
                              style: GoogleFonts.leagueSpartan(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          // Thông tin xe
          Positioned(
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.carData['name'] ?? 'Unknown Car',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'THƯƠNG HIỆU',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  widget.carData['brand'] ?? 'Unknown Brand',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBooking() async {
    if (!_formKey.currentState!.validate()) {
      _showModernSnackBar(
        icon: Icons.warning_amber_rounded,
        message: 'Vui lòng điền đầy đủ thông tin',
        color: Colors.orange,
      );
      return;
    }

    if (_selectedDate == null) {
      _showModernSnackBar(
        icon: Icons.warning_amber_rounded,
        message: 'Vui lòng chọn ngày',
        color: Colors.orange,
      );
      return;
    }

    if (_selectedTime == null) {
      _showModernSnackBar(
        icon: Icons.warning_amber_rounded,
        message: 'Vui lòng chọn thời gian',
        color: Colors.orange,
      );
      return;
    }

    if (_selectedLocation == null) {
      _showModernSnackBar(
        icon: Icons.warning_amber_rounded,
        message: 'Vui lòng chọn địa điểm',
        color: Colors.orange,
      );
      return;
    }

    try {
      // Lưu dữ liệu đăng ký lái thử tạm thời (chưa có showroom)
      final profileRef = UserService.currentUserProfileRef(
        phoneIdentifier: widget.carData['phoneNumber']?.toString(),
      );
      final provider = UserService.currentProvider();

      final bookingData = {
        'carName': widget.carData['name'] ?? '',
        'carBrand': widget.carData['brand'] ?? '',
        'carImage': widget.carData['image'] ?? '',
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'date': DateFormat('MMMM d, yyyy', 'en_US').format(_selectedDate!),
        'time': _selectedTime,
        'location': _selectedLocation,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        // Link to the *profile* (works for both Google and phone login)
        'userProvider': provider,
        'userProfilePath': profileRef?.path ?? '',
        // Keep for backward compatibility with existing screens/indexes
        'userPhone': widget.carData['phoneNumber']?.toString().trim() ?? '',
      };

      if (!mounted) return;

      // Chuyển ngay sang trang MapScreen để chọn showroom
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MapScreen(preferredBrand: widget.carData['brand']?.toString()),
        ),
      );

      // Nếu người dùng đã chọn showroom, lưu booking hoàn chỉnh
      if (result != null && result is Map<String, dynamic>) {
        final showroom = result['showroom'] as Map<String, dynamic>?;
        final googleMapsUrl = result['googleMapsUrl'] as String?;

        if (showroom != null && googleMapsUrl != null) {
          // Thêm thông tin showroom vào booking data
          bookingData['showroomName'] = showroom['name'];
          bookingData['showroomAddress'] = showroom['address'];
          bookingData['showroomBrand'] = showroom['brand'];
          bookingData['showroomLat'] = showroom['lat'];
          bookingData['showroomLng'] = showroom['lng'];
          bookingData['googleMapsUrl'] = googleMapsUrl;
          bookingData['status'] = 'confirmed';

          // Lưu vào Firestore
          await FirebaseFirestore.instance
              .collection('test_drive_bookings')
              .add(bookingData);

          if (!mounted) return;

          // Hiện thông báo thành công
          _showModernSnackBar(
            icon: Icons.check_circle_rounded,
            message: 'Đăng ký lái thử thành công!',
            color: Colors.green,
          );

          // Quay về HomeScreen với flag để hiện notification
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
              arguments: {
                'phoneNumber': widget.carData['phoneNumber'],
                'showBookingNotification': true,
              },
            );
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showModernSnackBar(
        icon: Icons.error_rounded,
        message: 'Có lỗi xảy ra. Vui lòng thử lại.',
        color: Colors.redAccent,
      );
    }
  }

  void _showModernSnackBar({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    AppSnackBar.showModern(
      context,
      icon: icon,
      message: message,
      color: color,
      durationSeconds: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ĐẶT LỊCH LÁI THỬ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: ScrollViewAnimation.children(
        padding: const EdgeInsets.all(20.0),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Card - giống deposit.dart
                _buildCarInfoCard(),
                const SizedBox(height: 24),

                // Full Name Field
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập họ và tên',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: _fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Number Field
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập số điện thoại',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: _fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập email',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: _fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date Selection
                const Text(
                  'CHỌN NGÀY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null
                                ? Colors.white30
                                : Colors.white,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Selection
                const Text(
                  'CHỌN THỜI GIAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTimeChip('09:00 AM')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeChip('02:00 PM')),
                  ],
                ),
                const SizedBox(height: 20),

                // Location Selection
                const Text(
                  'ĐỊA ĐIỂM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildLocationButton('SHOWROOM')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildLocationButton('AT HOME')),
                  ],
                ),
                const SizedBox(height: 24),

                // Priority Access Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a3a52),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2a5a82)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.blue[300],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ưu tiên truy cập vào các mẫu xe mới và sự kiện độc quyền',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3b82c8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'XÁC NHẬN ĐẶT LỊCH',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    final isSelected = _selectedTime == time;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTime = time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton(String location) {
    final isSelected = _selectedLocation == location;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLocation = location;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
