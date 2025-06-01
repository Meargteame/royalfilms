import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class ApiService {
  final String _baseUrl = 'https://ethionetflix.hopto.org';
  WebSocketChannel? _channel;

  Stream<dynamic> connectToContentWebSocket(
      {String? type, String? query, String? collectionId}) {
    String url = '$_baseUrl/content';
    final Map<String, String> params = {};
    if (type != null) {
      params['type'] = type;
    }
    if (query != null) {
      params['q'] = query;
    }
    if (collectionId != null) {
      params['collection'] = collectionId;
    }

    if (params.isNotEmpty) {
      url += '?' +
          Uri.encodeQueryComponent(
              params.entries.map((e) => '\${e.key}=\${e.value}').join('&'));
    }

    _channel = WebSocketChannel.connect(Uri.parse(url));
    print('Attempting to connect to WebSocket: \$url');
    return _channel!.stream.map((event) {
      print('WebSocket received: \$event');
      // Assuming the WebSocket sends JSON strings
      return json.decode(event);
    }).handleError((error) {
      print('WebSocket error: \$error');
      throw Exception('WebSocket error: \$error');
    });
  }

  void disconnectWebSocket() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      print('WebSocket disconnected.');
    }
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
        print(
            'Payment initialization failed: \${response.statusCode} - \${response.body}');
        throw Exception(
            'Failed to initialize payment: \${response.statusCode}');
      }
    } catch (e) {
      print('Error initializing payment: \$e');
      throw Exception('Error initializing payment: \$e');
    }
  }
}
