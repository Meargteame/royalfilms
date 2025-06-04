// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../screens/detail_screen.dart';
import '../screens/filter_screen.dart'; // Import FilterScreen
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  final ApiService apiService;
  final LocalStorageService localStorageService;
  
  const SearchScreen({
    required this.apiService,
    required this.localStorageService,
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ApiService _apiService;
  late final LocalStorageService _localStorageService;
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _webSocketSubscription;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _localStorageService = widget.localStorageService;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _webSocketSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _performSearch(query);
  }

  void _performSearch(String query) {
    _webSocketSubscription?.cancel(); // Cancel previous subscription

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _webSocketSubscription = _apiService
        .connectToContentWebSocket(
      type: 'search',
      query: query,
    )
        .listen(
      (data) {
        setState(() {
          _isLoading = false;
          if (data is List) {
            _searchResults = data;
          } else if (data is Map &&
              data.containsKey('results') &&
              data['results'] is List) {
            _searchResults = data['results'];
          } else if (data is Map) {
            // Handle single map objects received directly
            _searchResults = [data];
          } else {
            _searchResults = [];
            _errorMessage = 'Unexpected data format from WebSocket.';
          }
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load search results: $error';
          _searchResults = [];
        });
        print('Search WebSocket error: $error');
      },
      onDone: () {
        print('Search WebSocket disconnected.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            color: AppTheme.textColorPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilterScreen(apiService: _apiService),
                ),
              );
            },
          ),
        ],
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {}, // Handled by listener now
              style: const TextStyle(color: AppTheme.textColorPrimary),
              decoration: InputDecoration(
                hintText: 'Search for movies or series...',
                hintStyle: TextStyle(
                    color: AppTheme.textColorSecondary.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.textColorSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textColorSecondary),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      )
                    : Expanded(
                        child: _searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  _searchController.text.isEmpty
                                      ? 'Search for content.'
                                      : 'No results found for "${_searchController.text}".',
                                  style: const TextStyle(
                                    color: AppTheme.textColorSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final item = _searchResults[index];
                                  return ContentCard(
                                    imageUrl: item['poster_url'] ??
                                        'https://via.placeholder.com/300x450',
                                    title: item['title'] ?? 'No Title',
                                    quality: item['quality'] ?? 'HD',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailScreen(
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
                      ),
          ],
        ),
      ),
    );
  }
}
