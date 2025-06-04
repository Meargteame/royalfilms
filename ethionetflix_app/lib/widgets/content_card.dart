// lib/widgets/content_card.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Corrected Import

class ContentCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? type;
  final String? quality;
  final String? year;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool showDetails;
  final bool showQuality;
  final String? episodeInfo;
  final String? badge;

  const ContentCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    this.type,
    this.quality,
    this.year,
    required this.onTap,
    this.width = 150,
    this.height = 210,
    this.showDetails = true,
    this.showQuality = true,
    this.episodeInfo,
    this.badge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug print statements to diagnose rendering issues
    print('ContentCard - imageUrl: "$imageUrl"');
    print('ContentCard - title: "$title"');
    print('ContentCard - quality: "$quality"');
    print('ContentCard - type: "$type"');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: height * 0.7, // Allocate 70% of card height for the image
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (imageUrl.isNotEmpty) // Check if imageUrl is not empty
                        ? CachedNetworkImage(
                            // Use CachedNetworkImage for better handling and caching
                            imageUrl: imageUrl,
                            width: width,
                            height: height * 0.7, // Ensure height is applied
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: width,
                              height: height * 0.7,
                              color: AppTheme.cardColor,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: width,
                              height: height * 0.7,
                              color: AppTheme.cardColor,
                              child: const Icon(
                                Icons.broken_image,
                                color: AppTheme.textColorSecondary,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            // Show placeholder if imageUrl is empty
                            width: width,
                            height: height * 0.7,
                            color: AppTheme.cardColor,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppTheme.textColorSecondary,
                              size: 40,
                            ),
                          ),
                  ),
                ),

                // Quality tag (HD, SD, CAM)
                if (showQuality && quality != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        quality!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Episode info for series (S1:E8, etc.)
                if (episodeInfo != null)
                  Positioned(
                    top: quality != null && showQuality ? 34 : 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        episodeInfo!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Badge (Downloaded, New, etc.)
                if (badge != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
              
            if (showDetails) ...[

              const SizedBox(height: 6),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textColorPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      if (type != null || year != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (type != null) type,
                            if (year != null) year,
                          ].where((e) => e != null).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textColorSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
