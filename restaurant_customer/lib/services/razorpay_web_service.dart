// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';

class RazorpayWebService {
  /// Razorpay Checkout open karo (Web)
  /// Returns PaymentResult on success, null on failure
  static Future<PaymentResult?> openCheckout({
    required String keyId,
    required String razorpayOrderId,
    required int amountInPaisa,
    required String customerName,
    required String customerPhone,
    required String description,
  }) async {
    try {
      // Razorpay options configure karo
      final options = js.JsObject.jsify({
        'key': keyId,
        'amount': amountInPaisa,
        'currency': 'INR',
        'name': 'Restaurant POS',
        'description': description,
        'order_id': razorpayOrderId,
        'prefill': {
          'name': customerName,
          'contact': customerPhone,
        },
        'theme': {
          'color': '#1B5E20',
        },
        'modal': {
          'ondismiss': () {
            debugPrint('Razorpay modal closed by user');
          },
        },
      });

      // Handler setup karo (success/failure)
      final completer = _PaymentCompleter();

      options['handler'] = js.JsFunction.withThis((_, response) {
        final jsResponse = response as js.JsObject;
        final paymentId = jsResponse['razorpay_payment_id'] as String?;
        final orderId = jsResponse['razorpay_order_id'] as String?;
        final signature = jsResponse['razorpay_signature'] as String?;

        if (paymentId != null && orderId != null && signature != null) {
          completer.complete(PaymentResult(
            razorpayPaymentId: paymentId,
            razorpayOrderId: orderId,
            razorpaySignature: signature,
          ));
        } else {
          completer.complete(null);
        }
      });

      // Razorpay instance banao aur open karo
      final razorpay = js.JsObject(
        js.context['Razorpay'] as js.JsFunction,
        [options],
      );

      razorpay.callMethod('on', [
        'payment.failed',
        js.JsFunction.withThis((_, response) {
          final jsResponse = response as js.JsObject;
          debugPrint('Payment failed: ${jsResponse['error']}');
          completer.complete(null);
        }),
      ]);

      razorpay.callMethod('open');

      return await completer.future;
    } catch (e) {
      debugPrint('Razorpay Web Error: $e');
      return null;
    }
  }
}

// Simple completer for async JS callback
class _PaymentCompleter {
  PaymentResult? _result;
  bool _completed = false;

  Future<PaymentResult?> get future async {
    if (_completed) return _result;

    // Wait for JS callback (max 5 minutes)
    for (int i = 0; i < 300; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (_completed) return _result;
    }
    return null; // Timeout
  }

  void complete(PaymentResult? result) {
    _result = result;
    _completed = true;
  }
}
