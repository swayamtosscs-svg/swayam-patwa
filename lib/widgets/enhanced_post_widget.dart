import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/baba_like_service.dart';
import '../services/baba_comment_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/user_profile_screen.dart';
import 'baba_comment_dialog.dart';

class EnhancedPostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback? onLike; // Optional - only for Baba Ji posts
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onUserTap;
  final VoidCallback onPostTap;
  final VoidCallback? onDelete; // Add delete callback

  const EnhancedPostWidget({
    super.key,
    required this.post,
    this.onLike, // Optional - only for Baba Ji posts
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
    required this.onPostTap,
    this.onDelete, // Add delete callback parameter
  });

  @override
  State<EnhancedPostWidget> createState() => _EnhancedPostWidgetState();
}

class _EnhancedPostWidgetState extends State<EnhancedPostWidget> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFavourite = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    print('EnhancedPostWidget: Initializing post widget for post: ${widget.post.id}');
    print('EnhancedPostWidget: Post type: ${widget.post.type}, isReel: ${widget.post.isReel}, videoUrl: ${widget.post.videoUrl}');
    
    if (widget.post.isBabaJiPost) {
      _loadLikeStatus();
    }
    if (widget.post.type == PostType.reel || widget.post.isReel) {
      print('EnhancedPostWidget: This is a reel, initializing video...');
      _initializeVideo();
    } else {
      print('EnhancedPostWidget: This is not a reel, skipping video initialization');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.post.videoUrl == null) {
      print('EnhancedPostWidget: No video URL available for post: ${widget.post.id}');
      return;
    }
    
    try {
      print('EnhancedPostWidget: Initializing reel video: ${widget.post.videoUrl}');
      print('EnhancedPostWidget: Post type: ${widget.post.type}, isReel: ${widget.post.isReel}');
      
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post.videoUrl!),
      );
      
      // Set video player configuration
      _videoController!.setVolume(1.0);
      _videoController!.setLooping(true);
      
      print('EnhancedPostWidget: Video controller created, initializing...');
      await _videoController!.initialize();
      print('EnhancedPostWidget: Video controller initialized successfully');
      
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
        
        // Auto-play reels
        print('EnhancedPostWidget: Starting reel autoplay...');
        await _startAutoplayWithRetry();
      }
    } catch (e) {
      print('EnhancedPostWidget: Error initializing reel video: $e');
      print('EnhancedPostWidget: Video URL was: ${widget.post.videoUrl}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isVideoInitialized = false;
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
        print('EnhancedPostWidget: Reel autoplay started successfully (attempt ${retryCount + 1})');
        break;
      } catch (playError) {
        retryCount++;
        print('EnhancedPostWidget: Reel autoplay attempt $retryCount failed: $playError');
        
        if (retryCount < maxRetries) {
          // Wait before retrying, with increasing delay
          await Future.delayed(Duration(milliseconds: 300 * retryCount));
        } else {
          print('EnhancedPostWidget: All reel autoplay attempts failed');
        }
      }
    }
  }

  void _togglePlayPause() async {
    print('EnhancedPostWidget: Toggle play/pause called');
    print('EnhancedPostWidget: _hasError: $_hasError, _isVideoInitialized: $_isVideoInitialized, _isPlaying: $_isPlaying');
    
    if (_hasError) return;
    
    // If video is not initialized yet, try to initialize it
    if (!_isVideoInitialized && widget.post.videoUrl != null) {
      print('EnhancedPostWidget: Video not initialized, attempting to initialize...');
      await _initializeVideo();
      return;
    }
    
    if (_videoController != null && _isVideoInitialized) {
      if (_isPlaying) {
        print('EnhancedPostWidget: Pausing video...');
        await _videoController!.pause();
      } else {
        print('EnhancedPostWidget: Playing video...');
        await _videoController!.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } else {
      print('EnhancedPostWidget: Cannot toggle - video controller is null or not initialized');
    }
  }

  Future<void> _loadLikeStatus() async {
    if (!widget.post.isBabaJiPost) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId == null) return;

      Map<String, dynamic>? response;

      if (widget.post.isReel) {
        // This is a Baba Ji reel
        final reelId = widget.post.id.replaceFirst('baba_reel_', '');
        response = await BabaLikeService.getBabaReelLikeStatus(
          userId: userId,
          reelId: reelId,
          babaPageId: widget.post.babaPageId ?? '',
        );
      } else {
        // This is a Baba Ji post
        final postId = widget.post.id.replaceFirst('baba_', '');
        response = await BabaLikeService.getBabaPostLikeStatus(
          userId: userId,
          postId: postId,
          babaPageId: widget.post.babaPageId ?? '',
        );
      }

      if (response != null && response['success'] == true && mounted) {
        setState(() {
          _isLiked = response?['data']?['isLiked'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading like status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(),
          
          // Post Image/Content
          _buildPostContent(),
          
          // Post Actions
          _buildPostActions(),
          
          // Post Stats
          _buildPostStats(),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Check if userAvatar is a valid image URL
    if (widget.post.userAvatar.isNotEmpty && 
        (widget.post.userAvatar.startsWith('http://') || widget.post.userAvatar.startsWith('https://'))) {
      // If it's a valid URL, show the image
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          widget.post.userAvatar,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to initials if image fails to load
            return _buildAvatarInitials();
          },
        ),
      );
    } else {
      // If not a valid URL, show initials
      return _buildAvatarInitials();
    }
  }

  Widget _buildAvatarInitials() {
    // Get first letter of username for avatar
    final initial = widget.post.username.isNotEmpty ? widget.post.username[0].toUpperCase() : 'U';
    return Text(
      initial,
      style: const TextStyle(
        fontSize: 18,
        color: Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // User Avatar - Make it clickable
          GestureDetector(
            onTap: () {
              _navigateToUserProfile();
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: _buildAvatarContent(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // User Info - Make username clickable
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    _navigateToUserProfile();
                  },
                  child: Text(
                    widget.post.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Text(
                  _getTimeAgo(widget.post.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          // Three Dots Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF666666),
            ),
            onSelected: (value) {
              _handleMenuSelection(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved ? const Color(0xFF6366F1) : const Color(0xFF666666),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isSaved ? 'Saved' : 'Save',
                      style: TextStyle(
                        color: _isSaved ? const Color(0xFF6366F1) : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'favourite',
                child: Row(
                  children: [
                    Icon(
                      _isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavourite ? Colors.red : const Color(0xFF666666),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFavourite ? 'Favourited' : 'Add to Favourite',
                      style: TextStyle(
                        color: _isFavourite ? Colors.red : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'hide',
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, color: Color(0xFF666666), size: 20),
                    SizedBox(width: 8),
                    Text('Hide'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Color(0xFF666666), size: 20),
                    SizedBox(width: 8),
                    Text('Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF666666), size: 20),
                    SizedBox(width: 8),
                    Text('About this Account'),
                  ],
                ),
              ),
              // Delete option - only show if post belongs to current user
              if (_isCurrentUserPost())
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Color(0xFFE53E3E), size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Color(0xFFE53E3E))),
                    ],
                  ),
                ),
            ],
          ),
          
          // Follow Button - only show if post is NOT from current user
          // if (!_isCurrentUserPost())
          //   Container(
          //     margin: const EdgeInsets.only(left: 8),
          //     child: _buildFollowButton(),
          //   ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return GestureDetector(
      onTap: widget.onPostTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.post.caption!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          
          // Image/Video Content
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final aspectRatio = 4 / 3; // 4:3 aspect ratio for better mobile viewing
              final height = (maxWidth / aspectRatio).clamp(200.0, 400.0); // Min 200, Max 400
              
              return Container(
                width: maxWidth,
                height: height,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: _buildMediaContent(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    // Check if it's a video/reel
    if (widget.post.type == PostType.video || widget.post.type == PostType.reel || widget.post.isReel) {
      if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
        // Use different aspect ratios for reels vs regular videos
        final aspectRatio = (widget.post.type == PostType.reel || widget.post.isReel) ? 9 / 16 : 4 / 3;
        final height = MediaQuery.of(context).size.width / aspectRatio;
        
        return Container(
          height: height.clamp(200.0, 400.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Video Player or Thumbnail
                if (_isVideoInitialized && _videoController != null && !_hasError)
                  VideoPlayer(_videoController!)
                else
                  Image.network(
                    widget.post.thumbnailUrl ?? widget.post.imageUrl ?? 'https://via.placeholder.com/400x400/6366F1/FFFFFF?text=Video',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Center(
                          child: Icon(
                            Icons.video_library,
                            size: 64,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                      );
                    },
                  ),
                
                // Play/Pause Overlay - always show when video is not playing
                if (!_isPlaying || _hasError)
                  Center(
                    child: GestureDetector(
                      onTap: _hasError ? null : _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _hasError ? Icons.error : Icons.play_arrow,
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
      } else {
        // No video URL, show placeholder
        return Container(
          color: const Color(0xFFF0F0F0),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library,
                  size: 64,
                  color: Color(0xFFCCCCCC),
                ),
                SizedBox(height: 8),
                Text(
                  'Video not available',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Show image
      if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) {
        return Image.network(
          widget.post.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF0F0F0),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Color(0xFFCCCCCC),
                ),
              ),
            );
          },
        );
      } else {
        // No image URL, show placeholder
        return Container(
          color: const Color(0xFFF0F0F0),
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 64,
              color: Color(0xFFCCCCCC),
            ),
          ),
        );
      }
    }
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like Button - Only for Baba Ji posts
          if (widget.post.isBabaJiPost && widget.onLike != null) ...[
            GestureDetector(
              onTap: _handleLike,
              child: Row(
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : const Color(0xFF666666),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Like',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isLiked ? Colors.red : const Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
          ],
          
          // Comment Button
          GestureDetector(
            onTap: _handleComment,
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF666666),
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Share Button
          GestureDetector(
            onTap: widget.onShare,
            child: Row(
              children: [
                const Icon(
                  Icons.share_outlined,
                  color: Color(0xFF666666),
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _handleLike() async {
    if (!widget.post.isBabaJiPost || widget.onLike == null) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to like posts'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Map<String, dynamic>? response;

      if (widget.post.isReel) {
        // This is a Baba Ji reel
        final reelId = widget.post.id.replaceFirst('baba_reel_', '');
        if (_isLiked) {
          response = await BabaLikeService.unlikeBabaReel(
            userId: userId,
            reelId: reelId,
            babaPageId: widget.post.babaPageId ?? '',
          );
        } else {
          response = await BabaLikeService.likeBabaReel(
            userId: userId,
            reelId: reelId,
            babaPageId: widget.post.babaPageId ?? '',
          );
        }
      } else {
        // This is a Baba Ji post
        final postId = widget.post.id.replaceFirst('baba_', '');
        if (_isLiked) {
          response = await BabaLikeService.unlikeBabaPost(
            userId: userId,
            postId: postId,
            babaPageId: widget.post.babaPageId ?? '',
          );
        } else {
          response = await BabaLikeService.likeBabaPost(
            userId: userId,
            postId: postId,
            babaPageId: widget.post.babaPageId ?? '',
          );
        }
      }

      if (response != null && response['success'] == true) {
        if (mounted) {
          setState(() {
            _isLiked = !_isLiked;
          });
        }
        
        // Call the callback to notify parent
        widget.onLike!();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLiked ? 'Liked!' : 'Unliked!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Failed to like post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleComment() {
    if (widget.post.isBabaJiPost) {
      // Show comment dialog for Baba Ji posts
      showDialog(
        context: context,
        builder: (context) => BabaCommentDialog(
          postId: widget.post.id.replaceFirst(widget.post.isReel ? 'baba_reel_' : 'baba_', ''),
          babaPageId: widget.post.babaPageId ?? '',
          isReel: widget.post.isReel,
          onCommentAdded: () {
            // Call the callback to notify parent
            widget.onComment();
          },
        ),
      );
    } else {
      // For regular posts, just call the callback
      widget.onComment();
    }
  }

  Widget _buildPostStats() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          // Likes count
          Text(
            '${widget.post.likes} likes',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Comments count
          Text(
            '${widget.post.comments} comments',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          
          const Spacer(),
          
          // Hashtags
          if (widget.post.hashtags.isNotEmpty)
            Text(
              '#${widget.post.hashtags.first}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6366F1),
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'save':
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved ? 'Post saved!' : 'Post removed from saved'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'favourite':
        setState(() {
          _isFavourite = !_isFavourite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavourite ? 'Added to favourites!' : 'Removed from favourites'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'hide':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post hidden'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post reported'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'about':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('About this account'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool _isCurrentUserPost() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return widget.post.userId == authProvider.userProfile?.id;
  }

  // Follow button methods removed since follow button is hidden
  // Widget _buildFollowButton() {
  //   return ElevatedButton(
  //     onPressed: _handleFollow,
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: const Color(0xFF6366F1),
  //       foregroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     ),
  //     child: const Text(
  //       'Follow',
  //       style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  //     ),
  //   );
  // }

  // void _handleFollow() {
  //   // Handle follow logic here
  //   print('Follow button tapped for user: ${widget.post.userId}');
  // }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePost();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53E3E),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to delete posts'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting post...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Call delete API
      final response = await ApiService.deleteMedia(
        mediaId: widget.post.id,
        token: token,
      );

      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Call the delete callback if provided
        widget.onDelete?.call();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToUserProfile() {
    // Navigate to user profile screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: widget.post.userId,
          username: widget.post.username,
          fullName: widget.post.username, // Use username as fallback for fullName
          avatar: widget.post.userAvatar,
          bio: '', // Default empty bio
          followersCount: 0, // Default value
          followingCount: 0, // Default value
          postsCount: 0, // Default value
          isPrivate: false, // Default to public, will be updated when user profile is loaded
        ),
      ),
    );
  }
}
