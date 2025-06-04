import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';

class WatchListScreen extends StatefulWidget {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  
  const WatchListScreen({
    required this.apiService,
    required this.localStorageService,
    super.key,
  });

  @override
  State<WatchListScreen> createState() => _WatchListScreenState();
}

// Search delegate for watch list content
class _WatchListSearchDelegate extends SearchDelegate<dynamic> {
  final List<dynamic> watchListContent;
  final List<dynamic> downloadedContent;
  final ApiService apiService;
  final LocalStorageService localStorageService;

  _WatchListSearchDelegate({
    required this.watchListContent,
    required this.downloadedContent,
    required this.apiService,
    required this.localStorageService,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final allContent = [...watchListContent, ...downloadedContent];
    final results = allContent.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search your watchlist'),
      );
    }

    if (results.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ContentCard(
          imageUrl: item['poster_url'] ?? 'https://via.placeholder.com/300x450',
          title: item['title'] ?? 'No Title',
          quality: item['quality'] ?? 'HD',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  content: item,
                  apiService: apiService,
                  localStorageService: localStorageService,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WatchListScreenState extends State<WatchListScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _apiService;
  late final LocalStorageService _localStorageService;
  List<dynamic> _watchListContent = [];
  List<dynamic> _downloadedContent = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _watchListSubscription;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _localStorageService = widget.localStorageService;
    _loadWatchListContent();
  }

  @override
  void dispose() {
    _watchListSubscription?.cancel();
    super.dispose();
  }



  void _loadWatchListContent() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // First, get any downloaded content
    _loadDownloadedContent();
    
    // Then connect to the watchlist WebSocket endpoint
    _watchListSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'watchlist',
    )
        .listen(
      (data) {
        setState(() {
          _isLoading = false;
          if (data is List) {
            _watchListContent = data;
          } else if (data is Map &&
              data.containsKey('results') &&
              data['results'] is List) {
            _watchListContent = data['results'];
          } else if (data is Map) {
            _watchListContent = [data];
          } else {
            _watchListContent = [];
            _errorMessage = 'Unexpected data format for watchlist.';
          }
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load watchlist: $error';
        });
        print('Watchlist WebSocket error: $error');
      },
      onDone: () {
        print('Watchlist WebSocket disconnected.');
      },
    );
  }
  
  Future<void> _loadDownloadedContent() async {
    try {
      final downloadedVideos = await _localStorageService.getDownloadedVideos();
      if (mounted) {
        setState(() {
          _downloadedContent = downloadedVideos;
        });
      }
    } catch (e) {
      print('Error loading downloaded videos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Watch List',
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
              showSearch(
                context: context,
                delegate: _WatchListSearchDelegate(
                  watchListContent: _watchListContent,
                  downloadedContent: _downloadedContent,
                  apiService: _apiService,
                  localStorageService: _localStorageService,
                ),
              );
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWatchListContent,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWatchListContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First show downloaded content section if any
                      if (_downloadedContent.isNotEmpty) ...[                    
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Downloaded Content',
                            style: TextStyle(
                              color: AppTheme.textColorPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _downloadedContent.length,
                          itemBuilder: (context, index) {
                            final item = _downloadedContent[index];
                            return ContentCard(
                              imageUrl: item['poster_url'] ?? 
                                  'https://via.placeholder.com/300x450',
                              title: item['title'] ?? 'No Title',
                              quality: item['quality'] ?? 'HD',
                              badge: 'Downloaded',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      content: item,
                                      apiService: _apiService,
                                      localStorageService: _localStorageService,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Then show online watchlist
                      if (_watchListContent.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Watchlist',
                            style: TextStyle(
                              color: AppTheme.textColorPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _watchListContent.length,
                          itemBuilder: (context, index) {
                            final item = _watchListContent[index];
                            return ContentCard(
                              imageUrl: item['poster_url'] ??
                                  'https://via.placeholder.com/300x450',
                              title: item['title'] ?? 'No Title',
                              quality: item['quality'] ?? 'HD',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      content: item,
                                      apiService: _apiService,
                                      localStorageService: _localStorageService,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                      
                      // Show empty state if both lists are empty
                      if (_watchListContent.isEmpty && _downloadedContent.isEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const <Widget>[
                              SizedBox(height: 32),
                              Icon(
                                Icons.list_alt,
                                size: 64,
                                color: AppTheme.textColorSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Your watchlist is empty',
                                style: TextStyle(
                                  color: AppTheme.textColorPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add movies and shows to your watchlist',
                                style: TextStyle(
                                  color: AppTheme.textColorSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
    );
  }
}
