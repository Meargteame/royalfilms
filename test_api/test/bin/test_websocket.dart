import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  final uri = Uri.parse('wss://ethionetflix.hopto.org/content?type=all');

  try {
    final channel = WebSocketChannel.connect(uri);

    print('Attempting to connect to WebSocket: $uri');

    await channel.ready;
    print('WebSocket connection established.');

    channel.stream.listen(
      (message) {
        print('Received: $message');
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed.');
      },
    );

    // Keep the script running to listen for messages
    // You can send a message here if needed, e.g., channel.sink.add('{"action": "getMovies"}');
    // To stop, you'll typically interrupt the process (Ctrl+C)
  } catch (e) {
    print('Failed to connect to WebSocket: $e');
  }
}
