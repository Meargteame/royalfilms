import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
import '../screens/popular_content_screen.dart';
import 'package:ethionetflix_app/services/api_service.dart';
import 'package:ethionetflix_app/services/local_storage_service.dart';
import 'dart:async';

class TvSeriesScreen extends StatefulWidget {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  
  const TvSeriesScreen({
    required this.apiService,
    required this.localStorageService,
    super.key,
  });

  @override
  State<TvSeriesScreen> createState() => _TvSeriesScreenState();
}

class _TvSeriesScreenState extends State<TvSeriesScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  List<dynamic> _trendingSeries = [];
  List<dynamic> _popularSeries = [];
  List<dynamic> _latestSeries = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _seriesSubscription;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _loadTvSeries();
  }

  @override
  void dispose() {
    _seriesSubscription?.cancel();
    super.dispose();
  }

  void _loadTvSeries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('Loading TV series from WebSocket...');

    // Store received items in lists
    List<dynamic> receivedItems = [];

    _seriesSubscription = _apiService
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
            
            // Filter for TV series only
            final seriesItems = receivedItems.where((item) {
              final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
              final type = item['type']?.toString().toLowerCase() ?? '';
              final category = item['category']?.toString().toLowerCase() ?? '';
              final contentType = item['contentType']?.toString().toLowerCase() ?? '';
              
              // Check for explicit series indicators
              if (item['episode'] != null || item['seriesName'] != null) {
                return true;
              }

              // Check for TV series patterns in title
              if (title.contains('episode') || title.contains('season') || 
                  title.contains('s0') || title.contains('e0') || 
                  title.contains('x0') || title.contains(' 1 ')) {
                return true;
              }

              // Check for explicit TV series indicators in type/category
              if (type.contains('tv') || type.contains('series') || type.contains('show') || 
                  category.contains('tv') || category.contains('series') || category.contains('show') || 
                  contentType.contains('tv') || contentType.contains('series') || contentType.contains('show')) {
                return true;
              }
              
              return false;
            }).toList();
            
            // Sort by release date (newest first)
            seriesItems.sort((a, b) {
              final dateA = a['releaseDate'] ?? '';
              final dateB = b['releaseDate'] ?? '';
              return dateB.compareTo(dateA);
            });
            
            _trendingSeries = List.from(seriesItems);
            _popularSeries = List.from(seriesItems);
            _latestSeries = List.from(seriesItems);
          _isLoading = false;
          });
          print('Updated series lists: ${_trendingSeries.length} total items');
          } else if (data is Map) {
          // If data is a single item (Map), add it if not already present
          if (!receivedItems.any((existing) => 
             (existing['movieId'] != null && data['movieId'] != null && existing['movieId'] == data['movieId']) ||
             (existing['id'] != null && data['id'] != null && existing['id'] == data['id']))) {
            receivedItems.add(data);
            
            // Filter and update series lists
            setState(() {
              final seriesItems = receivedItems.where((item) {
                // Same filtering logic as above
                final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
                final type = item['type']?.toString().toLowerCase() ?? '';
                final category = item['category']?.toString().toLowerCase() ?? '';
                final contentType = item['contentType']?.toString().toLowerCase() ?? '';
                
                if (item['episode'] != null || item['seriesName'] != null) {
                  return true;
                }

                if (title.contains('episode') || title.contains('season') || 
                    title.contains('s0') || title.contains('e0') || 
                    title.contains('x0') || title.contains(' 1 ')) {
                  return true;
                }

                if (type.contains('tv') || type.contains('series') || type.contains('show') || 
                    category.contains('tv') || category.contains('series') || category.contains('show') || 
                    contentType.contains('tv') || contentType.contains('series') || contentType.contains('show')) {
                  return true;
                }
                
                return false;
          }).toList();
          
              // Sort by release date
              seriesItems.sort((a, b) {
                final dateA = a['releaseDate'] ?? '';
                final dateB = b['releaseDate'] ?? '';
                return dateB.compareTo(dateA);
              });
              
              _trendingSeries = List.from(seriesItems);
              _popularSeries = List.from(seriesItems);
              _latestSeries = List.from(seriesItems);
              _isLoading = false;
            });
          }
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Failed to load TV series: $error';
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
        title: const Text(
          'TV Series',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search screen
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Navigate to filter screen
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
                        'Error Loading TV Series',
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
                        onPressed: _loadTvSeries,
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
                    _loadTvSeries();
                  },
                  color: AppTheme.primaryColor,
                  child: ListView(
                    children: [
                      // Featured series at the top (first item from trending if available)
                      _trendingSeries.isNotEmpty
                          ? _buildFeaturedContent(_trendingSeries[0])
                          : SizedBox.shrink(),

                      // Content sections
                      _buildContentSection('Trending Series', _trendingSeries),
                      _buildContentSection('Popular Series', _popularSeries),
                      _buildContentSection('Latest Series', _latestSeries),

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
                featuredItem['seriesName'] ?? featuredItem['name'] ?? featuredItem['title'] ?? 'Featured Series',
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
                  if (featuredItem['episode'] != null)
                    Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'E${featuredItem['episode']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
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
                  title: content['seriesName'] ?? content['name'] ?? content['title'] ?? 'No Title',
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
