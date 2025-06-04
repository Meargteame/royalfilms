// lib/screens/video_player_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../config/app_theme.dart';

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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  final int _maxRetries = 3;
  String? _currentVideoUrl;
  final List<String> _attemptedFormats = [];
  bool _isRetrying = false;
  
  // Title animation variables
  bool _hideTitle = false;
  double _titleOpacity = 1.0;
  Timer? _titleTimer;
  
  // Detailed logging
  final StringBuffer _logBuffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializePlayer();
    
    // Set up title animation - show title for 5 seconds then fade out
    _titleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _titleOpacity = 0.0;
        });
        
        // Hide completely after fade animation completes
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _hideTitle = true;
            });
          }
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      _logMessage('Initializing player with content: ${widget.content.toJson()}');
      _logMessage('isOffline: ${widget.isOffline}, offlinePath: ${widget.offlinePath}');
      _logMessage('isTrailer: ${widget.isTrailer}');
      _logMessage('Retry count: $_retryCount of $_maxRetries');
      
      String? videoUrl;
      
      if (widget.isOffline && widget.offlinePath != null) {
        _logMessage('Playing from local file: ${widget.offlinePath}');
        final file = await _getOfflineVideoFile(widget.offlinePath!);
        if (!file.existsSync()) {
          throw Exception('Offline file not found: ${widget.offlinePath}');
        }
        
        _videoPlayerController = VideoPlayerController.file(file);
        _currentVideoUrl = file.path;
      } else if (widget.isTrailer && widget.content.trailerUrl != null) {
        // Use the trailer URL directly if this is a trailer
        videoUrl = widget.content.trailerUrl!;
        _logMessage('Playing trailer from: $videoUrl');
        
        // Validate trailer URL
        final validationResult = await widget.apiService.validateStreamUrl(videoUrl);
        _logMessage('Trailer URL validation result: ${validationResult['message']}');
        
        if (validationResult['isValid'] == true) {
          videoUrl = validationResult['url'] as String;
        } else {
          // If validation fails, try alternative URLs or formats
          videoUrl = await _tryAlternativeFormats(videoUrl) ?? 
              validationResult['fallbackUrl'] as String;
        }
        
        _videoPlayerController = VideoPlayerController.network(videoUrl);
        _currentVideoUrl = videoUrl;
      } else if (widget.content.id != null && widget.content.id!.isNotEmpty) {
        // Use API service to get the stream URL for normal content
        final contentId = widget.content.id!;
        final collectionId = widget.content.collectionId ?? 'all';
        
        _logMessage('Getting stream URL for contentId: $contentId, collectionId: $collectionId');
        videoUrl = widget.apiService.getVideoStreamUrl(contentId, collectionId);
        _logMessage('Generated stream URL: $videoUrl');
        
        // Validate the stream URL
        final validationResult = await widget.apiService.validateStreamUrl(videoUrl);
        _logMessage('Stream URL validation result: ${validationResult['message']}');
        
        if (validationResult['isValid'] == true) {
          videoUrl = validationResult['url'] as String;
          _logMessage('Using validated URL: $videoUrl');
        } else {
          // If validation fails, try alternative URLs or formats
          _logMessage('Stream validation failed, trying alternative formats');
          videoUrl = await _tryAlternativeFormats(videoUrl) ?? 
              validationResult['fallbackUrl'] as String;
        }
        
        _videoPlayerController = VideoPlayerController.network(videoUrl);
        _currentVideoUrl = videoUrl;
      } else {
        // Fallback to a sample video if we can't determine the proper URL
        _logMessage('No valid content ID, using fallback video');
        videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
        _videoPlayerController = VideoPlayerController.network(videoUrl);
        _currentVideoUrl = videoUrl;
      }

      _logMessage('Initializing video controller with URL: $_currentVideoUrl');
      
      // Set up error listener before initialization
      _videoPlayerController.addListener(() {
        final error = _videoPlayerController.value.errorDescription;
        if (error != null && error.isNotEmpty && !_hasError) {
          _logMessage('Video player error: $error');
          if (!_isRetrying && _retryCount < _maxRetries) {
            _handleVideoError(error);
          }
        }
      });
      
      await _videoPlayerController.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _logMessage('Video initialization timed out');
          throw TimeoutException('Video initialization timed out');
        },
      );
      
      _logMessage('Video initialized successfully. Duration: ${_videoPlayerController.value.duration}');
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        placeholder: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.primaryColor,
          backgroundColor: AppTheme.surfaceColor,
          bufferedColor: AppTheme.textColorSecondary,
        ),
        errorBuilder: (context, errorMessage) {
          _logMessage('Chewie error: $errorMessage');
          return _buildErrorWidget();
        },
      );

      setState(() {
        _isLoading = false;
        _retryCount = 0; // Reset retry count on success
      });
    } catch (e) {
      _logMessage('Error initializing video player: $e');
      
      if (_retryCount < _maxRetries) {
        await _handleVideoError(e.toString());
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load video after $_maxRetries attempts: $e';
        });
      }
    }
  }
  
  // New method to handle video errors with retry logic
  Future<void> _handleVideoError(String error) async {
    _logMessage('Handling video error with retry mechanism. Error: $error');
    setState(() {
      _isRetrying = true;
      _retryCount++;
      _isLoading = true;
    });
    
    // Clean up current controllers before retrying
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    
    // Short delay before retry
    await Future.delayed(const Duration(seconds: 1));
    
    _logMessage('Retrying video initialization (Attempt $_retryCount of $_maxRetries)');
    setState(() {
      _isRetrying = false;
    });
    
    // Retry initialization
    _initializePlayer();
  }
  
  // New method to try alternative formats
  Future<String?> _tryAlternativeFormats(String originalUrl) async {
    _logMessage('Trying alternative formats for: $originalUrl');
    
    // Record this format as attempted
    _attemptedFormats.add(originalUrl);
    
    // Try different formats
    final formatVariations = [
      // HLS format
      originalUrl.contains('format=') 
          ? originalUrl.replaceAll(RegExp(r'format=[^&]+'), 'format=hls') 
          : '$originalUrl&format=hls',
      
      // MP4 direct format
      originalUrl.contains('format=') 
          ? originalUrl.replaceAll(RegExp(r'format=[^&]+'), 'format=mp4') 
          : '$originalUrl&format=mp4',
      
      // Try different quality settings
      '$originalUrl&quality=720p',
      '$originalUrl&quality=480p',
      '$originalUrl&quality=360p',
      
      // Try download endpoint instead of stream
      originalUrl.replaceAll('/stream?', '/download?'),
      
      // Try direct CDN access if applicable
      originalUrl.contains('ethionetflix.hopto.org') 
          ? originalUrl.replaceAll('ethionetflix.hopto.org', 'cdn.ethionetflix.hopto.org') 
          : originalUrl,
    ];
    
    // Only try formats we haven't tried yet
    final untried = formatVariations.where((url) => !_attemptedFormats.contains(url)).toList();
    
    for (final altUrl in untried) {
      _logMessage('Trying alternative format: $altUrl');
      _attemptedFormats.add(altUrl);
      
      try {
        final validationResult = await widget.apiService.validateStreamUrl(altUrl);
        if (validationResult['isValid'] == true) {
          _logMessage('Found working alternative format: $altUrl');
          return validationResult['url'] as String;
        }
      } catch (e) {
        _logMessage('Error checking alternative format $altUrl: $e');
      }
    }
    
    _logMessage('No working alternative formats found');
    return null;
  }
  
  // Helper method for logging
  void _logMessage(String message) {
    final timestamp = DateTime.now().toString();
    final logMessage = '[$timestamp] $message';
    print(logMessage);
    _logBuffer.writeln(logMessage);
  }

  Future<File> _getOfflineVideoFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('File does not exist at path: $path');
      }
      return file;
    } catch (e) {
      print('Error loading offline video file: $e');
      throw FileSystemException('Failed to load offline video: $e');
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _titleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : _hasError
                ? _buildErrorWidget()
                : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        // Main video player
        Center(
          child: AspectRatio(
            aspectRatio: _videoPlayerController.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          ),
        ),
        // Back button
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        // Video title (shown briefly and then fades out)
        if (!_hideTitle)
          Positioned(
            top: 16,
            left: 70,
            right: 16,
            child: AnimatedOpacity(
              opacity: _titleOpacity,
              duration: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.content.title ?? 'Unknown Title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Playback Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Troubleshooting Information:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentVideoUrl != null)
                      Text(
                        'Current URL: $_currentVideoUrl',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Format attempts: ${_attemptedFormats.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Retry count: $_retryCount of $_maxRetries',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                        _errorMessage = '';
                        _retryCount = 0; // Reset retry counter
                        _attemptedFormats.clear(); // Clear format attempts
                      });
                      _initializePlayer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Try with fallback
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                        _errorMessage = '';
                      });
                      _videoPlayerController.dispose();
                      _chewieController?.dispose();
                      _videoPlayerController = VideoPlayerController.network(
                        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
                      );
                      _currentVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
                      _initializePlayer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: const Text('Try Sample Video'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text(
                  'View Debug Logs',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                children: [
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _logBuffer.toString(),
                        style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 10),
                      ),
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
}
