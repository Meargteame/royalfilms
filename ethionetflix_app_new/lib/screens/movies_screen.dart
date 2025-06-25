import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
import 'package:ethionetflix_app/services/api_service.dart';
import 'package:ethionetflix_app/services/local_storage_service.dart';
import 'dart:async';

class MoviesScreen extends StatefulWidget {
  final LocalStorageService localStorageService;
  final ApiService apiService;

  const MoviesScreen({
    Key? key,
    required this.localStorageService,
    required this.apiService,
  }) : super(key: key);

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  List<dynamic> _trendingMovies = [];
  List<dynamic> _popularMovies = [];
  List<dynamic> _latestMovies = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _moviesSubscription;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _loadMovies();
  }

  @override
  void dispose() {
    _moviesSubscription?.cancel();
    super.dispose();
  }

  void _loadMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<dynamic> receivedItems = [];

    _moviesSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'all',
    )
        .listen(
      (data) {
        if (data is List) {
        setState(() {
            for (var item in data) {
              if (!receivedItems.any((existing) =>
                (existing['movieId'] != null && item['movieId'] != null && existing['movieId'] == item['movieId']) ||
                (existing['id'] != null && item['id'] != null && existing['id'] == item['id']))) {
                receivedItems.add(item);
              }
            }
            _updateMovieLists(receivedItems);
          });
          } else if (data is Map) {
            if (!receivedItems.any((existing) =>
              (existing['movieId'] != null && data['movieId'] != null && existing['movieId'] == data['movieId']) ||
              (existing['id'] != null && data['id'] != null && existing['id'] == data['id']))) {
              receivedItems.add(data);
            setState(() {
              _updateMovieLists(receivedItems);
            });
          }
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Failed to load movies: $error';
          _isLoading = false;
        });
      },
      onDone: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }
  void _updateMovieLists(List<dynamic> items) {
    // Filter for movies only
    final allMovies = items.where((item) {
      final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
      final genre = (item['genre'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      
      // If it has episode number or seriesName, it's a TV series
      if (item['episode'] != null || (item['seriesName'] != null && item['seriesName'].toString().isNotEmpty)) {
        return false;
      }
      
      // If genre contains movie-related terms, include it
      if (genre.any((g) => g.contains('movie') || g.contains('film'))) {
        return true;
      }
      
      // If title contains movie indicators (year in parentheses, etc)
      if (RegExp(r'\(\d{4}\)|\[\d{4}\]|[12][0-9]{3}').hasMatch(title)) {
        return true;
      }
      
      // If title doesn't contain TV series patterns
      if (!RegExp(r'episode|season|\bs\d{1,2}e\d{1,2}\b|s\d{2}|e\d{2}', caseSensitive: false).hasMatch(title)) {
        return true;
      }
      
      return false;
    }).toList();

    // Create a copy for manipulation
    final moviePool = List<Map<String, dynamic>>.from(allMovies);

    // Latest movies: newest by release year (last 2 years)
    moviePool.sort((a, b) {
      final yearA = int.tryParse(a['year']?.toString().split('-').first ?? '') ?? 0;
      final yearB = int.tryParse(b['year']?.toString().split('-').first ?? '') ?? 0;
      return yearB.compareTo(yearA);
    });
    final currentYear = DateTime.now().year;
    _latestMovies = moviePool.where((movie) {
      final year = int.tryParse(movie['year']?.toString().split('-').first ?? '') ?? 0;
      return year >= currentYear - 2;
    }).take(15).toList();

    // Popular movies: highest rated movies
    final popularPool = List<Map<String, dynamic>>.from(moviePool);
    popularPool.sort((a, b) {
      final ratingA = double.tryParse(a['rating']?.toString().split('/').first ?? '0') ?? 0.0;
      final ratingB = double.tryParse(b['rating']?.toString().split('/').first ?? '0') ?? 0.0;
      if (ratingA == ratingB) {
        // If ratings are equal, sort by year (newer first)
        final yearA = int.tryParse(a['year']?.toString().split('-').first ?? '') ?? 0;
        final yearB = int.tryParse(b['year']?.toString().split('-').first ?? '') ?? 0;
        return yearB.compareTo(yearA);
      }
      return ratingB.compareTo(ratingA);
    });
    _popularMovies = popularPool.take(15).toList();

    // Trending movies: mix of recent and highly rated
    final trendingPool = List<Map<String, dynamic>>.from(moviePool);
    trendingPool.sort((a, b) {
      final yearA = int.tryParse(a['year']?.toString().split('-').first ?? '') ?? 0;
      final yearB = int.tryParse(b['year']?.toString().split('-').first ?? '') ?? 0;
      final ratingA = double.tryParse(a['rating']?.toString().split('/').first ?? '0') ?? 0.0;
      final ratingB = double.tryParse(b['rating']?.toString().split('/').first ?? '0') ?? 0.0;
      
      // Calculate a score based on both year and rating
      final scoreA = (yearA - 2000) * 0.3 + ratingA * 0.7;  // Weight rating more than year
      final scoreB = (yearB - 2000) * 0.3 + ratingB * 0.7;
      return scoreB.compareTo(scoreA);
    });
    _trendingMovies = trendingPool.take(15).toList();

    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Movies',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: AppTheme.primaryFontFamily,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search screen
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Error Loading Movies',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMovies,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadMovies();
                  },
                  color: AppTheme.primaryColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (_trendingMovies.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [                              const Text(
                                'Trending Movies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.primaryFontFamily,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement See All navigation or remove this button if not needed
                                },
                        child: Text(
                                  'See All',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _trendingMovies.length,
                          itemBuilder: (context, index) {
                            final movie = _trendingMovies[index];
                            return ContentCard(
                              imageUrl: _getPosterUrl(movie),
                              title: movie['title'] ?? movie['name'] ?? 'Untitled',
                              type: movie['type'] ?? 'Movie',
                              quality: movie['quality'] ?? 'HD',
                              year: movie['year']?.toString() ?? '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      content: movie,
                                      apiService: _apiService,
                                      localStorageService: widget.localStorageService,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                      if (_popularMovies.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [                              const Text(
                                'Popular Movies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.primaryFontFamily,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement See All navigation or remove this button if not needed
                                },
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _popularMovies.length,
                        itemBuilder: (context, index) {
                            final movie = _popularMovies[index];
                          return ContentCard(
                              imageUrl: _getPosterUrl(movie),
                              title: movie['title'] ?? movie['name'] ?? 'Untitled',
                              type: movie['type'] ?? 'Movie',
                            quality: movie['quality'] ?? 'HD',
                              year: movie['year']?.toString() ?? '',
                            onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      content: movie,
                                      apiService: _apiService,
                                      localStorageService: widget.localStorageService,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                      if (_latestMovies.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [                              const Text(
                                'Latest Movies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.primaryFontFamily,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement See All navigation or remove this button if not needed
                                },
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _latestMovies.length,
                          itemBuilder: (context, index) {
                            final movie = _latestMovies[index];
                            return ContentCard(
                              imageUrl: _getPosterUrl(movie),
                              title: movie['title'] ?? movie['name'] ?? 'Untitled',
                              type: movie['type'] ?? 'Movie',
                              quality: movie['quality'] ?? 'HD',
                              year: movie['year']?.toString() ?? '',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      content: movie,
                                      apiService: _apiService,
                                      localStorageService: widget.localStorageService,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  String _getPosterUrl(Map<String, dynamic> movie) {
    final thumb = movie['thumbNail']?.toString() ?? '';
    final poster = movie['poster_url']?.toString() ?? '';
    if (thumb.isNotEmpty && (thumb.startsWith('http') || thumb.startsWith('/thumbnails'))) {
      return thumb.startsWith('http')
          ? thumb
          : 'https://ethionetflix1.hopto.org$thumb';
    }
    if (poster.isNotEmpty && poster.startsWith('http')) {
      return poster;
    }
    return 'assets/images/default_poster.png';
  }
}
