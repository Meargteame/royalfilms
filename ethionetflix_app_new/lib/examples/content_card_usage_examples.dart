// lib/examples/content_card_usage_examples.dart
// Complete examples of how to use ContentCard with different text overflow strategies

import 'package:flutter/material.dart';
import '../widgets/content_card.dart';
import '../config/app_theme.dart';

class ContentCardUsageExamples extends StatelessWidget {
  const ContentCardUsageExamples({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Content Card Examples'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExampleSection(
              'Grid Layout (4 columns)',
              _buildGridExample(),
              'Used in: Home screen, category pages',
            ),
            const SizedBox(height: 32),
            _buildExampleSection(
              'Horizontal List Layout',
              _buildHorizontalListExample(),
              'Used in: "Continue Watching", "Trending Now"',
            ),
            const SizedBox(height: 32),
            _buildExampleSection(
              'Large Cards (2 columns)',
              _buildLargeCardsExample(),
              'Used in: Featured content, detailed browsing',
            ),
            const SizedBox(height: 32),
            _buildExampleSection(
              'Compact Cards (5 columns)',
              _buildCompactCardsExample(),
              'Used in: Search results, dense layouts',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleSection(String title, Widget example, String usage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 4),
        Text(
          usage,
          style: const TextStyle(
            color: AppTheme.textColorSecondary,
            fontSize: 12,
            fontFamily: AppTheme.secondaryFontFamily,
          ),
        ),
        const SizedBox(height: 16),
        example,
      ],
    );
  }

  /// Grid layout example - 4 columns like in your home screen
  Widget _buildGridExample() {
    return SizedBox(
      height: 300,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return ContentCard(
            imageUrl: 'https://via.placeholder.com/300x450',
            title: _getSampleTitle(index),
            type: 'Movie',
            year: '2025',
            quality: 'HD',
            textOverflow: TextOverflow.ellipsis,
            maxTitleLines: 2,
            maintainFixedHeight: true,
            showDetails: true,
            onTap: () => _showMessage('Tapped: ${_getSampleTitle(index)}'),
          );
        },
      ),
    );
  }

  /// Horizontal list example
  Widget _buildHorizontalListExample() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 130,
              child: ContentCard(
                imageUrl: 'https://via.placeholder.com/300x450',
                title: _getSampleTitle(index),
                type: 'Series',
                year: '2025',
                quality: 'UHD',
                episodeInfo: 'S1:E${index + 1}',
                textOverflow: TextOverflow.ellipsis,
                maxTitleLines: 2,
                maintainFixedHeight: true,
                showDetails: true,
                width: 130,
                height: 200,
                onTap: () => _showMessage('Tapped: ${_getSampleTitle(index)}'),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Large cards example - 2 columns
  Widget _buildLargeCardsExample() {
    return SizedBox(
      height: 400,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 0.7,
          mainAxisSpacing: 12,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return ContentCard(
            imageUrl: 'https://via.placeholder.com/300x450',
            title: _getSampleTitle(index),
            type: 'Movie',
            year: '2025',
            quality: '4K',
            badge: index == 0 ? 'New' : null,
            textOverflow: TextOverflow.ellipsis,
            maxTitleLines: 3, // More lines for larger cards
            maintainFixedHeight: true,
            showDetails: true,
            width: 200,
            height: 280,
            onTap: () => _showMessage('Tapped: ${_getSampleTitle(index)}'),
          );
        },
      ),
    );
  }

  /// Compact cards example - 5 columns
  Widget _buildCompactCardsExample() {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 4,
          mainAxisSpacing: 6,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return ContentCard(
            imageUrl: 'https://via.placeholder.com/300x450',
            title: _getSampleTitle(index),
            type: 'Movie',
            year: '2025',
            quality: 'HD',
            textOverflow: TextOverflow.ellipsis,
            maxTitleLines: 1, // Single line for compact cards
            maintainFixedHeight: true,
            showDetails: true,
            width: 100,
            height: 150,
            onTap: () => _showMessage('Tapped: ${_getSampleTitle(index)}'),
          );
        },
      ),
    );
  }

  String _getSampleTitle(int index) {
    final titles = [
      'HOW TO TRAIN YOUR DRAGON 2025',
      'THE AMAZING SPIDER-MAN: NO WAY HOME EXTENDED EDITION',
      'BLACK PANTHER: WAKANDA FOREVER DIRECTOR\'S CUT',
      'AVENGERS: ENDGAME ULTIMATE COLLECTION',
      'DUNE: PART TWO EPIC SAGA CONTINUES',
      'JOHN WICK: CHAPTER 4 ACTION THRILLER',
      'TOP GUN: MAVERICK IMAX EXPERIENCE',
      'THOR: LOVE AND THUNDER COSMIC ADVENTURE',
    ];
    return titles[index % titles.length];
  }

  void _showMessage(String message) {
    // In real app, this would navigate or show details
    print(message);
  }
}

/// GridView delegate for responsive columns based on screen size
class ResponsiveGridDelegate extends SliverGridDelegate {
  final double maxCrossAxisExtent;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGridDelegate({
    required this.maxCrossAxisExtent,
    this.childAspectRatio = 0.65,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final crossAxisCount = (constraints.crossAxisExtent / maxCrossAxisExtent).floor().clamp(2, 6);
    
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: (constraints.crossAxisExtent - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount / childAspectRatio + mainAxisSpacing,
      crossAxisStride: (constraints.crossAxisExtent - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount + crossAxisSpacing,
      childMainAxisExtent: (constraints.crossAxisExtent - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount / childAspectRatio,
      childCrossAxisExtent: (constraints.crossAxisExtent - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) => false;
}

/// Utility widget for consistent spacing in content sections
class ContentSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const ContentSection({
    Key? key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppTheme.textColorSecondary,
                        fontSize: 12,
                        fontFamily: AppTheme.secondaryFontFamily,
                      ),
                    ),
                  ],
                ],
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
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
        ...children,
        const SizedBox(height: 27), // Consistent bottom spacing
      ],
    );
  }
}
