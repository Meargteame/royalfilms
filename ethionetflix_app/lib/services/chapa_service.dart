import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/chapa_config.dart';

class ChapaService {
  static const String _baseUrl = ChapaConfig.baseUrl;
  final String _secretKey = ChapaConfig.secretKey;
  
  ChapaService();

    Future<Map<String, dynamic>> initializePayment({
    required String amount,
    required String currency,
    required String email,
    required String firstName,
    required String lastName,
    required String txRef,
    String? returnUrl,
    String? callbackUrl,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/transaction/initialize');
      
      final payload = {
        'amount': amount,
        'currency': currency,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'tx_ref': txRef,
        'return_url': returnUrl ?? 'https://ethionetflix.com/payment/success',
        'callback_url': callbackUrl ?? 'https://ethionetflix.com/payment/callback',
      };
      
      print('Initializing payment with payload: $payload');
      print('Using API endpoint: $url');
      print('Using secret key: ${_secretKey.substring(0, 10)}...');
      
      // First verify the connection by making a test request
      try {
        final testResponse = await http.get(Uri.parse('$_baseUrl/health-check'));
        print('API health check status: ${testResponse.statusCode}');
      } catch (e) {
        print('API health check failed: $e');
      }
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      print('Chapa response status code: ${response.statusCode}');
      print('Chapa response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initialize payment: ${response.body}');
      }
    } catch (e) {
      print('Error initializing payment: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyTransaction(String txRef) async {
    final url = Uri.parse('$_baseUrl/transaction/verify/$txRef');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify transaction: ${response.body}');
    }
  }
} 