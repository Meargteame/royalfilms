// lib/widgets/content_card.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_theme.dart';
import 'movie_poster.dart';

// Define text styles using AppTheme constants to replace bodyText1, bodyText3, etc.
class CardTextStyles {
  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.w600,
    color: AppTheme.textColorPrimary,
    fontSize: 16,
    fontFamily: AppTheme.secondaryFontFamily,
  );
  
  static const TextStyle subtitle = TextStyle(
    color: AppTheme.textColorSecondary,
    fontSize: 12,
    fontFamily: AppTheme.secondaryFontFamily,
  );
  
  static const TextStyle badge = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    fontFamily: AppTheme.secondaryFontFamily,
  );
  
  static const TextStyle episodeInfo = TextStyle(
    color: AppTheme.primaryColor,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    fontFamily: AppTheme.secondaryFontFamily,
  );
  
  static const TextStyle actionButtonText = TextStyle(
    color: AppTheme.textColorSecondary,
    fontSize: 10,
    fontFamily: AppTheme.secondaryFontFamily,
  );
}

class ContentCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? type;
  final String? quality;
  final String? year;
  final VoidCallback onTap;
  final String? videoUrl;
  final double width;
  final double height;
  final bool showDetails;
  final bool showQuality;
  final String? episodeInfo;
  final String? badge;
  final TextOverflow textOverflow;
  final int maxTitleLines;
  final bool maintainFixedHeight;
  final bool showButtons; // New parameter to control button visibility

  const ContentCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    this.type,
    this.quality,
    this.year,
    required this.onTap,
    this.videoUrl,
    this.width = 150,
    this.height = 210,
    this.showDetails = true,
    this.showQuality = true,
    this.episodeInfo,
    this.badge,
    this.textOverflow = TextOverflow.ellipsis,
    this.maxTitleLines = 2,
    this.maintainFixedHeight = true,
    this.showButtons = false, // Default to false for regular cards
  }) : super(key: key);

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  bool _isTouched = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initAndPlayVideo() {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty || _videoController != null) {
      return;
    }
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
      ..initialize().then((_) {
        if (mounted && (_isHovered || _isTouched)) {
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
          _videoController?.setVolume(0);
        } else {
          _videoController?.dispose();
          _videoController = null;
        }
      });
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
  }

  void _handleHoverEnter() {
    setState(() {
      _isHovered = true;
    });
    _initAndPlayVideo();
    _animationController.forward();
  }

  void _handleHoverExit() {
    setState(() {
      _isHovered = false;
    });
    if (!_isTouched) {
      // Add a small delay before hiding to prevent flickering
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isHovered && !_isTouched) {
          _animationController.reverse();
          _disposeVideo();
        }
      });
    }
  }

  void _handleTouchStart() {
    setState(() {
      _isTouched = true;
    });
    _initAndPlayVideo();
    _animationController.forward();
  }

  void _handleTouchEnd() {
    setState(() {
      _isTouched = false;
    });
    if (!_isHovered) {
      // Add a small delay for better mobile UX
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_isHovered && !_isTouched) {
          _animationController.reverse();
          _disposeVideo();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {    // Fallback logic for missing/invalid poster
    final String posterUrl = (widget.imageUrl.isNotEmpty && (widget.imageUrl.startsWith('http') || widget.imageUrl.startsWith('https')))
        ? widget.imageUrl
        : '';

    return Semantics(
      label: widget.title,
      hint: 'Movie card. ${widget.type ?? ''} ${widget.year ?? ''}. Tap to view details.',
      child: MouseRegion(
        onEnter: (_) => _handleHoverEnter(),
        onExit: (_) => _handleHoverExit(),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _handleTouchStart(),
          onTapUp: (_) => _handleTouchEnd(),
          onTapCancel: () => _handleTouchEnd(),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  // Fixed dimensions for consistent card sizing
                  width: widget.width == 150 ? null : widget.width,
                  height: widget.maintainFixedHeight ? widget.height : null,
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  decoration: AppTheme.movieCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      // Image container with fixed aspect ratio - takes most of the space
                      Expanded(
                        flex: 10, // Image container, takes most of the space
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: ((_isHovered || _isTouched) &&
                                      _videoController != null &&
                                      _videoController!.value.isInitialized)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(widget.showDetails ? 0 : 16),
                                        bottomRight: Radius.circular(widget.showDetails ? 0 : 16),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _videoController!.value.size.width,
                                          height: _videoController!.value.size.height,
                                          child: VideoPlayer(_videoController!),
                                        ),
                                      ),
                                    )
                                  : MoviePoster(
                                      imageUrl: posterUrl,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(widget.showDetails ? 0 : 16),
                                        bottomRight: Radius.circular(widget.showDetails ? 0 : 16),
                                      ),
                                    ),
                            ),
                            if (_isHovered || _isTouched)
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(widget.showDetails ? 0 : 16),
                                      bottomRight: Radius.circular(widget.showDetails ? 0 : 16),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.5],
                                    ),
                                  ),
                                ),
                              ),
                            // Quality tag (HD, SD, CAM)
                            if (widget.showQuality && widget.quality != null && widget.quality!.isNotEmpty)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),                                  child: Text(
                                    widget.quality!,
                                    style: CardTextStyles.badge,
                                  ),
                                ),
                              ),

                            // Badge (Downloaded, New, etc.)
                            if (widget.badge != null)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),                                  child: Text(
                                    widget.badge!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: AppTheme.secondaryFontFamily,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),                      // Bottom details section with strict height constraints to prevent overflow
                      if (widget.showDetails)
                        Container(
                          height: widget.height * (widget.showButtons ? 0.35 : 0.28), // Dynamically adjust height to prevent overflow
                          width: double.infinity,
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title with strict height constraint
                              SizedBox(
                                height: 24, // Fixed height for title (2 lines max)
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColorPrimary,
                                    fontSize: 11,
                                    fontFamily: AppTheme.secondaryFontFamily,
                                    height: 1.1, // Tight line height
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 1),
                              // Type and year with strict height constraint
                              SizedBox(
                                height: 11, // Fixed height for one line
                                child: Row(
                                  children: [
                                    if (widget.type != null)
                                      Flexible(
                                        child: Text(
                                          widget.type!,
                                          style: const TextStyle(
                                            color: AppTheme.textColorSecondary,
                                            fontSize: 9,
                                            fontFamily: AppTheme.secondaryFontFamily,
                                            height: 1.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    if (widget.type != null && widget.year != null)
                                      const Text(
                                        ' • ',
                                        style: TextStyle(
                                          color: AppTheme.textColorSecondary,
                                          fontSize: 9,
                                          height: 1.0,
                                        ),
                                      ),
                                    if (widget.year != null)
                                      Flexible(
                                        child: Text(
                                          widget.year!,
                                          style: const TextStyle(
                                            color: AppTheme.textColorSecondary,
                                            fontSize: 9,
                                            fontFamily: AppTheme.secondaryFontFamily,
                                            height: 1.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Episode info with strict height constraint
                              if (widget.episodeInfo != null)
                                Container(
                                  height: 11,
                                  margin: const EdgeInsets.only(top: 1.0),
                                  child: Text(
                                    widget.episodeInfo!,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                      fontFamily: AppTheme.secondaryFontFamily,
                                      height: 1.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              // Buttons (only if space allows and no episode info)
                              if (widget.showButtons && widget.episodeInfo == null)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildActionButton(Icons.play_arrow, 'Play'),
                                        _buildActionButton(Icons.info_outline, 'Info'),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textColorPrimary, size: 18),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textColorSecondary,
            fontSize: 8,
            fontFamily: AppTheme.secondaryFontFamily,
          ),
        ),
      ],
    );
  }
}