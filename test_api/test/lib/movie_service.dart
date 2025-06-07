import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class MovieService {
  final String baseUrl = "wss://ethionetflix.hopto.org/content";
  WebSocketChannel? _channel;

  void connect({String type = "all", String? query}) {
    String url = '$baseUrl?type=$type';
    if (query != null && type == "search") {
      url += '&q=$query';
    }
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  Stream<List<Movie>> getMoviesStream() {
    return _channel!.stream.map((message) {
      List jsonResponse = json.decode(message);
      return jsonResponse.map((movie) => Movie.fromJson(movie)).toList();
    });
  }

  void sendMessage(String message) {
    if (_channel != null && _channel!.sink != null) {
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}

class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0, // Provide a default or handle null appropriately
      title: json['title'] ?? 'No Title',
      overview: json['overview'] ?? 'No Overview',
      posterPath: json['poster_path'] ?? '',
    );
  }
}
