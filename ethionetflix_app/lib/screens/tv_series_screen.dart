import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
import 'filter_screen.dart';
import 'search_screen.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
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
  List<dynamic> _tvSeries = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _tvSeriesSubscription;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _loadTvSeries();
  }

  @override
  void dispose() {
    _tvSeriesSubscription?.cancel();
    super.dispose();
  }

  void _loadTvSeries() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _tvSeriesSubscription = _apiService
        .connectToContentWebSocket(
      type: 'collection',
      collectionId: 'all',
    )
        .listen(
      (data) {
        setState(() {
          _isLoading = false;
          List<dynamic> allContent = [];
          if (data is List) {
            allContent = data;
          } else if (data is Map &&
              data.containsKey('results') &&
              data['results'] is List) {
            allContent = data['results'];
          } else if (data is Map) {
            allContent = [data];
          }
          
          // Filter only TV series content
          _tvSeries = allContent.where((item) {
            final type = item['type']?.toString().toLowerCase() ?? '';
            return type == 'tv' || type == 'series' || type == 'show';
          }).toList();
          
          if (_tvSeries.isEmpty && allContent.isNotEmpty) {
            _errorMessage = 'No TV series found in the content.';
          }
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load TV series: $error';
          _tvSeries = [];
        });
        print('TV Series WebSocket error: $error');
      },
      onDone: () {
        print('TV Series WebSocket disconnected.');
      },
    );
  }

  void _openFilterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FilterScreen(apiService: _apiService)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TV Series',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    apiService: _apiService,
                    localStorageService: widget.localStorageService,
                  ),
                ),
              );
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
                        itemCount: _tvSeries.length,
                        itemBuilder: (context, index) {
                          final series = _tvSeries[index];
                          return ContentCard(
                            imageUrl: series['poster_url'] ??
                                'https://via.placeholder.com/300x450',
                            title: series['title'] ?? 'No Title',
                            quality: series['quality'] ?? 'HD',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(
                                    content: series,
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
                  ),
                ),
    );
  }
}
