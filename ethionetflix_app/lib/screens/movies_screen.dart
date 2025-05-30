import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../services/mock_data_service.dart'; // Assuming mock service is used for now
import 'detail_screen.dart'; // Assuming navigation to DetailScreen
import 'filter_screen.dart'; // Assuming a FilterScreen exists

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({Key? key}) : super(key: key);

  @override
  _MoviesScreenState createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _tabs = ['Latest', 'Trending', 'Popular', 'Filter'];
  final MockDataService _mockService = MockDataService();

  List<dynamic> _latestMovies = [];
  List<dynamic> _trendingMovies = [];
  List<dynamic> _popularMovies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadMoviesContent();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadMoviesContent() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _mockService.init(); // Ensure mock service is initialized

    // Listen to the latest content stream and filter for Movies
    _mockService.latestContent.listen(
      (content) {
        if (mounted) {
          setState(() {
            _latestMovies =
                content.where((item) => item['type'] == 'Movie').toList();
            // _isLoading = false; // Only set to false after all content types are loaded if preferred
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error loading latest movies: $error';
            _isLoading = false;
          });
        }
      },
    );

    // Listen to the trending content stream and filter for Movies
    _mockService.trendingContent.listen((content) {
      if (mounted) {
        setState(() {
          _trendingMovies =
              content.where((item) => item['type'] == 'Movie').toList();
          // _isLoading = false;
        });
      }
    });
    onError:
    (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading trending movies: $error';
          _isLoading = false;
        });
      }
    };

    // Listen to the popular content stream and filter for Movies
    _mockService.popularContent.listen((content) {
      if (mounted) {
        setState(() {
          _popularMovies =
              content.where((item) => item['type'] == 'Movie').toList();
          _isLoading =
              false; // Set to false after the last content type is loaded
        });
      }
    });
    onError:
    (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading popular movies: $error';
          _isLoading = false;
        });
      }
    };
  }

  void _openFilterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterScreen()),
    ); // Assuming FilterScreen exists
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality for Movies
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterScreen,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textColorSecondary,
        ),
      ),
      body:
          _isLoading
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
              : TabBarView(
                controller: _tabController,
                children: [
                  // Latest Movies Tab
                  _buildContentGrid(
                    _latestMovies,
                  ), // Need to implement _buildContentGrid
                  // Trending Movies Tab
                  _buildContentGrid(_trendingMovies),
                  // Popular Movies Tab
                  _buildContentGrid(_popularMovies),
                  // Filter Tab Placeholder
                  const Center(child: Text('Filter Options Placeholder')),
                ],
              ),
    );
  }

  Widget _buildContentGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No content available.',
          style: TextStyle(color: AppTheme.textColorSecondary),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // As per your screenshot
        childAspectRatio: 0.6, // Adjusted aspect ratio, can be fine-tuned
        crossAxisSpacing: 12, // Spacing as seen in screenshots
        mainAxisSpacing: 12, // Spacing as seen in screenshots
      ),
      itemCount: items.length,
      padding: const EdgeInsets.all(8), // Padding around the grid
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DetailScreen(
                      content: item,
                    ), // Assuming DetailScreen is used
              ),
            );
          },
          child: ContentCard(
            imageUrl:
                item['poster_url'] ??
                item['imageUrl'] ??
                'https://via.placeholder.com/300x450', // Use poster_url if available, fallback to imageUrl
            title: item['title'] ?? 'No Title',
            quality: item['quality'] ?? 'HD',
            showDetails: true,
            // Pass width and height based on desired grid item size, or let ContentCard size itself
            width: 110, // Example width, adjust as needed
            height: 160, // Example height, adjust as needed
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(content: item),
                ),
              );
            }, // Pass the onTap callback
          ),
        );
      },
    );
  }
}
