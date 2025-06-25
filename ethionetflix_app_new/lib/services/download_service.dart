import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class DownloadService {
  final Dio _dio = Dio();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Download progress tracking
  final Map<String, double> _downloadProgress = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, bool> _isPaused = {};
  
  // Stream for progress updates
  Stream<Map<String, double>> get downloadProgressStream async* {
    while (true) {
      yield Map.from(_downloadProgress);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!Platform.isAndroid) {
      throw UnsupportedError('Downloads are currently only supported on Android devices');
    }

    // Initialize notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);

    _isInitialized = true;
  }  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) {
      return true; // No permissions needed for other platforms
    }

    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      print('Android SDK version: ${deviceInfo.version.sdkInt}');
      
      if (deviceInfo.version.sdkInt <= 29) {
        // For Android 10 and below - request storage permission
        var status = await Permission.storage.status;
        print('Storage permission status: $status');
        
        if (status.isDenied) {
          status = await Permission.storage.request();
          print('Storage permission after request: $status');
        }
        
        if (status.isPermanentlyDenied) {
          print('Storage permission permanently denied. Using app-specific directory instead.');
          return true; // We'll use app-specific directory as fallback
        }
        
        return status.isGranted;
      } else {
        // For Android 11 and above - use app-specific directory (no special permissions needed)
        print('Android 11+: Using app-specific directory (no permissions required)');
        return true;
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      return true; // Fallback to app-specific directory
    }
  }

  Future<String?> _getDownloadPath() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      
      if (deviceInfo.version.sdkInt <= 29) {
        // For Android 10 and below - use external storage
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadPath = '${directory.path}/EthioNetflix/Downloads';
          await Directory(downloadPath).create(recursive: true);
          return downloadPath;
        }
      } else {
        // For Android 11 and above - use app-specific directory
        final directory = await getApplicationDocumentsDirectory();
        final downloadPath = '${directory.path}/Downloads';
        await Directory(downloadPath).create(recursive: true);
        return downloadPath;
      }
    } catch (e) {
      print('Error getting download path: $e');
      // Fallback to app documents directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        final downloadPath = '${directory.path}/Downloads';
        await Directory(downloadPath).create(recursive: true);
        return downloadPath;
      } catch (fallbackError) {
        print('Fallback download path also failed: $fallbackError');
        return null;
      }    }
    return null;
  }  Future<bool> validateUrl(String url) async {
    try {
      // Try with authentication headers first
      final response = await _dio.head(
        url,
        options: Options(
          headers: {
            'User-Agent': 'EthioNetflix-Mobile-App/1.0',
            'Accept': '*/*',
            'Connection': 'keep-alive',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      print('URL validation for $url: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('URL validation failed for $url: $e');
      return false;
    }
  }
  Future<bool> validateUrlWithAuth(String url, Map<String, dynamic> content) async {
    try {
      // Prepare authentication headers
      final Map<String, String> headers = {
        'User-Agent': 'EthioNetflix-Mobile-App/1.0',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };
      
      // Add decryption key if available
      final downloadDecryptionKey = content['download_decryption_key'];
      final streamDecryptionKey = content['stream_decryption_key'];
      
      if (downloadDecryptionKey != null) {
        headers['X-Decryption-Key'] = downloadDecryptionKey;
        headers['Authorization'] = 'Bearer $downloadDecryptionKey';
        print('Using download decryption key: $downloadDecryptionKey');
      } else if (streamDecryptionKey != null) {
        headers['X-Decryption-Key'] = streamDecryptionKey;
        headers['Authorization'] = 'Bearer $streamDecryptionKey';
        print('Using stream decryption key: $streamDecryptionKey');
      } else {
        print('No decryption keys found in content');
      }
      
      print('Validating URL with auth headers: $url');
      print('Headers: $headers');
      
      final response = await _dio.head(
        url,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      print('URL validation with auth for $url: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('URL validation with auth failed for $url: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> downloadContent(Map<String, dynamic> content) async {
    try {
      print('Starting download process...');
      await initialize();
      
      print('Requesting permissions...');
      final hasPermission = await _requestPermissions();
      print('Permission result: $hasPermission');
      
      if (!hasPermission) {
        print('Permission denied, but continuing with app-specific directory...');
      }

      print('Getting download path...');
      final downloadPath = await _getDownloadPath();
      print('Download path: $downloadPath');
      
      if (downloadPath == null) {
        throw Exception('Could not get download path');
      }

      final String url = content['downloadUrl'] ?? content['streamUrl'] ?? '';
      print('Download URL: $url');
      
      if (url.isEmpty) {
        throw Exception('No valid download URL found');
      }

      final String contentId = content['id'] ?? content['movieId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${content['title'] ?? 'video'}_$contentId.mp4';
      final String filePath = '$downloadPath/$fileName';
      final String metadataPath = '$downloadPath/${fileName}.metadata';

      // Create cancel token for this download
      final cancelToken = CancelToken();
      _cancelTokens[contentId] = cancelToken;
      _isPaused[contentId] = false;

      // Save metadata
      await _saveMetadata(metadataPath, content);

      // Show download started notification
      await _showNotification(
        'Download Started',
        'Downloading ${content['title']}',
        progress: 0,
      );      // Prepare authentication headers
      final Map<String, String> headers = {
        'User-Agent': 'EthioNetflix-Mobile-App/1.0',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };
      
      // Add decryption key if available
      final downloadDecryptionKey = content['download_decryption_key'];
      final streamDecryptionKey = content['stream_decryption_key'];
      
      if (downloadDecryptionKey != null) {
        headers['X-Decryption-Key'] = downloadDecryptionKey;
        headers['Authorization'] = 'Bearer $downloadDecryptionKey';
      } else if (streamDecryptionKey != null) {
        headers['X-Decryption-Key'] = streamDecryptionKey;
        headers['Authorization'] = 'Bearer $streamDecryptionKey';
      }
      
      print('Download headers: $headers');

      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) async {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[contentId] = progress;
            
            final progressPercent = (progress * 100).toInt();
            // Update notification with progress
            await _showNotification(
              'Downloading',
              'Downloading ${content['title']} - $progressPercent%',
              progress: progressPercent,
            );
          }
        },
        options: Options(
          headers: headers,
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 5),
        ),
      );

      // Clean up tracking
      _downloadProgress.remove(contentId);
      _cancelTokens.remove(contentId);
      _isPaused.remove(contentId);

      // Show download complete notification
      await _showNotification(
        'Download Complete',
        '${content['title']} has been downloaded',
        progress: 100,
      );

      return {
        ...content,
        'localPath': filePath,
        'downloadDate': DateTime.now().toIso8601String(),
        'size': await File(filePath).length(),
      };
    } catch (e) {
      final contentId = content['id'] ?? content['movieId'] ?? 'unknown';
      
      // Clean up on error
      _downloadProgress.remove(contentId);
      _cancelTokens.remove(contentId);
      _isPaused.remove(contentId);
      
      // Show error notification
      await _showNotification(
        'Download Failed',
        'Failed to download ${content['title']}: ${e.toString()}',
      );
      rethrow;
    }
  }

  // New methods for enhanced functionality
  Future<void> cancelDownload(String contentId) async {
    final cancelToken = _cancelTokens[contentId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
    }
    _downloadProgress.remove(contentId);
    _cancelTokens.remove(contentId);
    _isPaused.remove(contentId);
  }

  Future<void> pauseDownload(String contentId) async {
    _isPaused[contentId] = true;
    final cancelToken = _cancelTokens[contentId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download paused');
    }
  }

  bool isDownloading(String contentId) {
    return _cancelTokens.containsKey(contentId) && !_isPaused[contentId]!;
  }

  double getDownloadProgress(String contentId) {
    return _downloadProgress[contentId] ?? 0.0;
  }

  Future<void> _saveMetadata(String metadataPath, Map<String, dynamic> content) async {
    final metadata = {
      'title': content['title'],
      'description': content['description'],
      'posterUrl': content['posterUrl'] ?? content['thumbNail'],
      'downloadDate': DateTime.now().toIso8601String(),
      'originalContent': content,
    };
    
    final file = File(metadataPath);
    await file.writeAsString(json.encode(metadata));
  }

  Future<String?> getDownloadedContentPath(String contentId) async {
    try {
      final downloadPath = await _getDownloadPath();
      if (downloadPath == null) return null;

      final directory = Directory(downloadPath);
      if (!await directory.exists()) return null;

      await for (final file in directory.list()) {
        if (file is File && file.path.contains(contentId) && file.path.endsWith('.mp4')) {
          return file.path;
        }
      }
      return null;
    } catch (e) {
      print('Error getting downloaded content path: $e');
      return null;
    }
  }

  Future<void> _showNotification(
    String title,
    String body, {
    int? progress,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Download progress notifications', // Changed back to named argument
      importance: Importance.low,
      priority: Priority.low,
      showProgress: progress != null,
      maxProgress: 100,
      progress: progress ?? 0,
    );

    await _notifications.show(
      0,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<List<Map<String, dynamic>>> getDownloadedContent() async {
    try {
      final downloadPath = await _getDownloadPath();
      if (downloadPath == null) return [];

      final directory = Directory(downloadPath);
      if (!await directory.exists()) return [];

      final List<Map<String, dynamic>> downloadedContent = [];
      
      await for (final file in directory.list()) {
        if (file is File && file.path.endsWith('.mp4')) {
          final fileName = file.path.split('/').last;
          final stats = await file.stat();
          
          downloadedContent.add({
            'title': fileName.split('_').first,
            'localPath': file.path,
            'downloadDate': stats.modified.toIso8601String(),
            'size': stats.size,
          });
        }
      }

      return downloadedContent;
    } catch (e) {
      print('Error getting downloaded content: $e');
      return [];
    }
  }

  Future<void> deleteDownload(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting download: $e');
      rethrow;
    }
  }
}