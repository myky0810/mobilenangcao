import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  
  String _selectedGender = 'Nam';
  DateTime? _selectedDate;
  String? _selectedCity;
  String? _selectedDistrict;

  final List<String> _cities = [
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
  ];

  final List<String> _districts = [
    'Quận 1',
    'Quận 2',
    'Quận 3',
    'Quận 4',
    'Quận 5',
  ];

  @override
  void initState() {
    super.initState();
    // Set số điện thoại từ arguments
    _phoneController.text = _formatPhoneNumber(widget.phoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  // Format số điện thoại: +84987654321 -> 0987654321
  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '0123456789';
    if (phone.startsWith('+84')) {
      return '0${phone.substring(3)}';
    }
    if (phone.startsWith('84')) {
      return '0${phone.substring(2)}';
    }
    if (phone.startsWith('0')) {
      return phone;
    }
    return '0$phone';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF595959),
              onPrimary: Colors.white,
              surface: Color(0xFF333333),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges() {
    // TODO: Lưu thông tin vào Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu thay đổi'),
        backgroundColor: Color(0xFF333333),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Set status bar màu tối
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF333333),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Column(
        children: [
          // Header cùng màu #333333
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 8,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Thay đổi thông tin cá nhân',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                    
                    // Avatar tròn
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[700],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/RR.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Số điện thoại lớn (tên hiển thị)
                    Text(
                      _formatPhoneNumber(widget.phoneNumber),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Số điện thoại nhỏ
                    Text(
                      _formatPhoneNumber(widget.phoneNumber),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // TextField số điện thoại
                    TextField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '0123456789',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // TextField Email
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    // Radio buttons Nam/Nữ
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedGender = 'Nam';
                              });
                            },
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'Nam',
                                  groupValue: _selectedGender,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.all(Colors.white),
                                ),
                                const Text(
                                  'Nam',
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedGender = 'Nữ';
                              });
                            },
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'Nữ',
                                  groupValue: _selectedGender,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.all(Colors.white),
                                ),
                                const Text(
                                  'Nữ',
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chọn ngày sinh
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Chọn ngày sinh',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 20,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Chọn ngày sinh',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dropdown Chọn tỉnh/Thành phố
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      dropdownColor: const Color(0xFF333333),
                      decoration: InputDecoration(
                        hintText: 'Chọn tỉnh/Thành phố',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      items: _cities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCity = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Dropdown Chọn phường/xã
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      dropdownColor: const Color(0xFF333333),
                      decoration: InputDecoration(
                        hintText: 'Chọn phường/xã',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      items: _districts.map((String district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDistrict = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // TextField Tên đường
                    TextField(
                      controller: _streetController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Tên đường',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Nút Lưu thay đổi
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF333333),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
