import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../config/app_theme.dart';
import 'dart:io';

class VideoPlayerScreen extends StatefulWidget {
  final ContentItem content;
  final ApiService apiService;
  final LocalStorageService? localStorageService;
  final bool isOffline;
  final bool isTrailer;
  final String? offlinePath;

  const VideoPlayerScreen({
    Key? key,
    required this.content,
    required this.apiService,
    this.localStorageService,
    this.isOffline = false,
    this.isTrailer = false,
    this.offlinePath,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _initializePlayer();
  }

  @override
  void dispose() {
    _disposePlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _disposePlayer() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      String? videoUrl;

      if (widget.isOffline && widget.offlinePath != null) {
        // Play from local file
        final file = File(widget.offlinePath!);
        if (!file.existsSync()) {
          throw Exception('Offline file not found: ${widget.offlinePath}');        }
        
        _videoPlayerController = VideoPlayerController.file(file);
      } else if (widget.isTrailer && widget.content.trailerUrl != null) {
        // Play trailer
        videoUrl = widget.content.trailerUrl!;
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        // Get streaming URL from API
        videoUrl = await _getStreamingUrl();
        if (videoUrl == null) {
          throw Exception('No valid streaming URL found');
        }
        
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }

      // Initialize video player
      await _videoPlayerController!.initialize();

      // Create Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.primaryColor,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.withOpacity(0.5),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Playback Error',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
        _hasError = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      print('Video player initialization error: $e');
    }
  }

  Future<String?> _getStreamingUrl() async {
    try {
      // Try to get stream URL from API
      final contentId = widget.content.id;
      if (contentId == null) {
        throw Exception('Content ID is required for streaming');
      }      // Try multiple API endpoints
      final apiEndpoints = [
        'https://ethionetflix1.hopto.org/api/content/$contentId/stream',
        'https://ethionetflix1.hopto.org/stream/$contentId',
        'https://ethionetflix1.hopto.org/api/movie/$contentId/play',
      ];

      for (final endpoint in apiEndpoints) {
        try {
          final response = await widget.apiService.getStreamUrl(endpoint);
          if (response != null && response.isNotEmpty) {
            print('✅ Got streaming URL from: $endpoint');
            return response;
          }
        } catch (e) {
          print('❌ Failed to get URL from $endpoint: $e');
          continue;
        }
      }

      // Fallback to direct stream URL
      return 'https://ethionetflix1.hopto.org/stream/$contentId';
      
    } catch (e) {
      print('Error getting streaming URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_chewieController != null) {
      return _buildVideoPlayer();
    }

    return _buildLoadingWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isOffline 
                  ? 'Loading offline video...'
                  : 'Loading video...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.content.title ?? 'Video',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Video Playback Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty 
                    ? _errorMessage 
                    : 'Unable to play this video. Please try again later.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _initializePlayer();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),
        // Back button
        Positioned(
          top: 40,
          left: 16,
          child: SafeArea(
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        ),
        // Title overlay (fades after a few seconds)
        Positioned(
          top: 40,
          right: 16,
          left: 80,
          child: SafeArea(
            child: AnimatedOpacity(
              opacity: _isLoading ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.content.title ?? 'Video',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.content.releaseYear != null)
                      Text(
                        widget.content.releaseYear.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
