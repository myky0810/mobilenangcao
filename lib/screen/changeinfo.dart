import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vietnam_provinces/vietnam_provinces.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../data/firebase_helper.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  bool _isSaving = false;

  // Variables to track changes
  bool _hasChanges = false;
  String? _originalName;
  String? _originalPhone;
  String? _originalEmail;
  String? _originalStreet;
  String? _originalGender;
  DateTime? _originalDate;
  Province? _originalProvince;
  District? _originalDistrict;
  Ward? _originalWard;
  String? _originalAvatarUrl;

  Uint8List? _avatarBytes;
  String? _avatarUrl;

  final ImagePicker _imagePicker = ImagePicker();

  String _selectedGender = 'Nam';
  DateTime? _selectedDate;
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;

  Future<void>? _vietnamProvincesInit;

  Future<void> _ensureVietnamProvincesInitialized() async {
    _vietnamProvincesInit ??= () async {
      try {
        await VietnamProvinces.initialize(
          version: AdministrativeDivisionVersion.v1,
        );
      } catch (_) {
        // Best-effort
      }
    }();

    await _vietnamProvincesInit;
  }

  bool _looksLikePhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return RegExp(r'^[0-9+\s()\-]+$').hasMatch(v);
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  /// ✅ Ưu tiên FirebaseAuth UID, fallback sang phoneNumber
  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    return UserService.currentUserProfileRef(
      phoneIdentifier: widget.phoneNumber,
    );
  }

  Future<void> _loadUserProfile() async {
    // ✅ Debug log
    print('🔄 [ChangeInfo] _loadUserProfile() started');
    print('   widget.phoneNumber: ${widget.phoneNumber}');
    print('   provider: ${UserService.currentProvider()}');

    try {
      UserModel? userModel;

      // Provider-aware: derive correct profile doc ref for google/phone.
      final docRef = _userDocRef();
      if (docRef != null) {
        final doc = await docRef.get();
        if (doc.exists) {
          userModel = UserModel.fromSnapshot(doc);
          print('   ✅ Found user: ${userModel.name} (ref=${docRef.path})');
        } else {
          print(
            '   ⚠️ Profile doc not found (ref=${docRef.path}) - showing empty form',
          );
        }
      } else {
        print('   ⚠️ No profile ref resolved - showing empty form');
      }

      if (userModel == null) {
        print('   ❌ No user found - showing empty form');
        // Vẫn cho phép form hoạt động với data trống
        if (!mounted) return;
        setState(() {
          _hasChanges = false;
        });
        return;
      }

      final name = userModel.name;
      final phone = userModel.phone;
      final avatarUrl = userModel.avatarUrl;
      final email = userModel.email;
      final street = userModel.street;
      final gender = userModel.gender;
      final dobDate = userModel.dob;
      final provinceCode = userModel.provinceCode;
      final districtCode = userModel.districtCode;
      final wardCode = userModel.wardCode;

      Province? province;
      District? district;
      Ward? ward;

      if (provinceCode != null) {
        await _ensureVietnamProvincesInitialized();
        final provinces = VietnamProvinces.getProvinces();
        province = _firstWhereOrNull(provinces, (p) => p.code == provinceCode);

        if (province != null && districtCode != null) {
          final districts = VietnamProvinces.getDistricts(
            provinceCode: province.code,
          );
          district = _firstWhereOrNull(
            districts,
            (d) => d.code == districtCode,
          );
        }

        if (province != null && district != null && wardCode != null) {
          final wards = VietnamProvinces.getWards(
            provinceCode: province.code,
            districtCode: district.code,
          );
          ward = _firstWhereOrNull(wards, (w) => w.code == wardCode);
        }
      }

      if (!mounted) return;
      setState(() {
        _avatarUrl = (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            ? avatarUrl.trim()
            : null;
        final effectiveName = (name != null && name.trim().isNotEmpty)
            ? name
            : (phone != null &&
                  phone.trim().isNotEmpty &&
                  !_looksLikePhone(phone) &&
                  !phone.contains('@'))
            ? phone
            : null;
        if (effectiveName != null) _nameController.text = effectiveName;
        if (email != null) {
          _emailController.text = email;
        }
        if (street != null) {
          _streetController.text = street;
        }
        if (gender != null && (gender == 'Nam' || gender == 'Nữ')) {
          _selectedGender = gender;
        }
        _selectedDate = dobDate;
        _selectedProvince = province;
        _selectedDistrict = district;
        _selectedWard = ward;

        // Lưu giá trị gốc để so sánh thay đổi.
        _originalName = effectiveName;
        _originalPhone = phone;
        _originalEmail = email;
        _originalStreet = street;
        _originalGender = gender ?? 'Nam';
        _originalDate = dobDate;
        _originalProvince = province;
        _originalDistrict = district;
        _originalWard = ward;
        _originalAvatarUrl = _avatarUrl;
        _hasChanges = false;

        // Cập nhật phone controller
        if (phone != null && phone.trim().isNotEmpty) {
          _phoneController.text = _formatPhoneNumber(phone);
        } else if (widget.phoneNumber != null) {
          _phoneController.text = _formatPhoneNumber(widget.phoneNumber!);
        }
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _checkForChanges();
        }
      });
    } catch (_) {
      // Giữ giao diện vẫn dùng được ngay cả khi tải dữ liệu thất bại.
    }
  }

  void _addChangeListeners() {
    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _streetController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    if (!mounted) return;

    final nameChanged =
        _nameController.text.trim() != (_originalName?.trim() ?? '');
    final emailChanged =
        _emailController.text.trim() != (_originalEmail?.trim() ?? '');
    final streetChanged =
        _streetController.text.trim() != (_originalStreet?.trim() ?? '');

    final currentPhone = _formatPhoneNumber(_phoneController.text.trim());
    final originalPhone = _formatPhoneNumber(_originalPhone?.trim() ?? '');
    final phoneChanged = currentPhone != originalPhone;

    final genderChanged = _selectedGender != (_originalGender ?? 'Nam');
    final dateChanged = _selectedDate != _originalDate;
    final provinceChanged = _selectedProvince != _originalProvince;
    final districtChanged = _selectedDistrict != _originalDistrict;
    final wardChanged = _selectedWard != _originalWard;
    final avatarChanged =
        _avatarBytes != null || _avatarUrl != _originalAvatarUrl;

    final hasChanged =
        nameChanged ||
        emailChanged ||
        streetChanged ||
        phoneChanged ||
        genderChanged ||
        dateChanged ||
        provinceChanged ||
        districtChanged ||
        wardChanged ||
        avatarChanged;

    if (hasChanged != _hasChanges) {
      setState(() {
        _hasChanges = hasChanged;
      });
    }
  }

  // DIALOG POPUP THEO HÌNH 3
  Future<String?> _showExitConfirmationDialog() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Bo góc giống hệt hình 3
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xác nhận',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lưu thay đổi?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop('cancel'), // Đóng popup, ở lại trang
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1.2,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop('save'), // Lưu và chuyển trang
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Đồng ý',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // XỬ LÝ KHI BẤM NÚT BACK (GÓC TRÁI TRÊN)
  Future<void> _handleBackPress() async {
    // Đảm bảo trạng thái thay đổi được tính lại trước khi quyết định có hiện popup hay không.
    // Nếu user vừa chỉnh sửa xong và bấm Back ngay, _hasChanges đôi khi chưa kịp cập nhật.
    _checkForChanges();

    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    // Hiện popup xác nhận
    final result = await _showExitConfirmationDialog();

    if (result == 'save') {
      // Nếu bấm Đồng ý -> Lưu dữ liệu rồi tự động đẩy về trang infomation
      await _saveChangesAndExit();
    }
    // Nếu bấm 'cancel' (Hủy) -> không làm gì, tiếp tục ở lại trang changeinfo
  }

  // LƯU TẠI CHỖ (BẤM NÚT DƯỚI CÙNG TRANG) - CẬP NHẬT GIAO DIỆN KHÔNG THOÁT
  Future<void> _saveChanges() async {
    // ✅ Kiểm tra có user đăng nhập không (UID hoặc phoneNumber)
    final hasCurrentUser = UserService.getCurrentUid() != null;
    final hasPhoneNumber =
        widget.phoneNumber != null && widget.phoneNumber!.trim().isNotEmpty;

    if (!hasCurrentUser && !hasPhoneNumber) {
      print('❌ Cannot save: No user logged in');
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      print(
        '🔄 STARTING SAVE - UID: ${UserService.getCurrentUid()}, Phone: ${widget.phoneNumber}',
      );

      final newPhone = _phoneController.text.trim();
      
      // ✅ Validate phone format: phải là 10 chữ số (format: 0374854273)
      if (newPhone.isNotEmpty) {
        final cleanPhone = newPhone.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
        if (cleanPhone.length != 10 || !cleanPhone.startsWith('0')) {
          print('❌ Invalid phone format: $newPhone (cleaned: $cleanPhone)');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số điện thoại phải là 10 chữ số bắt đầu bằng 0 (ví dụ: 0374854273)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final identifier = widget.phoneNumber ?? '';
      final normalizedPhone = newPhone.isNotEmpty
          ? FirebaseHelper.normalizePhone(newPhone)
          : (identifier.isNotEmpty
                ? FirebaseHelper.normalizePhone(identifier)
                : '');

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final street = _streetController.text.trim();
      final province = _selectedProvince;
      final district = _selectedDistrict;
      final ward = _selectedWard;

      print('📝 SAVING DATA: name=$name, phone=$normalizedPhone, email=$email, identifier=${widget.phoneNumber}');

      // ✅ Dùng updateCurrentUserFields với phoneIdentifier để lưu vào đúng document
      await UserService.updateCurrentUserFields(
        {
          'phone': normalizedPhone,
          'phoneNumber': normalizedPhone,
          'name': name,
          'email': email,
          'gender': _selectedGender,
          'dob': _selectedDate,
          'provinceCode': province?.code,
          'provinceName': province?.name,
          'districtCode': district?.code,
          'districtName': district?.name,
          'wardCode': ward?.code,
          'wardName': ward?.name,
          'street': street,
        },
        phoneIdentifier: widget.phoneNumber, // ✅ Truyền phone để xác định document ID
      );

      print('✅ SAVE COMPLETED SUCCESSFULLY!');

      // LƯU LẠI GIÁ TRỊ GỐC ĐỂ GIAO DIỆN HIỂU LÀ ĐÃ CẬP NHẬT NHƯNG VẪN Ở LẠI TRANG
      _originalName = name;
      _originalPhone = normalizedPhone;
      _originalEmail = email;
      _originalStreet = street;
      _originalGender = _selectedGender;
      _originalDate = _selectedDate;
      _originalProvince = province;
      _originalDistrict = district;
      _originalWard = ward;
      _originalAvatarUrl = _avatarUrl;

      setState(() {
        _hasChanges = false;
        if (normalizedPhone.isNotEmpty) {
          _phoneController.text = _formatPhoneNumber(normalizedPhone);
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Lưu thông tin thành công'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // LƯU VÀ CHUYỂN VỀ TRANG INFO (BẤM TỪ POPUP)
  Future<void> _saveChangesAndExit() async {
    // ✅ Kiểm tra có user đăng nhập không (UID hoặc phoneNumber)
    final hasCurrentUser = UserService.getCurrentUid() != null;
    final hasPhoneNumber =
        widget.phoneNumber != null && widget.phoneNumber!.trim().isNotEmpty;

    if (!hasCurrentUser && !hasPhoneNumber) {
      print('❌ Cannot save: No user logged in');
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final newPhone = _phoneController.text.trim();

      // ✅ Validate phone format: phải là 10 chữ số (format: 0374854273)
      if (newPhone.isNotEmpty) {
        final cleanPhone = newPhone.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
        if (cleanPhone.length != 10 || !cleanPhone.startsWith('0')) {
          print('❌ Invalid phone format: $newPhone (cleaned: $cleanPhone)');
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số điện thoại phải là 10 chữ số bắt đầu bằng 0 (ví dụ: 0374854273)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final identifier = widget.phoneNumber ?? '';
      final normalizedPhone = newPhone.isNotEmpty
          ? FirebaseHelper.normalizePhone(newPhone)
          : (identifier.isNotEmpty
                ? FirebaseHelper.normalizePhone(identifier)
                : '');

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final street = _streetController.text.trim();
      final province = _selectedProvince;
      final district = _selectedDistrict;
      final ward = _selectedWard;

      // ✅ Dùng updateCurrentUserFields với phoneIdentifier để lưu vào đúng document
      await UserService.updateCurrentUserFields(
        {
          'phone': normalizedPhone,
          'phoneNumber': normalizedPhone,
          'name': name,
          'email': email,
          'gender': _selectedGender,
          'dob': _selectedDate,
          'provinceCode': province?.code,
          'provinceName': province?.name,
          'districtCode': district?.code,
          'districtName': district?.name,
          'wardCode': ward?.code,
          'wardName': ward?.name,
          'street': street,
        },
        phoneIdentifier: widget.phoneNumber, // ✅ Truyền phone để xác định document ID
      );

      if (mounted) {
        setState(() => _isSaving = false);
        // Trả về {saved: true} cho trang InfomationScreen để nó làm mới lại dữ liệu
        Navigator.pop(context, {'saved': true});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi xảy ra khi lưu!')),
        );
      }
    }
  }

  Future<T?> _showSelectionSheet<T>({
    required String title,
    required String hintText,
    required List<T> items,
    required String Function(T) labelOf,
    bool Function(T a, T b)? equals,
    T? initialValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final queryController = TextEditingController();
        String query = '';
        T? tempSelected = initialValue;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = query.trim().isEmpty
                ? items
                : items
                      .where(
                        (e) => labelOf(
                          e,
                        ).toLowerCase().contains(query.trim().toLowerCase()),
                      )
                      .toList();

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: queryController,
                          onChanged: (value) {
                            setModalState(() {
                              query = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: hintText,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.black26,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 360,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) {
                            return const Divider(height: 1);
                          },
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final label = labelOf(item);
                            final isSelected =
                                tempSelected != null &&
                                (equals?.call(tempSelected as T, item) ??
                                    tempSelected == item);

                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  tempSelected = item;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Colors.black),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Hủy',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: tempSelected == null
                                      ? null
                                      : () => Navigator.pop(ctx, tempSelected),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.black12,
                                    disabledForegroundColor: Colors.black38,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Đồng ý',
                                    style: TextStyle(
                                      fontSize: 18,
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickProvince() async {
    try {
      await _ensureVietnamProvincesInitialized();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải dữ liệu Tỉnh/Thành phố')),
      );
      return;
    }

    final provinces = VietnamProvinces.getProvinces();
    final selected = await _showSelectionSheet<Province>(
      title: 'Chọn Tỉnh/Thành phố',
      hintText: 'Chọn Tỉnh/Thành phố',
      items: provinces,
      labelOf: (p) => p.name,
      equals: (a, b) => a.code == b.code,
      initialValue: _selectedProvince,
    );

    if (selected == null) return;

    setState(() {
      _selectedProvince = selected;
      _selectedDistrict = null;
      _selectedWard = null;
    });
    _checkForChanges();
  }

  Future<void> _pickDistrict() async {
    final province = _selectedProvince;
    if (province == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Tỉnh/Thành phố trước')),
      );
      return;
    }

    try {
      await _ensureVietnamProvincesInitialized();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải dữ liệu Quận/Huyện')),
      );
      return;
    }

    final districts = VietnamProvinces.getDistricts(
      provinceCode: province.code,
    );
    final selected = await _showSelectionSheet<District>(
      title: 'Chọn Quận/Huyện',
      hintText: 'Chọn Quận/Huyện',
      items: districts,
      labelOf: (d) => d.name,
      equals: (a, b) => a.code == b.code,
      initialValue: _selectedDistrict,
    );

    if (selected == null) return;

    setState(() {
      _selectedDistrict = selected;
      _selectedWard = null;
    });
    _checkForChanges();
  }

  Future<void> _pickWard() async {
    final province = _selectedProvince;
    final district = _selectedDistrict;

    if (province == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Tỉnh/Thành phố trước')),
      );
      return;
    }
    if (district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Quận/Huyện trước')),
      );
      return;
    }

    try {
      await _ensureVietnamProvincesInitialized();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải dữ liệu Phường/Xã')),
      );
      return;
    }

    final wards = VietnamProvinces.getWards(
      provinceCode: province.code,
      districtCode: district.code,
    );
    final selected = await _showSelectionSheet<Ward>(
      title: 'Chọn Phường/Xã',
      hintText: 'Chọn Phường/Xã',
      items: wards,
      labelOf: (w) => w.name,
      equals: (a, b) => a.code == b.code,
      initialValue: _selectedWard,
    );

    if (selected == null) return;

    setState(() {
      _selectedWard = selected;
    });
    _checkForChanges();
  }

  @override
  void initState() {
    super.initState();

    if (widget.phoneNumber != null) {
      if (widget.phoneNumber!.contains('@')) {
        _phoneController.text = '';
      } else {
        _phoneController.text = _formatPhoneNumber(widget.phoneNumber!);
      }
    }

    _vietnamProvincesInit = VietnamProvinces.initialize(
      version: AdministrativeDivisionVersion.v1,
    );

    _addChangeListeners();
    _loadUserProfile();
  }

  Future<void> _pickAvatarFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        withReadStream: true,
        allowMultiple: false,
      );

      final file = result?.files.single;
      if (file == null) return;

      Uint8List? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        final stream = file.readStream;
        if (stream != null) {
          final collected = <int>[];
          await for (final chunk in stream) {
            collected.addAll(chunk);
          }
          bytes = Uint8List.fromList(collected);
        }
      }

      if (bytes == null || bytes.isEmpty) {
        await _pickAvatarFromGallery();
        return;
      }

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
      });
      _checkForChanges();

      await _uploadAvatarToFirebaseStorage(
        bytes: bytes,
        originalFileName: file.name,
      );
      return;
    } on PlatformException {
      await _pickAvatarFromGallery();
    } catch (_) {
      await _pickAvatarFromGallery();
    }
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể đọc file ảnh')));
        return;
      }

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
      });
      _checkForChanges();

      await _uploadAvatarToFirebaseStorage(
        bytes: bytes,
        originalFileName: picked.name,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trình chọn ảnh')),
      );
    }
  }

  String _guessImageExtension(String? fileName) {
    final name = (fileName ?? '').trim().toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'jpg';
    final ext = name.substring(dot + 1);
    if (ext == 'jpeg') return 'jpg';
    if (ext == 'jpg' || ext == 'png' || ext == 'webp') return ext;
    return 'jpg';
  }

  Future<void> _uploadAvatarToFirebaseStorage({
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final ref = _userDocRef();
    if (ref == null) return;

    try {
      final normalizedPhone = FirebaseHelper.normalizePhone(
        widget.phoneNumber!,
      );
      final ext = _guessImageExtension(originalFileName);
      final objectPath = 'avatars/$normalizedPhone/avatar.$ext';

      final storageRef = FirebaseStorage.instance.ref(objectPath);
      final metadata = SettableMetadata(contentType: 'image/$ext');

      await storageRef.putData(bytes, metadata);
      final url = await storageRef.getDownloadURL();

      await ref.set({
        'avatarUrl': url,
        'avatarUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tải tệp thất bại')));
    }
  }

  Future<void> _showAvatarPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                ListTile(
                  title: const Text('Tải tệp lên'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 200),
                    );
                    await _pickAvatarFromFiles();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String? phone) {
    final value = (phone ?? '').trim();
    if (value.isEmpty) return '';
    if (!_looksLikePhone(value)) return value;

    if (value.startsWith('+84')) {
      return '0${value.substring(3)}';
    }
    if (value.startsWith('84')) {
      return '0${value.substring(2)}';
    }
    if (value.startsWith('0')) {
      return value;
    }
    return '0$value';
  }

  Future<void> _selectDate(BuildContext context) async {
    final minimumDate = DateTime(1950, 1, 1);
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
      initialItem: (tempYear - 1950).clamp(0, 2027 - 1950),
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
                                      tempYear = 1950 + index;
                                      clampDayIfNeeded();
                                    });
                                  },
                                  children: List.generate(2027 - 1950 + 1, (i) {
                                    final year = 1950 + i;
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

    if (confirmed != null && confirmed != _selectedDate) {
      setState(() {
        _selectedDate = confirmed;
      });
      _checkForChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF333333),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF333333),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: topPadding + 12,
                left: 12,
                right: 12,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleBackPress,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Thay đổi thông tin cá nhân',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Spartan',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipOval(
                              child: Container(
                                color: Colors.grey[700],
                                child: _avatarBytes != null
                                    ? Image.memory(
                                        _avatarBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : (_avatarUrl != null &&
                                          _avatarUrl!.trim().isNotEmpty)
                                    ? Image.network(
                                        _avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/RR.jpg',
                                                fit: BoxFit.cover,
                                              );
                                            },
                                      )
                                    : Image.asset(
                                        'assets/images/RR.jpg',
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: GestureDetector(
                              onTap: _showAvatarPickerSheet,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF333333),
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/images/icons8-camera-48.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _nameController.text.trim().isNotEmpty
                          ? _nameController.text.trim()
                          : _formatPhoneNumber(widget.phoneNumber),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      _formatPhoneNumber(widget.phoneNumber),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Họ và tên',
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
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Nhập 9 chữ số (ví dụ: 374854273) hoặc 0xxxxx',
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
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (value) {
                        // Auto-format: remove leading 0 if user pastes +84 number
                        if (value.startsWith('84') && value.length >= 2) {
                          _phoneController.text = '0${value.substring(2)}';
                          _phoneController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _phoneController.text.length),
                          );
                        }
                        _checkForChanges();
                      },
                    ),
                    const SizedBox(height: 24),

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

                    RadioGroup<String>(
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedGender = value;
                        });
                        _checkForChanges();
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'Nam';
                                });
                                _checkForChanges();
                              },
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'Nam',
                                    fillColor: WidgetStateProperty.all(
                                      Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Nam',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
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
                                _checkForChanges();
                              },
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'Nữ',
                                    fillColor: WidgetStateProperty.all(
                                      Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Nữ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
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

                    InkWell(
                      onTap: _pickProvince,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Chọn Tỉnh/Thành phố',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _selectedProvince?.name ?? 'Chọn Tỉnh/Thành phố',
                          style: TextStyle(
                            color: _selectedProvince != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    InkWell(
                      onTap: _pickDistrict,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Chọn Quận/Huyện',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _selectedDistrict?.name ?? 'Chọn Quận/Huyện',
                          style: TextStyle(
                            color: _selectedDistrict != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    InkWell(
                      onTap: _pickWard,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Chọn Phường/Xã',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _selectedWard?.name ?? 'Chọn Phường/Xã',
                          style: TextStyle(
                            color: _selectedWard != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveChanges();
                        },
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
      ),
    );
  }
}
