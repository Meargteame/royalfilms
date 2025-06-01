import 'package:flutter/material.dart';
// import '../services/api_service.dart'; // Removed
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';

class WatchListScreen extends StatefulWidget {
  const WatchListScreen({super.key});

  @override
  State<WatchListScreen> createState() => _WatchListScreenState();
}

class _WatchListScreenState extends State<WatchListScreen>
    with SingleTickerProviderStateMixin {
  // final ApiService _apiService = ApiService(); // Removed
  List<dynamic> _watchListContent = [
    {
      'title': 'Dummy WatchList Item 1',
      'poster_url': 'https://via.placeholder.com/300x450?text=Watchlist+1',
      'quality': 'HD',
      'imdb_rating': 7.5,
      'release_year': 2020,
      'duration': 90,
      'description': 'This is a dummy item in your watchlist.',
    },
    {
      'title': 'Dummy WatchList Item 2',
      'poster_url': 'https://via.placeholder.com/300x450?text=Watchlist+2',
      'quality': 'FHD',
      'imdb_rating': 8.1,
      'release_year': 2021,
      'duration': 105,
      'description': 'This is another dummy item in your watchlist.',
    },
  ];
  bool _isLoading = false; // Set to false, no more loading from API
  String? _errorMessage; // No more error messages from API

  @override
  void initState() {
    super.initState();
    // _setupWebSocket(); // Removed
  }

  @override
  void dispose() {
    // _apiService.dispose(); // Removed
    super.dispose();
  }

  void _setupWebSocket() {
    // All WebSocket logic removed
  }

  void _loadWatchListContent() {
    // All API loading logic removed
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
              // TODO: Implement search functionality for Watch List
              print('Search tapped from WatchListScreen');
            },
          ),
        ],
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        builder: (context) => DetailScreen(content: item),
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
