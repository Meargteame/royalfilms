import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/content_card.dart';
import '../services/mock_data_service.dart'; // Assuming mock service is used for now
import 'detail_screen.dart'; // Assuming navigation to DetailScreen

class PopularContentScreen extends StatefulWidget {
  final int initialTabIndex;

  const PopularContentScreen({Key? key, this.initialTabIndex = 0})
    : super(key: key);

  @override
  _PopularContentScreenState createState() => _PopularContentScreenState();
}

class _PopularContentScreenState extends State<PopularContentScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _tabs = ['Movies', 'Tv Series'];
  final MockDataService _mockService = MockDataService();

  List<dynamic> _popularMovies = [];
  List<dynamic> _popularTvSeries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadPopularContent();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadPopularContent() {
    // Placeholder: In a real app, fetch popular movies and TV series from an API
    // For now, let's reuse some data or structure from the mock service if possible
    _mockService.init(); // Ensure mock service is initialized
    // Since mockService doesn't have explicit 'popular' endpoints,
    // we'll use a simplified approach or placeholder data for now.
    // Ideally, you'd call something like _mockService.fetchPopularMovies() and _mockService.fetchPopularTvSeries()

    // Using placeholder structure similar to your screenshot
    _popularMovies = [
      {
        'id': '1',
        'title': 'Lilo & Stitch',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Lilo+%26+Stitch',
        'type': 'Movie',
        'quality': 'CAM',
        'release_year': 2002,
        'genres': ['Animation', 'Adventure', 'Comedy'],
        'country': 'United States of America',
      },
      {
        'id': '2',
        'title': 'Minecraft Movie',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Minecraft+Movie',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Family', 'Comedy', 'Adventure'],
        'country': 'United States of America',
      },
      {
        'id': '3',
        'title': 'Final Destination',
        'imageUrl':
            'https://via.placeholder.com/300x450?text=Final+Destination',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2000,
        'genres': ['Horror', 'Thriller'],
        'country': 'United States of America',
      },
      {
        'id': '4',
        'title': 'Until Dawn',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Until+Dawn',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2015,
        'genres': ['Horror', 'Mystery', 'Thriller'],
        'country': 'United States of America',
      },
      {
        'id': '5',
        'title': 'Mission Impossible',
        'imageUrl':
            'https://via.placeholder.com/300x450?text=Mission+Impossible',
        'type': 'Movie',
        'quality': 'CAM',
        'release_year': 1996,
        'genres': ['Action', 'Adventure', 'Thriller'],
        'country': 'United States of America',
      },
      {
        'id': '6',
        'title': 'A Working Man',
        'imageUrl': 'https://via.placeholder.com/300x450?text=A+Working+Man',
        'type': 'Movie',
        'quality': 'HD',
        'release_year': 2025,
        'genres': ['Action', 'Crime', 'Thriller'],
        'country': 'United Kingdom, United States of America',
      },
    ];

    _popularTvSeries = [
      {
        'id': '7',
        'title': 'Sikandar',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Sikandar',
        'type': 'TV Series',
        'quality': 'HD',
        'release_year': 2024,
        'genres': ['Action', 'Adventure'],
        'country': 'India',
      },
      {
        'id': '8',
        'title': 'Fountain of Youth',
        'imageUrl':
            'https://via.placeholder.com/300x450?text=Fountain+of+Youth',
        'type': 'TV Series',
        'quality': 'HD',
        'release_year': 2024,
        'genres': ['Action', 'Comedy', 'Sci-Fi'],
        'country': 'United States of America',
      },
      {
        'id': '9',
        'title': 'Prom Queen',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Prom+Queen',
        'type': 'TV Series',
        'quality': 'HD',
        'release_year': 2024,
        'genres': ['Documentary', 'Crime'],
        'country': 'United States of America',
      },
      {
        'id': '10',
        'title': 'Warfare',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Warfare',
        'type': 'TV Series',
        'quality': 'HD',
        'release_year': 2024,
        'genres': ['Action', 'War'],
        'country': 'United States of America',
      },
      {
        'id': '11',
        'title': 'Legend of Ochi',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Legend+of+Ochi',
        'type': 'Movie', // This might be a movie, adjust if needed
        'quality': 'HD', 'release_year': 2024,
        'genres': ['Drama', 'Fantasy'],
        'country': 'United States of America',
      },
      {
        'id': '12',
        'title': 'Snow White',
        'imageUrl': 'https://via.placeholder.com/300x450?text=Snow+White',
        'type': 'Movie', // This might be a movie, adjust if needed
        'quality': 'HD', 'release_year': 2025,
        'genres': ['Family', 'Fantasy'],
        'country': 'United States of America',
      },
    ];

    setState(() {}); // Update UI after loading data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textColorSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Movies Tab Content
          _buildContentGrid(_popularMovies),
          // TV Series Tab Content
          _buildContentGrid(_popularTvSeries),
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
        childAspectRatio: 0.55, // Adjusted aspect ratio to make cells taller
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
                builder: (context) => DetailScreen(content: item),
              ),
            );
          },
          child: ContentCard(
            imageUrl: item['imageUrl'],
            title: item['title'],
            quality: item['quality'],
            showDetails: true,
            // Let ContentCard size itself based on grid constraints and its internal layout
            // width: 150, // Removed explicit width
            // height: 225, // Removed explicit height
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
