import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';

class InAppVideoWidget extends StatefulWidget {
  final BabaPageReel reel;
  final bool autoplay;
  final bool showFullDetails;
  final VoidCallback? onTap;

  const InAppVideoWidget({
    Key? key,
    required this.reel,
    this.autoplay = false,
    this.showFullDetails = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<InAppVideoWidget> createState() => _InAppVideoWidgetState();
}

class _InAppVideoWidgetState extends State<InAppVideoWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _hasError = false;
  Timer? _autoplayTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force autoplay when widget becomes visible
    if (widget.autoplay && _isVideoInitialized && !_isPlaying && !_hasError) {
      _forcePlay();
    }
  }

  void _forcePlay() async {
    if (_videoController != null && _isVideoInitialized) {
      try {
        print('InAppVideoWidget: Force playing video...');
        await _videoController!.play();
        setState(() {
          _isPlaying = true;
        });
        print('InAppVideoWidget: Force play successful');
      } catch (e) {
        print('InAppVideoWidget: Force play failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      print('InAppVideoWidget: Initializing video: ${widget.reel.video.url}');
      print('InAppVideoWidget: Autoplay enabled: ${widget.autoplay}');
      print('InAppVideoWidget: Video format: ${widget.reel.video.mimeType}');
      
      // Check if the video URL is valid
      if (widget.reel.video.url.isEmpty) {
        throw Exception('Video URL is empty');
      }
      
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.video.url),
      );
      
      // Set video player configuration for better compatibility
      _videoController!.setVolume(1.0);
      
      // Add error handling for initialization
      try {
        await _videoController!.initialize();
      } catch (initError) {
        print('InAppVideoWidget: Video initialization failed: $initError');
        throw initError;
      }
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        print('InAppVideoWidget: Video initialized successfully');
        
        // Add listener for video state changes
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _videoController!.value.isPlaying;
            });
          }
        });
        
        // Auto-play if enabled
        if (widget.autoplay) {
          print('InAppVideoWidget: Starting autoplay...');
          _videoController!.setLooping(true); // Enable looping for better autoplay
          
          // Start autoplay timer
          _autoplayTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
            if (_isPlaying || _hasError) {
              timer.cancel();
              return;
            }
            _forcePlay();
          });
          
          // Add a small delay to ensure video is ready
          await Future.delayed(const Duration(milliseconds: 500));
          
          try {
            await _videoController!.play();
            setState(() {
              _isPlaying = true;
            });
            _autoplayTimer?.cancel();
            print('InAppVideoWidget: Autoplay started successfully');
          } catch (playError) {
            print('InAppVideoWidget: Error starting autoplay: $playError');
            // Try again after a longer delay
            await Future.delayed(const Duration(milliseconds: 1000));
            try {
              await _videoController!.play();
              setState(() {
                _isPlaying = true;
              });
              _autoplayTimer?.cancel();
              print('InAppVideoWidget: Autoplay started on retry');
            } catch (retryError) {
              print('InAppVideoWidget: Failed to start autoplay after retry: $retryError');
            }
          }
        }
      }
    } catch (e) {
      print('InAppVideoWidget: Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _toggleControls,
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
                else
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

                // Play Button Overlay (when not playing or not initialized)
                if (!_isPlaying || !_isVideoInitialized || _hasError)
                  Center(
                    child: GestureDetector(
                      onTap: _hasError ? null : _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _hasError ? Icons.error : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
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
                        // Play/Pause button
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
