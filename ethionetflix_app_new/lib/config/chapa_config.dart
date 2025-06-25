import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChapaConfig {
  // API Keys from environment variables with fallback defaults for testing
  static String get publicKey {
    final key = dotenv.env['CHAPA_PUBLIC_KEY'] ?? 'CHAPUBK_TEST-7T1WmPB1ay0XTyn0fsYFcx5RWkFwB8QI';
    print('Using Chapa public key: ${key.substring(0, 15)}...');
    return key;
  }
  
  static String get secretKey {
    final key = dotenv.env['CHAPA_SECRET_KEY'] ?? 'CHASECK_TEST-N57AWzONzLogAAdsKEFXavNhB6d4LpIo';
    print('Using Chapa secret key: ${key.substring(0, 15)}...');
    return key;
  }
  
  // Environment detection
  static bool get isTestMode => publicKey.contains('TEST') || secretKey.contains('TEST');
  static bool get isLiveMode => !isTestMode;
  
  // Environment-specific configuration
  static String get environment => isTestMode ? 'sandbox' : 'live';
  
  // Chapa API endpoints
  static const String testBaseUrl = 'https://api.chapa.co/v1';
  static const String liveBaseUrl = 'https://api.chapa.co/v1';
  static String get baseUrl => isTestMode ? testBaseUrl : liveBaseUrl;
  
  static const String initializeEndpoint = '/transaction/initialize';
  static const String verifyEndpoint = '/transaction/verify';
  
  // Payment settings
  static const String currency = 'ETB';
  static const String paymentTitle = 'EthioNetflix Payment';
  static const String paymentDescription = 'Payment for movie streaming';
  
  // Network settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Validation method
  static bool validateKeys() {
    final pub = publicKey;
    final sec = secretKey;
    
    if (pub.isEmpty || sec.isEmpty) {
      print('ERROR: Chapa API keys are empty');
      return false;
    }
    
    if (!pub.startsWith('CHAPUBK_') || !sec.startsWith('CHASECK_')) {
      print('ERROR: Invalid Chapa API key format');
      return false;
    }
    
    print('✅ Chapa API keys validated successfully (${environment} mode)');
    return true;
  }
}