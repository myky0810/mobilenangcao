import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service tự động simulate thanh toán cho DEMO
/// Sau 15 giây sẽ tự động update Firestore để trigger payment success
class AutoPaymentDemo {
  /// Tự động "thanh toán" sau 15 giây
  static void startAutoPayment({required String transactionId}) {
    print('🎬 Auto payment will trigger after 15 seconds...');

    Timer(const Duration(seconds: 15), () async {
      try {
        print('💰 Auto payment triggered for: $transactionId');

        // Update Firestore - trigger listener
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(transactionId)
            .update({
              'status': 'paid',
              'paidAt': FieldValue.serverTimestamp(),
              'autoDemo': true,
            });

        print('✅ Payment status updated - app will auto detect!');
      } catch (e) {
        print('❌ Error updating payment: $e');
      }
    });
  }
}

/// Tự động tạo payment sau 1 thời gian để demo cho giảng viên
class AutoPaymentSimulator {
  /// Tự động simulate payment sau delay (CHỈ CHO DEMO)
  static void simulateAutoPayment({
    required String transactionId,
    required int delaySeconds,
  }) {
    print('🎬 [DEMO] Auto-payment sẽ trigger sau $delaySeconds giây...');

    Timer(Duration(seconds: delaySeconds), () async {
      try {
        print('💰 [DEMO] Simulating payment for: $transactionId');

        // Update Firestore để trigger listener
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(transactionId)
            .update({
              'status': 'paid',
              'paidAt': FieldValue.serverTimestamp(),
              'simulatedPayment': true, // Mark as simulated
            });

        print('✅ [DEMO] Payment simulated successfully!');
      } catch (e) {
        print('❌ [DEMO] Error simulating payment: $e');
      }
    });
  }
}
