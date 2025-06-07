import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/chapa_config.dart';

class ChapaService {
  static const String _baseUrl = ChapaConfig.baseUrl;
  final String _secretKey = ChapaConfig.secretKey;
  final String _publicKey = ChapaConfig.publicKey;
  
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
      // Make sure we have all required fields
      if (amount.isEmpty || email.isEmpty || firstName.isEmpty || lastName.isEmpty || txRef.isEmpty) {
        throw Exception('Required payment fields cannot be empty');
      }

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
        'customization[title]': ChapaConfig.paymentTitle,
        'customization[description]': ChapaConfig.paymentDescription
      };
      
      print('Initializing payment with payload: $payload');
      print('Using API endpoint: $url');
      
      // Deep logging for debugging
      if (kIsWeb) {
        print('Running in Web mode');
          // Test if browser can access the API directly (likely to fail due to CORS)
        try {
          final corsTestResponse = await http.head(url, 
            headers: {'Accept': 'application/json'});
          print('CORS test response: ${corsTestResponse.statusCode}');
        } catch (e) {
          print('CORS test failed as expected: $e');
          print('This is normal in web mode and we\'ll handle it properly');
        }
        
        // In web mode, direct API calls often fail due to CORS
        // We could implement a server proxy or use Chapa's checkout page directly
        
        // For demo purposes, we'll simulate a successful response
        // In a real app, you would implement a backend proxy or use Chapa's hosted checkout
        
        // Use direct Chapa hosted checkout if you're in web mode
        final mockResponse = {
          'status': 'success',
          'data': {
            'checkout_url': 'https://checkout.chapa.co/checkout/payment/${_publicKey}/${txRef}'
          }
        };
        
        print('Web mode: Using hosted checkout URL');
        return mockResponse;
      }
      
      // If we're not in web mode, proceed with direct API call
      print('Using secret key: ${_secretKey.substring(0, 10)}...');
      
      // Try a health check first
      try {
        final testResponse = await http.get(Uri.parse('$_baseUrl/health-check'));
        print('API health check status: ${testResponse.statusCode}');
      } catch (e) {
        print('API health check failed: $e');
        print('Proceeding with payment initialization anyway...');
      }
      
      // Set a timeout for the request
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('The connection to Chapa has timed out. Please check your internet connection and try again.');
      });
      
      print('Chapa response status code: ${response.statusCode}');
      print('Chapa response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initialize payment: ${response.body}');
      }
    } on TimeoutException catch (e) {
      print('Payment request timed out: $e');
      throw Exception('The payment request timed out. Please check your internet connection and try again.');
    } catch (e) {
      print('Error initializing payment: $e');
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        // This is a common error in web when facing CORS issues
        throw Exception('Payment gateway unavailable in web preview. This would work on a properly deployed web app with CORS handling or on the mobile app.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyTransaction(String txRef) async {
    try {
      final url = Uri.parse('$_baseUrl/transaction/verify/$txRef');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to verify transaction: ${response.body}');
      }
    } catch (e) {
      print('Error verifying transaction: $e');
      rethrow;
    }
  }
}