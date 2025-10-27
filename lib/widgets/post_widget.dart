import 'package:flutter/material.dart';
import 'video_player_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/user_like_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/avatar_utils.dart';
import '../screens/post_full_view_screen.dart';
import '../screens/post_slider_screen.dart';
import 'image_slider_widget.dart';
import 'user_comment_dialog.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onUserTap;
  final VoidCallback? onDelete; // Add delete callback

  const PostWidget({
    super.key,
    required this.post,
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
    this.onDelete, // Add delete callback parameter
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  // Video player is now handled by VideoPlayerWidget
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  bool _isCaptionExpanded = false;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize like count and status from post data
    _likeCount = widget.post.likes;
    _isLiked = widget.post.isLiked;
    
    // Load like status from local storage for persistent likes
    _loadLikeStatus();
  }

  Future<void> _loadLikeStatus() async {
    try {
      print('PostWidget: Loading like status for post ${widget.post.id}');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      final token = authProvider.authToken;
      
      if (userId == null || token == null) {
        print('PostWidget: User not authenticated, skipping like status load');
        return;
      }
      
      // Use API to get like status
      final response = await ApiService.getPostLikeStatus(
        postId: widget.post.id,
        token: token,
      );
      
      print('PostWidget: API response: $response');
      
      if (response['success'] == true && mounted) {
        setState(() {
          _isLiked = response['data']?['liked'] ?? response['data']?['isLiked'] ?? false;
          _likeCount = response['data']?['likesCount'] ?? response['data']?['likeCount'] ?? widget.post.likes;
        });
        
        print('PostWidget: Final state - liked=$_isLiked, count=$_likeCount');
      } else {
        print('PostWidget: Failed to load like status: ${response['message']}');
        // Keep default values from post data
      }
    } catch (e) {
      print('PostWidget: Error loading like status: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _togglePlayPause() {
    // Play/pause is handled by VideoPlayerWidget
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _handleLike() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      final token = authProvider.authToken;
      
      if (userId == null || token == null) {
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
      
      if (_isLiked) {
        response = await ApiService.unlikePost(
          postId: widget.post.id,
          token: token,
          userId: userId,
        );
      } else {
        response = await ApiService.likePost(
          postId: widget.post.id,
          token: token,
          userId: userId,
        );
      }

      if (response != null && response['success'] == true) {
        if (mounted) {
          setState(() {
            _isLiked = !_isLiked;
            // Update like count from API response if available
            final responseData = response?['data'];
            if (responseData != null && responseData is Map<String, dynamic> && responseData['likesCount'] != null) {
              _likeCount = responseData['likesCount'];
            } else {
              // Fallback to increment/decrement if API doesn't provide count
              if (_isLiked) {
                _likeCount++;
              } else {
                _likeCount--;
              }
            }
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLiked ? 'Liked!' : 'Unliked!'),
              duration: const Duration(seconds: 2),
              backgroundColor: _isLiked ? Colors.green : Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          String errorMessage = response?['message'] ?? 'Failed to like post';
          
          // Provide more specific error messages based on the response
          if (errorMessage.contains('Post not found')) {
            errorMessage = 'This post is not available on the server. Like saved locally.';
          } else if (errorMessage.contains('locally')) {
            errorMessage = 'Like saved locally (offline mode)';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: errorMessage.contains('locally') ? Colors.orange : Colors.red,
              duration: const Duration(seconds: 3),
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


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to post slider view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostSliderScreen(
              posts: [widget.post], // Single post for now
              initialIndex: 0,
            ),
          ),
        );
      },
      child: Container(
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
            
            // Post Content
            _buildPostContent(),
            
            // Post Actions
            _buildPostActions(),
            
            // Post Stats
            _buildPostStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Use AvatarUtils to properly handle avatar URLs
    if (widget.post.userAvatar.isNotEmpty && AvatarUtils.isValidAvatarUrl(widget.post.userAvatar)) {
      final absoluteAvatarUrl = AvatarUtils.getAbsoluteAvatarUrl(widget.post.userAvatar);
      print('PostWidget: Loading avatar for ${widget.post.username}: $absoluteAvatarUrl');
      
      // If it's a valid URL, show the image with caching
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: absoluteAvatarUrl,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          httpHeaders: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          placeholder: (context, url) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            print('PostWidget: Avatar load error for URL: $url');
            print('PostWidget: Error: $error');
            print('PostWidget: Original avatar URL: ${widget.post.userAvatar}');
            // Fallback to initials if image fails to load
            return _buildAvatarInitials();
          },
        ),
      );
    } else {
      print('PostWidget: No valid avatar URL for ${widget.post.username}, showing initials');
      print('PostWidget: Avatar URL was: ${widget.post.userAvatar}');
      // If not a valid URL, show initials
      return _buildAvatarInitials();
    }
  }

  Widget _buildAvatarInitials() {
    // Use AvatarUtils for consistent styling
    return AvatarUtils.buildDefaultAvatar(
      name: widget.post.username,
      size: 40,
      borderColor: AppTheme.primaryColor,
      borderWidth: 1,
    );
  }

  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      child: Row(
        children: [
          // User Avatar
          GestureDetector(
            onTap: widget.onUserTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildAvatarContent(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Post Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPostTypeColor(widget.post.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPostTypeColor(widget.post.type).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.post.type.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getPostTypeColor(widget.post.type),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 2),
                
                Text(
                  _getTimeAgo(widget.post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          // Three Dots Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
              size: 20,
            ),
            onSelected: (value) {
              _handleMenuSelection(value);
            },
            itemBuilder: (context) => [
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
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caption
        if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildExpandableCaption(),
          ),
        
        // Image/Video Content
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            // Use original image aspect ratio to preserve natural dimensions
            final aspectRatio = 4 / 3; // Natural aspect ratio to preserve original image
            final height = maxWidth / aspectRatio; // Preserve original proportions
            
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
        
        // Hashtags
        if (widget.post.hashtags.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.post.hashtags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.type == PostType.image) {
      // Support multiple images
      final imagesToShow = widget.post.imageUrls.isNotEmpty 
          ? widget.post.imageUrls 
          : (widget.post.imageUrl != null ? [widget.post.imageUrl!] : []);
      
      if (imagesToShow.isNotEmpty) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            // Use natural aspect ratio to preserve original image dimensions
            final aspectRatio = 4 / 3;
            final height = maxWidth / aspectRatio; // Preserve original proportions
            
            // Use ImageSliderWidget for all images
            return Container(
              width: maxWidth,
              height: height,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to user profile when clicking the main content image
                    widget.onUserTap();
                  },
                  child: ImageSliderWidget(
                    imageUrls: imagesToShow.cast<String>(),
                    height: height,
                    showCounter: true,
                    onTap: () {
                      // Navigate to full screen image viewer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostFullViewScreen(post: widget.post),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      }
    } else if ((widget.post.type == PostType.video || widget.post.type == PostType.reel || widget.post.isReel) && widget.post.videoUrl != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          // Use different aspect ratios for reels vs regular videos
          final aspectRatio = (widget.post.type == PostType.reel || widget.post.isReel) ? 9 / 16 : 4 / 3; // Natural ratio for regular videos, 9:16 for reels
          final height = maxWidth / aspectRatio; // Preserve original proportions
          
          return Container(
            width: maxWidth,
            height: height,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Stack(
                children: [
                  // Video Player
                  VideoPlayerWidget(
                    videoUrl: widget.post.videoUrl ?? '',
                    autoPlay: false,
                    looping: true,
                    muted: true,
                  ),
                  
                  // Play/Pause Overlay - always show when video is not playing
                  if (!_isPlaying || _hasError)
                    Center(
                      child: GestureDetector(
                        onTap: _hasError ? null : _togglePlayPause,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _hasError ? Icons.error : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildPostActions() {
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? const Color(0xFF666666),
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? const Color(0xFF666666),
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced horizontal padding
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Likes
          if (_likeCount > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced padding
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_likeCount likes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Comments
          if (widget.post.comments > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced padding
              child: Text(
                '${widget.post.comments} comments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.image:
        return Colors.blue;
      case PostType.video:
        return Colors.purple;
      case PostType.reel:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }

  bool _isCurrentUserPost() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userProfile?.id == widget.post.userId;
  }

  void _handleMenuSelection(String value) {
    if (value == 'delete') {
      _showDeleteConfirmation();
    }
  }

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
      if (!mounted) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to delete posts'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting post permanently...'),
          duration: Duration(seconds: 2),
        ),
      );

      print('PostWidget: Starting permanent deletion for post ID: ${widget.post.id}');

      // Call deletion API directly (without strict verification)
      final response = await ApiService.deleteMedia(
        mediaId: widget.post.id,
        token: token,
      );

      print('PostWidget: Delete response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Post permanently deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Clear from local storage only after successful API deletion
        await LocalStorageService.deletePost(widget.post.id);
        
        // Call the delete callback if provided
        widget.onDelete?.call();
        
        // Force a rebuild to remove the post from UI
        if (mounted) {
          setState(() {});
        }
      } else {
        // Show error message with more details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete post'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('PostWidget: Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildVideoThumbnail() {
    final thumbnailUrl = widget.post.thumbnailUrl ?? widget.post.imageUrl ?? '';
    
    if (thumbnailUrl.isEmpty) {
      return Container(
        color: Colors.grey.withOpacity(0.1),
        child: const Center(
          child: Icon(
            Icons.video_library,
            color: Color(0xFF666666),
            size: 48,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: thumbnailUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey.withOpacity(0.1),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('PostWidget: Video thumbnail error for URL: $url');
        print('PostWidget: Error: $error');
        return Container(
          color: Colors.grey.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.video_library,
              color: Color(0xFF666666),
              size: 48,
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandableCaption() {
    const int maxLines = 3; // Show only 3 lines initially
    final caption = widget.post.caption!;
    
    // Check if caption is long enough to need expansion
    final textPainter = TextPainter(
      text: TextSpan(
        text: caption,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A1A),
          fontFamily: 'Poppins',
          height: 1.4,
        ),
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final isLongCaption = textPainter.didExceedMaxLines;
    
    if (!isLongCaption) {
      // If caption is short, show it normally
      return Text(
        caption,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A1A),
          fontFamily: 'Poppins',
          height: 1.4,
        ),
      );
    }
    
    // If caption is long, show expandable version
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Poppins',
                height: 1.4,
              ),
              maxLines: _isCaptionExpanded ? null : maxLines,
              overflow: _isCaptionExpanded ? null : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCaptionExpanded = !_isCaptionExpanded;
                });
              },
              child: Text(
                _isCaptionExpanded ? 'Show less' : 'Show more',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 