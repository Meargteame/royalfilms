import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';

class MoviePoster extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const MoviePoster({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {    final bool useNetwork = imageUrl.isNotEmpty && 
        (imageUrl.startsWith('http') || imageUrl.startsWith('https'));
    final bool useAsset = imageUrl.isNotEmpty && 
        imageUrl.startsWith('assets/');

    // For debugging - print the image URL to check if it's valid
    if (useNetwork) {
      debugPrint('Loading image from URL: $imageUrl');
    } else {
      debugPrint('Invalid or empty image URL: "$imageUrl"');
    }

    Widget imageWidget;

    if (useNetwork) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        maxHeightDiskCache: 1500,
        maxWidthDiskCache: 1000,
        memCacheWidth: 800,
        cacheKey: Uri.parse(imageUrl).path, // Use path as cache key to avoid duplicates
        placeholder: (context, url) => placeholder ?? Container(
          width: width,
          height: height,
          color: AppTheme.cardColor,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Error loading image: $url, Error: $error');
          return errorWidget ?? Container(
            width: width,
            height: height,
            color: AppTheme.cardColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.movie,
                    color: AppTheme.textColorSecondary,
                    size: 40,
                  ),
                  if (error.toString() != "404" && error.toString() != "Invalid statusCode: 404")
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        'Loading failed',
                        style: TextStyle(
                          color: AppTheme.textColorSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),          );
        },
      );
    } else if (useAsset) {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset image: $imageUrl, Error: $error');
          return Container(
            width: width,
            height: height,
            color: AppTheme.cardColor,
            child: const Center(
              child: Icon(
                Icons.movie,
                color: AppTheme.textColorSecondary,
                size: 40,
              ),
            ),
          );
        },
      );
    } else {
      imageWidget = Container(
        width: width,
        height: height,
        color: AppTheme.cardColor,
        child: const Icon(
          Icons.movie,
          color: AppTheme.textColorSecondary,
          size: 40,
        ),
      );
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
