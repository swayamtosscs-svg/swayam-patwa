import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';
import '../utils/video_manager.dart';

class SingleVideoWidget extends StatefulWidget {
  final BabaPageReel reel;
  final bool autoplay;
  final VoidCallback? onTap;
  final bool showFullDetails;

  const SingleVideoWidget({
    super.key,
    required this.reel,
    this.autoplay = false,
    this.onTap,
    this.showFullDetails = false,
  });

  @override
  State<SingleVideoWidget> createState() => _SingleVideoWidgetState();
}

class _SingleVideoWidgetState extends State<SingleVideoWidget> {
  late final Player player;
  late final VideoController videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _showControls = true;
  final VideoManager _videoManager = VideoManager();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupVideoManager();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isInitialized) {
      player.dispose();
    }
    super.dispose();
  }

  void _setupVideoManager() {
    _videoManager.setOnVideoStateChanged((videoId) {
      if (videoId == widget.reel.id && !_isDisposed) {
        // This video should play
        if (_isInitialized && !_isPlaying) {
          player.play();
        }
      } else if (videoId != widget.reel.id && !_isDisposed) {
        // Another video is playing, pause this one
        if (_isInitialized && _isPlaying) {
          player.pause();
        }
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      player = Player();
      videoController = VideoController(player);
      
      // Set up event listeners
      player.stream.playing.listen((playing) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });

      player.stream.error.listen((error) {
        if (mounted && !_isDisposed) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        }
      });

      await player.open(Media(widget.reel.video.url));
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        
        // Auto-play if enabled
        if (widget.autoplay) {
          _videoManager.playVideo(widget.reel.id);
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized || _isDisposed) return;
    
    if (_isPlaying) {
      player.pause();
      _videoManager.pauseCurrentVideo();
    } else {
      _videoManager.playVideo(widget.reel.id);
    }
  }

  void _toggleControls() {
    if (!_isDisposed) {
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
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
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Video Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
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
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

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
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Video(
                  controller: videoController,
                  controls: NoVideoControls, // Use custom controls
                  fill: Colors.black,
                ),
              ),
              
              // Play/Pause indicator
              if (!_isPlaying)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),

              // Caption at top
              if (_showControls)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.reel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              // Bottom controls
              if (_showControls)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Like button
                        IconButton(
                          onPressed: () {
                            // Handle like
                          },
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        
                        // Play/Pause button
                        IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        
                        // Share button
                        IconButton(
                          onPressed: () {
                            // Handle share
                          },
                          icon: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
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
}
