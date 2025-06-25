// lib/examples/redesigned_layout_example.dart
// Complete example of the redesigned content layout with featured section

import 'package:flutter/material.dart';
import '../widgets/featured_card.dart';
import '../widgets/content_card.dart';
import '../config/app_theme.dart';

class RedesignedLayoutExample extends StatelessWidget {
  const RedesignedLayoutExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Redesigned Layout'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Section
            _buildFeaturedSection(),
            
            // Regular Content Sections
            _buildContentSection('Latest Movies', _getMovieData()),
            _buildContentSection('TV Series', _getSeriesData()),
            _buildContentSection('Trending Now', _getTrendingData()),
            
            const SizedBox(height: 80), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
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
          imageUrl: 'https://via.placeholder.com/600x300',
          title: 'HOW TO TRAIN YOUR DRAGON 2025: THE EPIC CONCLUSION',
          description: 'Join Hiccup and Toothless in their final adventure as they discover new worlds and face their greatest challenge yet in this stunning conclusion to the beloved trilogy.',
          type: 'Movie',
          year: '2025',
          quality: '4K',
          rating: '9.2',
          height: 280,
          onWatchNow: () => _showMessage('Playing featured content'),
          onAddToList: () => _showMessage('Added to My List'),
        ),
        const SizedBox(height: 27),
      ],
    );
  }

  Widget _buildContentSection(String title, List<Map<String, dynamic>> contentList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textColorPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTheme.primaryFontFamily,
                ),
              ),
              TextButton(
                onPressed: () => _showMessage('See All $title'),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.secondaryFontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Responsive grid layout
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.65,
            crossAxisSpacing: 6,
            mainAxisSpacing: 8,
          ),
          itemCount: contentList.length,
          itemBuilder: (context, index) {
            final content = contentList[index];
            return ContentCard(
              imageUrl: content['imageUrl'] ?? 'https://via.placeholder.com/300x450',
              title: content['title'] ?? 'No Title',
              type: content['type'],
              year: content['year'],
              quality: content['quality'] ?? 'HD',
              episodeInfo: content['episodeInfo'],
              textOverflow: TextOverflow.ellipsis,
              maxTitleLines: 2,
              maintainFixedHeight: true,
              showDetails: true,
              showButtons: false, // No buttons on regular cards
              onTap: () => _showMessage('Tapped: ${content['title']}'),
            );
          },
        ),
        const SizedBox(height: 27),
      ],
    );
  }

  List<Map<String, dynamic>> _getMovieData() {
    return [
      {
        'title': 'THE AMAZING SPIDER-MAN: NO WAY HOME EXTENDED EDITION',
        'type': 'Movie',
        'year': '2025',
        'quality': '4K',
        'imageUrl': 'https://via.placeholder.com/300x450/FF6B35/FFFFFF?text=SPIDER-MAN',
      },
      {
        'title': 'BLACK PANTHER: WAKANDA FOREVER DIRECTOR\'S CUT',
        'type': 'Movie',
        'year': '2025',
        'quality': 'UHD',
        'imageUrl': 'https://via.placeholder.com/300x450/663399/FFFFFF?text=BLACK+PANTHER',
      },
      {
        'title': 'AVENGERS: ENDGAME ULTIMATE COLLECTION',
        'type': 'Movie',
        'year': '2024',
        'quality': 'HD',
        'imageUrl': 'https://via.placeholder.com/300x450/0066CC/FFFFFF?text=AVENGERS',
      },
      {
        'title': 'DUNE: PART TWO EPIC SAGA CONTINUES',
        'type': 'Movie',
        'year': '2025',
        'quality': '4K',
        'imageUrl': 'https://via.placeholder.com/300x450/CC6600/FFFFFF?text=DUNE',
      },
      {
        'title': 'JOHN WICK: CHAPTER 4 ACTION THRILLER',
        'type': 'Movie',
        'year': '2024',
        'quality': 'HD',
        'imageUrl': 'https://via.placeholder.com/300x450/333333/FFFFFF?text=JOHN+WICK',
      },
      {
        'title': 'TOP GUN: MAVERICK IMAX EXPERIENCE',
        'type': 'Movie',
        'year': '2024',
        'quality': 'UHD',
        'imageUrl': 'https://via.placeholder.com/300x450/006633/FFFFFF?text=TOP+GUN',
      },
      {
        'title': 'THOR: LOVE AND THUNDER COSMIC ADVENTURE',
        'type': 'Movie',
        'year': '2024',
        'quality': 'HD',
        'imageUrl': 'https://via.placeholder.com/300x450/9900CC/FFFFFF?text=THOR',
      },
      {
        'title': 'FAST X: THE ULTIMATE RIDE CONTINUES',
        'type': 'Movie',
        'year': '2025',
        'quality': '4K',
        'imageUrl': 'https://via.placeholder.com/300x450/FF3366/FFFFFF?text=FAST+X',
      },
    ];
  }

  List<Map<String, dynamic>> _getSeriesData() {
    return [
      {
        'title': 'STRANGER THINGS: FINAL SEASON EPIC CONCLUSION',
        'type': 'Series',
        'year': '2025',
        'quality': '4K',
        'episodeInfo': 'S5:E1',
        'imageUrl': 'https://via.placeholder.com/300x450/990000/FFFFFF?text=STRANGER+THINGS',
      },
      {
        'title': 'THE MANDALORIAN: NEW ADVENTURES AWAIT',
        'type': 'Series',
        'year': '2025',
        'quality': 'UHD',
        'episodeInfo': 'S4:E3',
        'imageUrl': 'https://via.placeholder.com/300x450/003366/FFFFFF?text=MANDALORIAN',
      },
      {
        'title': 'HOUSE OF THE DRAGON: FIRE AND BLOOD',
        'type': 'Series',
        'year': '2024',
        'quality': 'HD',
        'episodeInfo': 'S2:E8',
        'imageUrl': 'https://via.placeholder.com/300x450/660000/FFFFFF?text=HOUSE+DRAGON',
      },
      {
        'title': 'THE WITCHER: CONTINENT OF MAGIC',
        'type': 'Series',
        'year': '2024',
        'quality': '4K',
        'episodeInfo': 'S3:E5',
        'imageUrl': 'https://via.placeholder.com/300x450/666600/FFFFFF?text=WITCHER',
      },
      {
        'title': 'WEDNESDAY: ADDAMS FAMILY MYSTERIES',
        'type': 'Series',
        'year': '2025',
        'quality': 'HD',
        'episodeInfo': 'S2:E2',
        'imageUrl': 'https://via.placeholder.com/300x450/330033/FFFFFF?text=WEDNESDAY',
      },
      {
        'title': 'EUPHORIA: TEEN DRAMA CONTINUES',
        'type': 'Series',
        'year': '2024',
        'quality': 'UHD',
        'episodeInfo': 'S3:E1',
        'imageUrl': 'https://via.placeholder.com/300x450/FF3399/FFFFFF?text=EUPHORIA',
      },
      {
        'title': 'OZARK: CRIME FAMILY SAGA FINALE',
        'type': 'Series',
        'year': '2024',
        'quality': 'HD',
        'episodeInfo': 'S4:E14',
        'imageUrl': 'https://via.placeholder.com/300x450/003300/FFFFFF?text=OZARK',
      },
      {
        'title': 'SUCCESSION: POWER STRUGGLE DRAMA',
        'type': 'Series',
        'year': '2024',
        'quality': '4K',
        'episodeInfo': 'S4:E10',
        'imageUrl': 'https://via.placeholder.com/300x450/336699/FFFFFF?text=SUCCESSION',
      },
    ];
  }

  List<Map<String, dynamic>> _getTrendingData() {
    return [
      {
        'title': 'GLASS ONION: A KNIVES OUT MYSTERY',
        'type': 'Movie',
        'year': '2024',
        'quality': '4K',
        'imageUrl': 'https://via.placeholder.com/300x450/FF9900/FFFFFF?text=GLASS+ONION',
      },
      {
        'title': 'THE CROWN: ROYAL FAMILY DRAMA',
        'type': 'Series',
        'year': '2024',
        'quality': 'UHD',
        'episodeInfo': 'S6:E4',
        'imageUrl': 'https://via.placeholder.com/300x450/6600CC/FFFFFF?text=THE+CROWN',
      },
      {
        'title': 'BABYLON: HOLLYWOOD GOLDEN AGE',
        'type': 'Movie',
        'year': '2024',
        'quality': 'HD',
        'imageUrl': 'https://via.placeholder.com/300x450/CCCC00/FFFFFF?text=BABYLON',
      },
      {
        'title': 'THE BEAR: KITCHEN CHAOS COMEDY',
        'type': 'Series',
        'year': '2025',
        'quality': '4K',
        'episodeInfo': 'S3:E6',
        'imageUrl': 'https://via.placeholder.com/300x450/CC3300/FFFFFF?text=THE+BEAR',
      },
    ];
  }

  void _showMessage(String message) {
    print('Action: $message');
  }
}

