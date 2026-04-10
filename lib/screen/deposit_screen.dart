import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:doan_cuoiki/services/showroom_api_service.dart';
import 'package:doan_cuoiki/screen/payment_methods.dart';
import '../services/user_service.dart';

class DepositScreen extends StatefulWidget {
  final String carName;
  final String carBrand;
  final String carImage;
  final String carPrice;
  final String? phoneNumber;

  const DepositScreen({
    super.key,
    required this.carName,
    required this.carBrand,
    required this.carImage,
    required this.carPrice,
    this.phoneNumber,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();

  bool _isLoading = false;
  bool _agreeTerms = false;
  int? _selectedDepositAmount;
  String _selectedPaymentMethod = 'bank_transfer';
  Map<String, dynamic>? _selectedShowroom;
  bool _isLoadingShowrooms = false;
  bool _isCustomAmount = false;

  // Màu sắc - Đồng bộ theo hình 2
  static const _bg = Color(0xFF1E2A47); // Nền xanh đậm theo hình 2
  static const _card = Color(
    0xFF2C3E5C,
  ); // Input field xanh đậm hơn theo hình 2
  static const _primaryColor = Color(0xFF5C8CFF); // Màu xanh navbar

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.phoneNumber == null || widget.phoneNumber!.isEmpty) return;

    try {
      final ref = UserService.currentUserProfileRef(
        phoneIdentifier: widget.phoneNumber,
      );
      if (ref == null) return;
      final doc = await ref.get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = widget.phoneNumber ?? '';
            _emailController.text = data['email'] ?? '';

            final street = data['street'] ?? '';
            final ward = data['wardName'] ?? '';
            final district = data['districtName'] ?? '';
            final province = data['provinceName'] ?? '';

            if (street.isNotEmpty) {
              _addressController.text = '$street, $ward, $district, $province';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _findNearestShowroom() async {
    debugPrint('🔍 Bắt đầu tìm showroom gần nhất...');
    setState(() => _isLoadingShowrooms = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ GPS không được bật');
        if (mounted) {
          _showSnackBar(
            'Vui lòng bật GPS để tìm showroom gần nhất',
            isError: true,
          );
        }
        setState(() => _isLoadingShowrooms = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('❌ Không có quyền truy cập vị trí');
        if (mounted) {
          _showSnackBar('Cần cấp quyền truy cập vị trí', isError: true);
        }
        setState(() => _isLoadingShowrooms = false);
        return;
      }

      // Thêm timeout cho getCurrentPosition
      debugPrint('📍 Đang lấy vị trí GPS...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      debugPrint('✅ Vị trí GPS: ${position.latitude}, ${position.longitude}');

      final showroomService = ShowroomApiService();

      debugPrint('🌐 Đang gọi API tìm showroom (GPS thật, bán kính 300km)...');
      final showrooms = await showroomService.fetchNearbyShowrooms(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInMeters: 300000,
        limit: 30,
        // Yêu cầu: chỉ lấy showroom đúng hãng xe khách hàng đã chọn
        brand: widget.carBrand,
      );

      debugPrint(
        '✅ API trả về ${showrooms.length} showroom (ưu tiên ${widget.carBrand}, nếu không có sẽ lấy gần nhất trong 300km)',
      );

      final showroomsWithDistance = _withDistanceSorted(
        showrooms,
        userLat: position.latitude,
        userLng: position.longitude,
      );

      if (showroomsWithDistance.isEmpty) {
        debugPrint('❌ Không có showroom nào trong bán kính 300km từ GPS');
        if (mounted) {
          _showSnackBar(
            'Không tìm thấy showroom nào trong bán kính 300km từ vị trí GPS của bạn.',
            isError: true,
          );
        }
        setState(() => _isLoadingShowrooms = false);
        return;
      }

      if (mounted) {
        _showShowroomSelector(showroomsWithDistance);
      }
    } catch (e) {
      debugPrint('❌ Lỗi tìm showroom: $e');
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('TimeoutException') || msg.contains('timeout')) {
          _showSnackBar(
            'Tìm kiếm showroom hơi lâu, vui lòng kiểm tra kết nối mạng và thử lại.',
            isError: true,
          );
        } else if (msg.contains('SocketException')) {
          _showSnackBar(
            'Không kết nối được mạng. Vui lòng kiểm tra Wi-Fi/4G.',
            isError: true,
          );
        } else if (msg.contains('LocationServiceDisabledException')) {
          _showSnackBar(
            'Vui lòng bật GPS trong cài đặt thiết bị.',
            isError: true,
          );
        } else {
          _showSnackBar(
            'Không thể tìm showroom. Vui lòng liên hệ hotline để được hỗ trợ.',
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingShowrooms = false);
      }
    }
  }

  /// Ensures each showroom has a numeric `distance` computed from the user's
  /// current GPS position, then sorts the list ascending by distance.
  List<Map<String, dynamic>> _withDistanceSorted(
    List<Map<String, dynamic>> showrooms, {
    required double userLat,
    required double userLng,
  }) {
    final enriched = <Map<String, dynamic>>[];
    for (final showroom in showrooms) {
      final lat = showroom['lat'];
      final lng = showroom['lng'];
      if (lat is! num || lng is! num) continue;

      final distance = Geolocator.distanceBetween(
        userLat,
        userLng,
        lat.toDouble(),
        lng.toDouble(),
      );

      enriched.add({...showroom, 'distance': distance});
    }

    enriched.sort(
      (a, b) => ((a['distance'] as num?) ?? double.infinity).compareTo(
        ((b['distance'] as num?) ?? double.infinity),
      ),
    );
    return enriched;
  }

  void _showShowroomSelector(List<Map<String, dynamic>> showrooms) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn Showroom',
              style: GoogleFonts.leagueSpartan(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: showrooms.length,
                itemBuilder: (context, index) {
                  final showroom = showrooms[index];
                  final name = showroom['name'] ?? 'Showroom';
                  final address = showroom['address'] ?? 'Không rõ địa chỉ';
                  final distance = showroom['distance'];
                  final distanceKm =
                      distance != null && distance is num && distance > 0
                      ? (distance / 1000).toStringAsFixed(1)
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (distanceKm != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Cách $distanceKm km',
                              style: GoogleFonts.leagueSpartan(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: distanceKm != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${distanceKm} km',
                                style: const TextStyle(
                                  color: _primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      onTap: () {
                        setState(() {
                          _selectedShowroom = showroom;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      _showSnackBar('Vui lòng đồng ý với điều khoản đặt cọc', isError: true);
      return;
    }

    if (_selectedShowroom == null) {
      _showSnackBar('Vui lòng chọn showroom', isError: true);
      return;
    }

    // Xác định số tiền đặt cọc
    int depositAmount;
    if (_isCustomAmount) {
      final customAmount = int.tryParse(
        _customAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (customAmount == null || customAmount <= 0) {
        _showSnackBar('Vui lòng nhập số tiền hợp lệ', isError: true);
        return;
      }
      depositAmount = customAmount;
    } else {
      if (_selectedDepositAmount == null) {
        _showSnackBar('Vui lòng chọn số tiền đặt cọc', isError: true);
        return;
      }
      depositAmount = _selectedDepositAmount!;
    }

    // Tạo booking data để truyền qua màn hình payment
    final bookingData = {
      'userPhone': (widget.phoneNumber ?? '').toString(),
      'carName': widget.carName,
      'carBrand': widget.carBrand,
      'carImage': widget.carImage,
      'carPrice': widget.carPrice,
      'customerName': _nameController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'customerEmail': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'notes': _notesController.text.trim(),
      'depositAmount': depositAmount,
      'showroom': (_selectedShowroom == null)
          ? null
          : Map<String, dynamic>.from(_selectedShowroom!),
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Điều hướng đến màn hình payment methods
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodsScreen(
          amount: depositAmount.toDouble(),
          carName: widget.carName,
          bookingData: bookingData,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildCarInfoCard(),
                  _buildCustomerInfo(),
                  _buildDepositAmountSection(),
                  _buildShowroomSection(),
                  _buildPaymentMethodSection(),
                  _buildNotesSection(),
                  _buildTermsSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'ĐẶT CỌC XE',
            style: GoogleFonts.leagueSpartan(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarInfoCard() {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final price =
        int.tryParse(widget.carPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // Debug log để kiểm tra URL
    debugPrint('Car Image URL: ${widget.carImage}');

    // Kiểm tra xem có phải network image không
    final isNetworkImage =
        widget.carImage.startsWith('http://') ||
        widget.carImage.startsWith('https://');

    return Container(
      margin: const EdgeInsets.all(16),
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
                    widget.carImage,
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
                    widget.carImage,
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
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.carName,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GIÁ NIÊM YẾT',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${formatter.format(price)} VND',
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

  Widget _buildCustomerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THÔNG TIN KHÁCH HÀNG',
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Họ và tên',
                  hint: 'Nguyễn Văn A',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: '+84 987 654 321',
                  readOnly: false,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'example@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _addressController,
                  label: 'Địa chỉ',
                  hint: 'Số nhà, Tên đường, Quận/Huyện, Tỉnh/TP',
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.leagueSpartan(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.leagueSpartan(
              fontSize: 14,
              color: Colors.white30,
            ),
            filled: true,
            fillColor: _card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepositAmountSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SỐ TIỀN ĐẶT CỌC',
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildDepositOption(30000000, '30.000.000'),
              _buildDepositOption(50000000, '50.000.000'),
              _buildDepositOption(100000000, '100.000.000'),
              _buildDepositOption(500000000, '500.000.000'),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCustomAmount = !_isCustomAmount;
                if (_isCustomAmount) {
                  _selectedDepositAmount = null;
                } else {
                  _customAmountController.clear();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCustomAmount ? _primaryColor.withOpacity(0.2) : _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCustomAmount ? _primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: _isCustomAmount ? _primaryColor : Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isCustomAmount
                        ? TextField(
                            controller: _customAmountController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _primaryColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập số tiền',
                              hintStyle: GoogleFonts.leagueSpartan(
                                fontSize: 16,
                                color: Colors.white30,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          )
                        : Text(
                            'Số tiền khác',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositOption(int amount, String label) {
    final isSelected = !_isCustomAmount && _selectedDepositAmount == amount;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedDepositAmount = amount;
        _isCustomAmount = false;
        _customAmountController.clear();
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.2) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.leagueSpartan(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected ? _primaryColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShowroomSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐỊA CHỈ NHẬN XE',
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isLoadingShowrooms ? null : _findNearestShowroom,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: _primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedShowroom?['name'] ??
                              'Bấm để tìm showroom ${widget.carBrand}',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (_selectedShowroom == null && !_isLoadingShowrooms)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Chạm vào đây để tìm kiếm',
                              style: GoogleFonts.leagueSpartan(
                                fontSize: 12,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        if (_selectedShowroom != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedShowroom!['address'] ?? '',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedShowroom!['distance'] != null &&
                              _selectedShowroom!['distance'] is num &&
                              _selectedShowroom!['distance'] > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: _primaryColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cách ${(_selectedShowroom!['distance'] / 1000).toStringAsFixed(1)} km',
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  if (_isLoadingShowrooms)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_selectedShowroom != null &&
                      _selectedShowroom!['distance'] != null &&
                      _selectedShowroom!['distance'] is num &&
                      _selectedShowroom!['distance'] > 0)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_selectedShowroom!['distance'] / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: _primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _findNearestShowroom(),
                          child: Icon(
                            Icons.refresh,
                            color: _primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    )
                  else
                    Icon(
                      Icons.location_searching,
                      color: _primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHƯƠNG THỨC THANH TOÁN',
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            'bank_transfer',
            'Chuyển khoản ngân hàng',
            Icons.account_balance,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            'cash',
            'Thanh toán tại showroom',
            Icons.monetization_on,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.2) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : Colors.white54,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.leagueSpartan(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _primaryColor : Colors.white,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _primaryColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YÊU CẦU ĐẶC BIỆT (Không bắt buộc)',
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.leagueSpartan(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập yêu cầu của bạn về màu sắc, thời gian nhận xe...',
              hintStyle: GoogleFonts.leagueSpartan(
                fontSize: 14,
                color: Colors.white30,
              ),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreeTerms,
            onChanged: (value) => setState(() => _agreeTerms = value ?? false),
            activeColor: _primaryColor,
            checkColor: Colors.white,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    children: [
                      const TextSpan(text: 'Tôi đã đọc và đồng ý với '),
                      TextSpan(
                        text: 'Điều khoản đặt cọc',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 13,
                          color: _primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitDeposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'XÁC NHẬN ĐẶT CỌC',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }
}
