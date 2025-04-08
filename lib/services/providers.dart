import 'package:arena_x/services/firebase_service.dart';
import 'package:arena_x/services/payment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return PaymentService(firebaseService);
});