/// Design Guidelines and Best Practices
class ContentLayoutGuidelines {
  // FEATURED CARD SPECIFICATIONS
  static const double featuredCardHeight = 280;
  static const int featuredTitleMaxLines = 2;
  static const int featuredDescriptionMaxLines = 2;
  
  // REGULAR CARD SPECIFICATIONS  
  static const double regularCardAspectRatio = 0.65;
  static const int regularTitleMaxLines = 2;
  static const bool regularCardsShowButtons = false;
  
  // GRID LAYOUT SPECIFICATIONS
  static const int gridCrossAxisCount = 4;
  static const double gridCrossAxisSpacing = 6;
  static const double gridMainAxisSpacing = 8;
  static const double sectionBottomSpacing = 27;
  
  // RESPONSIVE BREAKPOINTS
  static int getGridColumns(double screenWidth) {
    if (screenWidth < 600) return 3;      // Mobile portrait
    if (screenWidth < 900) return 4;      // Mobile landscape / Small tablet
    if (screenWidth < 1200) return 5;     // Tablet
    return 6;                             // Desktop
  }
  
  // TEXT OVERFLOW STRATEGIES
  static const Map<String, TextOverflowStrategy> textStrategies = {
    'compact': TextOverflowStrategy(maxLines: 1, fontSize: 11),
    'standard': TextOverflowStrategy(maxLines: 2, fontSize: 12),
    'detailed': TextOverflowStrategy(maxLines: 3, fontSize: 13),
  };
}

