import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../config/chapa_config.dart';

/// This class provides a way to handle Chapa API calls in the web environment
/// where direct API calls might be blocked by CORS restrictions.
class ChapaProxy {
  /// In a production application, this would call your own backend proxy
  /// Here we're just simulating a successful response for demo purposes
  static Future<Map<String, dynamic>> proxyInitializePayment({
    required String amount,
    required String currency,
    required String email,
    required String firstName,
    required String lastName,
    required String txRef,
  }) async {
    // For demonstration purposes, generate a fake checkout URL
    // In a real app, you would implement a backend proxy that makes the actual API call
    
    // Use Chapa's hosted checkout URL format with the public key
    final checkoutUrl = 'https://checkout.chapa.co/checkout/payment/${ChapaConfig.publicKey}/$txRef';
    
    // Return a simulated successful response
    return {
      'status': 'success',
      'message': 'Payment initialized (proxy simulation)',
      'data': {
        'checkout_url': checkoutUrl,
        'tx_ref': txRef,
      }
    };
  }
  
  /// In a production app, implement proper error handling for different scenarios
  static String getErrorMessage(dynamic error) {
    if (kIsWeb && error.toString().contains('Failed to fetch')) {
      return 'Unable to connect to payment gateway from web browser. This is likely due to CORS restrictions. In a production app, this would be handled by a server-side proxy.';
    }
    
    if (error.toString().contains('SocketException') || 
        error.toString().contains('Connection refused')) {
      return 'Could not connect to the payment server. Please check your internet connection and try again.';
    }
    
    return 'An error occurred while processing your payment: ${error.toString()}';
  }
}
