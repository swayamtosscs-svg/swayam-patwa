import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/user_profile_screen.dart';

class UserSearchResultWidget extends StatelessWidget {
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
  });

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
        child: profileImageUrl != null && profileImageUrl!.isNotEmpty
            ? Image.network(
                profileImageUrl!,
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
          username,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A2C2A), // Deep Brown
          ),
        ),
        if (isVerified) ...[
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
    String subtitle = fullName;
    
    if (followersCount > 0) {
      subtitle += ' • ${_formatCount(followersCount)} followers';
    }
    
    if (isFollowedByCurrentUser) {
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
    if (isFollowedByCurrentUser) {
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
      id: id,
      name: fullName,
      email: '', // Not available in search results
      username: username,
      profileImageUrl: profileImageUrl,
      bio: bio,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      verificationStatus: isVerified ? UserVerificationStatus.verified : UserVerificationStatus.unverified,
      followersCount: followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      reelsCount: 0,
      followers: [],
      following: [],
      isOnline: false,
      isPrivate: false,
      isEmailVerified: false,
      isVerified: isVerified,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: id,
          username: username,
          fullName: fullName,
          avatar: profileImageUrl ?? '',
          bio: bio ?? '',
          followersCount: followersCount,
          followingCount: followingCount,
          postsCount: postsCount,
        ),
      ),
    );
  }
}
