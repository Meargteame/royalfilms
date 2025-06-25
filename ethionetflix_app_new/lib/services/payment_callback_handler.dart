import 'dart:async';
import 'chapa_service.dart';

/// Handles payment callbacks and verification logic
class PaymentCallbackHandler {
  final ChapaService _chapaService = ChapaService();
  
  /// Handle payment success callback
  Future<Map<String, dynamic>> handlePaymentSuccess({
    required String txRef,
    String? status,
    String? message,
  }) async {
    print('PaymentCallbackHandler: Processing success callback for $txRef');
    
    try {
      // Always verify the transaction on our end, regardless of callback status
      final verificationResult = await _chapaService.verifyTransaction(txRef);
      
      if (verificationResult['status'] == 'success') {
        final transactionData = verificationResult['data'];
        final actualStatus = transactionData?['status'] ?? 'unknown';
        
        print('PaymentCallbackHandler: Transaction verified successfully');
        print('PaymentCallbackHandler: Actual status from Chapa: $actualStatus');
        
        return {
          'success': true,
          'verified': true,
          'transaction_status': actualStatus,
          'tx_ref': txRef,
          'amount': transactionData?['amount'],
          'currency': transactionData?['currency'],
          'message': 'Payment verified successfully',
          'verification_data': verificationResult,
        };
      } else {
        print('PaymentCallbackHandler: Transaction verification failed');
        return {
          'success': false, 
          'verified': false,
          'tx_ref': txRef,
          'message': 'Payment verification failed: ${verificationResult['message']}',
          'verification_data': verificationResult,
        };
      }
    } catch (e) {
      print('PaymentCallbackHandler: Error during verification: $e');
      
      // If verification fails due to network issues, still treat as success
      // but flag as unverified for manual review
      return {
        'success': true,
        'verified': false,
        'tx_ref': txRef,
        'message': 'Payment completed but verification failed. Manual review required.',
        'error': e.toString(),
      };
    }
  }
  
  /// Handle payment failure callback
  Map<String, dynamic> handlePaymentFailure({
    required String txRef,
    String? status,
    String? message,
    String? reason,
  }) {
    print('PaymentCallbackHandler: Processing failure callback for $txRef');
    print('PaymentCallbackHandler: Failure reason: $reason');
    
    return {
      'success': false,
      'verified': false,
      'tx_ref': txRef,
      'status': status,
      'message': message ?? 'Payment failed',
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Handle payment cancellation
  Map<String, dynamic> handlePaymentCancellation({
    required String txRef,
    String? message,
  }) {
    print('PaymentCallbackHandler: Processing cancellation for $txRef');
    
    return {
      'success': false,
      'verified': false,
      'cancelled': true,
      'tx_ref': txRef,
      'message': message ?? 'Payment was cancelled by user',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Process webhook callback (for server-side integration)
  Future<Map<String, dynamic>> processWebhookPayload(Map<String, dynamic> payload) async {
    print('PaymentCallbackHandler: Processing webhook payload');
    
    try {
      final txRef = payload['tx_ref'];
      final status = payload['status'];
      final event = payload['event'];
      
      if (txRef == null) {
        throw Exception('Missing transaction reference in webhook payload');
      }
      
      print('PaymentCallbackHandler: Webhook event: $event, status: $status');
      
      switch (event) {
        case 'charge.success':
          return await handlePaymentSuccess(
            txRef: txRef,
            status: status,
            message: payload['message'],
          );
          
        case 'charge.failed':
          return handlePaymentFailure(
            txRef: txRef,
            status: status,
            message: payload['message'],
            reason: payload['reason'],
          );
          
        default:
          print('PaymentCallbackHandler: Unknown webhook event: $event');
          return {
            'success': false,
            'message': 'Unknown webhook event: $event',
            'payload': payload,
          };
      }
    } catch (e) {
      print('PaymentCallbackHandler: Error processing webhook: $e');
      return {
        'success': false,
        'message': 'Error processing webhook',
        'error': e.toString(),
        'payload': payload,
      };
    }
  }
  
  /// Parse URL callback parameters (for return URL handling)
  Map<String, dynamic> parseUrlCallback(String url) {
    print('PaymentCallbackHandler: Parsing URL callback: $url');
    
    final uri = Uri.parse(url);
    final params = uri.queryParameters;
    
    final result = {
      'tx_ref': params['tx_ref'],
      'status': params['status'],
      'message': params['message'],
      'timestamp': DateTime.now().toIso8601String(),
      'url': url,
    };
    
    print('PaymentCallbackHandler: Parsed callback parameters: $result');
    return result;
  }
  
  /// Comprehensive payment validation
  Future<bool> validatePaymentCompletion(String txRef) async {
    try {
      print('PaymentCallbackHandler: Validating payment completion for $txRef');
      
      final verificationResult = await _chapaService.verifyTransaction(txRef);
      final isSuccess = verificationResult['status'] == 'success';
      final transactionStatus = verificationResult['data']?['status'];
      
      print('PaymentCallbackHandler: Verification result: $isSuccess');
      print('PaymentCallbackHandler: Transaction status: $transactionStatus');
      
      // Payment is considered complete if:
      // 1. Verification API returns success
      // 2. Transaction status is 'success' or 'completed'
      return isSuccess && (transactionStatus == 'success' || transactionStatus == 'completed');
      
    } catch (e) {
      print('PaymentCallbackHandler: Error validating payment: $e');
      return false;
    }
  }
}
