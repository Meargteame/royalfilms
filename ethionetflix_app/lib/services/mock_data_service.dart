// lib/services/mock_data_service.dart
import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// A mock service that provides dummy data for development
/// This allows UI development to continue while WebSocket issues are resolved
class MockDataService {
  // Singleton instance
  static final MockDataService _instance = MockDataService._internal();

  factory MockDataService() {
    return _instance;
  }

  MockDataService._internal();

  // Stream controllers for different content types
  final _trendingContentController = BehaviorSubject<List<dynamic>>();
  final _popularContentController = BehaviorSubject<List<dynamic>>();
  final _latestContentController = BehaviorSubject<List<dynamic>>();
  final _searchResultsController = BehaviorSubject<List<dynamic>>();

  // Stream getters
  Stream<List<dynamic>> get trendingContent => _trendingContentController.stream;
  Stream<List<dynamic>> get popularContent => _popularContentController.stream;
  Stream<List<dynamic>> get latestContent => _latestContentController.stream;
  Stream<List<dynamic>> get searchResults => _searchResultsController.stream;

  // Initialize with mock data
  void init() {
    _loadMockData();
  }

  void _loadMockData() {
    // Add mock trending content
    _trendingContentController.add(_generateMockMovies(10, 'Trending'));
    
    // Add mock popular content
    _popularContentController.add(_generateMockMovies(10, 'Popular'));
    
    // Add mock latest content
    _latestContentController.add(_generateMockMovies(10, 'Latest'));
  }

  // Generate mock movies with different titles based on category
  List<Map<String, dynamic>> _generateMockMovies(int count, String prefix) {
    final List<Map<String, dynamic>> movies = [];
    
    for (int i = 1; i <= count; i++) {
      movies.add({
        'id': '${prefix.toLowerCase()}_$i',
        'title': '$prefix Movie $i',
        'description': 'This is a mock description for $prefix movie $i. It is generated for UI development purposes while the WebSocket connection issue is being resolved.',
        'poster_url': 'https://via.placeholder.com/300x450?text=$prefix+$i',
        'type': i % 3 == 0 ? 'series' : 'movie',
        'quality': i % 2 == 0 ? 'HD' : '4K',
        'genres': ['Action', 'Drama', 'Thriller'],
        'countries': ['Ethiopia', 'USA'],
        'release_year': 2020 + (i % 5),
        'imdb_rating': 7.0 + (i % 30) / 10,
        'duration': 90 + (i * 5),
      });
    }
    
    return movies;
  }

  // Search function that filters mock data
  void search(String query) {
    if (query.isEmpty) {
      _searchResultsController.add([]);
      return;
    }
    
    // Create a combined list of all content
    final allContent = [
      ..._trendingContentController.value,
      ..._popularContentController.value,
      ..._latestContentController.value,
    ];
    
    // Filter based on query
    final filteredContent = allContent.where((item) {
      final title = item['title'].toString().toLowerCase();
      final description = item['description'].toString().toLowerCase();
      return title.contains(query.toLowerCase()) || 
             description.contains(query.toLowerCase());
    }).toList();
    
    // Remove duplicates (based on id)
    final uniqueContent = filteredContent.fold<List<dynamic>>([], (previous, element) {
      if (!previous.any((p) => p['id'] == element['id'])) {
        previous.add(element);
      }
      return previous;
    });
    
    _searchResultsController.add(uniqueContent);
  }

  // Clean up resources
  void dispose() {
    _trendingContentController.close();
    _popularContentController.close();
    _latestContentController.close();
    _searchResultsController.close();
  }
}
