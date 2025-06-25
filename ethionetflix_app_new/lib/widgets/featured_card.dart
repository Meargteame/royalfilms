// lib/widgets/featured_card.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'movie_poster.dart';

class FeaturedCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? description;
  final String? type;
  final String? quality;
  final String? year;
  final String? rating;
  final VoidCallback onWatchNow;
  final VoidCallback? onAddToList;
  final double height;

  const FeaturedCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    this.description,
    this.type,
    this.quality,
    this.year,
    this.rating,
    required this.onWatchNow,
    this.onAddToList,
    this.height = 280,
  }) : super(key: key);

  @override
  State<FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (widget.imageUrl.isNotEmpty && 
        (widget.imageUrl.startsWith('http') || widget.imageUrl.startsWith('https')))
        ? widget.imageUrl
        : '';
    final bool useNetwork = posterUrl.isNotEmpty;

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: useNetwork
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.cardColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.cardColor,
                            child: const Icon(
                              Icons.movie,
                              color: AppTheme.textColorSecondary,
                              size: 60,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.cardColor,
                          child: const Icon(
                            Icons.movie,
                            color: AppTheme.textColorSecondary,
                            size: 60,
                          ),
                        ),
                ),

                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Quality Badge
                if (widget.quality != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.quality!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.secondaryFontFamily,
                        ),
                      ),
                    ),
                  ),

                // Rating Badge
                if (widget.rating != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.primaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.secondaryFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content Info
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          fontFamily: AppTheme.primaryFontFamily,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),

                      // Type and Year
                      if (widget.type != null || widget.year != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (widget.type != null) widget.type,
                            if (widget.year != null) widget.year,
                          ].where((e) => e != null).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppTheme.secondaryFontFamily,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Description
                      if (widget.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            height: 1.3,
                            fontFamily: AppTheme.secondaryFontFamily,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          // Watch Now Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: widget.onWatchNow,
                              icon: const Icon(
                                Icons.play_arrow,
                                size: 20,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Watch Now',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.secondaryFontFamily,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // My List Button
                          Expanded(
                            flex: 1,
                            child: OutlinedButton.icon(
                              onPressed: widget.onAddToList ?? () {},
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'My List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTheme.secondaryFontFamily,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white70,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
