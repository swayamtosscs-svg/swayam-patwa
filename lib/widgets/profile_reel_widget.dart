import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/post_model.dart';
import '../screens/post_full_view_screen.dart';
import 'fallback_video_player_widget.dart';

class ProfileReelWidget extends StatefulWidget {
  final Post reel;
  final bool showThumbnail;

  const ProfileReelWidget({
    super.key,
    required this.reel,
    this.showThumbnail = true,
  });

  @override
  State<ProfileReelWidget> createState() => _ProfileReelWidgetState();
}

class _ProfileReelWidgetState extends State<ProfileReelWidget> {
  late final Player player;
  late final VideoController videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _useFallback = false;
  bool _showThumbnail = true;

  @override
  void initState() {
    super.initState();
    _showThumbnail = widget.showThumbnail;
    if (!_showThumbnail) {
      _initializePlayer();
    }
  }

  void _toggleThumbnailVideo() {
    print('ProfileReelWidget: Toggling thumbnail/video. Current thumbnail: $_showThumbnail');
    
    setState(() {
      _showThumbnail = !_showThumbnail;
    });
    
    if (!_showThumbnail && !_isInitialized && !_useFallback) {
      print('ProfileReelWidget: Initializing video player...');
      _initializePlayer();
    } else if (!_showThumbnail && _isInitialized) {
      print('ProfileReelWidget: Video player already initialized, starting playback...');
      // Start playing immediately when switching to video mode
      if (!_isPlaying) {
        _togglePlayPause();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isInitialized) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      print('ProfileReelWidget: Initializing player for reel: ${widget.reel.id}');
      print('ProfileReelWidget: Video URL: ${widget.reel.videoUrl}');
      
      // Validate URL
      if (widget.reel.videoUrl == null || widget.reel.videoUrl!.isEmpty) {
        throw Exception('Video URL is empty for reel: ${widget.reel.id}');
      }
      
      if (!widget.reel.videoUrl!.startsWith('http://') && !widget.reel.videoUrl!.startsWith('https://')) {
        throw Exception('Invalid video URL format: ${widget.reel.videoUrl}');
      }
      
      player = Player();
      videoController = VideoController(player);
      
      // Set up event listeners
      player.stream.playing.listen((playing) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = playing;
          });
          print('ProfileReelWidget: Playing state changed to: $playing for reel: ${widget.reel.id}');
        }
      });

      player.stream.error.listen((error) {
        if (mounted && !_isDisposed) {
          print('ProfileReelWidget: Player error for reel ${widget.reel.id}: $error');
          print('ProfileReelWidget: Switching to fallback player');
          setState(() {
            _useFallback = true;
            _hasError = false;
            _errorMessage = '';
          });
        }
      });

      // Add completion listener
      player.stream.completed.listen((completed) {
        if (mounted && !_isDisposed && completed) {
          print('ProfileReelWidget: Video completed for reel: ${widget.reel.id}');
          // Auto-loop
          player.seek(Duration.zero);
          player.play();
        }
      });

      print('ProfileReelWidget: Opening media for reel: ${widget.reel.id}');
      await player.open(Media(widget.reel.videoUrl!));
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        
        print('ProfileReelWidget: Player initialized successfully for reel: ${widget.reel.id}');
      }
    } catch (e) {
      print('ProfileReelWidget: Initialization error for reel ${widget.reel.id}: $e');
      print('ProfileReelWidget: Switching to fallback player');
      if (mounted && !_isDisposed) {
        setState(() {
          _useFallback = true;
          _hasError = false;
          _errorMessage = '';
        });
      }
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized || _isDisposed) return;
    
    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _navigateToFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostFullViewScreen(post: widget.reel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If showing thumbnail, just show thumbnail with play button
    if (_showThumbnail) {
      return GestureDetector(
        onTap: _toggleThumbnailVideo,
        onDoubleTap: _navigateToFullScreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show thumbnail if available
            if (widget.reel.thumbnailUrl != null && widget.reel.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.reel.thumbnailUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackThumbnail();
                  },
                ),
              )
            else
              _buildFallbackThumbnail(),
            
          ],
        ),
      );
    }

    // Use fallback player if media_kit failed
    if (_useFallback) {
      return GestureDetector(
        onTap: _toggleThumbnailVideo,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fallback video player
              FallbackVideoPlayerWidget(
                videoUrl: widget.reel.videoUrl!,
                autoPlay: false,
                looping: true,
                muted: true, // Audio disabled for profile reels
                showControls: false,
              ),
              
              // Play button overlay
              Center(
                child: GestureDetector(
                  onTap: _navigateToFullScreen,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return GestureDetector(
        onTap: _toggleThumbnailVideo,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
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
                  'Tap to view',
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
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleThumbnailVideo,
      onDoubleTap: _navigateToFullScreen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
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
            
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
