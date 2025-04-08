import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class PaymentService {
  final FirebaseService _firebaseService;
  late Razorpay _razorpay;

  PaymentService(this._firebaseService) {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<void> openCheckout({
    required UserModel user,
    required double amount,
    required Function(double) onSuccess,
    required Function(String) onError,
  }) async {
    // Amount needs to be in paise (100 paise = 1 rupee)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // This should come from environment variables in real app
      'amount': amountInPaise,
      'name': 'ArenaX',
      'description': 'Wallet Recharge',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);

      // Store callbacks for use in the handlers
      _onSuccessCallback = onSuccess;
      _onErrorCallback = onError;
      _amount = amount;
      _userId = user.id;
    } catch (e) {
      onError('Error: $e');
    }
  }

  // Callback storage
  late Function(double) _onSuccessCallback;
  late Function(String) _onErrorCallback;
  late double _amount;
  late String _userId;

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Get current user data
      final userData = await _firebaseService.getUserData(_userId);

      if (userData != null) {
        // Update wallet balance
        final newBalance = userData.walletBalance + _amount;
        final updatedUser = userData.copyWith(walletBalance: newBalance);

        await _firebaseService.updateUserData(updatedUser);

        // Call success callback
        _onSuccessCallback(newBalance);
      }
    } catch (e) {
      _onErrorCallback('Failed to update wallet: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onErrorCallback('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onErrorCallback('External wallet selected: ${response.walletName}');
  }
}
