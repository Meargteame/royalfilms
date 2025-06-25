import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:async';
import 'package:dio/dio.dart';
import '../models/content_item.dart';

class ApiService {  final String _baseUrl = 'https://ethionetflix1.hopto.org';
  final String _wsUrl = 'wss://ethionetflix1.hopto.org';
  WebSocketChannel? _channel;
  final StreamController<List<ContentItem>> _contentItemsController = StreamController<List<ContentItem>>.broadcast();
  
  // Getter for the content items stream
  Stream<List<ContentItem>> get contentItemsStream => _contentItemsController.stream;
  Stream<dynamic> connectToContentWebSocket({
    String? type,
    String? query,
    String? collectionId,
    int? limit,
  }) {
    disconnectWebSocket(); // Close any existing connection
    
    String url = '$_wsUrl/content';
    final Map<String, String> params = {};
    
    if (type != null) params['type'] = type;
    if (query != null) params['q'] = query;
    if (collectionId != null) params['collection'] = collectionId;
    if (limit != null) params['limit'] = limit.toString();
    
    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }
    
    print('Connecting to WebSocket: $url');
    _channel = WebSocketChannel.connect(Uri.parse(url));
    
    // Set up the stream transformation
    final stream = _channel!.stream.map((event) {
      print('WebSocket received: $event');
      try {
        final dynamic decodedData = json.decode(event);
        
        // Process the data if it's a List
        if (decodedData is List) {
          final contentItems = decodedData
              .map((item) => ContentItem.fromJson(item))
              .toList();
          _contentItemsController.add(contentItems);
        }
        
        return decodedData;
      } catch (e) {
        print('Error decoding WebSocket data: $e');
        return event; // Return raw data if it's not JSON
      }
    }).handleError((error) {
      print('WebSocket error: $error');
      throw Exception('WebSocket error: $error');
    });
    
