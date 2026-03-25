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
import 'infomation.dart';

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

        // Save original values để compare changes
        _originalName = effectiveName;
        _originalEmail = email;
        _originalStreet = street;
        _originalGender = gender ?? 'Nam';
        _originalDate = dobDate;
        _originalProvince = province;
        _originalDistrict = district;
        _originalWard = ward;
        _originalAvatarUrl = _avatarUrl;
        _originalPhone = _formatPhoneNumber(widget.phoneNumber);
        _hasChanges = false; // Reset changes flag
      });

      // Add listeners to track changes
      _addChangeListeners();
    } catch (_) {
      // Keep UI usable even if load fails.
    }
  }

  // Add listeners to track changes
  void _addChangeListeners() {
    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _streetController.addListener(_checkForChanges);
  }

  // Check if any field has been modified
  void _checkForChanges() {
    if (!mounted) return;
    
    final hasChanged = 
      _nameController.text.trim() != (_originalName ?? '') ||
      _emailController.text.trim() != (_originalEmail ?? '') ||
      _streetController.text.trim() != (_originalStreet ?? '') ||
      _selectedGender != _originalGender ||
      _selectedDate != _originalDate ||
      _selectedProvince != _originalProvince ||
      _selectedDistrict != _originalDistrict ||
      _selectedWard != _originalWard ||
      _avatarUrl != _originalAvatarUrl ||
      _avatarBytes != null; // New avatar selected
    
    if (hasChanged != _hasChanges) {
      setState(() {
        _hasChanges = hasChanged;
      });
    }
  }

  // Show confirmation dialog before leaving
  Future<bool> _showExitConfirmationDialog() async {
    if (!_hasChanges) return true; // No changes, allow exit
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Xác nhận',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn có muốn lưu những thay đổi đã thực hiện không?',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop('cancel'), // Cancel - stay on page
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop('save'), // Save and exit
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Đồng ý',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result == 'cancel') {
      return false; // User canceled - stay on page
    } else if (result == 'save') {
      // User wants to save - save changes then exit
      await _saveChanges();
      return true;
    }
    
    return false;
  }

  // Handle back button press
  Future<void> _handleBackPress() async {
    final shouldExit = await _showExitConfirmationDialog();
    if (shouldExit && mounted) {
      // Navigate back to infomation.dart
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InfomationScreen(phoneNumber: widget.phoneNumber),
        ),
      );
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
      final normalizedPhone = FirebaseHelper.normalizePhone(
        widget.phoneNumber!,
      );
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final street = _streetController.text.trim();
      final province = _selectedProvince;
      final district = _selectedDistrict;
      final ward = _selectedWard;

      await ref.set({
        'phone': normalizedPhone,
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
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Reset change detection after successful save
      _originalName = name;
      _originalPhone = _phoneController.text.trim();
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
      });

      if (!mounted) return;
      
      // Navigate back to infomation.dart instead of just popping
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InfomationScreen(phoneNumber: widget.phoneNumber),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Lưu thất bại')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
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
    // Set số điện thoại từ arguments
    _phoneController.text = _formatPhoneNumber(widget.phoneNumber);

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
    // 1) Try FilePicker first (works on many Android devices).
    // 2) If FilePicker can't open or returns unreadable bytes on emulator,
    //    fall back to ImagePicker (Android Photo Picker/Gallery).
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
      ).showSnackBar(const SnackBar(content: Text('Upload file thất bại')));
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
                  title: const Text('Upload file'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    // Give the bottom sheet time to fully close before opening
                    // the native file picker dialog.
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
      _checkForChanges();
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

    return PopScope(
      canPop: false, // Prevent default pop behavior
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleBackPress();
        }
      },
      child: Scaffold(
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
            decoration: const BoxDecoration(color: Color(0xFF333333)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _handleBackPress,
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
                    readOnly: true,
                    enableInteractiveSelection: false,
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
      ),
    ),
    );
  }
}
