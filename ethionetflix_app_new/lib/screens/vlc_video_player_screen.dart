// lib/screens/vlc_video_player_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../config/app_theme.dart';

class VLCVideoPlayer extends StatefulWidget {
  final ContentItem content;
  final ApiService apiService;
  final LocalStorageService? localStorageService;
  final bool isOffline;
  final bool isTrailer;
  final String? offlinePath;

  const VLCVideoPlayer({
    Key? key,
    required this.content,
    required this.apiService,
    this.localStorageService,
    this.isOffline = false,
    this.isTrailer = false,
    this.offlinePath,
  }) : super(key: key);

  @override
  State<VLCVideoPlayer> createState() => _VLCVideoPlayerState();
}

class _VLCVideoPlayerState extends State<VLCVideoPlayer> with SingleTickerProviderStateMixin {
  late VlcPlayerController _vlcPlayerController;
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
    
    // Hide title after 5 seconds
    _titleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _hideTitle = true;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _logMessage('Disposing player controller');
    _vlcPlayerController.dispose();
    _titleTimer?.cancel();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _logMessage(String message) {
    print('VLC Player: $message');
    _logBuffer.write('${DateTime.now()}: $message\n');
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
        final file = File(widget.offlinePath!);
        if (!file.existsSync()) {
          throw Exception('Offline file not found: ${widget.offlinePath}');
        }
        
        _vlcPlayerController = VlcPlayerController.file(
          file,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
            ]),
            subtitle: VlcSubtitleOptions([
              VlcSubtitleOptions.boldStyle(true),
              VlcSubtitleOptions.fontSize(30),
              VlcSubtitleOptions.outlineColor(VlcSubtitleColor.yellow),
              VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
            ]),
            http: VlcHttpOptions([
              VlcHttpOptions.httpReconnect(true),
            ]),
            rtp: VlcRtpOptions([
              VlcRtpOptions.rtpOverRtsp(true),
            ]),
          ),
        );
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
        
        _vlcPlayerController = VlcPlayerController.network(
          videoUrl,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
            ]),
            subtitle: VlcSubtitleOptions([
              VlcSubtitleOptions.boldStyle(true),
              VlcSubtitleOptions.fontSize(30),
              VlcSubtitleOptions.outlineColor(VlcSubtitleColor.yellow),
              VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
            ]),
            http: VlcHttpOptions([
              VlcHttpOptions.httpReconnect(true),
            ]),
            rtp: VlcRtpOptions([
              VlcRtpOptions.rtpOverRtsp(true),
            ]),
          ),
        );
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
        
        _vlcPlayerController = VlcPlayerController.network(
          videoUrl,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
            ]),
            subtitle: VlcSubtitleOptions([
              VlcSubtitleOptions.boldStyle(true),
              VlcSubtitleOptions.fontSize(30),
              VlcSubtitleOptions.outlineColor(VlcSubtitleColor.yellow),
              VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
            ]),
            http: VlcHttpOptions([
              VlcHttpOptions.httpReconnect(true),
            ]),
            rtp: VlcRtpOptions([
              VlcRtpOptions.rtpOverRtsp(true),
            ]),
          ),
        );
        _currentVideoUrl = videoUrl;
      } else {
        // Fallback to a sample video if we can't determine the proper URL
        _logMessage('No valid content ID, using fallback video');
        videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
        
        _vlcPlayerController = VlcPlayerController.network(
          videoUrl,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(),
        );
        _currentVideoUrl = videoUrl;
      }
      
      _logMessage('Initializing VLC controller with URL: $_currentVideoUrl');
      
      // Listen for player errors
      _vlcPlayerController.addOnInitListener(() {
        _logMessage('VLC player initialized');
      });
      
      // Watch player state for errors instead of using event listeners
      _vlcPlayerController.addListener(() {
        if (_vlcPlayerController.value.hasError) {
          String errorMessage = 'Unknown error';
          errorMessage = _vlcPlayerController.value.errorDescription;
          _logMessage('VLC player error: $errorMessage');
          if (!_hasError && !_isRetrying && _retryCount < _maxRetries) {
            _handleVideoError(errorMessage);
          }
        }
      });
      
      setState(() {
        _isLoading = false;
        _retryCount = 0; // Reset retry count on success
      });
    } catch (e) {
      _logMessage('Error initializing VLC player: $e');
      
      if (_retryCount < _maxRetries) {
        await _handleVideoError(e.toString());
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load video after $_maxRetries attempts.\n$e';
        });
      }
    }
  }

  Future<String?> _tryAlternativeFormats(String url) async {
    _logMessage('Trying alternative formats for URL: $url');
    // For different stream formats, try m3u8, mp4, etc.
    final formats = [
      'https://${url.split('://')[1].replaceAll('.mp4', '.m3u8')}',
      'https://${url.split('://')[1].replaceAll('.m3u8', '.mp4')}',
      url.replaceAll('http://', 'https://'),
    ];
    
    for (final format in formats) {
      if (!_attemptedFormats.contains(format)) {
        _attemptedFormats.add(format);
        _logMessage('Trying format: $format');
        
        final result = await widget.apiService.validateStreamUrl(format);
        if (result['isValid'] == true) {
          _logMessage('Alternative format valid: $format');
          return result['url'] as String;
        }
      }
    }
    
    _logMessage('All alternative formats failed');
    return null;
  }

  Future<void> _handleVideoError(String error) async {
    _logMessage('Handling video error: $error');
    
    if (_isRetrying) {
      _logMessage('Already retrying, ignoring duplicate error');
      return;
    }
    
    setState(() {
      _isRetrying = true;
      _hasError = true;
      _errorMessage = 'Video playback error: $error\nRetrying...';
    });
    
    // Wait a moment before retrying
    await Future.delayed(const Duration(seconds: 2));
    
    _retryCount++;
    _logMessage('Retrying playback, attempt $_retryCount of $_maxRetries');
    
    if (_retryCount < _maxRetries) {
      // Try a different format if available
      if (_currentVideoUrl != null) {
        final alternativeUrl = await _tryAlternativeFormats(_currentVideoUrl!);
        if (alternativeUrl != null) {
          // Dispose of the current controller
          await _vlcPlayerController.dispose();
          
          setState(() {
            _isLoading = true;
            _hasError = false;
            _errorMessage = '';
            _currentVideoUrl = alternativeUrl;
          });
          
          // Initialize with the new URL
          await _initializePlayer();
          setState(() {
            _isRetrying = false;
          });
          return;
        }
      }
      
      // If no alternative format worked, just retry with the same URL
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
      
      // Dispose and re-initialize the controller
      await _vlcPlayerController.dispose();
      await _initializePlayer();
      
      setState(() {
        _isRetrying = false;
      });
    } else {
      setState(() {
        _isRetrying = false;
        _errorMessage = 'Failed to play video after $_maxRetries attempts.\n$error';
      });
    }
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('0.5x'),
              onTap: () => _setPlaybackSpeed(0.5),
            ),
            ListTile(
              title: const Text('0.75x'),
              onTap: () => _setPlaybackSpeed(0.75),
            ),
            ListTile(
              title: const Text('Normal (1x)'),
              onTap: () => _setPlaybackSpeed(1.0),
            ),
            ListTile(
              title: const Text('1.25x'),
              onTap: () => _setPlaybackSpeed(1.25),
            ),
            ListTile(
              title: const Text('1.5x'),
              onTap: () => _setPlaybackSpeed(1.5),
            ),
            ListTile(
              title: const Text('2x'),
              onTap: () => _setPlaybackSpeed(2.0),
            ),
          ],
        ),
      ),
    );
  }

  void _setPlaybackSpeed(double speed) {
    _vlcPlayerController.setPlaybackSpeed(speed);
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _hasError
            ? _buildErrorScreen()
            : _isLoading
                ? _buildLoadingScreen()
                : _buildPlayerScreen(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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
            child: const Text('Retry'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _errorMessage = '';
              });
              _vlcPlayerController.dispose();
              _currentVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
              _initializePlayer();
            },
            child: const Text('Try Sample Video'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
          const SizedBox(height: 24),
          if (widget.isOffline)
            TextButton(
              onPressed: () async {
                final contentId = widget.content.id;
                if (contentId != null) {
                  await widget.localStorageService?.deleteDownloadedContent(contentId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deleted offline content')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete Offline Version'),
            ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Debug Info'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentVideoUrl != null)
                          SelectableText(
                            'Current URL: $_currentVideoUrl',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'Format attempts: ${_attemptedFormats.length}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'Retry count: $_retryCount of $_maxRetries',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Debug Log:'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            _logBuffer.toString(),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Show Debug Info',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Loading ${widget.content.title}...',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScreen() {
    return Stack(
      children: [
        // Video player
        Center(
          child: VlcPlayer(
            controller: _vlcPlayerController,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
          ),
        ),
        
        // Custom controls
        _buildCustomControls(),
        
        // Title bar that fades out
        AnimatedOpacity(
          opacity: _hideTitle ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.content.title ?? 'Unknown Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Custom controls for VLC Player
  Widget _buildCustomControls() {
    return ValueListenableBuilder<VlcPlayerValue>(
      valueListenable: _vlcPlayerController,
      builder: (context, value, child) {
        final bool isPlaying = value.isPlaying;
        
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (isPlaying) {
              _vlcPlayerController.pause();
            } else {
              _vlcPlayerController.play();
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Center play/pause button
                Center(
                  child: AnimatedOpacity(
                    opacity: isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom controls
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        ValueListenableBuilder<VlcPlayerValue>(
                          valueListenable: _vlcPlayerController,
                          builder: (context, value, child) {
                            final position = value.position;
                            final duration = value.duration;
                            final progress = duration.inMilliseconds > 0 
                              ? position.inMilliseconds / duration.inMilliseconds 
                              : 0.0;
                            
                            return GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                final box = context.findRenderObject() as RenderBox;
                                final dx = details.localPosition.dx;
                                final width = box.size.width;
                                final position = dx / width;
                                final clampedPosition = position.clamp(0.0, 1.0);
                                
                                final seekMs = (clampedPosition * duration.inMilliseconds).toInt();
                                _vlcPlayerController.setTime(seekMs);
                              },
                              child: Container(
                                height: 20,
                                width: double.infinity,
                                color: Colors.transparent,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Background
                                    Container(
                                      height: 4,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                      // Progress
                                    Container(
                                      height: 4,
                                      width: MediaQuery.of(context).size.width * progress,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    
                                    // Handle
                                    Positioned(
                                      left: MediaQuery.of(context).size.width * progress - 5,
                                      child: Container(
                                        height: 10,
                                        width: 10,                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Time and controls
                        Row(
                          children: [
                            // Current time and total duration
                            ValueListenableBuilder<VlcPlayerValue>(
                              valueListenable: _vlcPlayerController,
                              builder: (context, value, child) {
                                final position = value.position;
                                final duration = value.duration;
                                return Row(
                                  children: [                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    
                                    const Text(
                                      ' / ',
                                      style: TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                    
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            
                            const Spacer(),
                            
                            // Playback speed
                            IconButton(
                              icon: const Icon(Icons.speed, color: Colors.white),
                              onPressed: _showPlaybackSpeedDialog,
                            ),
                            
                            // Full screen toggle
                            IconButton(
                              icon: const Icon(Icons.fullscreen, color: Colors.white),
                              onPressed: () {
                                // Already in landscape mode
                              },
                            ),                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
