import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/video_player_widget.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_like_service.dart';
import '../widgets/user_comment_dialog.dart';

class PostFullViewScreen extends StatefulWidget {
  final Post post;
  final bool showNavigationControls;

  const PostFullViewScreen({
    super.key,
    required this.post,
    this.showNavigationControls = true,
  });

  @override
  State<PostFullViewScreen> createState() => _PostFullViewScreenState();
}

class _PostFullViewScreenState extends State<PostFullViewScreen> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFavourite = false;
  bool _isPlaying = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    _isFavourite = widget.post.isFavourite;
    _likesCount = widget.post.likesCount;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildMediaContent() {
    // Check if this is a video/reel post
    if ((widget.post.isReel || widget.post.type == PostType.video || widget.post.type == PostType.reel) && 
        widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      print('PostFullViewScreen: Building video content for ${widget.post.id}');
      print('PostFullViewScreen: Video URL: ${widget.post.videoUrl}');
      
      return Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayerWidget(
            videoUrl: widget.post.videoUrl ?? '',
            autoPlay: true, // Auto-play when opened
            looping: true,
            muted: false, // Enable audio for reels
            showControls: true,
          ),
          // Play/Pause overlay - only show when not playing
          if (!_isPlaying)
            Center(
              child: GestureDetector(
                onTap: () {
                  print('PostFullViewScreen: Play button tapped');
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
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
        ],
      );
    } else {
      // Handle image posts
      return Image.network(
        widget.post.imageUrl ?? 'https://via.placeholder.com/400x600/6366F1/FFFFFF?text=Post',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          // Share Button
          GestureDetector(
            onTap: () {
              // Handle share
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like Button
          GestureDetector(
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final userId = authProvider.userProfile?.id;
              final token = authProvider.authToken;

              if (userId == null || token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to like posts'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final response = await UserLikeService.toggleUserPostLike(
                postId: widget.post.id,
                token: token,
                userId: userId,
                isCurrentlyLiked: _isLiked,
              );

              if (mounted) {
                setState(() {
                  _isLiked = !_isLiked;
                  final data = response['data'] as Map<String, dynamic>?;
                  if (data != null && data['likesCount'] != null) {
                    _likesCount = data['likesCount'] as int;
                  } else {
                    _likesCount = (_likesCount + (_isLiked ? 1 : -1)).clamp(0, 1 << 31);
                  }
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Save Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isSaved = !_isSaved;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Favorite Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isFavourite = !_isFavourite;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isFavourite ? Icons.star : Icons.star_border,
                color: _isFavourite ? Colors.yellow : Colors.white,
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          // Comment Button
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => UserCommentDialog(
                  postId: widget.post.id,
                  onCommentAdded: () {},
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.comment,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar - only show if navigation controls are enabled
            if (widget.showNavigationControls) _buildTopBar(),
            
            // Media Content
            Expanded(
              child: _buildMediaContent(),
            ),
            
            // Post Info
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.caption ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_likesCount likes',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Bar - only show if navigation controls are enabled
            if (widget.showNavigationControls) _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}