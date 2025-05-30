// lib/screens/search_screen_new.dart
import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import 'filter_screen.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final MockDataService _mockService = MockDataService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _topSearches = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;
  Map<String, dynamic>? _selectedFilters;
  TabController? _tabController;
  final List<String> _tabs = ['Movies', 'Tv Series'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _setupSearchListener();
    _loadTopSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _setupSearchListener() {
    // Initialize the mock service
    _mockService.init();

    // Listen to search results from mock service
    _mockService.searchResults.listen(
      (content) {
        if (mounted) {
          setState(() {
            _searchResults = content;
            _isSearching = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage = 'Error searching: $error';
          });
        }
      },
    );
  }

  void _loadTopSearches() {
    // This would be fetched from an API in a real app
    _topSearches = [
      {
        'id': '1',
        'title': 'Sinners',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Sinners',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Horror', 'Action', 'Thriller'],
        'country': 'United States of America',
      },
      {
        'id': '2',
        'title': 'A Minecraft Movie',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Minecraft',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Family', 'Comedy', 'Adventure', 'Fantasy'],
        'country': 'Sweden, United States of America',
      },
      {
        'id': '3',
        'title': 'Snow White',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Snow+White',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Family', 'Fantasy'],
        'country': 'United States of America',
      },
      {
        'id': '4',
        'title': 'Thunderbolts',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Thunderbolts',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Action', 'Adventure', 'Science Fiction'],
        'country': 'United States of America',
      },
      {
        'id': '5',
        'title': 'Daredevil: Born Again',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Daredevil',
        'type': 'TV Series',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Drama', 'Crime'],
        'country': 'United States of America',
      },
      {
        'id': '6',
        'title': 'A Working Man',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Working+Man',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Action', 'Crime', 'Thriller'],
        'country': 'United Kingdom, United States of America',
      },
    ];
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    // Use the mock service search method instead of WebSocket query
    _mockService.search(query);
  }

  void _openFilterScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedFilters = result;
      });
      // Apply filters to search results in a real app
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppTheme.textColorPrimary),
          decoration: InputDecoration(
            hintText: 'Search for movies, series...',
            hintStyle: TextStyle(color: AppTheme.textColorTertiary),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppTheme.textColorTertiary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _hasSearched = false;
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.filter_list,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: _openFilterScreen,
                ),
              ],
            ),
          ),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
        bottom:
            _hasSearched
                ? TabBar(
                  controller: _tabController,
                  tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textColorSecondary,
                )
                : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.textColorSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.buttonTextColor,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_hasSearched) {
      // Search results view with tabs
      return TabBarView(
        controller: _tabController,
        children: [
          // Movies tab
          _buildSearchResultsGrid(
            _searchResults.where((item) => item['type'] == 'Movie').toList(),
          ),
          // TV Series tab
          _buildSearchResultsGrid(
            _searchResults
                .where((item) => item['type'] == 'TV Series')
                .toList(),
          ),
        ],
      );
    } else {
      // Top searches view
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColorPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildSearchResultsGrid(_topSearches)),
          ],
        ),
      );
    }
  }

  Widget _buildSearchResultsGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: AppTheme.textColorTertiary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _hasSearched
                  ? 'No results found for "${_searchController.text}"'
                  : 'No trending searches',
              style: const TextStyle(
                color: AppTheme.textColorSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(content: item),
              ),
            );
          },
          child: ContentCard(
            imageUrl: item['imageUrl'],
            title: item['title'],
            quality: item['quality'],
            showDetails: true,
            // width: 150,
            // height: 225,
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
    );
  }
}
