// lib/widgets/content_section.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'content_card.dart';

class ContentSection extends StatelessWidget {
  final String title;
  final List<dynamic> contentList;
  final VoidCallback? onSeeAllPressed;
  final bool showSeeAll;
  final double cardWidth;
  final double cardHeight;
  final bool isLoading;

  const ContentSection({
    Key? key,
    required this.title,
    required this.contentList,
    this.onSeeAllPressed,
    this.showSeeAll = true,
    this.cardWidth = 150,
    this.cardHeight = 225,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                ),
              ),
              if (showSeeAll)
                TextButton(
                  onPressed: onSeeAllPressed,
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: cardHeight + (cardHeight * 0.3), // Extra space for the title and details
          child: isLoading
              ? _buildLoadingIndicator()
              : contentList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16),
                      itemCount: contentList.length,
                      itemBuilder: (context, index) {
                        final item = contentList[index];
                        return ContentCard(
                          imageUrl: item['poster_url'] ?? 'https://via.placeholder.com/150x225',
                          title: item['title'] ?? 'No Title',
                          type: item['type'],
                          quality: item['quality'],
                          year: item['release_year']?.toString(),
                          episodeInfo: item['episode_info'],
                          width: cardWidth,
                          height: cardHeight,
                          onTap: () {
                            // Navigate to content detail page
                            // Will be implemented later
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      itemCount: 5, // Show 5 shimmer loading items
      itemBuilder: (context, index) {
        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: cardWidth,
                height: cardHeight,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: cardWidth * 0.8,
                height: 16,
                color: AppTheme.cardColor,
              ),
              const SizedBox(height: 4),
              Container(
                width: cardWidth * 0.5,
                height: 12,
                color: AppTheme.cardColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 48,
            color: AppTheme.textColorTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No content available',
            style: TextStyle(
              color: AppTheme.textColorSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
