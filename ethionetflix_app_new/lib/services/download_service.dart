import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DownloadService {
  final Dio _dio = Dio();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

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
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    
    if (deviceInfo.version.sdkInt <= 29) {
      // For Android 10 and below
      final status = await Permission.storage.request();
      return status.isGranted;
    } else {
      // For Android 11 and above
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
  }

  Future<String?> _getDownloadPath() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      final downloadPath = '${directory.path}/EthioNetflix/Downloads';
      await Directory(downloadPath).create(recursive: true);
      return downloadPath;
    }
    return null;
  }

  Future<Map<String, dynamic>> downloadContent(Map<String, dynamic> content) async {
    try {
      await initialize();
      
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      final downloadPath = await _getDownloadPath();
      if (downloadPath == null) {
        throw Exception('Could not get download path');
      }

      final String url = content['downloadUrl'] ?? content['streamUrl'] ?? '';
      if (url.isEmpty) {
        throw Exception('No valid download URL found');
      }

      final String fileName = '${content['title'] ?? 'video'}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String filePath = '$downloadPath/$fileName';

      // Show download started notification
      await _showNotification(
        'Download Started',
        'Downloading ${content['title']}',
        progress: 0,
      );

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) async {
          if (total != -1) {
            final progress = (received / total * 100).toInt();
            // Update notification with progress
            await _showNotification(
              'Downloading',
              'Downloading ${content['title']}',
              progress: progress,
            );
          }
        },
      );

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
      // Show error notification
      await _showNotification(
        'Download Failed',
        'Failed to download ${content['title']}: $e',
      );
      rethrow;
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
      channelDescription: 'Download progress notifications',
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