// lib/services/local_storage_service.dart
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/content_item.dart';

class LocalStorageService {
  final String _downloadsFolderName = 'ethionetflix_downloads';
  
  // Check if a movie is already downloaded
  Future<bool> isContentDownloaded(String contentId) async {
    try {
      final file = await _getFileForContent(contentId);
      return await file.exists();
    } catch (e) {
      print('Error checking if content is downloaded: $e');
      return false;
    }
  }
  
  // Get the path for a downloaded content item
  Future<String?> getDownloadedContentPath(String contentId) async {
    try {
      final file = await _getFileForContent(contentId);
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      print('Error getting downloaded content path: $e');
      return null;
    }
  }
  
  // Download content from URL
  Future<String?> downloadContent(ContentItem content, String url) async {
    if (content.id == null) {
      throw Exception('Content ID is required for downloading');
    }
    
    // First check if we have storage permissions
    final permissionStatus = await _requestStoragePermission();
    if (!permissionStatus) {
      throw Exception('Storage permission denied');
    }
    
    try {
      final file = await _getFileForContent(content.id!);
      
      // Create directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Download the file with progress tracking
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception(
            'Failed to download content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading content: $e');
      rethrow;
    }
  }
  
  // Delete a downloaded content
  Future<bool> deleteDownloadedContent(String contentId) async {
    try {
      final file = await _getFileForContent(contentId);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting downloaded content: $e');
      return false;
    }
  }
  
  // Get list of all downloaded contents
  Future<List<String>> getAllDownloadedContentIds() async {
    try {
      final directory = await _getDownloadsDirectory();
      if (!await directory.exists()) {
        return [];
      }
      
      final List<String> contentIds = [];
      final entities = await directory.list().toList();
      
      for (var entity in entities) {
        if (entity is File) {
          final filename = entity.path.split('/').last;
          if (filename.endsWith('.mp4')) {
            contentIds.add(filename.replaceAll('.mp4', ''));
          }
        }
      }
      
      return contentIds;
    } catch (e) {
      print('Error getting all downloaded content: $e');
      return [];
    }
  }
  
  // Get a file reference for a specific content
  Future<File> _getFileForContent(String contentId) async {
    if (kIsWeb) {
      throw UnsupportedError('File operations are not supported on web');
    }
    
    final directory = await _getDownloadsDirectory();
    return File('${directory.path}/$contentId.mp4');
  }
  
  // Get the downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Directory operations are not supported on web');
    }
    
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory('${appDocDir.path}/$_downloadsFolderName');
  }
  
  // Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) {
      print('Storage permissions not applicable in web environment');
      return false;
    }
    
    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }
    
    final result = await Permission.storage.request();
    return result.isGranted;
  }
  
  // Get available storage space
  Future<double> getAvailableStorageSpace() async {
    try {
      // This is a simplification - properly calculating free space requires platform-specific code
      // In a real implementation, we would use platform-specific methods to get actual free space
      final appDocDir = await getApplicationDocumentsDirectory();
      // Return a placeholder value of 1GB
      return 1000000000;
    } catch (e) {
      print('Error getting storage space: $e');
      return 0;
    }
  }
  
  // Get all downloaded videos as content items
  Future<List<dynamic>> getDownloadedVideos() async {
    try {
      final contentIds = await getAllDownloadedContentIds();
      
      // For each downloaded content ID, create a content item
      // In a real implementation, we would store metadata with the downloaded files
      // or have a local database that keeps track of downloaded content details
      List<dynamic> downloadedItems = [];
      
      for (final contentId in contentIds) {
        final path = await getDownloadedContentPath(contentId);
        if (path != null) {
          downloadedItems.add({
            'id': contentId,
            'title': 'Downloaded Item - $contentId',
            'poster_url': 'https://via.placeholder.com/300x450?text=Downloaded',
            'quality': 'HD',
            'offline_path': path,
            'is_downloaded': true,
          });
        }
      }
      
      return downloadedItems;
    } catch (e) {
      print('Error getting downloaded videos: $e');
      return [];
    }
  }
}
