import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_response.dart';
import '../config/chapa_config.dart';

class PaymentService {
  static const String _baseUrl = 'https://ethionetflix1.hopto.org';

  // Initialize payment with Chapa
  Future<PaymentResponse> initializePayment(double amount) async {
    try {
      // Generate a unique transaction reference
      final String txRef = 'tx-${DateTime.now().millisecondsSinceEpoch}';
      
      // First initialize payment with Chapa
      final chapaResponse = await http.post(
        Uri.parse('${ChapaConfig.baseUrl}${ChapaConfig.initializeEndpoint}'),
        headers: {
          'Authorization': 'Bearer ${ChapaConfig.secretKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': ChapaConfig.currency,
          'email': 'customer@example.com', // You should get this from user profile
          'first_name': 'Customer', // You should get this from user profile
          'last_name': 'Name', // You should get this from user profile
          'tx_ref': txRef,
          'callback_url': '$_baseUrl/payment/callback',
          'return_url': '$_baseUrl/payment/return',
          'customization': {
            'title': ChapaConfig.paymentTitle,
            'description': ChapaConfig.paymentDescription
          }
        }),
      );

      if (chapaResponse.statusCode == 200) {
        final chapaData = jsonDecode(chapaResponse.body);
        
        // Now notify our backend about the payment
        final response = await http.post(
          Uri.parse('$_baseUrl/pay'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'amount': amount,
            'tx_ref': txRef,
            'payment_url': chapaData['data']['checkout_url'],
          }),
        );

        if (response.statusCode == 200) {
          return PaymentResponse.fromJson({
            ...jsonDecode(response.body),
            'payment_url': chapaData['data']['checkout_url'],
            'tx_ref': txRef,
          });
        } else {
          return PaymentResponse(
            status: 'error',
            message: 'Failed to initialize payment: ${response.body}',
          );
        }
      } else {
        return PaymentResponse(
          status: 'error',
          message: 'Failed to initialize Chapa payment: ${chapaResponse.body}',
        );
      }
    } catch (e) {
      return PaymentResponse(
        status: 'error',
        message: 'Payment initialization error: $e',
      );
    }
  }

  // Check payment status with Chapa
  Future<PaymentResponse> checkPaymentStatus(String txRef) async {
    try {
      // First check with Chapa
      final chapaResponse = await http.get(
        Uri.parse('${ChapaConfig.baseUrl}${ChapaConfig.verifyEndpoint}/$txRef'),
        headers: {
          'Authorization': 'Bearer ${ChapaConfig.secretKey}',
          'Content-Type': 'application/json',
        },
      );

      if (chapaResponse.statusCode == 200) {
        final chapaData = jsonDecode(chapaResponse.body);
        final chapaStatus = chapaData['status'] == 'success' ? 'success' : 'pending';
        
        // Now check with our backend
        final response = await http.get(
          Uri.parse('$_baseUrl/check/$txRef'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final backendData = jsonDecode(response.body);
          // Only return success if both Chapa and our backend confirm success
          return PaymentResponse.fromJson({
            ...backendData,
            'status': chapaStatus == 'success' && backendData['status'] == 'success' 
                ? 'success' 
                : 'pending'
          });
        } else {
          return PaymentResponse(
            status: 'error',
            message: 'Failed to check payment status: ${response.body}',
          );
        }
      } else {
        return PaymentResponse(
          status: 'error',
          message: 'Failed to verify Chapa payment: ${chapaResponse.body}',
        );
      }
    } catch (e) {
      return PaymentResponse(
        status: 'error',
        message: 'Payment status check error: $e',
      );
    }
  }
} 