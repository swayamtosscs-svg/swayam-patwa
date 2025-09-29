import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'video_player_widget.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/baba_like_service.dart';

class InAppVideoWidget extends StatefulWidget {
  final BabaPageReel reel;
  final bool autoplay;
  final VoidCallback? onTap;
  final bool showFullDetails;

  const InAppVideoWidget({
    super.key,
    required this.reel,
    this.autoplay = false,
    this.onTap,
    this.showFullDetails = false,
  });

  @override
  State<InAppVideoWidget> createState() => _InAppVideoWidgetState();
}

class _InAppVideoWidgetState extends State<InAppVideoWidget> {
  bool _isPlaying = false;
  bool _showControls = true;
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
    print('🔄 InAppVideoWidget: Loading like status...');
    print('🔄 Reel ID: ${widget.reel.id}');
    print('🔄 Baba Page ID: ${widget.reel.babaPageId}');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;

      print('🔄 User ID: $userId');

      if (userId == null) {
        print('❌ User ID is null during like status load');
        return;
      }

      final response = await BabaLikeService.getBabaReelLikeStatus(
        userId: userId,
        reelId: widget.reel.id,
        babaPageId: widget.reel.babaPageId,
      );

      print('🔄 Like status response: $response');

      if (response != null && response['success'] == true && mounted) {
        final data = response['data'] as Map<String, dynamic>?;
        print('🔄 Like status data: $data');
        print('🔄 Is liked: ${data?['isLiked']}');
        print('🔄 Like count: ${data?['likesCount']}');
        
        setState(() {
          _isLiked = data?['isLiked'] ?? false;
          _likeCount = data?['likesCount'] ?? widget.reel.likesCount;
        });
        
        print('🔄 Updated _isLiked: $_isLiked');
        print('🔄 Updated _likeCount: $_likeCount');
      } else {
        print('❌ Failed to load like status');
        print('❌ Response: $response');
      }
    } catch (e) {
      print('❌ InAppVideoWidget: Error loading like status: $e');
    }
  }

  Future<void> _handleLike() async {
    if (_isLoadingLike) return;

    print('🔥 InAppVideoWidget: Like button tapped!');
    print('🔥 Current _isLiked state: $_isLiked');
    print('🔥 Current _likeCount: $_likeCount');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;

      print('🔥 User ID: $userId');
      print('🔥 Reel ID: ${widget.reel.id}');
      print('🔥 Baba Page ID: ${widget.reel.babaPageId}');

      if (userId == null) {
        print('❌ User ID is null - user not logged in');
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
        print('🔥 Calling unlike API...');
        response = await BabaLikeService.unlikeBabaReel(
          userId: userId,
          reelId: widget.reel.id,
          babaPageId: widget.reel.babaPageId,
        );
      } else {
        print('🔥 Calling like API...');
        response = await BabaLikeService.likeBabaReel(
          userId: userId,
          reelId: widget.reel.id,
          babaPageId: widget.reel.babaPageId,
        );
      }

      print('🔥 API Response: $response');

      if (response != null && response['success'] == true && mounted) {
        final data = response['data'] as Map<String, dynamic>?;
        print('🔥 Response data: $data');
        print('🔥 New like count: ${data?['likesCount']}');
        print('🔥 Is liked: ${data?['isLiked']}');
        
        setState(() {
          _isLiked = !_isLiked;
          _likeCount = data?['likesCount'] ?? _likeCount;
        });

        print('🔥 Updated _isLiked: $_isLiked');
        print('🔥 Updated _likeCount: $_likeCount');

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
        print('❌ API call failed or response is null');
        print('❌ Response: $response');
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
      print('❌ InAppVideoWidget: Error handling like: $e');
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
      onTap: widget.onTap ?? () {
        setState(() {
          _showControls = !_showControls;
        });
      },
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
                muted: false, // Always start unmuted (audio on)
                showControls: true, // Show video controls
              ),

              // No play button overlay needed - videos auto-play and tap handles mute/unmute

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

              // Like button and count on the right side
              if (_showControls)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      // Like button
                      GestureDetector(
                        onTap: _handleLike,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: _isLoadingLike
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
                      ),
                      const SizedBox(height: 8),
                      // Like count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatCount(_likeCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}