class TextOverflowStrategy {
  final int maxLines;
  final double fontSize;
  
  const TextOverflowStrategy({
    required this.maxLines,
    required this.fontSize,
  });
}

/// Responsive Content Grid Widget
class ResponsiveContentGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onItemTap;
  
  const ResponsiveContentGrid({
    Key? key,
    required this.items,
    required this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ContentLayoutGuidelines.getGridColumns(constraints.maxWidth);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: ContentLayoutGuidelines.regularCardAspectRatio,
            crossAxisSpacing: ContentLayoutGuidelines.gridCrossAxisSpacing,
            mainAxisSpacing: ContentLayoutGuidelines.gridMainAxisSpacing,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ContentCard(
              imageUrl: item['imageUrl'] ?? 'https://via.placeholder.com/300x450',
              title: item['title'] ?? 'No Title',
              type: item['type'],
              year: item['year'],
              quality: item['quality'] ?? 'HD',
              episodeInfo: item['episodeInfo'],
              textOverflow: TextOverflow.ellipsis,
              maxTitleLines: ContentLayoutGuidelines.regularTitleMaxLines,
              maintainFixedHeight: true,
              showDetails: true,
              showButtons: ContentLayoutGuidelines.regularCardsShowButtons,
              onTap: () => onItemTap(item),
            );
          },
        );
      },
    );
  }
}
