import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
import '../screens/popular_content_screen.dart';
import 'package:ethionetflix_app/services/api_service.dart';
import 'package:ethionetflix_app/services/local_storage_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  
  const HomeScreen({
    required this.apiService,
    required this.localStorageService,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
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
    _apiService = widget.apiService;
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

    print('Loading all content from WebSocket...');

    // Store received items in lists
    List<dynamic> receivedItems = [];

    _trendingSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'all', // Using 'all' to get all content
    )
        .listen(
      (data) {
        print('Received data: ${data.runtimeType}');
        
        if (data is List) {
          // If data is a list, add all items
          print('Received list data with ${data.length} items');
          setState(() {
            for (var item in data) {
              if (!receivedItems.any((existing) => 
                 (existing['movieId'] != null && item['movieId'] != null && existing['movieId'] == item['movieId']) ||
                 (existing['id'] != null && item['id'] != null && existing['id'] == item['id']))) {
                receivedItems.add(item);
              }
            }
            _trendingContent = List.from(receivedItems);
            _popularContent = List.from(receivedItems);
            _latestContent = List.from(receivedItems);
            _isLoading = false;
          });
          print('Updated content lists: ${receivedItems.length} total items');
        } else if (data is Map) {
          // If data is a single item (Map), add it if not already present
          if (!receivedItems.any((existing) => 
             (existing['movieId'] != null && data['movieId'] != null && existing['movieId'] == data['movieId']) ||
             (existing['id'] != null && data['id'] != null && existing['id'] == data['id']))) {
            receivedItems.add(data);
            
            // Update all content lists with all received items
            setState(() {
              _trendingContent = List.from(receivedItems);
              _popularContent = List.from(receivedItems);
              _latestContent = List.from(receivedItems);
              _isLoading = false;
            });
            print('Added item to all content lists: ${receivedItems.length} total items');
            print('Content item details: ${data['name'] ?? data['title'] ?? 'Unknown'}, Thumbnail: ${data['thumbNail']}');
          }
        }
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
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Royal',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'Films',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search screen
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Navigate to profile screen
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
                      Icon(Icons.error_outline, color: Colors.red, size: 60),
                      SizedBox(height: 16),
                      Text(
                        'Error Loading Content',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadAllContent();
                  },
                  color: AppTheme.primaryColor,
                  child: ListView(
                    children: [
                      // Featured content at the top (first item from trending if available)
                      _trendingContent.isNotEmpty
                          ? _buildFeaturedContent(_trendingContent[0])
                          : SizedBox.shrink(),

                      // Content sections
                      _buildContentSection('Trending', _trendingContent),
                      _buildContentSection('Popular', _popularContent),
                      _buildContentSection('Latest', _latestContent),

                      SizedBox(height: 80), // Bottom padding
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
                featuredItem['name'] ?? featuredItem['seriesName'] ?? featuredItem['title'] ?? 'Featured Content',
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
                            localStorageService: LocalStorageService(),
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
                        localStorageService: LocalStorageService(),
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
                  title: content['name'] ?? content['seriesName'] ?? content['title'] ?? 'No Title',
                  type: content['type'],
                  year: content['year'],
                  quality: content['quality'] ?? 'HD',
                  episodeInfo: content['episode'] != null ? 'E${content['episode']}' : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          content: content,
                          apiService: _apiService,
                          localStorageService: LocalStorageService(),
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
