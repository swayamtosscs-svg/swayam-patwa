import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

class FallbackVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final bool showControls;

  const FallbackVideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
    this.muted = false,
    this.showControls = true,
  }) : super(key: key);

  @override
  State<FallbackVideoPlayerWidget> createState() => _FallbackVideoPlayerWidgetState();
}

class _FallbackVideoPlayerWidgetState extends State<FallbackVideoPlayerWidget> {
  // video_player (mobile/web/macOS)
  VideoPlayerController? _controller;
  // media_kit (Windows/Linux fallback)
  mk.Player? _mkPlayer;
  mkv.VideoController? _mkVideoController;
  bool _useMediaKit = false;
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
  void didUpdateWidget(FallbackVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl && !_isDisposed) {
      _loadNewVideo();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Dispose appropriate backend
    _controller?.dispose();
    _mkPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      print('FallbackVideoPlayerWidget: Initializing player for URL: ${widget.videoUrl}');
      
      // Validate URL or local file path
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      bool isRemoteUrl = widget.videoUrl.startsWith('http://') || widget.videoUrl.startsWith('https://');
      bool isFileUrl = widget.videoUrl.startsWith('file://');
      bool isWindowsPath = RegExp(r'^[a-zA-Z]:\\').hasMatch(widget.videoUrl);
      bool isUnixPath = widget.videoUrl.startsWith('/');
      bool isLocalPath = isFileUrl || isWindowsPath || isUnixPath;
      // Choose backend: video_player for web/mobile/macOS; media_kit for Windows/Linux
      final platform = defaultTargetPlatform;
      final useVideoPlayer = kIsWeb ||
          platform == TargetPlatform.android ||
          platform == TargetPlatform.iOS ||
          platform == TargetPlatform.macOS;

      _useMediaKit = !useVideoPlayer;

      if (_useMediaKit) {
        // media_kit path (Windows/Linux)
        _mkPlayer = mk.Player();
        _mkVideoController = mkv.VideoController(_mkPlayer!);

        // Listeners
        _mkPlayer!.stream.playing.listen((playing) {
          if (mounted && !_isDisposed) {
            setState(() {
              _isPlaying = playing;
            });
          }
        });

        _mkPlayer!.stream.error.listen((error) {
          if (mounted && !_isDisposed) {
            setState(() {
              _hasError = true;
              _errorMessage = error.toString();
            });
          }
        });
        // media_kit supports both URLs & file paths directly
        await _mkPlayer!.open(mk.Media(widget.videoUrl));
        if (widget.muted) {
          _mkPlayer!.setVolume(0.0);
        }
        if (mounted && !_isDisposed) {
          setState(() {
            _isInitialized = true;
          });
          if (widget.autoPlay) {
            await _mkPlayer!.play();
          }
        }
      } else {
        // video_player path (Android/iOS/Web/macOS)
        if (isRemoteUrl) {
          _controller = VideoPlayerController.network(
            widget.videoUrl,
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: false,
            ),
          );
        } else if (isLocalPath) {
          // Normalize file:// URI to path for controller.file
          final String path = isFileUrl
              ? widget.videoUrl.replaceFirst('file://', '')
              : widget.videoUrl;
          _controller = VideoPlayerController.file(
            File(path),
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
              allowBackgroundPlayback: false,
            ),
          );
        } else {
          throw Exception('Invalid video source: ${widget.videoUrl}');
        }

        // Set video player configuration
        _controller!.setVolume(widget.muted ? 0.0 : 1.0);
        _controller!.setLooping(widget.looping);

        await _controller!.initialize();
      }
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        
        // Add listener for video state changes
        if (!_useMediaKit) {
          _controller!.addListener(() {
            if (mounted && !_isDisposed) {
              setState(() {
                _isPlaying = _controller!.value.isPlaying;
              });
            }
          });
        }
        
        // Auto-play the video
        if (widget.autoPlay) {
          print('FallbackVideoPlayerWidget: Starting autoplay...');
          if (_useMediaKit) {
            await _mkPlayer!.play();
          } else {
            await _controller!.play();
          }
        }
      }
    } catch (e) {
      print('FallbackVideoPlayerWidget: Initialization error: $e');
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
      await _controller?.dispose();
      await _initializePlayer();
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
    print('FallbackVideoPlayerWidget: Toggling play/pause. Current state: $_isPlaying, Initialized: $_isInitialized');
    
    if (_isInitialized) {
      if (_useMediaKit && _mkPlayer != null) {
        if (_isPlaying) {
          _mkPlayer!.pause();
        } else {
          _mkPlayer!.play();
        }
      } else if (_controller != null) {
        if (_isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      }
      if (mounted) {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
    } else {
      print('FallbackVideoPlayerWidget: Controller not ready or not initialized');
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
                'Video Error (Fallback)',
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              Text(
                'URL: ${widget.videoUrl}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
      onTap: _togglePlayPause,
      onDoubleTap: _toggleControls,
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
              child: _useMediaKit
                  ? mkv.Video(
                      controller: _mkVideoController!,
                      controls: mkv.NoVideoControls,
                      fill: Colors.black,
                    )
                  : AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
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
            
            // Large play button overlay when not playing (only if showControls is true)
            if (!_isPlaying && _isInitialized && _showControls)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
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
          ],
        ),
      ),
    );
  }
}
