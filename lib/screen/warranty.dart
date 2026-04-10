import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WarrantyScreen extends StatefulWidget {
  final String? phoneNumber;

  const WarrantyScreen({super.key, this.phoneNumber});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carNameController = TextEditingController();
  final _vinController = TextEditingController();
  final _issueController = TextEditingController();
  final _historySearchController = TextEditingController();

  DateTime? _purchaseDate;
  bool _isSubmitting = false;
  int _activeNavIndex = 3;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _carNameController.dispose();
    _vinController.dispose();
    _issueController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _submitWarranty() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày mua xe')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('warranties').add({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'carName': _carNameController.text.trim(),
        'vinOrPlate': _vinController.text.trim(),
        'issueDescription': _issueController.text.trim(),
        'purchaseDate': DateFormat('yyyy-MM-dd').format(_purchaseDate!),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'mobile_app',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi yêu cầu bảo hành thành công')),
      );
      _formKey.currentState!.reset();
      _fullNameController.clear();
      _carNameController.clear();
      _vinController.clear();
      _issueController.clear();
      if (widget.phoneNumber == null || widget.phoneNumber!.isEmpty) {
        _phoneController.clear();
      }
      setState(() {
        _purchaseDate = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi bảo hành, vui lòng thử lại'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'processing':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'processing':
        return 'Đang xử lý';
      case 'done':
        return 'Đã hoàn tất';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Chờ tiếp nhận';
    }
  }

  void _showWarrantyDetails(Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121B28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final status = (data['status'] ?? 'pending').toString();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (data['carName'] ?? '').toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'VIN/Biển số: ${(data['vinOrPlate'] ?? '').toString()}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày mua: ${(data['purchaseDate'] ?? '--').toString()}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mô tả lỗi:',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (data['issueDescription'] ?? '').toString(),
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilters() {
    final filters = <Map<String, String>>[
      {'value': 'all', 'label': 'Tất cả'},
      {'value': 'pending', 'label': 'Chờ tiếp nhận'},
      {'value': 'processing', 'label': 'Đang xử lý'},
      {'value': 'done', 'label': 'Hoàn tất'},
      {'value': 'rejected', 'label': 'Từ chối'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((item) {
        final selected = _selectedStatusFilter == item['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedStatusFilter = item['value']!;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF3b82c8)
                  : const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? const Color(0xFF3b82c8) : Colors.white12,
              ),
            ),
            child: Text(
              item['label']!,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistorySection() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text(
          'Nhập số điện thoại để xem lịch sử bảo hành.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('warranties')
          .where('phone', isEqualTo: phone)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs =
            (snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              ..sort((a, b) {
                final aTs = a.data()['createdAt'];
                final bTs = b.data()['createdAt'];
                final aMs = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
                final bMs = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
                return bMs.compareTo(aMs);
              });

        final keyword = _historySearchController.text.trim().toLowerCase();

        final filteredDocs = docs
            .where((doc) {
              if (_selectedStatusFilter == 'all') return true;
              return (doc.data()['status'] ?? 'pending').toString() ==
                  _selectedStatusFilter;
            })
            .where((doc) {
              if (keyword.isEmpty) return true;
              final carName = (doc.data()['carName'] ?? '')
                  .toString()
                  .toLowerCase();
              return carName.contains(keyword);
            })
            .toList();

        final pendingCount = docs
            .where((doc) => (doc.data()['status'] ?? 'pending') == 'pending')
            .length;
        final processingCount = docs
            .where((doc) => (doc.data()['status'] ?? '') == 'processing')
            .length;
        final doneCount = docs
            .where((doc) => (doc.data()['status'] ?? '') == 'done')
            .length;

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Text(
              'Chưa có yêu cầu bảo hành nào.',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                _buildStatTile('Chờ', pendingCount, Colors.blueGrey),
                const SizedBox(width: 8),
                _buildStatTile('Xử lý', processingCount, Colors.orange),
                const SizedBox(width: 8),
                _buildStatTile('Xong', doneCount, Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusFilters(),
            const SizedBox(height: 12),
            TextField(
              controller: _historySearchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên xe',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1a1a1a),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF3b82c8),
                    width: 1.5,
                  ),
                ),
                suffixIcon: _historySearchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _historySearchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (filteredDocs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Không có dữ liệu phù hợp bộ lọc.',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ...filteredDocs.map((doc) {
              final data = doc.data();
              final status = (data['status'] ?? 'pending').toString();
              final createdAtRaw = data['createdAt'];
              final createdAt = createdAtRaw is Timestamp
                  ? DateFormat('dd/MM/yyyy HH:mm').format(createdAtRaw.toDate())
                  : '--';

              return GestureDetector(
                onTap: () => _showWarrantyDetails(data),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (data['carName'] ?? '').toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                status,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'VIN/Biển số: ${(data['vinOrPlate'] ?? '').toString()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lỗi: ${(data['issueDescription'] ?? '').toString()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Tạo lúc: $createdAt',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white30,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildStatTile(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _activeNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: widget.phoneNumber,
        );
        break;
      case 1:
        Navigator.pushReplacementNamed(
          context,
          '/newcar',
          arguments: widget.phoneNumber,
        );
        break;
      case 2:
        Navigator.pushReplacementNamed(
          context,
          '/mycar',
          arguments: widget.phoneNumber,
        );
        break;
      case 3:
        Navigator.pushReplacementNamed(
          context,
          '/favorite',
          arguments: widget.phoneNumber,
        );
        break;
      case 4:
        Navigator.pushReplacementNamed(
          context,
          '/profile',
          arguments: widget.phoneNumber,
        );
        break;
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: const BorderSide(color: Color(0xFF3b82c8), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 32, 47),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 32, 47),
        elevation: 0,
        title: const Text(
          'BẢO HÀNH',
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gửi yêu cầu bảo hành',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập thông tin xe và lỗi để trung tâm hỗ trợ nhanh hơn.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Họ và tên'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập họ tên'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Số điện thoại'),
                onChanged: (_) {
                  setState(() {});
                },
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập số điện thoại'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _carNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Tên xe'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên xe'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vinController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Số VIN hoặc biển số'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập VIN/biển số'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    _purchaseDate == null
                        ? 'Chọn ngày mua xe'
                        : DateFormat('dd/MM/yyyy').format(_purchaseDate!),
                    style: TextStyle(
                      color: _purchaseDate == null
                          ? Colors.white30
                          : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issueController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Mô tả lỗi cần bảo hành'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập mô tả lỗi bảo hành'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitWarranty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3b82c8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'GỬI BẢO HÀNH',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lịch sử bảo hành',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã làm mới danh sách')),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Làm mới'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7eb7f0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Lọc theo trạng thái và tìm theo tên xe.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 10),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_rounded, 0),
              // NewCar -> đổi thành kính lúp (search)
              _buildNavItem(Icons.search_rounded, 1),
              // My Car -> icon xe ở giữa
              _buildNavItem(Icons.directions_car_rounded, 2),
              _buildNavItem(Icons.favorite_rounded, 3),
              _buildNavItem(Icons.person_rounded, 4),
            ],
          ),
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
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: isActive ? 28 : 26,
        ),
      ),
    );
  }
}
