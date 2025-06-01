import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/logo.dart';
import '../screens/detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_screen.dart';
import '../screens/filter_screen.dart';
import '../screens/popular_content_screen.dart';
import 'package:ethionetflix_app/services/api_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _trendingContent = [];
  List<dynamic> _popularContent = [];
  List<dynamic> _latestContent = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _trendingSubscription;
  StreamSubscription? _popularSubscription;
  StreamSubscription? _latestSubscription;

  @override
  void initState() {
    super.initState();
    _loadAllContent();
  }

  @override
  void dispose() {
    _trendingSubscription?.cancel();
    _popularSubscription?.cancel();
    _latestSubscription?.cancel();
    super.dispose();
  }

  void _loadAllContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _trendingSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'trending',
    )
        .listen(
      (data) {
        setState(() {
          if (data is List) {
            _trendingContent = data;
          } else if (data is Map &&
              data.containsKey('results') &&
              data['results'] is List) {
            _trendingContent = data['results'];
          } else if (data is Map) {
            _trendingContent = [data];
          } else {
            _trendingContent = [];
            _errorMessage = 'Unexpected data format for trending content.';
          }
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Failed to load trending content: $error';
          _trendingContent = [];
        });
        print('Trending content WebSocket error: $error');
      },
      onDone: () {
        print('Trending content WebSocket disconnected.');
      },
    );

    _popularSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'popular',
    )
        .listen(
      (data) {
        setState(() {
          if (data is List) {
            _popularContent = data;
          } else if (data is Map &&
              data.containsKey('results') &&
              data['results'] is List) {
            _popularContent = data['results'];
          } else if (data is Map) {
            _popularContent = [data];
          } else {
            _popularContent = [];
            _errorMessage = 'Unexpected data format for popular content.';
          }
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Failed to load popular content: $error';
          _popularContent = [];
        });
        print('Popular content WebSocket error: $error');
      },
      onDone: () {
        print('Popular content WebSocket disconnected.');
      },
    );

    _latestSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'latest',
    )
        .listen(
      (data) {
        setState(() {
          _isLoading =
              false; // Set to false after all subscriptions are initialized
          if (data is List) {
            _latestContent = data;
          } else if (data is Map &&
              data.containsKey('results') &&
              data['results'] is List) {
            _latestContent = data['results'];
          } else if (data is Map) {
            _latestContent = [data];
          } else {
            _latestContent = [];
            _errorMessage = 'Unexpected data format for latest content.';
          }
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load latest content: $error';
          _latestContent = [];
        });
        print('Latest content WebSocket error: $error');
      },
      onDone: () {
        print('Latest content WebSocket disconnected.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppLogo(width: 120, height: 36),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FilterScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Content (use first trending item as featured)
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor)) // Loading indicator
            else if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              )
            else ...[
              if (_trendingContent.isNotEmpty)
                _buildFeaturedContent(_trendingContent[0]),

              // Trending Content Section
              _buildContentSection('Trending', _trendingContent),

              // Popular Content Section
              _buildContentSection('Popular', _popularContent),

              // Latest Content Section (using the dummy data)
              _buildContentSection('Latest', _latestContent),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedContent(dynamic featuredItem) {
    return Container(
      height: 240,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Stack(
        children: [
          // Featured image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              featuredItem['poster_url'] ??
                  'https://via.placeholder.com/500x300',
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 240,
                color: AppTheme.cardColor,
                child: const Icon(
                  Icons.broken_image,
                  color: AppTheme.textColorSecondary,
                  size: 50,
                ),
              ),
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // Content details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    featuredItem['title'] ?? 'Featured Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (featuredItem['quality'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            featuredItem['quality']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (featuredItem['imdb_rating'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                featuredItem['imdb_rating']!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (featuredItem['release_year'] != null)
                        Text(
                          featuredItem['release_year'].toString(),
                          style: const TextStyle(
                            color: AppTheme.textColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (featuredItem['duration'] != null)
                        Text(
                          '${featuredItem['duration']} min',
                          style: const TextStyle(
                            color: AppTheme.textColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featuredItem['description'] ?? 'No description available.',
                    style: const TextStyle(
                      color: AppTheme.textColorSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailScreen(content: featuredItem),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'Watch Now',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  // Navigate to a screen showing all content for this category
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PopularContentScreen(
                          title: title, contentList: contentList),
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
                  imageUrl: content['poster_url'] ??
                      'https://via.placeholder.com/300x450',
                  title: content['title'] ?? 'No Title',
                  quality: content['quality'] ?? 'HD',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(content: content),
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
