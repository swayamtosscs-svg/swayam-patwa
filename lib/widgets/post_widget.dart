import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/post_model.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../screens/post_full_view_screen.dart';
import 'image_slider_widget.dart';

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
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  bool _isCaptionExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.type == PostType.reel || widget.post.isReel) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.post.videoUrl == null) return;
    
    try {
      print('PostWidget: Initializing reel video: ${widget.post.videoUrl}');
      
      _videoController = VideoPlayerController.network(
        widget.post.videoUrl!,
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
        
        // Auto-play reels
        print('PostWidget: Starting reel autoplay...');
        await _startAutoplayWithRetry();
      }
    } catch (e) {
      print('PostWidget: Error initializing reel video: $e');
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
        print('PostWidget: Reel autoplay started successfully (attempt ${retryCount + 1})');
        break;
      } catch (playError) {
        retryCount++;
        print('PostWidget: Reel autoplay attempt $retryCount failed: $playError');
        
        if (retryCount < maxRetries) {
          // Wait before retrying, with increasing delay
          await Future.delayed(Duration(milliseconds: 300 * retryCount));
        } else {
          print('PostWidget: All reel autoplay attempts failed');
        }
      }
    }
  }

  void _togglePlayPause() async {
    if (_hasError) return;
    
    // If video is not initialized yet, try to initialize it
    if (!_isVideoInitialized && widget.post.videoUrl != null) {
      await _initializeVideo();
      return;
    }
    
    if (_videoController != null && _isVideoInitialized) {
      if (_isPlaying) {
        await _videoController!.pause();
      } else {
        await _videoController!.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to full screen post view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostFullViewScreen(post: widget.post),
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
    // Check if userAvatar is a valid image URL
    if (widget.post.userAvatar.isNotEmpty && 
        (widget.post.userAvatar.startsWith('http://') || widget.post.userAvatar.startsWith('https://'))) {
      // If it's a valid URL, show the image with caching
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: widget.post.userAvatar,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          placeholder: (context, url) => Container(
            width: 40,
            height: 40,
            color: Colors.grey[200],
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
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
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
                  // Video Player or Thumbnail
                  if (_isVideoInitialized && _videoController != null && !_hasError)
                    VideoPlayer(_videoController!)
                  else
                    _buildVideoThumbnail(),
                  
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced horizontal padding
      child: Row(
        children: [
          
          // Comment Button
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: '${widget.post.comments}',
            onTap: widget.onComment,
          ),
          
          const SizedBox(width: 24),
          
          // Share Button
          _buildActionButton(
            icon: Icons.share,
            label: '${widget.post.shares}',
            onTap: widget.onShare,
          ),
          
          const Spacer(),
          
          // Bookmark Button
          IconButton(
            onPressed: () {
              // Handle bookmark
            },
            icon: const Icon(
              Icons.bookmark_border,
              color: Color(0xFF666666),
              size: 20,
            ),
          ),
        ],
      ),
    );
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
          if (widget.post.likes > 0) ...[
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
                    '${widget.post.likes} likes',
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