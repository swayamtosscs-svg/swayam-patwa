import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced margins
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
        if (widget.post.caption != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced padding
            child: Text(
              widget.post.caption!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Media Content
        if (widget.post.imageUrl != null || widget.post.videoUrl != null) ...[
          _buildMediaContent(),
          const SizedBox(height: 12),
        ],
        
        // Hashtags
        if (widget.post.hashtags.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12), // Reduced padding
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
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildMediaContent() {
    if (widget.post.type == PostType.image && widget.post.imageUrl != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final aspectRatio = 4 / 3; // 4:3 aspect ratio
          final height = (maxWidth / aspectRatio).clamp(200.0, 300.0); // Min 200, Max 300
          
          return Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 12), // Reduced margin
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.post.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Color(0xFF666666),
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else if (widget.post.type == PostType.video && widget.post.videoUrl != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final aspectRatio = 4 / 3; // 4:3 aspect ratio
          final height = (maxWidth / aspectRatio).clamp(200.0, 300.0); // Min 200, Max 300
          
          return Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 12), // Reduced margin
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    widget.post.thumbnailUrl ?? widget.post.imageUrl ?? '',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.withOpacity(0.1),
                      child: const Center(
                        child: Icon(
                          Icons.video_library,
                          color: Color(0xFF666666),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Color(0xFF666666),
                        size: 30,
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
} 