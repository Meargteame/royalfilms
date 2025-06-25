import 'package:dio/dio.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'dart:io';

/// Modern Download Service using Storage Access Framework
/// Compatible with Android 10+ without requiring storage permissions
class ModernDownloadService {
  static final ModernDownloadService _instance = ModernDownloadService._internal();
  factory ModernDownloadService() => _instance;
  ModernDownloadService._internal();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, double> _downloadProgress = {};

  /// Initialize the download service
  Future<void> initialize() async {
    // Configure Dio
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 30);
    _dio.options.sendTimeout = const Duration(minutes: 5);
    _dio.options.headers = {
      'User-Agent': 'EthioNetflix-Mobile-App/2.0',
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
  }

  /// Download and save file using Storage Access Framework
  /// This method works on Android 10+ without any storage permissions
  Future<bool> downloadAndSaveFile(
    String fileUrl, 
    String fileName, {
    Map<String, String>? headers,
    Function(double)? onProgress,
  }) async {
    CancelToken? cancelToken;
    String? tempPath;
    
    try {
      print('🚀 Starting modern download: $fileName');
      print('📍 URL: $fileUrl');

      // Create cancel token for this download
      cancelToken = CancelToken();
      final downloadId = DateTime.now().millisecondsSinceEpoch.toString();
      _cancelTokens[downloadId] = cancelToken;

      // Get temporary directory (no permissions needed)
      final tempDir = Directory.systemTemp;
      tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);

      print('📁 Temp path: $tempPath');

      // Prepare headers
      final requestHeaders = <String, String>{
        ..._dio.options.headers.cast<String, String>(),
        if (headers != null) ...headers,
      };

      // Download file to temporary location
      await _dio.download(
        fileUrl,
        tempPath,
        cancelToken: cancelToken,
        options: Options(headers: requestHeaders),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[downloadId] = progress;
            
            final percentage = (progress * 100).toInt();
            print('📥 Downloading: $percentage%');
            
            // Call progress callback
            onProgress?.call(progress);
          }
        },
      );

      print('✅ Download completed to temp: ${tempFile.lengthSync()} bytes');

      // Use Storage Access Framework to save file
      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: fileName,
        mimeTypesFilter: [_getMimeType(fileName)],
      );

      final finalPath = await FlutterFileDialog.saveFile(params: params);
      
      if (finalPath != null) {
        print('💾 File saved successfully via SAF: $finalPath');
        
        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
          print('🗑️ Temp file cleaned up');
        }
        
        // Clean up tracking
        _cancelTokens.remove(downloadId);
        _downloadProgress.remove(downloadId);
        
        return true;
      } else {
        print('❌ User cancelled save dialog');
        return false;
      }

    } catch (e) {
      print('💥 Download failed: $e');
      
      // Clean up temp file if it exists
      if (tempPath != null) {
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
          print('🗑️ Temp file cleaned up after error');
        }
      }
      
      rethrow;
    }
  }

  /// Download content from EthioNetflix with proper authentication
  Future<bool> downloadEthioNetflixContent(
    Map<String, dynamic> content, {
    Function(double)? onProgress,
  }) async {
    try {
      print('🎬 Downloading EthioNetflix content...');
      
      // Get content details
      final contentName = content['name'] ?? content['title'] ?? 'video.mp4';
      final fileName = _sanitizeFileName(contentName);
      
      // Build authentication headers
      final headers = _buildAuthHeaders(content);
      
      // Try to get actual download URL from API
      final downloadUrl = await _getDownloadUrlFromApi(content, headers);
      
      if (downloadUrl == null) {
        throw Exception('Could not get download URL from server');
      }
      
      print('🔗 Got download URL: $downloadUrl');
      
      // Download using the modern method
      return await downloadAndSaveFile(
        downloadUrl,
        fileName,
        headers: headers,
        onProgress: onProgress,
      );
      
    } catch (e) {
      print('💥 EthioNetflix download failed: $e');
      rethrow;
    }
  }

  /// Get download URL from EthioNetflix API
  Future<String?> _getDownloadUrlFromApi(Map<String, dynamic> content, Map<String, String> headers) async {
    print('🔗 Getting download URL from API...');
    
    final contentId = content['id'] ?? content['movieId'] ?? content['_id'];
      // API endpoints to try
    final apiEndpoints = [
      if (contentId != null) 'https://ethionetflix1.hopto.org/api/content/$contentId/download-url',
      if (contentId != null) 'https://ethionetflix1.hopto.org/api/movie/$contentId/stream',
      if (contentId != null) 'https://ethionetflix1.hopto.org/api/v1/content/$contentId',
      'https://ethionetflix1.hopto.org/api/content/download-info',
    ];

    final requestData = {
      if (contentId != null) 'id': contentId,
      if (contentId != null) 'movieId': contentId,
      if (content['download_hash'] != null) 'downloadHash': content['download_hash'],
      if (content['stream_hash'] != null) 'streamHash': content['stream_hash'],
      if (content['databaseHash'] != null) 'databaseHash': content['databaseHash'],
      'action': 'getDownloadUrl',
    };

    for (final url in apiEndpoints) {
      try {
        print('🌐 Trying API: $url');
        
        // Try POST request
        final response = await _dio.post(
          url,
          data: requestData,
          options: Options(
            headers: {...headers, 'Content-Type': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        print('📡 API Response: ${response.statusCode}');
        
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          
          // Look for download URL in response
          if (data is Map) {
            final downloadUrl = data['downloadUrl'] ?? 
                              data['download_url'] ?? 
                              data['url'] ?? 
                              data['streamUrl'] ?? 
                              data['stream_url'] ??
                              data['fileUrl'] ??
                              data['file_url'];
            
            if (downloadUrl != null && downloadUrl.toString().isNotEmpty) {
              print('✅ Found download URL: $downloadUrl');
              return downloadUrl.toString();
            }
          }
        }
        
      } catch (e) {
        print('❌ API $url failed: $e');
        continue;
      }
    }
      // Fallback: try direct content streaming
    if (contentId != null) {
      final streamUrl = 'https://ethionetflix1.hopto.org/stream/$contentId';
      print('🔄 Fallback to stream URL: $streamUrl');
      return streamUrl;
    }
    
    return null;
  }

  /// Build authentication headers for EthioNetflix
  Map<String, String> _buildAuthHeaders(Map<String, dynamic> content) {
    final headers = <String, String>{
      'User-Agent': 'EthioNetflix-Mobile-App/2.0',
      'Accept': '*/*',
      'Connection': 'keep-alive',
      'Accept-Encoding': 'gzip, deflate, br',
      'Accept-Language': 'en-US,en;q=0.9',
    };

    // Add decryption keys if available
    final downloadKey = content['download_decryption_key'];
    final streamKey = content['stream_decryption_key'];
    
    if (downloadKey != null) {
      headers['X-Decryption-Key'] = downloadKey;
      headers['Authorization'] = 'Bearer $downloadKey';
    } else if (streamKey != null) {
      headers['X-Decryption-Key'] = streamKey;
      headers['Authorization'] = 'Bearer $streamKey';
    }

    return headers;
  }

  /// Get MIME type for file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'wmv':
        return 'video/x-ms-wmv';
      default:
        return 'video/*';
    }
  }

  /// Sanitize filename for safe saving
  String _sanitizeFileName(String filename) {
    // Ensure it has .mp4 extension if no extension
    if (!filename.contains('.')) {
      filename = '$filename.mp4';
    }
    
    // Remove invalid characters
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get download progress for a specific download
  double getDownloadProgress(String downloadId) {
    return _downloadProgress[downloadId] ?? 0.0;
  }

  /// Cancel a specific download
  Future<void> cancelDownload(String downloadId) async {
    final cancelToken = _cancelTokens[downloadId];
    if (cancelToken != null) {
      cancelToken.cancel('Download cancelled by user');
      _cancelTokens.remove(downloadId);
      _downloadProgress.remove(downloadId);
      print('❌ Download cancelled: $downloadId');
    }
  }

  /// Cancel all downloads
  Future<void> cancelAllDownloads() async {
    for (final token in _cancelTokens.values) {
      token.cancel('All downloads cancelled');
    }
    _cancelTokens.clear();
    _downloadProgress.clear();
    print('❌ All downloads cancelled');
  }

  /// Dispose the service
  void dispose() {
    cancelAllDownloads();
  }
}
