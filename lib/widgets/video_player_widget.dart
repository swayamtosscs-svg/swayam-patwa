import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'fallback_video_player_widget.dart';
import 'visibility_detector_widget.dart';
import '../utils/video_manager.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final bool showControls;
  final String? videoId; // Add video ID for tracking

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
    this.muted = false, // Changed default to false for audio
    this.showControls = true, // Added controls option
    this.videoId, // Add video ID parameter
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
  bool _useFallback = false;
  final VideoManager _videoManager = VideoManager();
  String get _videoId => widget.videoId ?? widget.videoUrl; // Use videoId or fallback to URL
  
  // Progress bar related variables
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _showControls = widget.showControls;
    _setupVideoManager();
    // Always initialize the player, regardless of autoPlay setting
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

  void _setupVideoManager() {
    _videoManager.setOnVideoStateChanged((videoId) {
      if (!_isDisposed) {
        if (videoId == _videoId) {
          // This video should play
          if (_isInitialized && !_isPlaying) {
            print('VideoPlayerWidget: Playing video $_videoId');
            player.play();
          }
        } else if (videoId != _videoId) {
          // Another video is playing, pause this one
          if (_isInitialized && _isPlaying) {
            print('VideoPlayerWidget: Pausing video $_videoId (another video playing)');
            player.pause();
          }
        } else if (videoId == null) {
          // No video should play, pause this one
          if (_isInitialized && _isPlaying) {
            print('VideoPlayerWidget: Pausing video $_videoId (no video should play)');
            player.pause();
          }
        }
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      print('VideoPlayerWidget: Initializing player for URL: ${widget.videoUrl}');
      
      // Validate URL or local file path
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      final bool isRemoteUrl = widget.videoUrl.startsWith('http://') || widget.videoUrl.startsWith('https://');
      final bool isFileUrl = widget.videoUrl.startsWith('file://');
      final bool isWindowsPath = RegExp(r'^[a-zA-Z]:\\').hasMatch(widget.videoUrl);
      final bool isUnixPath = widget.videoUrl.startsWith('/');
      final bool isLocalPath = isFileUrl || isWindowsPath || isUnixPath;
      if (!(isRemoteUrl || isLocalPath)) {
        throw Exception('Invalid video source: ${widget.videoUrl}');
      }
      
      player = Player();
      videoController = VideoController(player);
      
      // Set up event listeners
      player.stream.playing.listen((playing) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = playing;
          });
          print('VideoPlayerWidget: Playing state changed to: $playing');
        }
      });

      player.stream.error.listen((error) {
        if (mounted && !_isDisposed) {
          print('VideoPlayerWidget: Player error: $error');
          print('VideoPlayerWidget: Switching to fallback player');
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
          print('VideoPlayerWidget: Video completed');
          if (widget.looping) {
            player.seek(Duration.zero);
            player.play();
          }
        }
      });

      // Add duration listener
      player.stream.duration.listen((duration) {
        if (mounted && !_isDisposed) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Add position listener
      player.stream.position.listen((position) {
        if (mounted && !_isDisposed && !_isDragging) {
          setState(() {
            _position = position;
          });
        }
      });

      print('VideoPlayerWidget: Opening media...');
      await player.open(Media(widget.videoUrl));
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        
        print('VideoPlayerWidget: Player initialized successfully');
        
        if (widget.autoPlay) {
          print('VideoPlayerWidget: Starting autoplay...');
          _videoManager.playVideo(_videoId);
        }
      }
    } catch (e) {
      print('VideoPlayerWidget: Initialization error: $e');
      print('VideoPlayerWidget: Switching to fallback player');
      if (mounted && !_isDisposed) {
        setState(() {
          _useFallback = true;
          _hasError = false;
          _errorMessage = '';
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
          _videoManager.playVideo(_videoId);
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
    if (_isDisposed) return;
    
    print('VideoPlayerWidget: Toggling play/pause. Current state: $_isPlaying, Initialized: $_isInitialized');
    
    // If not initialized yet, try to initialize first
    if (!_isInitialized && !_useFallback) {
      print('VideoPlayerWidget: Player not initialized, initializing now...');
      _initializePlayer();
      return;
    }
    
    if (_isPlaying) {
      if (_isInitialized) {
        player.pause();
        _videoManager.pauseCurrentVideo();
        print('VideoPlayerWidget: Pausing video');
      }
    } else {
      if (_isInitialized) {
        _videoManager.playVideo(_videoId);
        print('VideoPlayerWidget: Playing video');
      }
    }
  }

  void _toggleControls() {
    if (!_isDisposed) {
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  void _onProgressBarDragStart() {
    setState(() {
      _isDragging = true;
    });
  }

  void _onProgressBarDragEnd() {
    setState(() {
      _isDragging = false;
    });
  }

  void _onProgressBarChanged(double value) {
    if (_isInitialized && _duration.inMilliseconds > 0) {
      final position = Duration(milliseconds: (value * _duration.inMilliseconds).round());
      player.seek(position);
      setState(() {
        _position = position;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Use fallback player if media_kit failed
    if (_useFallback) {
      return FallbackVideoPlayerWidget(
        videoUrl: widget.videoUrl,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        muted: widget.muted,
        showControls: widget.showControls,
      );
    }

    if (_hasError) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[800]!,
              Colors.grey[900]!,
            ],
          ),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                    _isInitialized = false;
                    _useFallback = true;
                  });
                },
                child: const Text('Use Fallback Player'),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[800]!,
              Colors.grey[900]!,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return VisibilityDetectorWidget(
      videoKey: _videoId,
      onVisibilityChanged: (isVisible) {
        _videoManager.updateVideoVisibility(_videoId, isVisible);
      },
      child: GestureDetector(
        onTap: widget.showControls ? _togglePlayPause : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[800]!,
                Colors.grey[900]!,
              ],
            ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        if (_duration.inMilliseconds > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      trackHeight: 2,
                                    ),
                                    child: Slider(
                                      value: _duration.inMilliseconds > 0
                                          ? _position.inMilliseconds / _duration.inMilliseconds
                                          : 0.0,
                                      onChanged: _onProgressBarChanged,
                                      onChangeStart: (_) => _onProgressBarDragStart(),
                                      onChangeEnd: (_) => _onProgressBarDragEnd(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(_duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Play/Pause button
                        Row(
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