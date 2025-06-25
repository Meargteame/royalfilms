#!/usr/bin/env dart

// Comprehensive Chapa Payment Integration Test
// Run this script to test all aspects of the payment integration

import 'dart:io';

void main() async {
  print('🚀 Starting Chapa Payment Integration Validation...\n');
  
  // Test 1: Environment Setup
  await testEnvironmentSetup();
  
  // Test 2: Code Compilation
  await testCodeCompilation();
  
  // Test 3: Configuration Validation
  await testConfiguration();
  
  // Test 4: App Structure
  await testAppStructure();
  
  print('\n✅ All tests completed! Ready for manual testing.');
  print('\n📋 Manual Testing Instructions:');
  print('1. Run: flutter run');
  print('2. Navigate to Settings');
  print('3. Tap "Test Payment (Web Only)" if in web mode');
  print('4. Fill in test data and proceed');
  print('5. Monitor console logs for payment flow');
  print('6. Verify success/failure handling');
}

Future<void> testEnvironmentSetup() async {
  print('🔍 Testing Environment Setup...');
  
  // Check .env file
  final envFile = File('.env');
  if (await envFile.exists()) {
    final content = await envFile.readAsString();
    if (content.contains('CHAPA_PUBLIC_KEY') && content.contains('CHAPA_SECRET_KEY')) {
      print('  ✅ .env file configured with API keys');
    } else {
      print('  ❌ .env file missing API keys');
    }
  } else {
    print('  ❌ .env file not found');
  }
  
  // Check pubspec.yaml dependencies
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    final requiredDeps = ['http:', 'flutter_dotenv:', 'webview_flutter:'];
    bool allDepsPresent = true;
    
    for (final dep in requiredDeps) {
      if (content.contains(dep)) {
        print('  ✅ Dependency $dep found');
      } else {
        print('  ❌ Missing dependency: $dep');
        allDepsPresent = false;
      }
    }
    
    if (allDepsPresent) {
      print('  ✅ All required dependencies present');
    }
  }
}

Future<void> testCodeCompilation() async {
  print('\n🔍 Testing Code Compilation...');
  
  final result = await Process.run('flutter', ['analyze', '--no-pub']);
  
  if (result.exitCode == 0) {
    print('  ✅ Code analysis passed');
  } else {
    print('  ⚠️  Code analysis warnings/errors:');
    print('  ${result.stdout}');
    print('  ${result.stderr}');
  }
}

Future<void> testConfiguration() async {
  print('\n🔍 Testing Configuration Files...');
  
  // Test ChapaConfig
  final chapaConfigFile = File('lib/config/chapa_config.dart');
  if (await chapaConfigFile.exists()) {
    final content = await chapaConfigFile.readAsString();
    if (content.contains('validateKeys()') && content.contains('baseUrl')) {
      print('  ✅ ChapaConfig properly structured');
    } else {
      print('  ❌ ChapaConfig missing key methods');
    }
  }
  
  // Test ChapaService
  final chapaServiceFile = File('lib/services/chapa_service.dart');
  if (await chapaServiceFile.exists()) {
    final content = await chapaServiceFile.readAsString();
    if (content.contains('initializePayment') && content.contains('verifyTransaction')) {
      print('  ✅ ChapaService has required methods');
    } else {
      print('  ❌ ChapaService missing required methods');
    }
  }
  
  // Test PaymentCallbackHandler
  final callbackHandlerFile = File('lib/services/payment_callback_handler.dart');
  if (await callbackHandlerFile.exists()) {
    print('  ✅ PaymentCallbackHandler found');
  } else {
    print('  ❌ PaymentCallbackHandler missing');
  }
}

Future<void> testAppStructure() async {
  print('\n🔍 Testing App Structure...');
  
  // Check main.dart for routes
  final mainFile = File('lib/main.dart');
  if (await mainFile.exists()) {
    final content = await mainFile.readAsString();
    if (content.contains('PaymentTestScreen') && content.contains('routes:')) {
      print('  ✅ Payment test route configured');
    } else {
      print('  ❌ Payment test route not configured');
    }
  }
  
  // Check payment screens
  final paymentScreenFile = File('lib/screens/payment_screen.dart');
  final paymentTestScreenFile = File('lib/screens/payment_test_screen.dart');
  
  if (await paymentScreenFile.exists()) {
    print('  ✅ PaymentScreen found');
  } else {
    print('  ❌ PaymentScreen missing');
  }
  
  if (await paymentTestScreenFile.exists()) {
    print('  ✅ PaymentTestScreen found');
  } else {
    print('  ❌ PaymentTestScreen missing');
  }
  
  // Check settings screen for payment test integration
  final settingsScreenFile = File('lib/screens/settings_screen.dart');
  if (await settingsScreenFile.exists()) {
    final content = await settingsScreenFile.readAsString();
    if (content.contains('PaymentTestScreen')) {
      print('  ✅ Settings screen integrated with payment test');
    } else {
      print('  ❌ Settings screen missing payment test integration');
    }
  }
}
