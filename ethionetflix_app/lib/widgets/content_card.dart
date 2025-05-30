// lib/widgets/content_card.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: height * 0.7, // Allocate 70% of card height for the image
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: width,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: width,
                            height: height,
                            color: AppTheme.cardColor,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppTheme.textColorSecondary,
                              size: 40,
                            ),
                          ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: width,
                          height: height,
                          color: AppTheme.cardColor,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
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
                          episodeInfo!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
