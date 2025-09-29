import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'video_player_widget.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';
import '../screens/fullscreen_reel_viewer_screen.dart';
import '../providers/auth_provider.dart';
import '../services/baba_like_service.dart';

class VideoReelWidget extends StatefulWidget {
  final BabaPageReel reel;
  final VoidCallback? onTap;
  final bool showFullDetails;
  final bool autoplay;

  const VideoReelWidget({
    super.key,
    required this.reel,
    this.onTap,
    this.showFullDetails = false,
    this.autoplay = false,
  });

  @override
  State<VideoReelWidget> createState() => _VideoReelWidgetState();
}

class _VideoReelWidgetState extends State<VideoReelWidget> {
  bool _isPlaying = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoadingLike = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.reel.likesCount;
    _loadLikeStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLikeStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;

      if (userId == null) return;

      final response = await BabaLikeService.getBabaReelLikeStatus(
        userId: userId,
        reelId: widget.reel.id,
        babaPageId: widget.reel.babaPageId,
      );

      if (response != null && response['success'] == true && mounted) {
        final data = response['data'] as Map<String, dynamic>?;
        setState(() {
          _isLiked = data?['isLiked'] ?? false;
          _likeCount = data?['likesCount'] ?? widget.reel.likesCount;
        });
      }
    } catch (e) {
      print('VideoReelWidget: Error loading like status: $e');
    }
  }

  Future<void> _handleLike() async {
    if (_isLoadingLike) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to like reels'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoadingLike = true;
      });

      Map<String, dynamic>? response;

      if (_isLiked) {
        response = await BabaLikeService.unlikeBabaReel(
          userId: userId,
          reelId: widget.reel.id,
          babaPageId: widget.reel.babaPageId,
        );
      } else {
        response = await BabaLikeService.likeBabaReel(
          userId: userId,
          reelId: widget.reel.id,
          babaPageId: widget.reel.babaPageId,
        );
      }

      if (response != null && response['success'] == true && mounted) {
        final data = response['data'] as Map<String, dynamic>?;
        setState(() {
          _isLiked = !_isLiked;
          _likeCount = data?['likesCount'] ?? _likeCount;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLiked ? 'Liked!' : 'Unliked!'),
              duration: const Duration(seconds: 2),
              backgroundColor: _isLiked ? Colors.red : Colors.grey,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update like status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('VideoReelWidget: Error handling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating like status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLike = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    // This will be handled by the VideoPlayerWidget
    setState(() {
      _isPlaying = !_isPlaying;
    });
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
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
        child: AspectRatio(
          aspectRatio: 9 / 16, // Vertical video aspect ratio
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Player
              VideoPlayerWidget(
                videoUrl: widget.reel.video.url,
                autoPlay: widget.autoplay,
                looping: true,
                muted: true,
              ),

              // Play/Pause Overlay (only show when not playing)
              if (!_isPlaying)
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

              // Full details overlay (if enabled)
              if (widget.showFullDetails)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.reel.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.reel.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[600],
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Baba Page',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '@babapage',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isLoadingLike ? null : _handleLike,
                              icon: _isLoadingLike
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Icon(
                                      _isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: _isLiked ? Colors.red : Colors.white,
                                      size: 24,
                                    ),
                            ),
                            // Like count
                            Text(
                              _formatCount(_likeCount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Handle share action
                              },
                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 24,
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