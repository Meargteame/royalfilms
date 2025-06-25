import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/featured_card.dart';
import '../screens/detail_screen.dart';
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
  
  // Separate content lists for movies and TV series
  List<dynamic> _allContent = [];
  List<dynamic> _movies = [];
  List<dynamic> _tvSeries = [];
  List<dynamic> _trendingContent = [];
  List<dynamic> _popularContent = [];
  List<dynamic> _latestContent = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _contentSubscription;
  
  // Filter/Toggle state
  String _selectedFilter = 'all'; // 'all', 'movies', 'series'
  
  // Configuration flag to control section visibility
  bool _hidePopularAndTrendingWhenLatestPresent = true;
  
  // Helper getter to check if Latest section should suppress other sections
  bool get _shouldHidePopularAndTrending => 
      _hidePopularAndTrendingWhenLatestPresent && _latestContent.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _loadAllContent();
  }
  @override
  void dispose() {
    _contentSubscription?.cancel();
    super.dispose();
  }
  void _loadAllContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('Loading all content with limit=5000...');

    _contentSubscription = _apiService
        .connectToContentWebSocket(
      type: 'all',
      limit: 5000, // Fetch all 5000 items
    )
        .listen(
      (data) {
        print('Received data: ${data.runtimeType}');
        
        if (data is List) {
          print('Received list data with ${data.length} items');
          _processAllContent(data);
        } else if (data is Map) {
          _processAllContent([data]);
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        setState(() {
          _errorMessage = 'Failed to load content: $error';
          _isLoading = false;
        });
      },
      onDone: () {
        print('WebSocket connection closed');
        if (_allContent.isEmpty && _isLoading) {
          setState(() {
            _errorMessage = 'No content received from server';
            _isLoading = false;
          });
        }
      },
    );
  }
  void _processAllContent(List<dynamic> items) {
    List<dynamic> allItems = List.from(_allContent);
    
    for (var item in items) {
      // Check for duplicates
      if (!allItems.any((existing) => 
         (existing['movieId'] != null && item['movieId'] != null && existing['movieId'] == item['movieId']) ||
         (existing['id'] != null && item['id'] != null && existing['id'] == item['id']) ||
         (existing['title'] != null && item['title'] != null && existing['title'] == item['title']) ||
         (existing['name'] != null && item['name'] != null && existing['name'] == item['name']))) {
        allItems.add(item);
      }
    }
    
    // Separate movies and TV series
    List<dynamic> movies = [];
    List<dynamic> series = [];
    
    for (var item in allItems) {
      if (_isMovie(item)) {
        movies.add(item);
      } else if (_isTVSeries(item)) {
        series.add(item);
      }
    }
    
    setState(() {
      _allContent = allItems;
      _movies = movies;
      _tvSeries = series;
      
      // Update existing content lists for backward compatibility
      _latestContent = allItems;
      _trendingContent = allItems;
      _popularContent = allItems;
      
      _isLoading = false;
    });
    
    print('Content processing complete:');
    print('- Total items: ${allItems.length}');
    print('- Movies: ${movies.length}');
    print('- TV Series: ${series.length}');
  }

  // Helper method to determine if content is a movie
  bool _isMovie(dynamic item) {
    // Check various indicators that suggest it's a movie
    final type = item['type']?.toString().toLowerCase();
    final title = item['title']?.toString().toLowerCase() ?? '';
    final name = item['name']?.toString().toLowerCase() ?? '';
    final collection = item['collection']?.toString().toLowerCase() ?? '';
    
    // Direct type indicators
    if (type != null) {
      if (type.contains('movie') || type.contains('film')) return true;
      if (type.contains('series') || type.contains('tv') || type.contains('show')) return false;
    }
    
    // Check if it has episode information (likely a series)
    if (item['episode'] != null || item['season'] != null) return false;
    
    // Check collection names
    if (collection.contains('movie') || collection.contains('film')) return true;
    if (collection.contains('series') || collection.contains('tv') || collection.contains('show')) return false;
    
    // Check title/name patterns
    if (title.contains(' s0') || title.contains(' season ') || 
        name.contains(' s0') || name.contains(' season ')) return false;
    
    // Default to movie if unclear (can be adjusted based on your data patterns)
    return true;
  }
  // Helper method to determine if content is a TV series
  bool _isTVSeries(dynamic item) {
    return !_isMovie(item);
  }

  // Build filter chip widget
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : AppTheme.textColorPrimary,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.secondaryFontFamily,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.black,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
        width: 1,
      ),
    );
  }

  // Get filtered content count
  int _getFilteredContentCount() {
    switch (_selectedFilter) {
      case 'movies':
        return _movies.length;
      case 'series':
        return _tvSeries.length;
      default:
        return _allContent.length;
    }
  }
  // Get filtered content for sections
  List<dynamic> _getFilteredContent() {
    switch (_selectedFilter) {
      case 'movies':
        return _movies;
      case 'series':
        return _tvSeries;
      default:
        return _allContent;
    }
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Movies', 'movies'),
                        const SizedBox(width: 8),
                        _buildFilterChip('TV Series', 'series'),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${_getFilteredContentCount()} items',
                  style: const TextStyle(
                    color: AppTheme.textColorSecondary,
                    fontSize: 12,
                    fontFamily: AppTheme.secondaryFontFamily,
                  ),
                ),
              ],
            ),
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
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
          // Settings/toggle button for section visibility
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'toggle_sections') {
                togglePopularTrendingVisibility();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'toggle_sections',
                child: Row(
                  children: [
                    Icon(
                      _shouldHidePopularAndTrending ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _shouldHidePopularAndTrending 
                          ? 'Show all sections'
                          : 'Hide Popular/Trending',
                    ),
                  ],
                ),
              ),
            ],
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
                        onPressed: _loadAllContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: AppTheme.secondaryFontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      // Genre tags section
                      _buildGenreSection(),
                      // Featured content section
                      if (_allContent.isNotEmpty) _buildFeaturedSection(),
                      
                      // Content sections - conditionally show based on Latest presence
                      ..._buildContentSections(),

                      SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
    );
  }

  /// Build content sections with proper movie/series separation
  List<Widget> _buildContentSections() {
    List<Widget> sections = [];
    
    // Get filtered content based on current filter
    final filteredContent = _getFilteredContent();
    
    if (filteredContent.isEmpty) {
      return sections;
    }
    
    // Build sections based on current filter
    switch (_selectedFilter) {
      case 'movies':
        _buildMovieSections(sections);
        break;
      case 'series':
        _buildSeriesSections(sections);
        break;
      default:
        _buildAllContentSections(sections);
        break;
    }
    
    return sections;
  }

  /// Build featured content section
  Widget _buildFeaturedSection() {
    // Get the first item from filtered content as featured
    final featuredContent = _allContent.isNotEmpty ? _allContent.first : null;
    
    if (featuredContent == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Featured Today',
            style: TextStyle(
              color: AppTheme.textColorPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFontFamily,
            ),
          ),
        ),
        FeaturedCard(
          imageUrl: _getSafeImageUrl(featuredContent),
          title: _getSafeFeaturedTitle(featuredContent),
          description: _getSafeDescription(featuredContent),
          type: _getSafeStringValue(featuredContent['type']),
          year: _getSafeStringValue(featuredContent['year']),
          quality: _getSafeStringValue(featuredContent['quality']) ?? 'HD',
          rating: _getSafeStringValue(featuredContent['rating']),
          onWatchNow: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  content: featuredContent,
                  apiService: _apiService,
                  localStorageService: LocalStorageService(),
                ),
              ),
            );
          },
          onAddToList: () {
            // Add to list functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${_getSafeTitle(featuredContent)}" to My List'),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 27), // Maintain spacing
      ],
    );
  }
  void _buildMovieSections(List<Widget> sections) {
    if (_movies.isEmpty) return;
    
    // Latest Movies - Show more content
    sections.add(_buildContentSection('Latest Movies', _movies.take(50).toList()));
    
    // Top Rated Movies (HD/4K quality) - Show more
    var topRatedMovies = _movies.where((item) => 
      item['quality'] == 'HD' || item['quality'] == '4K' || item['quality'] == 'UHD'
    ).take(40).toList();
    if (topRatedMovies.isNotEmpty) {
      sections.add(_buildContentSection('Top Rated Movies', topRatedMovies));
    }
    
    // Action Movies - Show more
    var actionMovies = _movies.where((item) => 
      item['type']?.toString().toLowerCase().contains('action') == true ||
      item['title']?.toString().toLowerCase().contains('action') == true ||
      item['name']?.toString().toLowerCase().contains('action') == true
    ).take(40).toList();
    if (actionMovies.isNotEmpty) {
      sections.add(_buildContentSection('Action Movies', actionMovies));
    }
    
    // Comedy Movies
    var comedyMovies = _movies.where((item) => 
      item['type']?.toString().toLowerCase().contains('comedy') == true ||
      item['title']?.toString().toLowerCase().contains('comedy') == true ||
      item['name']?.toString().toLowerCase().contains('comedy') == true
    ).take(30).toList();
    if (comedyMovies.isNotEmpty) {
      sections.add(_buildContentSection('Comedy Movies', comedyMovies));
    }
    
    // Drama Movies
    var dramaMovies = _movies.where((item) => 
      item['type']?.toString().toLowerCase().contains('drama') == true ||
      item['title']?.toString().toLowerCase().contains('drama') == true ||
      item['name']?.toString().toLowerCase().contains('drama') == true
    ).take(30).toList();
    if (dramaMovies.isNotEmpty) {
      sections.add(_buildContentSection('Drama Movies', dramaMovies));
    }
    
    // Recently Added Movies (from the end of the list)
    if (_movies.length > 90) {
      sections.add(_buildContentSection('Recently Added Movies', _movies.skip(90).take(50).toList()));
    }
    
    // More Popular Movies (different range)
    if (_movies.length > 140) {
      sections.add(_buildContentSection('More Popular Movies', _movies.skip(140).take(40).toList()));
    }
  }
  void _buildSeriesSections(List<Widget> sections) {
    if (_tvSeries.isEmpty) return;
    
    // Latest TV Series - Show more content
    sections.add(_buildContentSection('Latest TV Series', _tvSeries.take(50).toList()));
    
    // Top Rated Series - Show more
    var topRatedSeries = _tvSeries.where((item) => 
      item['quality'] == 'HD' || item['quality'] == '4K' || item['quality'] == 'UHD'
    ).take(40).toList();
    if (topRatedSeries.isNotEmpty) {
      sections.add(_buildContentSection('Top Rated Series', topRatedSeries));
    }
    
    // Continue Watching (series with episodes) - Show more
    var continueWatching = _tvSeries.where((item) => 
      item['episode'] != null || item['season'] != null
    ).take(30).toList();
    if (continueWatching.isNotEmpty) {
      sections.add(_buildContentSection('Continue Watching', continueWatching));
    }
    
    // Popular Series - Show more
    sections.add(_buildContentSection('Popular TV Series', _tvSeries.skip(50).take(40).toList()));
    
    // Additional TV Series Sections for more content
    
    // Drama Series
    var dramaSeries = _tvSeries.where((item) => 
      item['type']?.toString().toLowerCase().contains('drama') == true ||
      item['title']?.toString().toLowerCase().contains('drama') == true ||
      item['name']?.toString().toLowerCase().contains('drama') == true
    ).take(30).toList();
    if (dramaSeries.isNotEmpty) {
      sections.add(_buildContentSection('Drama Series', dramaSeries));
    }
    
    // Comedy Series
    var comedySeries = _tvSeries.where((item) => 
      item['type']?.toString().toLowerCase().contains('comedy') == true ||
      item['title']?.toString().toLowerCase().contains('comedy') == true ||
      item['name']?.toString().toLowerCase().contains('comedy') == true
    ).take(30).toList();
    if (comedySeries.isNotEmpty) {
      sections.add(_buildContentSection('Comedy Series', comedySeries));
    }
    
    // Recently Added Series (from the end of the list)
    if (_tvSeries.length > 90) {
      sections.add(_buildContentSection('Recently Added Series', _tvSeries.skip(90).take(40).toList()));
    }
    
    // More Popular Series (different range)
    if (_tvSeries.length > 130) {
      sections.add(_buildContentSection('More Popular Series', _tvSeries.skip(130).take(40).toList()));
    }
  }
  void _buildAllContentSections(List<Widget> sections) {
    // Latest Movies - Show more content
    if (_movies.isNotEmpty) {
      sections.add(_buildContentSection('Latest Movies', _movies.take(50).toList()));
    }
    
    // Latest TV Series - Show more content
    if (_tvSeries.isNotEmpty) {
      sections.add(_buildContentSection('Latest TV Series', _tvSeries.take(50).toList()));
    }
    
    // Trending Now (mixed content) - Show more content
    if (_allContent.isNotEmpty) {
      sections.add(_buildContentSection('Trending Now', _allContent.take(60).toList()));
    }
    
    // Top Rated Movies - Show more content
    if (_movies.isNotEmpty) {
      var topRatedMovies = _movies.where((item) => 
        item['quality'] == 'HD' || item['quality'] == '4K' || item['quality'] == 'UHD'
      ).take(40).toList();
      if (topRatedMovies.isNotEmpty) {
        sections.add(_buildContentSection('Top Rated Movies', topRatedMovies));
      }
    }
    
    // Popular TV Series - Show more content
    if (_tvSeries.isNotEmpty) {
      sections.add(_buildContentSection('Popular TV Series', _tvSeries.skip(50).take(40).toList()));
    }
      // Continue Watching - Show more content
    if (_allContent.isNotEmpty) {
      var continueWatching = _allContent.take(30).toList();
      sections.add(_buildContentSection('Continue Watching', continueWatching));
    }
    
    // Additional Mixed Content Sections for more variety
    
    // Action Content (Movies + Series)
    var actionContent = _allContent.where((item) => 
      item['type']?.toString().toLowerCase().contains('action') == true ||
      item['title']?.toString().toLowerCase().contains('action') == true ||
      item['name']?.toString().toLowerCase().contains('action') == true
    ).take(40).toList();
    if (actionContent.isNotEmpty) {
      sections.add(_buildContentSection('Action Content', actionContent));
    }
    
    // Horror/Thriller Content
    var horrorContent = _allContent.where((item) => 
      item['type']?.toString().toLowerCase().contains('horror') == true ||
      item['type']?.toString().toLowerCase().contains('thriller') == true ||
      item['title']?.toString().toLowerCase().contains('horror') == true ||
      item['title']?.toString().toLowerCase().contains('thriller') == true ||
      item['name']?.toString().toLowerCase().contains('horror') == true ||
      item['name']?.toString().toLowerCase().contains('thriller') == true
    ).take(35).toList();
    if (horrorContent.isNotEmpty) {
      sections.add(_buildContentSection('Horror & Thriller', horrorContent));
    }
    
    // High Quality Content (4K/UHD)
    var highQualityContent = _allContent.where((item) => 
      item['quality'] == '4K' || item['quality'] == 'UHD' || item['quality'] == 'Ultra HD'
    ).take(30).toList();
    if (highQualityContent.isNotEmpty) {
      sections.add(_buildContentSection('4K Ultra HD', highQualityContent));
    }
    
    // Recently Released (assuming newer content appears later in the list)
    if (_allContent.length > 200) {
      sections.add(_buildContentSection('Recently Released', _allContent.skip(200).take(50).toList()));
    }
    
    // More Content to Explore (from middle of the list)
    if (_allContent.length > 300) {
      sections.add(_buildContentSection('More to Explore', _allContent.skip(300).take(60).toList()));
    }
    
    // Editor's Choice (random selection from different parts)
    if (_allContent.length > 100) {
      var editorsChoice = <dynamic>[];
      // Take some from beginning, middle, and end
      editorsChoice.addAll(_allContent.take(10));
      if (_allContent.length > 50) editorsChoice.addAll(_allContent.skip(50).take(10));
      if (_allContent.length > 150) editorsChoice.addAll(_allContent.skip(150).take(10));
      if (_allContent.length > 250) editorsChoice.addAll(_allContent.skip(250).take(15));
      
      if (editorsChoice.isNotEmpty) {
        sections.add(_buildContentSection("Editor's Choice", editorsChoice));
      }
    }
      // Debug logging with detailed section information
    print('Content sections visibility:');
    print('- Total content fetched: ${_allContent.length} items');
    print('- Movies: ${_movies.length} items');
    print('- TV Series: ${_tvSeries.length} items');
    print('- Latest content: ${_latestContent.length} items');
    print('- Trending content: ${_trendingContent.length} items');
    print('- Popular content: ${_popularContent.length} items');
    print('- Should hide Popular/Trending: $_shouldHidePopularAndTrending');
    print('- Sections being shown: ${sections.length}');
    print('- Current filter: $_selectedFilter');
      // Calculate total items being displayed (estimate)
    int totalDisplayedItems = sections.length * 50; // Rough estimate per section
    print('- Estimated total items displayed: $totalDisplayedItems');
  }
  /// Toggle the visibility behavior for Popular/Trending sections
  void togglePopularTrendingVisibility() {
    setState(() {
      _hidePopularAndTrendingWhenLatestPresent = !_hidePopularAndTrendingWhenLatestPresent;
    });
    print('Popular/Trending visibility toggled: ${_hidePopularAndTrendingWhenLatestPresent ? 'Hidden when Latest present' : 'Always shown'}');
  }

  /// Build genre tags section for easy navigation
  Widget _buildGenreSection() {
    final genres = [
      'Action', 'Drama', 'Comedy', 'Thriller', 'Sci-Fi', 
      'Horror', 'Romance', 'Adventure', 'Documentary', 'Animation'
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Browse by Genre',
              style: const TextStyle(
                color: AppTheme.textColorPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFontFamily,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to genre-specific content
                      print('Selected genre: ${genres[index]}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardColor,
                      foregroundColor: AppTheme.textColorPrimary,
                      elevation: 2,
                      shadowColor: AppTheme.cardShadowColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      genres[index],
                      style: const TextStyle(
                        fontFamily: AppTheme.secondaryFontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
          padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textColorPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: AppTheme.primaryFontFamily,
              letterSpacing: 0.3,
            ),
          ),
        ),
        // Fix infinite height constraint with LayoutBuilder for proper sizing
        LayoutBuilder(
          builder: (context, constraints) {
            const int crossAxisCount = 4;
            const double spacing = 8.0;
            const double childAspectRatio = 0.65;
            
            // Calculate item width based on available space
            final double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount + 1))) / crossAxisCount;
            final double itemHeight = itemWidth / childAspectRatio;
            
            // Calculate number of rows
            final int rows = (contentList.length / crossAxisCount).ceil();
            final double totalHeight = (rows * itemHeight) + ((rows - 1) * spacing) + (spacing * 2);
            
            return SizedBox(
              height: totalHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(spacing),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                ),
                itemCount: contentList.length,
                itemBuilder: (context, index) {
                  final content = contentList[index];
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: ContentCard(
                      imageUrl: _getSafeImageUrl(content),
                      title: _getSafeTitle(content),
                      type: _getSafeStringValue(content['type']),
                      year: _getSafeStringValue(content['year']),
                      quality: _getSafeStringValue(content['quality']) ?? 'HD',
                      episodeInfo: content['episode'] != null ? 'E${_getSafeStringValue(content['episode'])}' : null,
                      textOverflow: TextOverflow.ellipsis,
                      maxTitleLines: 2,
                      maintainFixedHeight: true,
                      showDetails: true,
                      showButtons: false, // Remove buttons from regular cards
                      width: itemWidth,
                      height: itemHeight,
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
            );
          },
        ),
        const SizedBox(height: 27), // Maintain the 27px bottom spacing
      ],
    );
  }

  // Helper methods for safe type handling
  String? _getSafeStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is List && value.isNotEmpty) return value.first?.toString();
    return value.toString();
  }
  String _getSafeImageUrl(Map<String, dynamic> content) {
    // Try multiple fields for image URLs
    final thumbNail = _getSafeStringValue(content['thumbNail']);
    final posterUrl = _getSafeStringValue(content['poster_url']);
    final imageUrl = _getSafeStringValue(content['image']);
    final coverUrl = _getSafeStringValue(content['cover']);
    
    String? finalUrl;
    String fieldUsed = 'none';
    
    // Priority order: thumbNail > poster_url > image > cover
    if (thumbNail != null && thumbNail.isNotEmpty) {
      finalUrl = thumbNail;
      fieldUsed = 'thumbNail';
    } else if (posterUrl != null && posterUrl.isNotEmpty) {
      finalUrl = posterUrl;
      fieldUsed = 'poster_url';
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      finalUrl = imageUrl;
      fieldUsed = 'image';
    } else if (coverUrl != null && coverUrl.isNotEmpty) {
      finalUrl = coverUrl;
      fieldUsed = 'cover';
    }
    
    if (finalUrl != null) {
      // Process the URL to ensure it's complete
      String processedUrl = _processImageUrl(finalUrl);
      
      // Debug logging for problematic URLs
      final title = _getSafeTitle(content);
      print('🖼️ Image for "$title": $processedUrl (from $fieldUsed)');
      
      return processedUrl;
    }
    
    // Fallback to placeholder
    final title = _getSafeTitle(content);
    print('⚠️ No image found for "$title" - using placeholder');
    return 'https://via.placeholder.com/600x300/2a2a2a/ffffff?text=${Uri.encodeComponent(title)}';
  }
  String _processImageUrl(String url) {
    // Remove any extra whitespace
    url = url.trim();
    
    // Handle different URL formats
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Filter out problematic URLs that cause image load errors
      if (url.contains('pic.onlinewebfonts.com') || 
          url.endsWith('.svg') || 
          url.contains('onlinewebfonts') ||
          url.contains('.svg?') ||
          url.toLowerCase().contains('svg')) {
        print('⚠️ Filtering out problematic SVG/font URL: $url');
        return 'https://via.placeholder.com/300x450/2a2a2a/ffffff?text=No+Image';
      }
      return url;
    } else if (url.startsWith('/thumbnails/') || url.startsWith('/images/')) {
      return 'https://ethionetflix1.hopto.org$url';
    } else if (url.startsWith('thumbnails/') || url.startsWith('images/')) {
      return 'https://ethionetflix1.hopto.org/$url';
    } else if (!url.startsWith('/') && !url.contains('://')) {
      // Assume it's a relative path
      return 'https://ethionetflix1.hopto.org/thumbnails/$url';
    }
    
    return url;
  }
  String _getSafeTitle(Map<String, dynamic> content) {
    return _getSafeStringValue(content['name']) ??
           _getSafeStringValue(content['seriesName']) ??
           _getSafeStringValue(content['title']) ??
           'No Title';
  }

  String _getSafeFeaturedTitle(Map<String, dynamic> content) {
    return _getSafeStringValue(content['name']) ??
           _getSafeStringValue(content['seriesName']) ??
           _getSafeStringValue(content['title']) ??
           'Featured Content';
  }

  String _getSafeDescription(Map<String, dynamic> content) {
    return _getSafeStringValue(content['description']) ??
           'Discover amazing content in our featured selection.';
  }
}
