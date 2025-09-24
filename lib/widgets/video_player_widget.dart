import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool muted;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
    this.muted = true,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      print('VideoPlayerWidget: Initializing video: ${widget.videoUrl}');
      
      _controller = VideoPlayerController.network(
        widget.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      // Set video player configuration
      if (widget.muted) {
        await _controller!.setVolume(0.0);
      }
      await _controller!.setLooping(widget.looping);
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Add listener for video state changes
        _controller!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _controller!.value.isPlaying;
            });
          }
        });
        
        // Auto-play if enabled
        if (widget.autoPlay) {
          print('VideoPlayerWidget: Starting autoplay...');
          await _startAutoplayWithRetry();
        }
      }
    } catch (e) {
      print('VideoPlayerWidget: Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _startAutoplayWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries && mounted && _controller != null) {
      try {
        print('VideoPlayerWidget: Autoplay attempt ${retryCount + 1}');
        await _controller!.play();
        
        // Wait a bit to see if it actually started playing
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (_controller!.value.isPlaying) {
          print('VideoPlayerWidget: Autoplay successful');
          break;
        } else {
          retryCount++;
          if (retryCount < maxRetries) {
            print('VideoPlayerWidget: Autoplay failed, retrying...');
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        }
      } catch (e) {
        print('VideoPlayerWidget: Autoplay error: $e');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }
    
    if (retryCount >= maxRetries) {
      print('VideoPlayerWidget: Autoplay failed after $maxRetries attempts');
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _isInitialized) {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                'Video Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading video',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          VideoPlayer(_controller!),
          
          // Play/Pause overlay - only show when not playing
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
