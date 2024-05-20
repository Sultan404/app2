import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:second/payment/key.dart';

abstract class PaymentManager {
  static Future<bool> makePayment(double amount, String currency) async {
    try {
      String clientSecret =
          await _getClientSecret(amount, currency);
      await _initializePaymentSheet(clientSecret);
      await Stripe.instance.presentPaymentSheet();
      // Payment succeeded if execution reaches this point
      return true;
    } catch (error) {
      // Payment failed
      print("Payment error: $error");
      return false;
    }
  }

  static Future<void> _initializePaymentSheet(String clientSecret) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: "holek",
      ),
    );
  }

  static Future<String> _getClientSecret(double amount, String currency) async {
    // Convert the amount to cents (assuming the currency is in dollars)
    int amountInCents = (amount * 100).toInt();

    Dio dio = Dio();
    var response = await dio.post(
      'https://api.stripe.com/v1/payment_intents',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${ApiKeys.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      ),
      data: {
        'amount': amountInCents, // Provide the amount as an integer
        'currency': currency,
      },
    );
    return response.data["client_secret"];
  }
}
