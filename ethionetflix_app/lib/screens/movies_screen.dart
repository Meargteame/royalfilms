import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
import '../screens/popular_content_screen.dart';
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
      final type = item['type']?.toString().toLowerCase() ?? '';
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
                            children: [
                              const Text(
                                'Trending Movies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PopularContentScreen(
                                        title: 'Trending Movies',
                                        contentList: _trendingMovies,
                                        apiService: _apiService,
                                        localStorageService: widget.localStorageService,
                                      ),
                                    ),
                                  );
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
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _trendingMovies.length,
                          itemBuilder: (context, index) {
                            final movie = _trendingMovies[index];
                            return ContentCard(
                              imageUrl: movie['thumbNail'] ?? '',
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
                            children: [
                              const Text(
                                'Popular Movies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PopularContentScreen(
                                        title: 'Popular Movies',
                                        contentList: _popularMovies,
                                        apiService: _apiService,
                                        localStorageService: widget.localStorageService,
                                      ),
                                    ),
                                  );
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
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _popularMovies.length,
                        itemBuilder: (context, index) {
                            final movie = _popularMovies[index];
                          return ContentCard(
                              imageUrl: movie['thumbNail'] ?? '',
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
                            children: [
                              const Text(
                                'Latest Movies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                context,
                                    MaterialPageRoute(
                                      builder: (context) => PopularContentScreen(
                                        title: 'Latest Movies',
                                        contentList: _latestMovies,
                                        apiService: _apiService,
                                        localStorageService: widget.localStorageService,
                                      ),
                                    ),
                                  );
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
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _latestMovies.length,
                          itemBuilder: (context, index) {
                            final movie = _latestMovies[index];
                            return ContentCard(
                              imageUrl: movie['thumbNail'] ?? '',
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

  Widget _buildFeaturedContent(dynamic featuredItem) {
    return Stack(
      children: [
        // Background image
        Container(
          height: 450,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                featuredItem['thumbNail'] != null && featuredItem['thumbNail'].toString().isNotEmpty
                    ? featuredItem['thumbNail'].toString().startsWith('http')
                        ? featuredItem['thumbNail'].toString()
                        : featuredItem['thumbNail'].toString().startsWith('/thumbnails')
                            ? 'https://ethionetflix.hopto.org${featuredItem['thumbNail']}'
                            : featuredItem['thumbNail'].toString()
                    : featuredItem['poster_url'] != null && featuredItem['poster_url'].toString().isNotEmpty
                        ? featuredItem['poster_url'].toString()
                        : 'https://via.placeholder.com/800x450',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Gradient overlay
        Container(
          height: 450,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.9),
              ],
              stops: const [0.4, 0.75, 1.0],
            ),
          ),
        ),
        
        // Content details
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                featuredItem['name'] ?? featuredItem['title'] ?? 'Featured Movie',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (featuredItem['quality'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                        child: Text(
                        featuredItem['quality'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (featuredItem['year'] != null)
                    Text(
                      featuredItem['year'].toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            content: featuredItem,
                            apiService: _apiService,
                            localStorageService: widget.localStorageService,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('Watch Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Add to watchlist functionality
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('My List'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(String title, List<dynamic> contentList) {
    if (contentList.isEmpty) {
      return Container(); // Don't show section if no content
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textColorPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PopularContentScreen(
                        title: title,
                        contentList: contentList,
                        apiService: _apiService,
                        localStorageService: widget.localStorageService,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220, // Height for the horizontal list of content cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: contentList.length,
            itemBuilder: (context, index) {
              final content = contentList[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ContentCard(
                  imageUrl: content['thumbNail'] != null && content['thumbNail'].toString().isNotEmpty
                      ? content['thumbNail'].toString().startsWith('http')
                          ? content['thumbNail'].toString()
                          : content['thumbNail'].toString().startsWith('/thumbnails')
                              ? 'https://ethionetflix.hopto.org${content['thumbNail']}'
                              : content['thumbNail'].toString()
                      : content['poster_url'] != null && content['poster_url'].toString().isNotEmpty
                          ? content['poster_url'].toString()
                          : 'https://via.placeholder.com/300x450',
                  title: content['name'] ?? content['title'] ?? 'No Title',
                  type: content['type'],
                  year: content['year'],
                  quality: content['quality'] ?? 'HD',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          content: content,
                          apiService: _apiService,
                          localStorageService: widget.localStorageService,
                        ),
                      ),
                    );
                  },
                ),
                          );
                        },
                      ),
      ),
        const SizedBox(height: 20),
      ],
    );
  }
}
