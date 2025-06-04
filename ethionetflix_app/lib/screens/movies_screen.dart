import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:ethionetflix_app/services/api_service.dart';
import 'package:ethionetflix_app/services/local_storage_service.dart';
import 'package:ethionetflix_app/widgets/content_card.dart';
import 'dart:async';

class MoviesScreen extends StatefulWidget {
  final LocalStorageService localStorageService;

  const MoviesScreen({Key? key, required this.localStorageService}) : super(key: key);

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _movies = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _moviesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _moviesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    final completer = Completer<void>();
    var firstDataReceived = false;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _movies = [];
    });
    List<dynamic> receivedItems = [];
    _moviesSubscription?.cancel();
    _moviesSubscription = _apiService.connectToContentWebSocket(type: 'collection', collectionId: 'all').listen(
      (data) {
        if (!mounted) return;
        setState(() {
          if (data is List) {
            for (var item in data) {
              if (!receivedItems.any((existing) =>
                (existing['movieId'] != null && item['movieId'] != null && existing['movieId'] == item['movieId']) ||
                (existing['id'] != null && item['id'] != null && existing['id'] == item['id']))) {
                receivedItems.add(item);
              }
            }
          } else if (data is Map) {
            if (!receivedItems.any((existing) =>
              (existing['movieId'] != null && data['movieId'] != null && existing['movieId'] == data['movieId']) ||
              (existing['id'] != null && data['id'] != null && existing['id'] == data['id']))) {
              receivedItems.add(data);
            }
          }

          print('Total items before filtering: ${receivedItems.length}');
          _movies = receivedItems.where((item) {
            final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
            final type = item['type']?.toString().toLowerCase() ?? '';
            final category = item['category']?.toString().toLowerCase() ?? '';
            final contentType = item['contentType']?.toString().toLowerCase() ?? '';
            
            // Immediately exclude if it has series/episode indicators
            if (item['episode'] != null || item['seriesName'] != null) {
              print('Excluding due to episode/series: ${item['title'] ?? item['name']}');
              return false;
            }

            // Check for TV series patterns in title
            if (title.contains('episode') || title.contains('season') || 
                title.contains('s0') || title.contains('e0') || 
                title.contains('x0') || title.contains(' 1 ')) {
              print('Excluding due to title pattern: $title');
              return false;
            }

            // Check for explicit movie indicators
            if (type.contains('movie') || type.contains('film') || 
                category.contains('movie') || category.contains('film') || 
                contentType.contains('movie') || contentType.contains('film')) {
              print('Including due to movie type: ${item['title'] ?? item['name']}');
              return true;
            }

            // For items with type 'all', use additional checks
            if (type == 'all') {
              // Check if the title looks like a movie (has year but no episode/season)
              final hasYear = RegExp(r'\b20[0-2][0-9]\b').hasMatch(title);
              if (hasYear && !title.contains('season') && !title.contains('episode')) {
                print('Including due to year pattern: ${item['title'] ?? item['name']}');
                return true;
              }
            }
            
            return false;
          }).toList();
          print('Total movies after filtering: ${_movies.length}');

          _movies.sort((a, b) {
            final dateA = a['releaseDate'] ?? '';
            final dateB = b['releaseDate'] ?? '';
            return dateB.compareTo(dateA);
          });

          _isLoading = false;
          if (!firstDataReceived) {
            firstDataReceived = true;
            completer.complete();
          }
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Failed to load content: $error';
          _isLoading = false;
        });
        print('WebSocket error: $error');
      },
      onDone: () {
        setState(() {
          _isLoading = false;
        });
        print('WebSocket disconnected.');
      },
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Movies',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMovies,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMovies,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: _loadMovies,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _movies.isEmpty
                    ? const Center(
                        child: Text(
                          'No movies available',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: _movies.length,
                        itemBuilder: (context, index) {
                          final movie = _movies[index];
                          return ContentCard(
                            title: movie['title'] ?? movie['name'] ?? '',
                            imageUrl: movie['thumbNail'],
                            quality: movie['quality'] ?? 'HD',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/detail',
                                arguments: {
                                  'content': movie,
                                  'apiService': _apiService,
                                  'localStorageService': widget.localStorageService,
                                },
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
