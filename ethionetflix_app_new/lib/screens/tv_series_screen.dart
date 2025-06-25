import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
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
        if (data is List) {
          setState(() {
            for (var item in data) {
              if (!receivedItems.any((existing) =>
                  (existing['movieId'] != null && item['movieId'] != null && existing['movieId'] == item['movieId']) ||
                  (existing['id'] != null && item['id'] != null && existing['id'] == item['id']))) {
                receivedItems.add(item);
              }
            }
            // UPDATED series filter: show items where seriesName != null and episode == 1
            final seriesItems = receivedItems.where((item) {
              final hasSeriesName = item['seriesName'] != null;
              final isFirstEpisode = item['episode'] == 1;
              return hasSeriesName && isFirstEpisode;
            }).toList();

            // --- Make sections unique ---
            // Latest: newest by releaseDate
            final latestSeries = List.from(seriesItems);
            latestSeries.sort((a, b) {
              final dateA = a['releaseDate'] ?? '';
              final dateB = b['releaseDate'] ?? '';
              return dateB.compareTo(dateA);
            });
            // Trending: by views if available, else shuffle
            final trendingSeries = List.from(seriesItems);
            if (trendingSeries.isNotEmpty && trendingSeries.first.containsKey('views')) {
              trendingSeries.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
            } else {
              trendingSeries.shuffle();
            }
            // Popular: by rating if available, else shuffle
            final popularSeries = List.from(seriesItems);
            if (popularSeries.isNotEmpty && popularSeries.first.containsKey('rating')) {
              popularSeries.sort((a, b) => (b['rating'] ?? '').toString().compareTo((a['rating'] ?? '').toString()));
            } else {
              popularSeries.shuffle();
            }

            _trendingSeries = trendingSeries;
            _popularSeries = popularSeries;
            _latestSeries = latestSeries;
            _isLoading = false;
          });
          print('Updated series lists: {_trendingSeries.length} total items');
        } else if (data is Map) {
          if (!receivedItems.any((existing) =>
              (existing['movieId'] != null && data['movieId'] != null && existing['movieId'] == data['movieId']) ||
              (existing['id'] != null && data['id'] != null && existing['id'] == data['id']))) {
            receivedItems.add(data);
            setState(() {
              // UPDATED series filter: show items where seriesName != null and episode == 1
              final seriesItems = receivedItems.where((item) {
                final hasSeriesName = item['seriesName'] != null;
                final isFirstEpisode = item['episode'] == 1;
                return hasSeriesName && isFirstEpisode;
              }).toList();
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

  String getContentImageUrl(dynamic item) {
    final thumb = item['thumbNail']?.toString() ?? '';
    final poster = item['poster_url']?.toString() ?? '';
    // Prefer thumbNail if valid
    if (thumb.isNotEmpty) {
      if (thumb.startsWith('http')) {
        return thumb;
      } else if (thumb.startsWith('/thumbnails')) {
        return 'https://ethionetflix1.hopto.org$thumb';
      } else if (thumb.startsWith('assets/')) {
        return thumb;
      }
    }
    // Fallback to poster_url if valid
    if (poster.isNotEmpty && poster.startsWith('http')) {
      return poster;
    } else if (poster.isNotEmpty && poster.startsWith('assets/')) {
      return poster;
    }
    // Final fallback to local asset
    return 'assets/images/default_poster.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,        title: const Text(
          'TV Series',
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
                      SizedBox(height: 16),                      Text(
                        'Error Loading TV Series',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 18,
                          fontFamily: AppTheme.primaryFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                    _errorMessage!,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTheme.secondaryFontFamily,
                          fontWeight: FontWeight.w400,
                        ),
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
                      // Content sections (no featured section)
                      _buildContentSection('Trending Series', _trendingSeries),
                      _buildContentSection('Popular Series', _popularSeries),
                      _buildContentSection('Latest Series', _latestSeries),

                      SizedBox(height: 80), // Bottom padding
                    ],
                  ),
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
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textColorPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.primaryFontFamily,
                  letterSpacing: 0.3,
                ),
              ),
              /* TextButton(
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
                },                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontFamily: AppTheme.secondaryFontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ), */
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.68,
              crossAxisSpacing: 4,
              mainAxisSpacing: 8,
            ),
            itemCount: contentList.length,
            itemBuilder: (context, index) {
              final content = contentList[index];
              return ContentCard(
                imageUrl: getContentImageUrl(content),
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
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
