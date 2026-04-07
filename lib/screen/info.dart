import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vietnam_provinces/vietnam_provinces.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../data/firebase_helper.dart';
import '../services/user_service.dart';

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

  Uint8List? _avatarBytes;
  String? _avatarUrl;
  String? _loginProvider; // 'google' or 'phone'
  bool _dataLoaded = false; // Flag để tránh load dữ liệu liên tục

  // Chỉ bắt đầu cảnh báo "chưa lưu" sau khi đã load xong dữ liệu từ Firestore.
  // Nếu chưa load xong mà so sánh initial values (đang rỗng) sẽ gây hiện popup sai.
  bool _readyForUnsavedCheck = false;

  // Chỉ hiện popup khi user thật sự có tương tác chỉnh sửa (gõ/chọn/đổi ảnh).
  // Điều này đảm bảo: vào ChangeInfo rồi bấm back ngay -> không popup.
  bool _userInteracted = false;

  final ImagePicker _imagePicker = ImagePicker();

  String _selectedGender = 'Nam';
  DateTime? _selectedDate;
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;

  // Lưu trữ giá trị ban đầu để so sánh
  String _initialName = '';
  String _initialPhone = '';
  String _initialEmail = '';
  String _initialStreet = '';
  String _initialGender = 'Nam';
  DateTime? _initialDate;
  String? _initialAvatarUrl;
  Province? _initialProvince;
  District? _initialDistrict;
  Ward? _initialWard;

  Future<void>? _vietnamProvincesInit;

  Future<void> _ensureVietnamProvincesInitialized() async {
    _vietnamProvincesInit ??= () async {
      try {
        await VietnamProvinces.initialize(
          version: AdministrativeDivisionVersion.v1,
        );
      } catch (_) {
        // Best-effort: package may already be initialized,
        // or initialization might have been done in main().
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

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    // ✅ Ưu tiên uid (chuẩn hoá toàn app): users/{uid}
    final uidRef = UserService.googleUserRefByUid();
    if (uidRef != null) return uidRef;

    // Fallback: legacy identifier-based (phone/email)
    final identifier = widget.phoneNumber;
    if (identifier == null || identifier.trim().isEmpty) return null;
    return UserService.userRef(identifier);
  }

  Future<void> _loadUserProfile() async {
    // UID-first: vẫn cho phép fallback theo phoneNumber nếu chưa có currentUser
    final identifier = widget.phoneNumber;
    final hasUid = UserService.getCurrentUid() != null;
    if (!hasUid && (identifier == null || identifier.trim().isEmpty)) return;

    try {
      // Sử dụng UserService.get (đã ưu tiên UID bên trong) để đồng bộ dữ liệu
      final userModel = await UserService.get(identifier ?? '');
      if (userModel == null) return;

      final data = {
        'name': userModel.name,
        'phone': userModel.phoneNumber,
        'email': userModel.email,
        'avatarUrl': userModel.avatarUrl,
        'gender': userModel.gender,
        'dob': userModel.dob,
        'street': userModel.street,
        'provinceCode': userModel.provinceCode,
        'districtCode': userModel.districtCode,
        'wardCode': userModel.wardCode,
      };

      final name = data['name'] as String?;
      final legacyPhoneField = data['phone'] as String?;
      final avatarUrl = data['avatarUrl'] as String?;
      final email = data['email'] as String?;
      final street = data['street'] as String?;
      final gender = data['gender'] as String?;
      final dob = data['dob'];
      final provider = data['provider'] as String?; // 'google' or null

      // Phân biệt Google vs Phone login
      final isGoogleLogin =
          provider == 'google' || (widget.phoneNumber?.contains('@') == true);

      setState(() {
        _loginProvider = isGoogleLogin ? 'google' : 'phone';
      });

      final provinceCode = _toInt(data['provinceCode']);
      final districtCode = _toInt(data['districtCode']);
      final wardCode = _toInt(data['wardCode']);

      DateTime? dobDate;
      if (dob is Timestamp) {
        dobDate = dob.toDate();
      } else if (dob is DateTime) {
        dobDate = dob;
      } else if (dob is String) {
        dobDate = DateTime.tryParse(dob);
      }

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
        _loginProvider = isGoogleLogin ? 'google' : 'phone';
        _avatarUrl = (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            ? avatarUrl.trim()
            : null;
        final effectiveName = (name != null && name.trim().isNotEmpty)
            ? name
            : (legacyPhoneField != null &&
                  legacyPhoneField.trim().isNotEmpty &&
                  !_looksLikePhone(legacyPhoneField) &&
                  !legacyPhoneField.contains('@'))
            ? legacyPhoneField
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
      });
    } catch (_) {
      // Keep UI usable even if load fails.
    }
  }

  Future<void> _saveChanges() async {
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu số điện thoại để lưu dữ liệu')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phoneInput = _phoneController.text.trim();
      final street = _streetController.text.trim();
      final province = _selectedProvince;
      final district = _selectedDistrict;
      final ward = _selectedWard;

      // Validation
      if (name.isEmpty) {
        throw Exception('Vui lòng nhập tên');
      }

      // Nếu user có chọn avatar mới mà chưa upload, upload trước rồi mới lưu profile.
      if (_avatarBytes != null && _avatarBytes!.isNotEmpty) {
        await _uploadAvatarToFirebaseStorage(
          bytes: _avatarBytes!,
          originalFileName: 'avatar.jpg',
        );
      }

      // Tạo data object cơ bản
      Map<String, dynamic> updateData = {
        'name': name,
        'gender': _selectedGender,
        'dob': _selectedDate,
        'provinceCode': province?.code,
        'provinceName': province?.name,
        'districtCode': district?.code,
        'districtName': district?.name,
        'wardCode': ward?.code,
        'wardName': ward?.name,
        'street': street,
      };

      // Lưu thông tin email và phone mà user đã nhập (cho phép sửa đổi)
      if (email.isNotEmpty && email.contains('@')) {
        updateData['email'] = email.trim().toLowerCase();
      }

      if (phoneInput.isNotEmpty) {
        final normalizedPhone = FirebaseHelper.normalizePhone(phoneInput);
        updateData['phone'] = normalizedPhone;
        updateData['phoneNumber'] = normalizedPhone;
      }

      // Set provider dựa trên cách đăng nhập ban đầu
      if (_loginProvider == 'google') {
        updateData['provider'] = 'google';
      } else if (_loginProvider == 'phone') {
        updateData['provider'] = 'phone';
      }

      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        updateData['avatarUrl'] = _avatarUrl;
      }

      // ✅ Lưu theo UID (canonical users/{uid}) để đồng bộ với Home/Profile/ChangeInfo
      // Nếu chưa có currentUser thì fallback sang identifier-based.
      final identifier = widget.phoneNumber ?? '';
      if (UserService.getCurrentUid() != null) {
        await UserService.updateCurrentUserFields(updateData);
      } else {
        await UserService.updateFields(identifier, updateData);
      }

      if (!mounted) return;

      // Cập nhật lại giá trị ban đầu sau khi lưu thành công
      _updateInitialValues();

      // Đã lưu thành công => coi như không còn unsaved changes.
      _userInteracted = false;

      // Quay về Information và báo kết quả để trang trước tự show SnackBar + reload.
      Navigator.pop(context, {
        'saved': true,
        'name': name,
        'phone': updateData['phone'],
        'email': updateData['email'],
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Lỗi: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                          style: const TextStyle(
                            color: Colors.black87, // Text đậm hơn
                            fontSize: 16,
                            fontWeight: FontWeight.w500, // Đậm hơn
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              query = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: const TextStyle(
                              color: Colors.black54, // Hint text đậm hơn
                              fontSize: 16,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.black54, // Icon đậm hơn
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.black38, // Border đậm hơn
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.black87, // Focus border đậm hơn
                                width: 2,
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
  }

  void _showStyledSnackBar({
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickDistrict() async {
    final province = _selectedProvince;
    if (province == null) {
      _showStyledSnackBar(
        message: '🏙️ Vui lòng chọn Tỉnh/Thành phố trước',
        backgroundColor: Colors.blue.shade600,
        icon: Icons.location_city,
        iconColor: Colors.white,
      );
      return;
    }

    try {
      await _ensureVietnamProvincesInitialized();
    } catch (_) {
      if (!mounted) return;
      _showStyledSnackBar(
        message: '❌ Không thể tải dữ liệu Quận/Huyện',
        backgroundColor: Colors.red.shade600,
        icon: Icons.error_outline,
        iconColor: Colors.white,
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
  }

  Future<void> _pickWard() async {
    final province = _selectedProvince;
    final district = _selectedDistrict;

    if (province == null) {
      _showStyledSnackBar(
        message: '🏙️ Vui lòng chọn Tỉnh/Thành phố trước',
        backgroundColor: Colors.blue.shade600,
        icon: Icons.location_city,
        iconColor: Colors.white,
      );
      return;
    }
    if (district == null) {
      _showStyledSnackBar(
        message: '🏘️ Vui lòng chọn Quận/Huyện trước',
        backgroundColor: Colors.blue.shade600,
        icon: Icons.location_on,
        iconColor: Colors.white,
      );
      return;
    }

    try {
      await _ensureVietnamProvincesInitialized();
    } catch (_) {
      if (!mounted) return;
      _showStyledSnackBar(
        message: '❌ Không thể tải dữ liệu Phường/Xã',
        backgroundColor: Colors.red.shade600,
        icon: Icons.error_outline,
        iconColor: Colors.white,
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
  }

  @override
  void initState() {
    super.initState();

    // Reset data loaded flag khi khởi tạo lại trang
    _dataLoaded = false;

    // Chưa cho phép check unsaved changes cho tới khi Firestore load xong.
    _readyForUnsavedCheck = false;

    // Chưa có tương tác chỉnh sửa.
    _userInteracted = false;

    // Set thông tin ban đầu dựa trên phoneNumber argument
    final phone = widget.phoneNumber;
    if (phone != null && phone.contains('@')) {
      // Google login - hiển thị email
      _loginProvider = 'google';
      // Đừng set text ngay, để TextEditingController rỗng trước
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _emailController.text = phone;
        _phoneController.text = ''; // Để trống, sẽ load từ Firestore
      });
    } else {
      // Phone login - hiển thị SĐT
      _loginProvider = 'phone';
      // Đừng set text ngay, để TextEditingController rỗng trước
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phoneController.text = _formatPhoneNumber(phone);
      });
    }

    // Không gắn listener setState cho _nameController nữa.
    // Listener này dễ gây rebuild liên tục và có thể làm popup back bị kích hoạt sai.

    // Pre-warm dataset to avoid LateInitializationError on hot reload.
    _vietnamProvincesInit = VietnamProvinces.initialize(
      version: AdministrativeDivisionVersion.v1,
    );

    _loadUserProfile();
  }

  Future<void> _pickAvatarFromFiles() async {
    // Improved FilePicker with better error handling and size limits
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        withReadStream: true,
        allowMultiple: false,
      );

      final file = result?.files.single;
      if (file == null) return;

      // Check file size before processing
      if (file.size > 5 * 1024 * 1024) {
        if (!mounted) return;
        _showStyledSnackBar(
          message: '📁 File quá lớn! Vui lòng chọn file nhỏ hơn 5MB',
          backgroundColor: Colors.red.shade600,
          icon: Icons.file_upload_off,
          iconColor: Colors.white,
        );
        return;
      }

      Uint8List? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        final stream = file.readStream;
        if (stream != null) {
          try {
            final collected = <int>[];
            await for (final chunk in stream) {
              collected.addAll(chunk);
              // Check size while reading
              if (collected.length > 5 * 1024 * 1024) {
                if (!mounted) return;
                _showStyledSnackBar(
                  message: '📁 File quá lớn! Vui lòng chọn file nhỏ hơn 5MB',
                  backgroundColor: Colors.red.shade600,
                  icon: Icons.file_upload_off,
                  iconColor: Colors.white,
                );
                return;
              }
            }
            bytes = Uint8List.fromList(collected);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi đọc file: $e')));
            return;
          }
        }
      }

      if (bytes == null || bytes.isEmpty) {
        // Fallback to gallery picker
        await _pickAvatarFromGallery();
        return;
      }

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
      });

      _userInteracted = true;

      await _uploadAvatarToFirebaseStorage(
        bytes: bytes,
        originalFileName: file.name,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: ${e.message}')));
      // Fallback to gallery
      await _pickAvatarFromGallery();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi chọn file: $e')));
      // Fallback to gallery
      await _pickAvatarFromGallery();
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        _showStyledSnackBar(
          message: '📷 Không thể đọc file ảnh từ camera',
          backgroundColor: Colors.red.shade600,
          icon: Icons.camera_alt_outlined,
          iconColor: Colors.white,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
      });

      _userInteracted = true;

      await _uploadAvatarToFirebaseStorage(
        bytes: bytes,
        originalFileName: picked.name,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi mở camera: $e')));
    }
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 1024, // Giới hạn kích thước để tối ưu performance
        maxHeight: 1024,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        _showStyledSnackBar(
          message: '🖼️ Không thể đọc file ảnh từ thư viện',
          backgroundColor: Colors.red.shade600,
          icon: Icons.image_not_supported,
          iconColor: Colors.white,
        );
        return;
      }

      // Kiểm tra kích thước file (tối đa 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        _showStyledSnackBar(
          message: '📁 Ảnh quá lớn! Vui lòng chọn ảnh nhỏ hơn 5MB',
          backgroundColor: Colors.red.shade600,
          icon: Icons.file_upload_off,
          iconColor: Colors.white,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
      });

      _userInteracted = true;

      await _uploadAvatarToFirebaseStorage(
        bytes: bytes,
        originalFileName: picked.name,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi mở thư viện ảnh: $e')));
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      final ext = _guessImageExtension(originalFileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_${timestamp}.$ext';
      final objectPath = 'users/${user.uid}/avatars/$fileName';

      final storageRef = FirebaseStorage.instance.ref().child(objectPath);

      // Tạo metadata phù hợp
      final metadata = SettableMetadata(
        contentType: 'image/$ext',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFileName': originalFileName,
        },
      );

      // Upload file với progresss tracking
      final uploadTask = storageRef.putData(bytes, metadata);

      // Đợi upload hoàn thành
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final url = await storageRef.getDownloadURL();

        // Cập nhật Firestore
        await ref.set({
          'avatarUrl': url,
          'avatarPath': objectPath,
          'avatarUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        setState(() {
          _avatarUrl = url;
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Upload ảnh thành công!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        throw 'Upload không thành công';
      }
    } catch (e) {
      if (!mounted) return;
      print('Upload error: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Upload ảnh thất bại',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Vui lòng thử lại sau. Lỗi: ${e.toString()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
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
                const SizedBox(height: 16),
                const Text(
                  'Chọn ảnh đại diện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Nút chọn từ Camera
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text(
                    'Chụp ảnh từ Camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 200),
                    );
                    await _pickImageFromCamera();
                  },
                ),
                // Nút chọn từ Thư viện
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: const Text(
                    'Chọn từ Thư viện',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 200),
                    );
                    await _pickAvatarFromGallery();
                  },
                ),
                // Nút Upload File (cho những file khác)
                ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    'Upload File',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 200),
                    );
                    await _pickAvatarFromFiles();
                  },
                ),
                const SizedBox(height: 16),
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

  // Format số điện thoại: +84987654321 -> 0987654321
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
    }
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
      body: widget.phoneNumber == null || widget.phoneNumber!.trim().isEmpty
          ? _buildErrorState()
          : StreamBuilder<Map<String, dynamic>?>(
              stream: UserService.watch(widget.phoneNumber!).map((userModel) {
                return userModel?.toMap();
              }),
              builder: (context, snapshot) {
                // Load dữ liệu từ UserService vào các controller khi có dữ liệu
                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!;
                  _loadDataFromFirestore(data);
                }

                return _buildMainContent(topPadding);
              },
            ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Text(
        'Không thể tải thông tin người dùng',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _loadDataFromFirestore(Map<String, dynamic>? data) {
    if (data == null) return;

    // Chỉ load dữ liệu từ Firestore 1 lần để không ghi đè user input
    if (_dataLoaded) return;

    // Sử dụng addPostFrameCallback để tránh setState trong build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _dataLoaded) return;

      setState(() {
        // Load dữ liệu từ Firestore vào controllers
        if (data['name'] != null) {
          _nameController.text = data['name'];
          _initialName = data['name'];
        }

        if (data['phone'] != null) {
          _phoneController.text = data['phone'];
          _initialPhone = data['phone'];
        }

        if (data['email'] != null) {
          _emailController.text = data['email'];
          _initialEmail = data['email'];
        }

        if (data['avatarUrl'] != null) {
          _avatarUrl = data['avatarUrl'];
          _initialAvatarUrl = data['avatarUrl'];
        }

        // Load thông tin khác nếu có
        if (data['gender'] != null) {
          _selectedGender = data['gender'];
          _initialGender = data['gender'];
        }

        if (data['street'] != null) {
          _streetController.text = data['street'];
          _initialStreet = data['street'];
        }

        // Ngày sinh: hỗ trợ cả key mới 'dob' (đang dùng khi save) và key cũ 'birthDate'
        final dynamic dobValue = data['dob'] ?? data['birthDate'];
        if (dobValue != null) {
          DateTime? parsed;
          if (dobValue is Timestamp) {
            parsed = dobValue.toDate();
          } else if (dobValue is DateTime) {
            parsed = dobValue;
          } else if (dobValue is String) {
            parsed = DateTime.tryParse(dobValue);
          }

          if (parsed != null) {
            _selectedDate = parsed;
            _initialDate = parsed;
          }
        }

        // Đánh dấu dữ liệu đã load xong
        _dataLoaded = true;
        _readyForUnsavedCheck = true;
        _userInteracted = false; // Reset trạng thái tương tác
      });
    });
  }

  // Kiểm tra xem có thay đổi nào chưa lưu không
  bool _hasUnsavedChanges() {
    // Nếu dữ liệu chưa load xong mà check thì rất dễ ra true giả.
    if (!_readyForUnsavedCheck) return false;

    // Nếu user chưa thực sự tương tác chỉnh sửa thì không cảnh báo.
    if (!_userInteracted) return false;

    // Kiểm tra text controllers
    if (_nameController.text.trim() != _initialName.trim()) return true;
    if (_phoneController.text.trim() != _initialPhone.trim()) return true;
    if (_emailController.text.trim() != _initialEmail.trim()) return true;
    if (_streetController.text.trim() != _initialStreet.trim()) return true;

    // Kiểm tra gender
    if (_selectedGender != _initialGender) return true;

    // Kiểm tra birthDate
    if (_selectedDate?.toString() != _initialDate?.toString()) return true;

    // Kiểm tra avatar
    if (_avatarBytes != null) return true; // Có ảnh mới chưa upload
    if (_avatarUrl != _initialAvatarUrl) return true;

    // Kiểm tra địa chỉ
    if (_selectedProvince?.name != _initialProvince?.name) return true;
    if (_selectedDistrict?.name != _initialDistrict?.name) return true;
    if (_selectedWard?.name != _initialWard?.name) return true;

    return false;
  }

  // Cập nhật lại giá trị ban đầu sau khi lưu thành công
  void _updateInitialValues() {
    _initialName = _nameController.text.trim();
    _initialPhone = _phoneController.text.trim();
    _initialEmail = _emailController.text.trim();
    _initialStreet = _streetController.text.trim();
    _initialGender = _selectedGender;
    _initialDate = _selectedDate;
    _initialAvatarUrl = _avatarUrl;
    _initialProvince = _selectedProvince;
    _initialDistrict = _selectedDistrict;
    _initialWard = _selectedWard;

    // Reset avatar bytes và data loaded flag
    _avatarBytes = null;
    _dataLoaded = false; // Reset để cho phép load lại khi quay về

    // Sau khi lưu, coi như không còn thay đổi chưa lưu.
    _readyForUnsavedCheck = true;

    // Reset cờ tương tác.
    _userInteracted = false;
  }

  // Hiển thị dialog xác nhận lưu thay đổi
  Future<bool> _showSaveChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xác nhận',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đồng ý',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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

    return result ?? false;
  }

  Widget _buildMainContent(double topPadding) {
    return Column(
      children: [
        // Header with back button and title
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
                onTap: () async {
                  // Kiểm tra nếu có thay đổi chưa lưu
                  if (_hasUnsavedChanges()) {
                    final shouldSave = await _showSaveChangesDialog();
                    if (shouldSave) {
                      // Nếu chọn Đồng ý, lưu thay đổi và quay về trang Information
                      await _saveChanges();
                      // Không pop, vì _saveChanges() đã có logic quay về
                    }
                    // Nếu chọn Hủy (shouldSave == false), không làm gì, giữ nguyên trang
                  } else {
                    // Không có thay đổi, pop bình thường
                    Navigator.pop(context);
                  }
                },
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
              const SizedBox(width: 40), // Balance the back button
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

                // Avatar tròn + nút camera
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
                                ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                                : (_avatarUrl != null &&
                                      _avatarUrl!.trim().isNotEmpty)
                                ? Image.network(
                                    _avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
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

                // Số điện thoại lớn (tên hiển thị)
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

                // TextField Họ và tên
                TextField(
                  controller: _nameController,
                  enabled: true,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  onChanged: (value) {
                    if (!_userInteracted) _userInteracted = true;
                  },
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

                // TextField số điện thoại
                TextField(
                  controller: _phoneController,
                  enabled: true,
                  autofocus: false,
                  onChanged: (value) {
                    if (!_userInteracted) _userInteracted = true;
                  },
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
                  enabled: true,
                  autofocus: false,
                  onChanged: (value) {
                    if (!_userInteracted) _userInteracted = true;
                  },
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
                RadioGroup<String>(
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedGender = value;
                    });

                    if (!_userInteracted) _userInteracted = true;
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedGender = 'Nam';
                            });

                            if (!_userInteracted) _userInteracted = true;
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

                            if (!_userInteracted) _userInteracted = true;
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

                // Chọn ngày sinh
                InkWell(
                  onTap: () async {
                    final before = _selectedDate;
                    await _selectDate(context);
                    if (_selectedDate != before && !_userInteracted) {
                      _userInteracted = true;
                    }
                  },
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

                // Chọn tỉnh/Thành phố (bottom sheet search)
                InkWell(
                  onTap: () async {
                    final before = _selectedProvince;
                    await _pickProvince();
                    if (_selectedProvince != before && !_userInteracted) {
                      _userInteracted = true;
                    }
                  },
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
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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

                // Chọn quận/huyện (bottom sheet search)
                InkWell(
                  onTap: () async {
                    final before = _selectedDistrict;
                    await _pickDistrict();
                    if (_selectedDistrict != before && !_userInteracted) {
                      _userInteracted = true;
                    }
                  },
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
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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

                // Chọn phường/xã (bottom sheet search)
                InkWell(
                  onTap: () async {
                    final before = _selectedWard;
                    await _pickWard();
                    if (_selectedWard != before && !_userInteracted) {
                      _userInteracted = true;
                    }
                  },
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
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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

                // TextField Tên đường
                TextField(
                  controller: _streetController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  onChanged: (_) {
                    if (!_userInteracted) _userInteracted = true;
                  },
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
    );
  }
}
