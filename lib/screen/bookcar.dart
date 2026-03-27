import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

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

  int _activeNavIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _activeNavIndex = index;
    });
    // Handle navigation based on index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/newcar');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/favorite');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
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

  void _confirmBooking() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thời gian'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa điểm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show success dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đặt lịch thành công',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Họ và tên: ${_nameController.text}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Số điện thoại: ${_phoneController.text}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Email: ${_emailController.text}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Ngày: ${_formatDate(_selectedDate)}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Thời gian: $_selectedTime',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Địa điểm: $_selectedLocation',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              'Xe: ${widget.carData['name']} - ${widget.carData['brand']}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3b82c8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3b82c8),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 32, 47),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 32, 47),
        elevation: 0,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          widget.carData['image'] ?? 'assets/images/RR.jpg',
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 80,
                              color: const Color(0xFF2a2a2a),
                              child: const Icon(
                                Icons.car_rental,
                                size: 40,
                                color: Colors.white54,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.carData['name'] ?? 'Unknown Car',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.carData['brand'] ?? 'Unknown Brand',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3b82c8),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3b82c8),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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
                    fillColor: const Color(0xFF1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3b82c8),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3b82c8) : const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3b82c8) : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3b82c8) : const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3b82c8) : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
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

  // Bottom Navigation from HomeScreen
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.directions_car_rounded, 1),
            _buildNavItem(Icons.favorite_rounded, 2),
            _buildNavItem(Icons.person_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: isActive ? 56 : 50,
        height: isActive ? 56 : 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(
                  colors: [const Color(0xFF3b82c8), const Color(0xFF1e5a9e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3b82c8).withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: isActive ? 28 : 26,
            ),
          ),
        ),
      ),
    );
  }
}
