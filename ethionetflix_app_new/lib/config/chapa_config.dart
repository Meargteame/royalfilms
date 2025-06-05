class ChapaConfig {
  // TODO: Replace these with your actual Chapa API keys
  static const String publicKey = 'CHAPUBK_TEST-7T1WmPB1ay0XTyn0fsYFcx5RWkFwB8QI';
  static const String secretKey = 'CHASECK_TEST-N57AWzONzLogAAdsKEFXavNhB6d4LpIo';
  
  // Chapa API endpoints
  static const String baseUrl = 'https://api.chapa.co/v1';
  static const String initializeEndpoint = '/transaction/initialize';
  static const String verifyEndpoint = '/transaction/verify';
  
  // Customization
  static const String currency = 'ETB';
  static const String paymentTitle = 'EthioNetflix Payment';
  static const String paymentDescription = 'Payment for movie streaming';
} 