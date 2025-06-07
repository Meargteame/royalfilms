class WebStorageFallback {
  // This class provides web-safe fallbacks for storage operations
  // We need to add this to avoid making major changes to every method in LocalStorageService
  
  static Future<bool> isAvailable() async {
    return kIsWeb ? false : true;
  }
  
  static void warnOnWeb(String operation) {
    if (kIsWeb) {
      print('Warning: $operation is not available in web environments');
    }
  }
}
