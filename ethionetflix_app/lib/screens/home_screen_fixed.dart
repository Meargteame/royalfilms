// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/logo.dart';
import '../screens/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final MockDataService _mockService = MockDataService();
  List<dynamic> _trendingContent = [];
  List<dynamic> _popularContent = [];
  List<dynamic> _latestContent = [];
  bool _isLoading = true;
  String? _errorMessage;
  // TabController and _categories removed as tabs are handled by MainScreen

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    // Dispose removed TabController
    super.dispose();
  }

  void _loadContent() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Initialize the mock service
    _mockService.init();

    // Listen to the trending content stream
    _mockService.trendingContent.listen(
      (content) {
        if (mounted) {
          setState(() {
            _trendingContent = content;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error loading content: $error';
          });
        }
      },
    );

    // Listen to the popular content stream
    _mockService.popularContent.listen((content) {
      if (mounted) {
        setState(() {
          _popularContent = content;
        });
      }
    });

    // Listen to the latest content stream
    _mockService.latestContent.listen((content) {
      if (mounted) {
        setState(() {
          _latestContent = content;
        });
      }
    });
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
                IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadContent,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppTheme.buttonTextColor,
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Content
                    if (_trendingContent.isNotEmpty)
                      _buildFeaturedContent(_trendingContent[0]),

                    // Trending Content Section
                    _buildContentSection('Trending', _trendingContent),

                    // Popular Content Section
                    _buildContentSection('Popular', _popularContent),

                    // Latest Content Section
                    _buildContentSection('Latest', _latestContent),
                  ],
                ),
              ),
    );
  }

  // Removed _buildCategoryContentPage as tabs are handled by MainScreen

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
              errorBuilder:
                  (context, error, stackTrace) => Container(
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
                            featuredItem['quality'],
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (featuredItem['imdb_rating'] != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              featuredItem['imdb_rating'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 8),
                      if (featuredItem['release_year'] != null)
                        Text(
                          featuredItem['release_year'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (featuredItem['duration'] != null)
                        Text(
                          '${featuredItem['duration']} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      DetailScreen(content: featuredItem),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      DetailScreen(content: featuredItem),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_filter,
            color: AppTheme.textColorSecondary,
            size: 50,
          ),
          const SizedBox(height: 16),
          const Text(
            'No content available',
            style: TextStyle(color: AppTheme.textColorSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(String title, List<dynamic> contentList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColorPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: contentList.length,
            itemBuilder: (context, index) {
              final item = contentList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ContentCard(
                  imageUrl: item['poster_url'],
                  title: item['title'] ?? 'No Title',
                  quality: item['quality'],
                  showDetails: true,
                  width: 140,
                  height: 150,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(content: item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
