import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'dart:async';
import '../config/app_theme.dart';

class VlcControls extends StatefulWidget {
  final VlcPlayerController controller;
  final Function? onBackPressed;

  const VlcControls({
    Key? key,
    required this.controller,
    this.onBackPressed,
  }) : super(key: key);

  @override
  State<VlcControls> createState() => _VlcControlsState();
}

class _VlcControlsState extends State<VlcControls> {
  bool _showControls = true;
  Timer? _hideTimer;
  late VlcPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  void _handleTap() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      _startHideTimer();
    } else {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AbsorbPointer(
        absorbing: !_showControls,
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
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
                      if (widget.onBackPressed != null) {
                        widget.onBackPressed!();
                      }
                    },
                  ),
                ),
              ),

              // Center play/pause button
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 50,
                    padding: const EdgeInsets.all(12),
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlayPause,
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
                      _buildProgressBar(),
                      const SizedBox(height: 8),
                      // Bottom row controls
                      _buildBottomRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildProgressBar() {
    return Container(
      height: 20,
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Progress - use controller value directly
          FractionallySizedBox(
            widthFactor: _controller.value.duration.inMilliseconds > 0 
                ? _controller.value.position.inMilliseconds / _controller.value.duration.inMilliseconds 
                : 0.0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Thumb
          Positioned(
            left: (MediaQuery.of(context).size.width * 
                (_controller.value.duration.inMilliseconds > 0 
                    ? _controller.value.position.inMilliseconds / _controller.value.duration.inMilliseconds 
                    : 0.0)) - 10,
            top: -4,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [        // Current time
        Text(
          _formatDuration(_controller.value.position),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: AppTheme.secondaryFontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
          const Text(
          ' / ',
          style: TextStyle(
            color: Colors.white, 
            fontSize: 14,
            fontFamily: AppTheme.secondaryFontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
          // Total duration
        Text(
          _formatDuration(_controller.value.duration),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: AppTheme.secondaryFontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const Spacer(),
        
        // Playback speed
        IconButton(
          icon: const Icon(Icons.speed, color: Colors.white),
          onPressed: _showPlaybackSpeedDialog,
        ),
        
        // Subtitle control
        IconButton(
          icon: const Icon(Icons.subtitles, color: Colors.white),
          onPressed: _showSubtitleOptions,
        ),
        
        // Full screen toggle
        IconButton(
          icon: const Icon(Icons.fullscreen, color: Colors.white),
          onPressed: () {
            // Already in landscape mode
          },
        ),
      ],
    );
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),        title: const Text(
          'Playback Speed',
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedButton(0.5),
            _buildSpeedButton(0.75),
            _buildSpeedButton(1.0),
            _buildSpeedButton(1.25),
            _buildSpeedButton(1.5),
            _buildSpeedButton(2.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    return TextButton(
      onPressed: () {
        _controller.setPlaybackSpeed(speed);
        Navigator.pop(context);
        _startHideTimer();
      },      child: Text(
        '${speed}x',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: AppTheme.secondaryFontFamily,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSubtitleOptions() {
    // VLC Player can handle subtitles, add options here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),        title: const Text(
          'Subtitles',
          style: TextStyle(
            color: Colors.white,
            fontFamily: AppTheme.primaryFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                // Enable subtitles
                Navigator.pop(context);
                _startHideTimer();
              },              child: const Text(
                'Enable Subtitles',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppTheme.secondaryFontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Disable subtitles
                Navigator.pop(context);
                _startHideTimer();
              },              child: const Text(
                'Disable Subtitles',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppTheme.secondaryFontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
