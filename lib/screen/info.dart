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
    final phone = widget.phoneNumber;
    if (phone == null || phone.trim().isEmpty) return null;

    // Nếu phoneNumber chứa @, đó là email từ Google login
    if (phone.contains('@')) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(phone.trim().toLowerCase());
    }

    // Ngược lại, đó là phone number
    final normalized = FirebaseHelper.normalizePhone(phone);
    return FirebaseFirestore.instance.collection('users').doc(normalized);
  }

  Future<void> _loadUserProfile() async {
    final ref = _userDocRef();
    if (ref == null) return;

    try {
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

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
    final ref = _userDocRef();
    if (ref == null) {
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
      final phone = _phoneController.text.trim();
      final street = _streetController.text.trim();
      final province = _selectedProvince;
      final district = _selectedDistrict;
      final ward = _selectedWard;

      // Validation
      if (name.isEmpty) {
        throw Exception('Vui lòng nhập tên');
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Xử lý theo loại đăng nhập
      if (_loginProvider == 'google') {
        // Google login: email cố định, có thể thêm phone
        if (phone.isNotEmpty) {
          updateData['phone'] = FirebaseHelper.normalizePhone(phone);
        }
      } else {
        // Phone login: phone cố định, có thể thêm email
        final normalizedPhone = FirebaseHelper.normalizePhone(
          widget.phoneNumber!,
        );
        updateData['phone'] = normalizedPhone;
        if (email.isNotEmpty && email.contains('@')) {
          updateData['email'] = email;
        }
      }

      // Lưu vào Firestore
      await ref.set(updateData, SetOptions(merge: true));

      if (!mounted) return;

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

    // Set thông tin ban đầu dựa trên phoneNumber argument
    final phone = widget.phoneNumber;
    if (phone != null && phone.contains('@')) {
      // Google login - hiển thị email
      _emailController.text = phone;
      _phoneController.text = ''; // Để trống, sẽ load từ Firestore
      _loginProvider = 'google';
    } else {
      // Phone login - hiển thị SĐT
      _phoneController.text = _formatPhoneNumber(phone);
      _loginProvider = 'phone';
    }

    _nameController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

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

    final userDocRef = _userDocRef();

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: userDocRef == null
          ? _buildErrorState()
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userDocRef.snapshots(),
              builder: (context, snapshot) {
                // Load dữ liệu từ Firestore vào các controller khi có dữ liệu
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data();
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

    // Chỉ set một lần để tránh loop
    if (_nameController.text.isEmpty && data['name'] != null) {
      _nameController.text = data['name'];
    }

    if (_phoneController.text.isEmpty && data['phone'] != null) {
      _phoneController.text = data['phone'];
    }

    if (_emailController.text.isEmpty && data['email'] != null) {
      _emailController.text = data['email'];
    }

    if (data['avatarUrl'] != null) {
      _avatarUrl = data['avatarUrl'];
    }

    // Load thông tin khác nếu có
    if (data['gender'] != null) {
      _selectedGender = data['gender'];
    }

    if (data['street'] != null) {
      _streetController.text = data['street'];
    }

    if (data['birthDate'] != null) {
      final timestamp = data['birthDate'] as Timestamp?;
      if (timestamp != null) {
        _selectedDate = timestamp.toDate();
      }
    }
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
                onTap: () => Navigator.pop(context),
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

                // TextField số điện thoại
                TextField(
                  controller: _phoneController,
                  readOnly:
                      _loginProvider ==
                      'phone', // Khóa SĐT nếu đăng nhập bằng phone
                  enableInteractiveSelection: _loginProvider != 'phone',
                  style: TextStyle(
                    color: _loginProvider == 'phone'
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: '0123456789',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _loginProvider == 'phone'
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white54,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _loginProvider == 'phone'
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixIcon: _loginProvider == 'phone'
                        ? const Icon(
                            Icons.lock_outline,
                            color: Colors.white54,
                            size: 16,
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),

                // TextField Email
                TextField(
                  controller: _emailController,
                  readOnly:
                      _loginProvider ==
                      'google', // Khóa email nếu đăng nhập bằng Google
                  enableInteractiveSelection: _loginProvider != 'google',
                  style: TextStyle(
                    color: _loginProvider == 'google'
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _loginProvider == 'google'
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white54,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _loginProvider == 'google'
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixIcon: _loginProvider == 'google'
                        ? const Icon(
                            Icons.lock_outline,
                            color: Colors.white54,
                            size: 16,
                          )
                        : null,
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
                  },
                  child: Row(
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

                // Chọn tỉnh/Thành phố (bottom sheet search)
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
