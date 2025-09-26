import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final bool showControls;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
    this.muted = false, // Changed default to false for audio
    this.showControls = true, // Added controls option
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player player;
  late final VideoController videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPlaying = false;
  bool _isDisposed = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _showControls = widget.showControls;
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl && !_isDisposed) {
      _loadNewVideo();
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

      await player.open(Media(widget.videoUrl));
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        
        if (widget.autoPlay) {
          player.play();
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

  Future<void> _loadNewVideo() async {
    try {
      await player.open(Media(widget.videoUrl));
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
        
        if (widget.autoPlay) {
          player.play();
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
    } else {
      player.play();
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
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
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
      );
    }

    if (!_isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Video player
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Video(
                controller: videoController,
                controls: _showControls ? AdaptiveVideoControls : NoVideoControls,
                fill: Colors.black,
              ),
            ),
            
            // Custom controls overlay
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}