    return stream;
  }

  void disconnectWebSocket() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
      print('WebSocket disconnected.');
    }
  }
  
  void dispose() {
    disconnectWebSocket();
    _contentItemsController.close();
  }
  
  // Get video stream URL
  Future<List<dynamic>> fetchContent(String collectionId) async {
    try {
      final url = '$_baseUrl/api/content?collection=$collectionId';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('results')) {
          return data['results'];
        } else if (data is Map) {
          return [data];
        }
      }
      
      throw Exception('Failed to load content: ${response.statusCode}');
    } catch (e) {
      print('Error fetching content: $e');
      throw Exception('Failed to load content: $e');
    }
  }

  String getVideoStreamUrl(String id, String? collection) {
    // Print debug info
    print('Getting video stream URL for ID: $id, Collection: $collection');
    
    if (id.isEmpty) {
      print('Error: Empty content ID provided to getVideoStreamUrl');
      // Return a fallback sample video URL instead of failing
      return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    }
    
    // Handle special case for sample_trailer
    if (id == 'sample_trailer') {
      print('Sample trailer ID detected, returning sample video');
      return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    }
    
    // Build the stream URL
    var url = '$_baseUrl/stream?id=$id';
    if (collection != null && collection.isNotEmpty) {
      url += '&collection=$collection';
    }
    
    // Add quality parameter as a fallback option
    url += '&quality=auto';
    
    print('Created stream URL: $url');
    return url;
  }
  
  // New method to validate stream URL before playback
  Future<Map<String, dynamic>> validateStreamUrl(String url) async {
    print('Validating stream URL: $url');
    try {
      // First try a HEAD request to check if the resource exists
      final dio = Dio();
      final response = await dio.head(
        url,
        options: Options(
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      
      print('Stream validation status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return {'isValid': true, 'url': url, 'message': 'Stream is available'};
      } else if (response.statusCode == 302 || response.statusCode == 301) {
        // Handle redirects - some streaming servers use redirects
        final String redirectUrl = response.headers.map['location']?.first ?? '';
        print('Stream redirected to: $redirectUrl');
        if (redirectUrl.isNotEmpty) {
          return {'isValid': true, 'url': redirectUrl, 'message': 'Stream available via redirect'};
        }
      }
      
      // If the HEAD request doesn't work, try GET with range header for partial content
      final rangeResponse = await dio.get(
        url,
        options: Options(
          headers: {'Range': 'bytes=0-10000'},
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      
      print('Range request status code: ${rangeResponse.statusCode}');
      
      if (rangeResponse.statusCode == 206 || rangeResponse.statusCode == 200) {
        return {'isValid': true, 'url': url, 'message': 'Stream is available via range request'};
      }
      
      // Check for common alternative formats
      final alternativeFormats = [
        '$url&format=hls',     // HLS streaming
        '$url&format=mp4',     // Direct MP4
        '$url&format=dash',    // DASH streaming
        url.replaceAll('/stream?', '/download?'), // Try download endpoint
      ];
      
      for (final altUrl in alternativeFormats) {
        try {
          final altResponse = await dio.head(
            altUrl,
            options: Options(
              validateStatus: (status) => true,
              receiveTimeout: const Duration(seconds: 3),
              sendTimeout: const Duration(seconds: 3),
            ),
          );
          
          if (altResponse.statusCode == 200 || altResponse.statusCode == 206) {
            print('Alternative format available: $altUrl');
            return {'isValid': true, 'url': altUrl, 'message': 'Alternative format available'};
          }
        } catch (e) {
          print('Error checking alternative format $altUrl: $e');
        }
      }
      
      return {
        'isValid': false,
        'url': url,
        'message': 'Stream validation failed with status ${response.statusCode}',
        'fallbackUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
      };
    } catch (e) {
      print('Error validating stream URL: $e');
      return {
        'isValid': false,
        'url': url,
        'message': 'Error validating stream: $e',
        'fallbackUrl': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
      };
    }
  }
  
  // Search content
  Stream<List<ContentItem>> searchContent(String query) {
    return connectToContentWebSocket(type: 'search', query: query).map((data) {
      if (data is List) {
        return data.map((item) => ContentItem.fromJson(item)).toList();
      }
      return <ContentItem>[];
    });
  }
  
  // Get featured content
  Stream<List<ContentItem>> getFeaturedContent() {
    return connectToContentWebSocket(type: 'featured').map((data) {
      if (data is List) {
        return data.map((item) => ContentItem.fromJson(item)).toList();
      }
      return <ContentItem>[];
    });
  }

  Future<Map<String, dynamic>> initializePayment(double amount) async {
    final url = Uri.parse('$_baseUrl/pay');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Payment initialization failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to initialize payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error initializing payment: $e');
      throw Exception('Error initializing payment: $e');
    }
  }
    Future<Map<String, dynamic>> checkPaymentStatus(String txRef) async {
    final url = Uri.parse('$_baseUrl/check/$txRef');
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Payment check failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to check payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking payment: $e');
      throw Exception('Error checking payment: $e');
    }
  }

  // Get streaming URL for video player
  Future<String?> getStreamUrl(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'User-Agent': 'EthioNetflix-Mobile-App/2.0',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map) {
            // Look for various stream URL fields
            return data['streamUrl'] ?? 
                   data['stream_url'] ?? 
                   data['url'] ?? 
                   data['downloadUrl'] ?? 
                   data['download_url'];
          }
        } catch (e) {
          // If response is not JSON, treat as direct URL
          return response.body.trim();
        }
      } else if (response.statusCode == 302 || response.statusCode == 301) {
        // Handle redirects
        return response.headers['location'];
      }
      
      return null;
    } catch (e) {
      print('Error getting stream URL from $endpoint: $e');
      return null;
    }
  }

  // Get series episodes by series ID or series name
  Future<List<ContentItem>> getSeriesEpisodes(String seriesIdentifier, {bool useSeriesId = true}) async {
    try {
      String url;
      if (useSeriesId) {
        url = '$_baseUrl/api/content?series_id=$seriesIdentifier';
      } else {
        url = '$_baseUrl/api/content?series_name=${Uri.encodeComponent(seriesIdentifier)}';
      }
      
      print('Fetching series episodes from: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> episodesList;
        
        if (data is List) {
          episodesList = data;
        } else if (data is Map && data.containsKey('results')) {
          episodesList = data['results'];
        } else if (data is Map && data.containsKey('episodes')) {
          episodesList = data['episodes'];
        } else {
          return [];
        }
        
        // Convert to ContentItem list and sort by episode number
        List<ContentItem> episodes = episodesList
            .map((item) => ContentItem.fromJson(item))
            .toList();
            
        // Sort episodes by episode number, season number, or title
        episodes.sort((a, b) {
          // First try to sort by season number
          if (a.seasonNumber != null && b.seasonNumber != null) {
            int seasonCompare = a.seasonNumber!.compareTo(b.seasonNumber!);
            if (seasonCompare != 0) return seasonCompare;
          }
          
          // Then by episode number
          if (a.episodeNumber != null && b.episodeNumber != null) {
            return a.episodeNumber!.compareTo(b.episodeNumber!);
          }
          
          // Fallback to episode field
          if (a.episode != null && b.episode != null) {
            return a.episode!.compareTo(b.episode!);
          }
          
          // Final fallback to title alphabetical order
          return (a.title ?? '').compareTo(b.title ?? '');
        });
        
        print('Found ${episodes.length} episodes for series: $seriesIdentifier');
        return episodes;
      }
      
      throw Exception('Failed to load series episodes: ${response.statusCode}');
    } catch (e) {
      print('Error fetching series episodes: $e');
      return [];
    }
  }
}
