import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';

class FullscreenReelViewerScreen extends StatefulWidget {
  final BabaPageReel reel;

  const FullscreenReelViewerScreen({
    Key? key,
    required this.reel,
  }) : super(key: key);

  @override
  State<FullscreenReelViewerScreen> createState() => _FullscreenReelViewerScreenState();
}

class _FullscreenReelViewerScreenState extends State<FullscreenReelViewerScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _hasError = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      print('FullscreenReelViewerScreen: Initializing video: ${widget.reel.video.url}');
      
      _videoController = VideoPlayerController.network(
        widget.reel.video.url,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      // Set video player configuration
      _videoController!.setVolume(1.0);
      _videoController!.setLooping(true);
      
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // Add listener for video state changes
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _videoController!.value.isPlaying;
            });
          }
        });
        
        // Auto-play the video with retry mechanism
        print('FullscreenReelViewerScreen: Starting autoplay...');
        await _startAutoplayWithRetry();
      }
    } catch (e) {
      print('FullscreenReelViewerScreen: Error initializing video: $e');
      if (mounted) {
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
        print('FullscreenReelViewerScreen: Autoplay started successfully (attempt ${retryCount + 1})');
        break;
      } catch (playError) {
        retryCount++;
        print('FullscreenReelViewerScreen: Autoplay attempt $retryCount failed: $playError');
        
        if (retryCount < maxRetries) {
          // Wait before retrying, with increasing delay
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        } else {
          print('FullscreenReelViewerScreen: All autoplay attempts failed');
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
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
    if (_videoController != null && _isVideoInitialized) {
      final position = Duration(milliseconds: (value * _videoController!.value.duration.inMilliseconds).round());
      _videoController!.seekTo(position);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
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
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.white,
                      size: 100,
                    ),
                  );
                },
              ),


            // Controls Overlay
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Top Bar
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _togglePlayPause,
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Center Play/Pause Button
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Progress bar
                    if (_videoController != null && _isVideoInitialized && _videoController!.value.duration.inMilliseconds > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_videoController!.value.position),
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
                                  value: _videoController!.value.duration.inMilliseconds > 0
                                      ? _videoController!.value.position.inMilliseconds / _videoController!.value.duration.inMilliseconds
                                      : 0.0,
                                  onChanged: _onProgressBarChanged,
                                  onChangeStart: (_) => _onProgressBarDragStart(),
                                  onChangeEnd: (_) => _onProgressBarDragEnd(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_videoController!.value.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bottom Info
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reel.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.reel.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStatItem(Icons.visibility, widget.reel.viewsCount),
                                const SizedBox(width: 20),
                                _buildStatItem(Icons.favorite, widget.reel.likesCount),
                                const SizedBox(width: 20),
                                _buildStatItem(Icons.comment, widget.reel.commentsCount),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
          size: 20,
          color: Colors.white,
        ),
        const SizedBox(width: 6),
        Text(
          _formatCount(count),
          style: const TextStyle(
            fontSize: 16,
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
