import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:doan_cuoiki/widgets/scrollview_animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/firebase_helper.dart';
import '../services/user_service.dart';

class DetailCalendarCarScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const DetailCalendarCarScreen({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    final carName = (bookingData['carName'] as String?) ?? 'Unknown Car';
    final carBrand = (bookingData['carBrand'] as String?) ?? '';
    final carImage = bookingData['carImage'] as String?;
    final date = (bookingData['date'] as String?) ?? '';
    final time = (bookingData['time'] as String?) ?? '';
    final name = (bookingData['name'] as String?) ?? '';
    final phone = (bookingData['phone'] as String?) ?? '';
    final email = (bookingData['email'] as String?) ?? '';

    // Thông tin showroom
    final showroomName = (bookingData['showroomName'] as String?) ?? '';
    final showroomAddress = (bookingData['showroomAddress'] as String?) ?? '';
    final googleMapsUrl = (bookingData['googleMapsUrl'] as String?) ?? '';

    // Debug info để kiểm tra dữ liệu
    print('🔍 DetailCalendarCarScreen Debug Info:');
    print('📅 Date: $date');
    print('🏢 Showroom Name: $showroomName');
    print('📍 Showroom Address: $showroomAddress');
    print('🗺️ Google Maps URL: $googleMapsUrl');
    print('📄 Full booking data keys: ${bookingData.keys.toList()}');
    if (googleMapsUrl.isEmpty) {
      print('❌ Google Maps URL is empty! Full data: $bookingData');
    }

    Future<bool> showCancelDialog() async {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            title: Text(
              'Cancel booking?',
              style: GoogleFonts.leagueSpartan(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Are you sure you want to cancel this test drive booking?',
              style: GoogleFonts.leagueSpartan(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.leagueSpartan(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82c8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'CONFIRM',
                  style: GoogleFonts.leagueSpartan(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return result == true;
    }

    Future<void> cancelBooking() async {
      final shouldCancel = await showCancelDialog();
      if (!shouldCancel) return;

      final bookingId = (bookingData['id'] as String?)?.trim() ?? '';
      final userPhoneRaw =
          (bookingData['userPhone'] as String?)?.trim() ??
          (bookingData['phone'] as String?)?.trim() ??
          '';
      final normalizedPhone = userPhoneRaw.isNotEmpty
          ? FirebaseHelper.normalizePhone(userPhoneRaw)
          : '';

      try {
        // 1) Delete the booking document (authoritative booking storage)
        if (bookingId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('test_drive_bookings')
              .doc(bookingId)
              .delete();
        } else {
          // Backward compatibility: if we don't have docId, do a best-effort delete.
          // (This should be rare — CalendarDrive can pass docId now.)
          final profileRef = UserService.currentUserProfileRef(
            phoneIdentifier: normalizedPhone,
          );
          final profilePath = profileRef?.path ?? '';

          Query query = FirebaseFirestore.instance.collection(
            'test_drive_bookings',
          );
          if (profilePath.isNotEmpty) {
            query = query.where('userProfilePath', isEqualTo: profilePath);
          } else if (normalizedPhone.isNotEmpty) {
            query = query.where('userPhone', isEqualTo: normalizedPhone);
          }

          // Match by immutable-ish fields from bookingData
          final date = (bookingData['date'] as String?) ?? '';
          final time = (bookingData['time'] as String?) ?? '';
          final carName = (bookingData['carName'] as String?) ?? '';
          final carBrand = (bookingData['carBrand'] as String?) ?? '';

          final snap = await query.limit(50).get();
          final matches = snap.docs.where((doc) {
            final m = doc.data() as Map<String, dynamic>;
            return (m['date'] ?? '') == date &&
                (m['time'] ?? '') == time &&
                (m['carName'] ?? '') == carName &&
                (m['carBrand'] ?? '') == carBrand;
          }).toList();

          for (final doc in matches) {
            await doc.reference.delete();
          }
        }

        // 2) Also remove the booking field on user profile (as you requested)
        if (normalizedPhone.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(normalizedPhone)
              .set({
                'testDriveBooking': FieldValue.delete(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding: EdgeInsets.zero,
              content: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A1C),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Booking canceled successfully.',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Failed to cancel booking. Please try again.',
                style: GoogleFonts.leagueSpartan(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            // Header with centered title and circular back button (no right icons)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
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
                        'My Test Drives',
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

            // Scrollable content
            Expanded(
              child: ScrollViewAnimation.children(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 10),

                      // Success checkmark icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1a3a52),
                          border: Border.all(
                            color: const Color(0xFF3b82c8),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Color(0xFF3b82c8),
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // XÁC NHẬN ĐẶT LỊCH THÀNH CÔNG
                      Text(
                        'XÁC NHẬN ĐẶT LỊCH',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'THÀNH CÔNG',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'YOUR HIGH-PERFORMANCE EXPERIENCE\nAWAITS.',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Car Image section
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (carImage != null && carImage.isNotEmpty)
                            ? Image.asset(
                                carImage,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderImage(),
                              )
                            : _buildPlaceholderImage(),
                      ),

                      const SizedBox(height: 10),

                      // SELECTED VEHICLE label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SELECTED VEHICLE',
                          style: GoogleFonts.leagueSpartan(
                            color: Colors.white30,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Car name
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          carBrand.isNotEmpty ? '$carName $carBrand' : carName,
                          style: GoogleFonts.leagueSpartan(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // SCHEDULE Section
                      _buildSectionCard(
                        icon: Icons.calendar_today_rounded,
                        sectionTitle: 'SCHEDULE',
                        children: [
                          _buildInfoRow('DATE', date),
                          const SizedBox(height: 12),
                          _buildInfoRow('TIME', time),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // DRIVER INFORMATION Section
                      _buildSectionCard(
                        icon: Icons.person_outline_rounded,
                        sectionTitle: 'DRIVER INFORMATION',
                        children: [
                          _buildInfoRow('FULL NAME', name),
                          const SizedBox(height: 12),
                          _buildInfoRow('PHONE NUMBER', phone),
                          const SizedBox(height: 12),
                          _buildInfoRow('EMAIL ADDRESS', email),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SHOWROOM LOCATION Section (if available)
                      if (showroomName.isNotEmpty)
                        _buildShowroomSection(
                          context: context,
                          showroomName: showroomName,
                          showroomAddress: showroomAddress,
                          googleMapsUrl: googleMapsUrl,
                        ),

                      if (showroomName.isNotEmpty) const SizedBox(height: 16),

                      // Info note
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a2e),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF3b82c8,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFF3b82c8),
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Một chuyên viên tư vấn sẽ liên hệ với bạn trong vòng 24 giờ để nhắc nhở điểm đón. Vui lòng mang theo bằng lái xe còn hiệu lực khi tham gia lái thử.',
                                style: GoogleFonts.leagueSpartan(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // BACK TO HOME button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cancelBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3b82c8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'CANCEL BOOKING',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // DOWNLOAD E-TICKET button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                padding: EdgeInsets.zero,
                                content: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1a3a52),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF3b82c8,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.download_rounded,
                                        color: Color(0xFF3b82c8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Tính năng đang phát triển',
                                        style: GoogleFonts.leagueSpartan(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white54,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'DOWNLOAD E-TICKET',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Footer
                      Column(
                        children: [
                          Text(
                            '© 2026 LUXE DRIVE GLOBAL · KINETIC ELEGANCE',
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.white24,
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'ALL RIGHTS RESERVED.',
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.white24,
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String sectionTitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3b82c8), size: 16),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: GoogleFonts.leagueSpartan(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            color: Colors.white30,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '—',
          style: GoogleFonts.leagueSpartan(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildShowroomSection({
    required BuildContext context,
    required String showroomName,
    required String showroomAddress,
    required String googleMapsUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF4285F4), size: 16),
              const SizedBox(width: 8),
              Text(
                'SHOWROOM LOCATION',
                style: GoogleFonts.leagueSpartan(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 20),

          // Showroom name
          Text(
            'SHOWROOM',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showroomName,
            style: GoogleFonts.leagueSpartan(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // Showroom address
          Text(
            'ADDRESS',
            style: GoogleFonts.leagueSpartan(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getDisplayAddress(showroomAddress),
            style: GoogleFonts.leagueSpartan(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),

          if (googleMapsUrl.isNotEmpty ||
              (showroomName.isNotEmpty && showroomAddress.isNotEmpty)) ...[
            const SizedBox(height: 16),
            // Google Maps Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (googleMapsUrl.isNotEmpty) {
                    _openGoogleMaps(googleMapsUrl, context);
                  } else {
                    // Fallback: tạo URL từ địa chỉ
                    _openGoogleMapsWithAddress(showroomAddress, context);
                  }
                },
                icon: const Icon(Icons.directions, size: 18),
                label: Text(
                  'Chỉ đường',
                  style: GoogleFonts.leagueSpartan(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(String url, BuildContext context) async {
    try {
      // Debug info
      print('🗺️ Attempting to open Google Maps with URL: $url');

      // Kiểm tra nếu URL có format cũ thì chuyển đổi
      String processedUrl = url;
      if (url.contains('google.navigation:')) {
        // Nếu là URL navigation, chuyển thành web URL
        final RegExp coordRegex = RegExp(r'q=(-?\d+\.?\d*),(-?\d+\.?\d*)');
        final match = coordRegex.firstMatch(url);
        if (match != null) {
          final lat = match.group(1);
          final lng = match.group(2);
          processedUrl =
              'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
          print('🗺️ Converted to web URL: $processedUrl');
        }
      }

      final uri = Uri.parse(processedUrl);

      // Thử mở Google Maps app trước
      final coordinates = _extractCoordinates(processedUrl);
      final googleMapsUri = Uri.parse(
        'google.navigation:q=$coordinates&mode=d',
      );
      print('🗺️ Trying Google Maps app with: $googleMapsUri');

      bool launched = false;

      if (await canLaunchUrl(googleMapsUri)) {
        launched = await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );
        print('🗺️ Google Maps app launch result: $launched');
      }

      // Nếu không mở được app thì mở trên browser
      if (!launched && await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('🗺️ Web browser launch result: $launched');
      }

      if (!launched && context.mounted) {
        print('❌ Failed to launch any Google Maps option');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không mở được Google Maps. Vui lòng kiểm tra đã cài đặt ứng dụng Google Maps.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (launched) {
        print('✅ Successfully opened Google Maps');
      }
    } catch (e) {
      print('❌ Error opening Google Maps: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi mở Google Maps: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMapsWithAddress(
    String address,
    BuildContext context,
  ) async {
    try {
      print('🗺️ Opening Google Maps with address: $address');

      // Tạo URL search từ địa chỉ
      final encodedAddress = Uri.encodeComponent(address);
      final searchUrl =
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      final searchUri = Uri.parse(searchUrl);

      // Thử mở Google Maps app trước với search
      final googleMapsSearchUri = Uri.parse('geo:0,0?q=$encodedAddress');

      bool launched = false;

      // Thử Google Maps app search
      if (await canLaunchUrl(googleMapsSearchUri)) {
        launched = await launchUrl(
          googleMapsSearchUri,
          mode: LaunchMode.externalApplication,
        );
        print('🗺️ Google Maps app search launch result: $launched');
      }

      // Nếu không mở được app thì mở trên browser
      if (!launched && await canLaunchUrl(searchUri)) {
        launched = await launchUrl(
          searchUri,
          mode: LaunchMode.externalApplication,
        );
        print('🗺️ Web search launch result: $launched');
      }

      if (!launched && context.mounted) {
        print('❌ Failed to launch Google Maps search');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không mở được Google Maps. Vui lòng kiểm tra địa chỉ showroom.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (launched) {
        print('✅ Successfully opened Google Maps search');
      }
    } catch (e) {
      print('❌ Error opening Google Maps search: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm địa chỉ: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _extractCoordinates(String url) {
    final RegExp coordRegex = RegExp(
      r'destination=(-?\d+\.?\d*),(-?\d+\.?\d*)',
    );
    final match = coordRegex.firstMatch(url);
    if (match != null) {
      return '${match.group(1)},${match.group(2)}';
    }
    return '21.027763,105.834160'; // Fallback to Hanoi
  }

  /// Cải thiện hiển thị địa chỉ - luôn có địa chỉ cụ thể
  String _getDisplayAddress(String address) {
    if (address.isEmpty) return 'Địa chỉ showroom không có sẵn';

    // Các từ khóa cần thay thế bằng địa chỉ backup
    const hiddenPhrases = [
      'địa chỉ đang cập nhật',
      'đang cập nhật',
      'vị trí showroom',
      'cơ sở của',
    ];

    final lowerAddress = address.toLowerCase();
    for (final phrase in hiddenPhrases) {
      if (lowerAddress.contains(phrase)) {
        // Nếu chỉ có phrase này thì thay thế
        if (lowerAddress.trim() == phrase) {
          return 'Địa chỉ chi tiết có trên Google Maps';
        }
      }
    }

    return address;
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.directions_car_outlined,
        size: 60,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}
