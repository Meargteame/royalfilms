import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/chapa_config.dart';

class ChapaService {
  static const String _className = 'ChapaService';
  final String _secretKey = ChapaConfig.secretKey;
  final String _publicKey = ChapaConfig.publicKey;
  
  ChapaService() {
    _logInfo('Initializing ChapaService...');
    _logInfo('Environment: ${ChapaConfig.environment}');
    _logInfo('Base URL: ${ChapaConfig.baseUrl}');
    
    // Validate API keys on initialization
    if (!ChapaConfig.validateKeys()) {
      _logError('Invalid API keys detected! Payment integration may fail.');
    }
  }

  void _logInfo(String message) {
    print('[$_className] ℹ️ $message');
  }

  void _logError(String message) {
    print('[$_className] ❌ ERROR: $message');
  }

  void _logSuccess(String message) {
    print('[$_className] ✅ $message');
  }

  void _logWarning(String message) {
    print('[$_className] ⚠️ WARNING: $message');
  }
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
    _logInfo('Starting payment initialization...');
    _logInfo('Transaction Reference: $txRef');
    _logInfo('Amount: $amount $currency');
    _logInfo('Email: $email');
    
    try {
      // Validate input parameters
      final validationResult = _validatePaymentParams(
        amount: amount,
        currency: currency,
        email: email,
        firstName: firstName,
        lastName: lastName,
        txRef: txRef,
      );
      
      if (!validationResult['isValid']) {
        throw Exception('Validation Error: ${validationResult['message']}');
      }

      final url = Uri.parse('${ChapaConfig.baseUrl}/transaction/initialize');
      
      final payload = {
        'amount': amount,
        'currency': currency,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'tx_ref': txRef,
        'return_url': returnUrl ?? 'https://ethionetflix.com/payment/success',
        'callback_url': callbackUrl ?? 'https://ethionetflix.com/payment/callback',
        'customization': {
          'title': ChapaConfig.paymentTitle,
          'description': ChapaConfig.paymentDescription,
        }
      };
      
      _logInfo('API Endpoint: $url');
      _logInfo('Payload: ${jsonEncode(payload)}');
      
      // Handle web environment differently
      if (kIsWeb) {
        return _handleWebPayment(txRef, payload);
      }
      
      // Perform health check first
      await _performHealthCheck();
      
      // Make the actual payment request with retry logic
      final response = await _makeRequestWithRetry(
        () => http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'EthioNetflix-Mobile-App/2.0',
          },
          body: jsonEncode(payload),
        ),
      );
      
      _logInfo('Response Status: ${response.statusCode}');
      _logInfo('Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        _logSuccess('Payment initialized successfully');
        return responseData;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        _logError('Payment initialization failed: $errorMessage');
        throw Exception('Payment initialization failed: $errorMessage');
      }
    } on TimeoutException catch (e) {
      _logError('Request timeout: ${e.message}');
      throw Exception('Payment request timed out. Please check your internet connection and try again.');
    } on SocketException catch (e) {
      _logError('Network error: ${e.message}');
      throw Exception('Network connection failed. Please check your internet connection.');
    } on FormatException catch (e) {
      _logError('Invalid response format: ${e.message}');
      throw Exception('Invalid response from payment gateway. Please try again.');
    } catch (e) {
      _logError('Unexpected error: $e');
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        throw Exception('Payment gateway unavailable in web preview. This would work on mobile or with proper CORS setup.');
      }
      rethrow;
    }
  }


  /// Validate payment parameters
  Map<String, dynamic> _validatePaymentParams({
    required String amount,
    required String currency,
    required String email,
    required String firstName,
    required String lastName,
    required String txRef,
  }) {
    // Check required fields
    if (amount.isEmpty || email.isEmpty || firstName.isEmpty || lastName.isEmpty || txRef.isEmpty) {
      return {'isValid': false, 'message': 'Required payment fields cannot be empty'};
    }
    
    // Validate amount
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      return {'isValid': false, 'message': 'Invalid amount: must be a positive number'};
    }
    
    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return {'isValid': false, 'message': 'Invalid email format'};
    }
    
    // Validate currency
    if (currency != 'ETB') {
      return {'isValid': false, 'message': 'Only ETB currency is supported'};
    }
    
    // Validate transaction reference
    if (txRef.length < 5 || txRef.length > 50) {
      return {'isValid': false, 'message': 'Transaction reference must be 5-50 characters'};
    }
    
    return {'isValid': true, 'message': 'Validation passed'};
  }
  
  /// Handle payment in web environment
  Future<Map<String, dynamic>> _handleWebPayment(String txRef, Map<String, dynamic> payload) async {
    _logWarning('Running in Web mode - using hosted checkout');
    
    // Test CORS accessibility
    try {
      final corsTestResponse = await http.head(
        Uri.parse('${ChapaConfig.baseUrl}/transaction/initialize'),
        headers: {'Accept': 'application/json'}
      ).timeout(Duration(seconds: 5));
      _logInfo('CORS test response: ${corsTestResponse.statusCode}');
    } catch (e) {
      _logWarning('CORS test failed (expected): $e');
    }
    
    // Generate hosted checkout URL
    final checkoutUrl = 'https://checkout.chapa.co/checkout/payment/$_publicKey/$txRef';
    
    final mockResponse = {
      'status': 'success',
      'message': 'Web mode - using hosted checkout',
      'data': {
        'checkout_url': checkoutUrl,
        'tx_ref': txRef,
      }
    };
    
    _logInfo('Generated hosted checkout URL: $checkoutUrl');
    return mockResponse;
  }
  
  /// Perform API health check
  Future<void> _performHealthCheck() async {
    try {
      _logInfo('Performing API health check...');
      final response = await http.get(
        Uri.parse('${ChapaConfig.baseUrl}/health-check')
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _logSuccess('API health check passed');
      } else {
        _logWarning('API health check returned ${response.statusCode}');
      }
    } catch (e) {
      _logWarning('API health check failed: $e');
      _logInfo('Proceeding with payment initialization anyway...');
    }
  }
  
  /// Make HTTP request with retry logic
  Future<http.Response> _makeRequestWithRetry(Future<http.Response> Function() requestFunction) async {
    int attempts = 0;
    Exception? lastException;
    
    while (attempts < ChapaConfig.maxRetries) {
      attempts++;
      _logInfo('Attempt $attempts/${ChapaConfig.maxRetries}');
      
      try {
        final response = await requestFunction().timeout(ChapaConfig.requestTimeout);
        return response;
      } on TimeoutException catch (e) {
        lastException = e;
        _logWarning('Attempt $attempts timed out: ${e.message}');
        if (attempts < ChapaConfig.maxRetries) {
          await Future.delayed(Duration(seconds: attempts * 2)); // Exponential backoff
        }
      } on SocketException catch (e) {
        lastException = Exception('Network error: ${e.message}');
        _logWarning('Network error on attempt $attempts: ${e.message}');
        if (attempts < ChapaConfig.maxRetries) {
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      } catch (e) {
        _logError('Unexpected error on attempt $attempts: $e');
        throw e; // Don't retry for unexpected errors
      }
    }
      _logError('All $attempts attempts failed');
    throw lastException ?? Exception('Request failed after $attempts attempts');
  }

  Future<Map<String, dynamic>> verifyTransaction(String txRef) async {
    _logInfo('Starting transaction verification for: $txRef');
    
    try {
      if (txRef.isEmpty) {
        throw Exception('Transaction reference cannot be empty');
      }
      
      final url = Uri.parse('${ChapaConfig.baseUrl}/transaction/verify/$txRef');
      _logInfo('Verification URL: $url');
      
      if (kIsWeb) {
        _logWarning('Transaction verification not available in web mode');
        return {
          'status': 'pending',
          'message': 'Transaction verification not available in web preview mode',
          'data': {'tx_ref': txRef}
        };
      }
      
      final response = await _makeRequestWithRetry(
        () => http.get(
          url,
          headers: {
            'Authorization': 'Bearer $_secretKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'EthioNetflix-Mobile-App/2.0',
          },
        ),
      );

      _logInfo('Verification response status: ${response.statusCode}');
      _logInfo('Verification response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _logSuccess('Transaction verification completed');
        return responseData;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        _logError('Transaction verification failed: $errorMessage');
        throw Exception('Failed to verify transaction: $errorMessage');
      }
    } on TimeoutException catch (e) {
      _logError('Verification timeout: ${e.message}');
      throw Exception('Transaction verification timed out. Please try again.');
    } on SocketException catch (e) {
      _logError('Network error during verification: ${e.message}');
      throw Exception('Network error during verification. Please check your connection.');
    } catch (e) {
      _logError('Verification error: $e');
      rethrow;
    }
  }
  
  /// Get payment status summary
  Map<String, dynamic> getPaymentStatusSummary() {
    return {
      'service': 'Chapa Payment Service',
      'environment': ChapaConfig.environment,
      'mode': ChapaConfig.isTestMode ? 'Test/Sandbox' : 'Live/Production',
      'base_url': ChapaConfig.baseUrl,
      'api_keys_valid': ChapaConfig.validateKeys(),
      'web_environment': kIsWeb,
    };
  }
}