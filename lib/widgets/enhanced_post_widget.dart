import 'package:flutter/material.dart';
import 'video_player_widget.dart';
import '../models/post_model.dart';
import '../models/baba_page_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/baba_like_service.dart';
import '../services/user_like_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/user_profile_screen.dart';
import '../screens/post_full_view_screen.dart';
import '../screens/post_slider_screen.dart';
import '../screens/baba_profile_ui_demo.dart';
import '../utils/avatar_utils.dart';
import '../utils/responsive_image_utils.dart';
import 'baba_comment_dialog.dart';
import 'user_comment_dialog.dart';
import 'image_slider_widget.dart';

class EnhancedPostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback? onLike; // Optional callback for like actions
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onUserTap;
  final VoidCallback onPostTap;
  final VoidCallback? onDelete; // Add delete callback

  const EnhancedPostWidget({
    super.key,
    required this.post,
    this.onLike, // Optional callback for like actions
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
  bool _isPlaying = false;
  bool _isCaptionExpanded = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    print('EnhancedPostWidget: Initializing post widget for post: ${widget.post.id}');
    print('EnhancedPostWidget: Post type: ${widget.post.type}, isReel: ${widget.post.isReel}, videoUrl: ${widget.post.videoUrl}');
    
    // Initialize like count and status from post data
    _likeCount = widget.post.likes;
    _isLiked = widget.post.isLiked;
    
    // Load like status for both Baba Ji posts and regular user posts
    _loadLikeStatus();
    
    if (widget.post.type == PostType.reel || widget.post.isReel) {
      print('EnhancedPostWidget: This is a reel, initializing video...');
      _initializeVideo();
    } else {
      print('EnhancedPostWidget: This is not a reel, skipping video initialization');
    }
  }

  @override
  void dispose() {
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
      
      // Video player is now handled by VideoPlayerWidget
      print('EnhancedPostWidget: Video will be handled by VideoPlayerWidget');
    } catch (e) {
      print('EnhancedPostWidget: Error: $e');
    }
  }

  void _togglePlayPause() {
    // Play/pause is handled by VideoPlayerWidget
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  Future<void> _loadLikeStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      final token = authProvider.authToken;
      
      if (userId == null || token == null) return;

      Map<String, dynamic>? response;

      if (widget.post.isBabaJiPost) {
        // Handle Baba Ji posts
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
      } else {
        // Handle regular user posts - use API to get like status
        // For Baba Ji posts, remove the prefix to get the original post ID
        String actualPostId = widget.post.id;
        if (widget.post.isBabaJiPost) {
          actualPostId = widget.post.id.replaceFirst('baba_', '');
        }
        
        response = await ApiService.getPostLikeStatus(
          postId: actualPostId,
          token: token,
        );
      }

      if (response != null && response['success'] == true && mounted) {
        setState(() {
          _isLiked = response?['data']?['liked'] ?? response?['data']?['isLiked'] ?? response?['isLiked'] ?? false;
          // Update like count from server response if available
          if (response?['data']?['likesCount'] != null) {
            _likeCount = response?['data']?['likesCount'] ?? _likeCount;
          } else if (response?['likeCount'] != null) {
            _likeCount = response?['likeCount'] ?? _likeCount;
          }
        });
      }
    } catch (e) {
      print('Error loading like status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Better spacing like second image
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Slightly stronger shadow
            blurRadius: 15,
            offset: const Offset(0, 4),
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
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Use AvatarUtils to properly handle avatar URLs
    if (widget.post.userAvatar.isNotEmpty && AvatarUtils.isValidAvatarUrl(widget.post.userAvatar)) {
      final absoluteAvatarUrl = AvatarUtils.getAbsoluteAvatarUrl(widget.post.userAvatar);
      print('EnhancedPostWidget: Loading avatar for ${widget.post.username}: $absoluteAvatarUrl');
      
      // If it's a valid URL, show the image
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          absoluteAvatarUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('EnhancedPostWidget: Avatar load error for URL: $absoluteAvatarUrl');
            print('EnhancedPostWidget: Error: $error');
            // Fallback to initials if image fails to load
            return _buildAvatarInitials();
          },
        ),
      );
    } else {
      print('EnhancedPostWidget: No valid avatar URL for ${widget.post.username}, showing initials');
      print('EnhancedPostWidget: Avatar URL was: ${widget.post.userAvatar}');
      // If not a valid URL, show initials
      return _buildAvatarInitials();
    }
  }

  Widget _buildAvatarInitials() {
    // Use AvatarUtils for consistent styling
    return AvatarUtils.buildDefaultAvatar(
      name: widget.post.username,
      size: 40,
      borderColor: const Color(0xFF6366F1),
      borderWidth: 1,
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
              child: _buildExpandableCaption(),
            ),
          
          // Image/Video Content - Full width like second image
          Container(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: _buildMediaContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    // Check if it's a video/reel
    if (widget.post.type == PostType.video || widget.post.type == PostType.reel || widget.post.isReel) {
      if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
        // Use consistent height for videos like second image
        return Container(
          height: 300, // Reduced height to match images and prevent stretching
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
                VideoPlayerWidget(
                  videoUrl: widget.post.videoUrl ?? '',
                  autoPlay: false,
                  looping: true,
                  muted: true,
                ),
                
                // Play/Pause Overlay - always show when video is not playing
                if (!_isPlaying)
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
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
      // Show images - support multiple images
      final imagesToShow = widget.post.imageUrls.isNotEmpty 
          ? widget.post.imageUrls 
          : (widget.post.imageUrl != null ? [widget.post.imageUrl!] : []);
      
      if (imagesToShow.isNotEmpty) {
        // Use ImageSliderWidget for all images with improved aspect ratio handling
        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate optimal height based on screen width and image count
            final screenWidth = constraints.maxWidth;
            final optimalHeight = ResponsiveImageUtils.calculateOptimalImageHeight(
              screenWidth: screenWidth,
              imageCount: imagesToShow.length,
              maxHeight: 500.0,
              minHeight: 250.0,
            );
            
            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to user profile when clicking the main content image
                    _navigateToUserProfile();
                  },
                  child: ImageSliderWidget(
                    imageUrls: imagesToShow.cast<String>(),
                    height: optimalHeight,
                    showCounter: true,
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
                  ),
                ),
              ],
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute buttons evenly
        children: [
          // Like Button - For all posts
          Expanded(
            child: GestureDetector(
              onTap: _handleLike,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : const Color(0xFF666666),
                    size: 24, // Reduced size
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Like',
                    style: TextStyle(
                      fontSize: 12, // Reduced font size
                      fontWeight: FontWeight.w500,
                      color: _isLiked ? Colors.red : const Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_likeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: _isLiked ? Colors.red : const Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Comment Button
          Expanded(
            child: GestureDetector(
              onTap: _handleComment,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF666666),
                    size: 24, // Reduced size
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 12, // Reduced font size
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
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

      if (widget.post.isBabaJiPost) {
        // Handle Baba Ji posts
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
      } else {
        // Handle regular user posts - use the working like API
        // For Baba Ji posts, remove the prefix to get the original post ID
        String actualPostId = widget.post.id;
        if (widget.post.isBabaJiPost) {
          actualPostId = widget.post.id.replaceFirst('baba_', '');
        }
        
        print('EnhancedPostWidget: Attempting to like post with ID: $actualPostId (original: ${widget.post.id})');
        print('EnhancedPostWidget: Post isBabaJiPost: ${widget.post.isBabaJiPost}');
        
        if (_isLiked) {
          response = await ApiService.unlikePost(
            postId: actualPostId,
            token: token,
            userId: userId,
          );
        } else {
          response = await ApiService.likePost(
            postId: actualPostId,
            token: token,
            userId: userId,
          );
        }
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
        
        // Call the callback to notify parent if provided
        if (widget.onLike != null) {
          widget.onLike!();
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
      // Show comment dialog for regular user posts
      showDialog(
        context: context,
        builder: (context) => UserCommentDialog(
          postId: widget.post.id,
          onCommentAdded: () {
            // Call the callback to notify parent
            widget.onComment();
          },
        ),
      );
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
          content: Text('Deleting post permanently...'),
          duration: Duration(seconds: 2),
        ),
      );

      print('EnhancedPostWidget: Starting permanent deletion for post ID: ${widget.post.id}');

      // Call deletion API directly
      final response = await ApiService.deleteMedia(
        mediaId: widget.post.id,
        token: token,
      );

      print('EnhancedPostWidget: Delete response: $response');

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete post'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('EnhancedPostWidget: Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _navigateToUserProfile() {
    print('Navigating to profile for user: ${widget.post.userId}, username: ${widget.post.username}, isBabaJiPost: ${widget.post.isBabaJiPost}');
    
    try {
      if (widget.post.isBabaJiPost && widget.post.babaPageData != null) {
        print('Baba Ji profile detected with complete data, navigating to Baba Ji profile UI demo screen');
        // Navigate to Baba Ji profile UI demo screen with complete data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BabaProfileUiDemoScreen(
              babaPage: widget.post.babaPageData,
            ),
          ),
        );
      } else if (widget.post.isBabaJiPost) {
        print('Baba Ji profile detected but no complete data, fetching Baba Ji page data');
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          // Fetch Baba Ji page data
          // Note: You may need to implement a service method to fetch Baba Ji page data by userId
          // For now, we'll navigate to a basic Baba Ji profile screen
          Navigator.of(context).pop(); // Close loading dialog
          
          // Navigate to Baba Ji profile UI demo screen with basic data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BabaProfileUiDemoScreen(
                babaPage: BabaPage(
                  id: widget.post.userId,
                  name: widget.post.username,
                  description: 'Baba Ji Profile',
                  avatar: widget.post.userAvatar,
                  coverImage: '',
                  location: '',
                  religion: 'Hinduism',
                  website: '',
                  creatorId: widget.post.userId,
                  followersCount: 0,
                  postsCount: 0,
                  videosCount: 0,
                  storiesCount: 0,
                  isActive: true,
                  isFollowing: false,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ),
            ),
          );
        } catch (e) {
          Navigator.of(context).pop(); // Close loading dialog
          print('Error fetching Baba Ji page data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading Baba Ji profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('Regular user profile, navigating to user profile screen');
        // Navigate to regular user profile screen
        Navigator.push(
          context,
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
    } catch (e) {
      print('Error navigating to profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
