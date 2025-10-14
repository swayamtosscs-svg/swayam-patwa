import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';
import '../screens/fullscreen_reel_viewer_screen.dart';
import '../providers/auth_provider.dart';
import '../services/baba_like_service.dart';
import 'video_player_widget.dart';

class BabaPageReelWidget extends StatefulWidget {
  final BabaPageReel reel;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final bool showFullDetails;
  final bool autoplay;

  const BabaPageReelWidget({
    Key? key,
    required this.reel,
    this.onTap,
    this.onLike,
    this.showFullDetails = true,
    this.autoplay = true, // Enable autoplay by default
  }) : super(key: key);

  @override
  State<BabaPageReelWidget> createState() => _BabaPageReelWidgetState();
}

class _BabaPageReelWidgetState extends State<BabaPageReelWidget> {
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
      print('BabaPageReelWidget: Error loading like status: $e');
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
      print('BabaPageReelWidget: Error handling like: $e');
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
              color: AppTheme.borderColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video/Thumbnail Section
            _buildVideoSection(),
            
            if (widget.showFullDetails) ...[
              const SizedBox(height: 12),
              // Title and Description
              _buildContentSection(),
              const SizedBox(height: 8),
              // Stats Section
              _buildStatsSection(),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
            
            // Category Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.reel.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            
            // Duration Badge
            if (widget.reel.video.duration > 0)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(widget.reel.video.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.reel.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.reel.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem(Icons.visibility, widget.reel.viewsCount),
          const SizedBox(width: 16),
          _buildStatItem(Icons.favorite, _likeCount, onTap: _handleLike, isLoading: _isLoadingLike),
          const SizedBox(width: 16),
          _buildStatItem(Icons.comment, widget.reel.commentsCount),
          const Spacer(),
          Text(
            _formatDate(widget.reel.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, {VoidCallback? onTap, bool isLoading = false}) {
    final isLikeButton = icon == Icons.favorite && onTap != null;
    
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading && isLikeButton)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
              ),
            )
          else
            Icon(
              icon,
              size: 16,
              color: isLikeButton 
                  ? (_isLiked ? Colors.red : AppTheme.textSecondary)
                  : AppTheme.textSecondary,
            ),
          const SizedBox(width: 4),
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 12,
              color: isLikeButton 
                  ? (_isLiked ? Colors.red : AppTheme.textSecondary)
                  : AppTheme.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
