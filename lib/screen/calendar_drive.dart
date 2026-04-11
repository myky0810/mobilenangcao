import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_calendarcar.dart';

import '../services/user_service.dart';

class TestDriveScreen extends StatefulWidget {
  const TestDriveScreen({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  State<TestDriveScreen> createState() => _TestDriveScreenState();
}

class _TestDriveScreenState extends State<TestDriveScreen> {
  // Use Deposit palette
  static const Color _showroomTop = Color(0xFF1E2A47);
  static const Color _showroomMid = Color(0xFF1E2A47);
  static const Color _showroomBase = Color(0xFF1E2A47);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _showroomBase,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_showroomTop, _showroomMid, _showroomBase],
                ),
              ),
            ),

            Column(
              children: [
                // Header with back button and title
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
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
                            color: Colors.white.withValues(alpha: 0.10),
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
                            'Lịch lái thử',
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

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Bookings list from Firestore (lọc theo userPhone)
                        StreamBuilder<QuerySnapshot>(
                          stream: () {
                            final profileRef =
                                UserService.currentUserProfileRef(
                                  phoneIdentifier: widget.phoneNumber,
                                );
                            final profilePath = profileRef?.path ?? '';

                            if (profilePath.isNotEmpty) {
                              return FirebaseFirestore.instance
                                  .collection('test_drive_bookings')
                                  .where(
                                    'userProfilePath',
                                    isEqualTo: profilePath,
                                  )
                                  .snapshots();
                            }

                            // Backward compatibility: older docs used userPhone.
                            final phone = widget.phoneNumber?.trim() ?? '';
                            if (phone.isNotEmpty) {
                              return FirebaseFirestore.instance
                                  .collection('test_drive_bookings')
                                  .where('userPhone', isEqualTo: phone)
                                  .snapshots();
                            }

                            return FirebaseFirestore.instance
                                .collection('test_drive_bookings')
                                .snapshots();
                          }(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              // Hiện tất cả booking nếu query lỗi (fallback)
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('test_drive_bookings')
                                    .snapshots(),
                                builder: (context, fallbackSnap) {
                                  if (!fallbackSnap.hasData ||
                                      fallbackSnap.data!.docs.isEmpty) {
                                    return _buildEmptyState();
                                  }

                                  final profileRef =
                                      UserService.currentUserProfileRef(
                                        phoneIdentifier: widget.phoneNumber,
                                      );
                                  final profilePath = profileRef?.path ?? '';
                                  final docs = fallbackSnap.data!.docs.where((
                                    doc,
                                  ) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    if (profilePath.isNotEmpty) {
                                      final path =
                                          (data['userProfilePath']
                                              as String?) ??
                                          '';
                                      return path == profilePath;
                                    }
                                    final up =
                                        (data['userPhone'] as String?) ?? '';
                                    final phone =
                                        widget.phoneNumber?.trim() ?? '';
                                    return phone.isEmpty || up == phone;
                                  }).toList();
                                  docs.sort((a, b) {
                                    final at =
                                        (a.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >)['createdAt'];
                                    final bt =
                                        (b.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >)['createdAt'];
                                    if (at == null && bt == null) return 0;
                                    if (at == null) return 1;
                                    if (bt == null) return -1;
                                    return (bt as dynamic).compareTo(
                                      at as dynamic,
                                    );
                                  });
                                  if (docs.isEmpty) return _buildEmptyState();
                                  return Column(
                                    children: docs.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      return _buildBookingCard(data, doc.id);
                                    }).toList(),
                                  );
                                },
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(
                                    color: Colors.white54,
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return _buildEmptyState();
                            }

                            // Sort bằng Dart (không cần Firestore index)
                            final docs = List.from(snapshot.data!.docs);
                            docs.sort((a, b) {
                              final at =
                                  (a.data()
                                      as Map<String, dynamic>)['createdAt'];
                              final bt =
                                  (b.data()
                                      as Map<String, dynamic>)['createdAt'];
                              if (at == null && bt == null) return 0;
                              if (at == null) return 1;
                              if (bt == null) return -1;
                              return (bt as dynamic).compareTo(at as dynamic);
                            });

                            return Column(
                              children: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildBookingCard(data, doc.id);
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        // Đặt lịch lái thử khác
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/newcar',
                                    arguments: widget.phoneNumber,
                                  );
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.directions_car_outlined,
                                    color: Colors.white.withValues(alpha: 0.3),
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/newcar',
                                    arguments: widget.phoneNumber,
                                  );
                                },
                                child: const Text(
                                  'Đặt lịch lái thử khác?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Spartan',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Trải nghiệm những mẫu xe mới\nvà công nghệ hiện đại nhất.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontFamily: 'Spartan',
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Colors.white.withValues(alpha: 0.2),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có lịch lái thử',
              style: TextStyle(
                color: Colors.white54,
                fontFamily: 'Spartan',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đặt lịch lái thử từ trang chi tiết xe',
              style: TextStyle(
                color: Colors.white30,
                fontFamily: 'Spartan',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String docId) {
    final status = (data['status'] as String?) ?? 'pending';
    final carName = (data['carName'] as String?) ?? 'Xe chưa xác định';
    final carImage = data['carImage'] as String?;
    final date = (data['date'] as String?) ?? '';
    final time = (data['time'] as String?) ?? '';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'confirmed':
        statusColor = const Color(0xFF22C55E);
        statusText = 'ĐÃ XÁC NHẬN';
        break;
      case 'completed':
        statusColor = const Color(0xFF6B7280);
        statusText = 'HOÀN THÀNH';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'ĐANG CHỜ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: carImage != null && carImage.isNotEmpty
                ? Image.asset(
                    carImage,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car name + status badge row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        carName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Spartan',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontFamily: 'Spartan',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date and time row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Spartan',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Spartan',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    if (status == 'pending')
                      Expanded(
                        child: _buildOutlineButton('ĐỔI LỊCH', onTap: () {}),
                      ),
                    if (status == 'pending') const SizedBox(width: 10),
                    Expanded(
                      child: _buildFilledButton(
                        status == 'completed' ? 'ĐÁNH GIÁ' : 'CHI TIẾT  →',
                        onTap: () {
                          final bookingData = <String, dynamic>{
                            ...data,
                            // Needed by DetailCalendarCarScreen to cancel booking reliably
                            'id': docId,
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailCalendarCarScreen(
                                bookingData: bookingData,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 160,
      color: const Color(0xFF2a2a2a),
      child: Icon(
        Icons.directions_car,
        size: 50,
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _buildOutlineButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Spartan',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledButton(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Spartan',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
