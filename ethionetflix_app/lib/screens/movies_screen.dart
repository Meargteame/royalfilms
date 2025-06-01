import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
import 'filter_screen.dart';
import '../services/api_service.dart';
import 'dart:async';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _movies = [];
  bool _isLoading = true;
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

  void _loadMovies() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _moviesSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'movies',
    )
        .listen(
      (data) {
        setState(() {
          _isLoading = false;
          if (data is List) {
            _movies = data;
          } else if (data is Map &&
              data.containsKey('results') &&
              data['results'] is List) {
            _movies = data['results'];
          } else if (data is Map) {
            _movies = [data];
          } else {
            _movies = [];
            _errorMessage = 'Unexpected data format for movies.';
          }
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load movies: $error';
          _movies = [];
        });
        print('Movies WebSocket error: $error');
      },
      onDone: () {
        print('Movies WebSocket disconnected.');
      },
    );
  }

  void _openFilterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Movies',
          style: TextStyle(
            color: AppTheme.textColorPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality (or navigate to SearchScreen)
              print('Search tapped from MoviesScreen');
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterScreen,
          ),
        ],
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _movies.length,
                        itemBuilder: (context, index) {
                          final movie = _movies[index];
                          return ContentCard(
                            imageUrl: movie['poster_url'] ??
                                'https://via.placeholder.com/300x450',
                            title: movie['title'] ?? 'No Title',
                            quality: movie['quality'] ?? 'HD',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailScreen(content: movie),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
