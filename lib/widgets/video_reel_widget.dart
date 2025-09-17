import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';
import '../screens/fullscreen_reel_viewer_screen.dart';

class VideoReelWidget extends StatefulWidget {
  final BabaPageReel reel;
  final bool autoplay;
  final bool showFullDetails;
  final VoidCallback? onTap;

  const VideoReelWidget({
    Key? key,
    required this.reel,
    this.autoplay = true, // Enable autoplay by default
    this.showFullDetails = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<VideoReelWidget> createState() => _VideoReelWidgetState();
}

class _VideoReelWidgetState extends State<VideoReelWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      print('VideoReelWidget: Initializing video: ${widget.reel.video.url}');
      print('VideoReelWidget: Autoplay enabled: ${widget.autoplay}');
      
      // Check if URL is valid
      if (widget.reel.video.url.isEmpty) {
        throw Exception('Video URL is empty');
      }
      
      _videoController = VideoPlayerController.network(
        widget.reel.video.url,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      // Set video player configuration
      _videoController!.setVolume(0.0); // Start muted
      _videoController!.setLooping(true);
      
      // Add error listener before initialization
      _videoController!.addListener(_videoListener);
      
      try {
        await _videoController!.initialize();
      } catch (initError) {
        print('VideoReelWidget: Video initialization failed: $initError');
        // Try alternative initialization
        try {
          print('VideoReelWidget: Trying alternative initialization...');
          _videoController?.dispose();
          _videoController = VideoPlayerController.network(
            widget.reel.video.url,
          );
          await _videoController!.initialize();
          print('VideoReelWidget: Alternative initialization successful');
        } catch (altError) {
          print('VideoReelWidget: Alternative initialization also failed: $altError');
          throw initError;
        }
      }
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasError = false;
        });
        
        // Auto-play if enabled - with multiple retry attempts
        if (widget.autoplay) {
          print('VideoReelWidget: Starting autoplay...');
          await _startAutoplayWithRetry();
        }
      }
    } catch (e) {
      print('VideoReelWidget: Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _videoController != null) {
      setState(() {
        _isPlaying = _videoController!.value.isPlaying;
      });
      
      // Check for errors
      if (_videoController!.value.hasError) {
        print('VideoReelWidget: Video error: ${_videoController!.value.errorDescription}');
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _startAutoplayWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries && mounted && !_isPlaying) {
      try {
        await _videoController!.play();
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
        print('VideoReelWidget: Autoplay started successfully (attempt ${retryCount + 1})');
        break;
      } catch (playError) {
        retryCount++;
        print('VideoReelWidget: Autoplay attempt $retryCount failed: $playError');
        
        if (retryCount < maxRetries) {
          // Wait before retrying, with increasing delay
          await Future.delayed(Duration(milliseconds: 300 * retryCount));
        } else {
          print('VideoReelWidget: All autoplay attempts failed');
        }
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _openFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenReelViewerScreen(
          reel: widget.reel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _openFullScreen,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 9 / 16, // Vertical video aspect ratio
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video Player or Thumbnail
                if (_isVideoInitialized && _videoController != null && !_hasError)
                  VideoPlayer(_videoController!)
                else if (_hasError)
                  // Show error state with retry option
                  Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 50,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Video Error',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _isVideoInitialized = false;
                              });
                              _initializeVideo();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Show thumbnail while loading
                  Image.network(
                    widget.reel.thumbnail.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(
                            Icons.video_library,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),

                // Play/Pause Overlay
                if (_isVideoInitialized && !_hasError)
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                // Play Button Overlay (when not initialized or has error)
                if (!_isVideoInitialized || _hasError)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                // Video Info Overlay
                if (widget.showFullDetails) ...[
                  // Top gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
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
                    ),
                  ),

                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Title
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      widget.reel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Stats
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _buildStatItem(Icons.visibility, widget.reel.viewsCount),
                        const SizedBox(width: 16),
                        _buildStatItem(Icons.favorite, widget.reel.likesCount),
                        const SizedBox(width: 16),
                        _buildStatItem(Icons.comment, widget.reel.commentsCount),
                        const Spacer(),
                        if (_isVideoInitialized && !_hasError)
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}



