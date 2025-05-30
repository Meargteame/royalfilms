// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';

// Base URL for the API
const String _baseUrl = 'https://ethionetflix.hopto.org';

// WebSocket URL for content
const String _webSocketContentUrl = 'wss://ethionetflix.hopto.org/content';

class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  WebSocketChannel? _channel;
  final _contentStreamController = BehaviorSubject<List<dynamic>>();

  /// A stream of content results from the WebSocket.
  Stream<List<dynamic>> get contentStream => _contentStreamController.stream;

  /// Establishes and maintains the WebSocket connection for content.
  void connectToContentWebSocket() {
    // If a channel already exists and is active, do nothing.
    if (_channel != null && _channel!.closeCode == null) {
      print('WebSocket already connected.');
      return;
    }

    print('Attempting to connect to WebSocket...');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketContentUrl));

      _channel!.stream.listen(
        (data) {
          // Decode the incoming JSON string
          final decodedData = json.decode(data);
          // Ensure the decoded data is a list before adding to the stream
          if (decodedData is List) {
            _contentStreamController.add(decodedData);
          } else if (decodedData is Map &&
              decodedData.containsKey('results') &&
              decodedData['results'] is List) {
            // Sometimes the response might be an object containing a 'results' list
            _contentStreamController.add(decodedData['results']);
          } else {
            print('Unexpected data format from WebSocket: $decodedData');
            _contentStreamController.add(
              [],
            ); // Add an empty list or handle error appropriately
          }
          print('Received data from WebSocket: $decodedData');
        },
        onError: (error) {
          print('WebSocket error: $error');
          _contentStreamController.addError(error);
          _disposeChannel(); // Dispose channel on error
          // Implement a reconnect logic here, perhaps with a delay
          Future.delayed(
            const Duration(seconds: 5),
            () => connectToContentWebSocket(),
          );
        },
        onDone: () {
          print('WebSocket disconnected. Attempting to reconnect...');
          _disposeChannel(); // Dispose channel when done
          if (!_contentStreamController.isClosed) {
            _contentStreamController.addError('WebSocket disconnected');
          }
          // Reconnect automatically when done
          Future.delayed(
            const Duration(seconds: 5),
            () => connectToContentWebSocket(),
          );
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      if (!_contentStreamController.isClosed) {
        _contentStreamController.addError('Failed to connect to WebSocket: $e');
      }
      _disposeChannel(); // Ensure channel is disposed if connection fails initially
    }
  }

  /// Sends a query to the WebSocket for content.
  /// Parameters:
  /// - type: 'search', 'collection', 'series', 'all'
  /// - q: Search keyword (for type='search')
  /// - collection: collectionId (for type='collection')
  /// - limit: Limit number of results (default: 100)
  void queryContent({
    required String type,
    String? q,
    String? collection,
    int limit = 100,
  }) {
    if (_channel == null || _channel!.closeCode != null) {
      print(
        'WebSocket is not connected. Attempting to reconnect before sending query...',
      );
      connectToContentWebSocket();
      // Wait a bit for connection before sending, or handle with a state
      Future.delayed(const Duration(seconds: 1), () {
        _sendContentQuery(
          type: type,
          q: q,
          collection: collection,
          limit: limit,
        );
      });
    } else {
      _sendContentQuery(type: type, q: q, collection: collection, limit: limit);
    }
  }

  void _sendContentQuery({
    required String type,
    String? q,
    String? collection,
    int limit = 100,
  }) {
    final Map<String, String> finalQueryParams = {
      'type': type,
      'limit': limit.toString(), // Convert int to String here
    };
    if (q != null) finalQueryParams['q'] = q;
    if (collection != null) finalQueryParams['collection'] = collection;

    // Use Uri.parse for the base and then replace queryParameters to ensure proper encoding.
    final uriWithQueryParams = Uri.parse(
      _webSocketContentUrl,
    ).replace(queryParameters: finalQueryParams);
    final queryString =
        uriWithQueryParams.query; // This will be the actual query string part

    _channel?.sink.add(queryString); // Send the query string
    print('Sent WebSocket query: $queryString');
  }

  /// Disposes the WebSocket channel.
  void _disposeChannel() {
    _channel?.sink.close();
    _channel = null;
  }

  /// Closes the content stream and WebSocket connection.
  void dispose() {
    _contentStreamController.close();
    _disposeChannel();
  }

  // --- HTTP API Calls ---

  /// Initializes a payment.
  /// Returns the response body as a Map if successful, or throws an exception.
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
        throw Exception(
          'Failed to initialize payment: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error initializing payment: $e');
    }
  }

  /// Checks the status of a payment.
  /// Returns the response body as a Map if successful, or throws an exception.
  Future<Map<String, dynamic>> checkPaymentStatus(String txRef) async {
    final url = Uri.parse('$_baseUrl/check/$txRef');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to check payment status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }

  /// Fetches the stream URL for a movie or collection.
  /// Note: The API returns the stream directly, so we might need a video player
  /// that can handle direct streaming or a URL to pass to it.
  /// This method returns the raw response, assuming the video player will handle it.
  /// For a real app, this might return a stream URL, not the content itself.
  Future<String> getStreamUrl({int? id, String? collection}) async {
    final Map<String, dynamic> queryParams = {};
    if (id != null) queryParams['id'] = id.toString();
    if (collection != null) queryParams['collection'] = collection;

    if (id == null && collection == null) {
      throw ArgumentError(
        'Either "id" or "collection" must be provided for streaming.',
      );
    }

    final uri = Uri.parse('$_baseUrl/stream').replace(
      queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
    );
    // The API documentation curl example uses --output movie.mp4, which suggests
    // it's a direct stream. For Flutter, we'd usually just get the URL.
    // If the API returns the URL directly, we'd return that.
    // If it requires a direct HTTP GET to stream, we'd provide that URL
    // to a video player. For now, we'll return the constructed URI string.
    // A robust implementation would involve handling video player specific requirements.
    return uri.toString();
  }
}
