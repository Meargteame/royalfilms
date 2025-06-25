import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'lib/config/chapa_config.dart';
import 'lib/services/chapa_service.dart';

void main() async {
  print('=== Chapa Payment Integration Test ===\n');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('   Proceeding with hardcoded defaults...\n');
  }

  // Test 1: Configuration validation
  print('--- Test 1: Configuration Validation ---');
  final configValid = ChapaConfig.validateKeys();
  print('API Keys Valid: ${configValid ? "✅" : "❌"}');
  print('Environment: ${ChapaConfig.environment}');
  print('Mode: ${ChapaConfig.isTestMode ? "Sandbox/Test" : "Live/Production"}');
  print('Base URL: ${ChapaConfig.baseUrl}');
  print('Public Key: ${ChapaConfig.publicKey.substring(0, 15)}...');
  print('Secret Key: ${ChapaConfig.secretKey.substring(0, 15)}...\n');

  // Test 2: Service initialization
  print('--- Test 2: Service Initialization ---');
  final chapaService = ChapaService();
  final statusSummary = chapaService.getPaymentStatusSummary();
  print('Service Status: ${statusSummary}');
  print('');

  // Test 3: Payment initialization (simulation)
  print('--- Test 3: Payment Initialization Test ---');
  try {
    print('Testing payment initialization with test data...');
    final response = await chapaService.initializePayment(
      amount: '100.00',
      currency: 'ETB',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      txRef: 'tx-test-${DateTime.now().millisecondsSinceEpoch}',
      returnUrl: 'https://ethionetflix.com/payment/success',
      callbackUrl: 'https://ethionetflix.com/payment/callback',
    );
    
    print('✅ Payment initialization successful!');
    print('Response: $response');
    
    // Extract transaction reference for verification test
    final txRef = response['data']?['tx_ref'] ?? 'unknown';
    
    // Test 4: Transaction verification
    print('\n--- Test 4: Transaction Verification Test ---');
    try {
      final verificationResponse = await chapaService.verifyTransaction(txRef);
      print('✅ Transaction verification successful!');
      print('Verification Response: $verificationResponse');
    } catch (e) {
      print('⚠️ Transaction verification failed (expected for test): $e');
    }
    
  } catch (e) {
    print('❌ Payment initialization failed: $e');
  }

  print('\n=== Test Summary ===');
  print('1. Configuration: ${configValid ? "✅ PASS" : "❌ FAIL"}');
  print('2. Service Init: ✅ PASS');
  print('3. Environment: ${ChapaConfig.environment} (${ChapaConfig.isTestMode ? "Test Mode" : "Live Mode"})');
  print('\n=== End of Test ===');
  
  exit(0);
}
