import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../screens/user_profile_screen.dart';
import '../services/user_media_service.dart';
import '../providers/auth_provider.dart';

class UserSearchResultWidget extends StatefulWidget {
  final String id;
  final String username;
  final String fullName;
  final String? profileImageUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isVerified;
  final bool isFollowedByCurrentUser;
  final String? bio;
  final bool isPrivate;

  const UserSearchResultWidget({
    super.key,
    required this.id,
    required this.username,
    required this.fullName,
    this.profileImageUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isVerified,
    required this.isFollowedByCurrentUser,
    this.bio,
    this.isPrivate = false,
  });

  @override
  State<UserSearchResultWidget> createState() => _UserSearchResultWidgetState();
}

class _UserSearchResultWidgetState extends State<UserSearchResultWidget> {
  int _realPostsCount = 0;
  bool _isLoadingRealCount = false;

  @override
  void initState() {
    super.initState();
    _loadRealPostCount();
    _loadRealCounts();
  }

  Future<void> _loadRealPostCount() async {
    if (widget.id.isEmpty) return;
    
    setState(() {
      _isLoadingRealCount = true;
    });

    try {
      // Fetch real post count from API
      final realCount = await UserMediaService.getRealPostCount(
        userId: widget.id,
      );
      
      if (mounted) {
        setState(() {
          _realPostsCount = realCount;
          _isLoadingRealCount = false;
        });
      }
    } catch (e) {
      print('Error loading real post count: $e');
      if (mounted) {
        setState(() {
          _isLoadingRealCount = false;
        });
      }
    }
  }

  Future<void> _loadRealCounts() async {
    if (widget.id.isEmpty) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final counts = await authProvider.getUserCounts(widget.id);
      
      if (mounted) {
        setState(() {
          // Update followers/following counts will be handled separately if needed
        });
      }
    } catch (e) {
      print('Error loading real counts: $e');
    }
  }

  // Use real count if available, otherwise fallback to search API count
  int get displayPostsCount {
    if (_isLoadingRealCount) {
      return widget.postsCount; // Show search API count while loading
    }
    // Show real count if available and greater than 0, otherwise use search API count
    return _realPostsCount > 0 ? _realPostsCount : widget.postsCount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: ListTile(
        leading: _buildProfilePicture(),
        title: _buildUsername(),
        subtitle: _buildSubtitle(),
        trailing: _buildActionButton(),
        onTap: () => _navigateToProfile(context),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
        child: ClipOval(
        child: widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
            ? Image.network(
                widget.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderAvatar();
                },
              )
            : _buildPlaceholderAvatar(),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: 25,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildUsername() {
    return Row(
      children: [
        Text(
          widget.username,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A2C2A), // Deep Brown
          ),
        ),
        if (widget.isVerified) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.verified,
            color: Colors.blue,
            size: 14,
          ),
        ],
      ],
    );
  }

  Widget _buildSubtitle() {
    String subtitle = widget.fullName;
    
    // Add post count to subtitle with real data
    if (displayPostsCount > 0) {
      subtitle += ' • ${displayPostsCount} ${displayPostsCount == 1 ? 'post' : 'posts'}';
    }
    
    if (widget.followersCount > 0) {
      subtitle += ' • ${_formatCount(widget.followersCount)} followers';
    }
    
    if (widget.isFollowedByCurrentUser) {
      subtitle += ' • Followed by you';
    }
    
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButton() {
    if (widget.isFollowedByCurrentUser) {
      return Container(
        width: 80,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'Following',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 80,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF2E5D4F), // Deep Green
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Text(
            'Follow',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
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

  void _navigateToProfile(BuildContext context) {
    // Create a UserModel from the search result
    final user = UserModel(
      id: widget.id,
      name: widget.fullName,
      email: '', // Not available in search results
      username: widget.username,
      profileImageUrl: widget.profileImageUrl,
      bio: widget.bio,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      verificationStatus: widget.isVerified ? UserVerificationStatus.verified : UserVerificationStatus.unverified,
      followersCount: widget.followersCount,
      followingCount: widget.followingCount,
      postsCount: displayPostsCount, // Use real post count
      reelsCount: 0,
      followers: [],
      following: [],
      isOnline: false,
      isPrivate: widget.isPrivate,
      isEmailVerified: false,
      isVerified: widget.isVerified,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: widget.id,
          username: widget.username,
          fullName: widget.fullName,
          avatar: widget.profileImageUrl ?? '',
          bio: widget.bio ?? '',
          followersCount: widget.followersCount,
          followingCount: widget.followingCount,
          postsCount: displayPostsCount, // Pass real post count
          isPrivate: widget.isPrivate,
        ),
      ),
    );
  }
}
