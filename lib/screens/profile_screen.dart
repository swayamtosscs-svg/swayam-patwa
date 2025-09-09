import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../widgets/post_widget.dart';
import 'package:flutter/foundation.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/following_screen.dart';
import '../screens/followers_screen.dart';
import '../utils/app_theme.dart';
import '../services/post_service.dart';
import '../services/user_media_service.dart';
import '../screens/user_profile_screen.dart'; // Added import for UserProfileScreen
import '../screens/chat_screen.dart'; // Added import for ChatScreen

import '../widgets/profile_picture_widget.dart'; // Added import for ProfilePictureWidget
import '../screens/profile_picture_test_screen.dart'; // Added import for ProfilePictureTestScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.userProfile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.refreshUserProfile();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(authProvider.userProfile!),
                  
                  // Profile Stats
                  _buildProfileStats(authProvider.userProfile!),
                  
                  // Tab Bar
                  _buildTabBar(),
                  
                  // Tab Content
                  _buildTabContent(authProvider.userProfile!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isRefreshing ? null : () async {
                    setState(() {
                      _isRefreshing = true;
                    });
                    
                    try {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.refreshUserProfile();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile refreshed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to refresh profile: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                        });
                      }
                    }
                  },
                  icon: _isRefreshing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
                ),
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditScreen(user: user),
                      ),
                    );
                    
                    if (result == true) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.refreshUserProfile();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.edit, color: Color(0xFF1A1A1A)),
                ),
                
                // Test Profile Picture Button
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePictureTestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
                  tooltip: 'Test Profile Picture',
                ),
                
                // Message Button (only show if not own profile)
                if (Provider.of<AuthProvider>(context, listen: false).userProfile?.id != user.id)
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipientUserId: user.id,
                            recipientUsername: user.username ?? '',
                            recipientFullName: user.name,
                            recipientAvatar: user.profileImageUrl,
                            threadId: null, // New conversation
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, color: Color(0xFF6366F1)),
                    tooltip: 'Send Message',
                  ),
                // Logout Button
                IconButton(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: Color(0xFFE53E3E)),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
          
          // Profile Content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getReligionColor(user.selectedReligion).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Profile Image
                Builder(
                  builder: (context) {
                    print('ProfileScreen: Building ProfilePictureWidget');
                    print('ProfileScreen: User profile image URL: ${user.profileImageUrl}');
                    print('ProfileScreen: User ID: ${user.id}');
                    print('ProfileScreen: Auth token available: ${Provider.of<AuthProvider>(context, listen: false).authToken?.isNotEmpty}');
                    
                    return ProfilePictureWidget(
                      currentImageUrl: user.profileImageUrl,
                      userId: user.id,
                      token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
                                        onImageChanged: (String newImageUrl) async {
                        print('ProfileScreen: Profile picture changed to: $newImageUrl');
                        // Update the user profile with new image URL
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        if (authProvider.userProfile != null) {
                          print('ProfileScreen: Updating local user profile');
                          final updatedUser = authProvider.userProfile!.copyWith(
                            profileImageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                          );
                          print('ProfileScreen: Updated user profile image: ${updatedUser.profileImageUrl}');
                          authProvider.updateLocalUserProfile(updatedUser);
                        } else {
                          print('ProfileScreen: No user profile found in auth provider');
                        }
                      },
                      size: 120,
                      borderColor: _getReligionColor(user.selectedReligion),
                      showEditButton: true,
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // User Name and Verification
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (user.isVerified)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Username
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bio
                if (user.bio != null && user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      user.bio!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Website
                if (user.website != null && user.website!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.link,
                          size: 16,
                          color: Color(0xFF666666),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.website!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6366F1),
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Privacy Toggle Button
                _buildPrivacyToggleButton(user),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildProfileStats(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Posts', '0'),
                ),
                Expanded(
                  child: _buildStatItem('Reels', '0'),
                ),
                Expanded(
                  child: _buildStatItem('Followers', user.followersCount.toString()),
                ),
                Expanded(
                  child: _buildStatItem('Following', user.followingCount.toString()),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

            return FutureBuilder<UserMediaResponse>(
          future: UserMediaService.getUserMedia(userId: user.id),
          builder: (context, snapshot) {
            // Debug: Log the user ID being used
            print('ProfileScreen Stats: Using user ID: ${user.id} for ${user.username}');
        
        int postsCount = 0;
        int reelsCount = 0;
        
        if (snapshot.hasData && snapshot.data!.success) {
          postsCount = snapshot.data!.posts.length;
          reelsCount = snapshot.data!.reels.length;
          
          // Debug logging
          print('Profile Stats: Total posts: ${snapshot.data!.posts.length}, Image posts: $postsCount, Reels: $reelsCount');
          for (final post in snapshot.data!.posts) {
            print('Profile Stats Post: ${post.id} - Type: ${post.type} - Caption: ${post.caption}');
          }
        } else {
          print('ProfileScreen Stats: No data or failed for user ${user.id}');
          if (snapshot.hasError) {
            print('ProfileScreen Stats: Error: ${snapshot.error}');
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItemWithCount('Posts', postsCount.toString(), () => _setTabIndex(0)),
                  ),
                  Expanded(
                    child: _buildStatItemWithCount('Reels', reelsCount.toString(), () => _setTabIndex(1)),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowersScreen(userId: user.id),
                          ),
                        );
                      },
                      child: _buildStatItem('Followers', user.followersCount.toString()),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowingScreen(userId: user.id),
                          ),
                        );
                      },
                      child: _buildStatItem('Following', user.followingCount.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Privacy Status Indicator
              _buildPrivacyStatusIndicator(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyStatusIndicator(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: user.isPrivate ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isPrivate ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            user.isPrivate ? Icons.lock : Icons.public,
            color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Text(
            user.isPrivate ? 'Private Account' : 'Public Account',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _setTabIndex(int index) {
    _tabController.animateTo(index);
  }

  Widget _buildStatItemWithCount(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 2, color: Color(0xFF6366F1)),
          ),
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF666666),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
          tabs: const [
            Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Reels'),
            Tab(icon: Icon(Icons.favorite), text: 'Liked'),
            Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
          ],
        ),
    );
  }

  Widget _buildTabContent(UserModel user) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.6, // Fixed height to prevent overflow
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(user),
            _buildReelsTab(user),
            _buildLikedTab(),
            _buildSavedTab(),
          ],
        ),
    );
  }

  Widget _buildPostsTab(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      return const Center(
        child: Text('Please login to view posts'),
      );
    }
    
            return FutureBuilder<UserMediaResponse>(
          future: UserMediaService.getUserMedia(userId: user.id),
          builder: (context, snapshot) {
            // Debug: Log the user ID being used for posts tab
            print('ProfileScreen Posts Tab: Using user ID: ${user.id} for ${user.username}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('ProfileScreen Posts Tab: Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading posts: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final userMedia = snapshot.data;
        if (userMedia == null || !userMedia.success) {
          print('ProfileScreen Posts Tab: No data or failed for user ${user.id}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load posts: Unknown error'),
              ],
            ),
          );
        }
        
        // Get only image posts
        final posts = userMedia.posts;
        
        // Debug logging
        print('ProfileScreen Posts Tab: Found ${posts.length} posts from API for user ${user.id}');
        for (final post in posts) {
          print('ProfileScreen Posts Tab Post: ${post.id} - ${post.caption} - ${post.imageUrl} - Type: ${post.type}');
        }
        
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No posts yet'),
                Text('Share your first post!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isSmallScreen = maxHeight < 600;
            
            return Container(
              height: maxHeight,
              child: ListView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // Reduce padding
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8), // Reduce margin
                    child: PostWidget(
                      post: post,
                      onLike: () async {
                        try {
                          await PostService.toggleLike(
                            postId: post.id,
                            token: authProvider.authToken!,
                          );
                          // Refresh the posts tab
                          setState(() {});
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to like post: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onComment: () {
                        // Handle comment
                      },
                      onShare: () {
                        // Handle share
                      },
                      onUserTap: () {
                        _navigateToUserProfile(post);
                      },
                      onDelete: () {
                        // Remove the deleted post from the list and refresh
                        setState(() {
                          posts.removeWhere((p) => p.id == post.id);
                        });
                        print('Post deleted: ${post.id}');
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReelsTab(UserModel user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken == null) {
      return const Center(
        child: Text('Please login to view reels'),
      );
    }
    
    return FutureBuilder<UserMediaResponse>(
      future: UserMediaService.getUserMedia(userId: user.id),
      builder: (context, snapshot) {
        // Debug: Log the username being used for reels tab
        print('ProfileScreen Reels Tab: Using username: ${user.username} for ${user.id}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          print('ProfileScreen Reels Tab: Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading reels: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final userMedia = snapshot.data;
        if (userMedia == null || !userMedia.success) {
          print('ProfileScreen Reels Tab: No data or failed for username: ${user.username}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load reels: Unknown error'),
              ],
            ),
          );
        }
        
        // Get only reels (videos)
        final reels = userMedia.reels;
        
        // Debug logging
        print('ProfileScreen Reels Tab: Found ${reels.length} reels from API for username: ${user.username}');
        for (final reel in reels) {
          print('ProfileScreen Reels Tab Reel: ${reel.id} - ${reel.caption} - ${reel.videoUrl} - Type: ${reel.type}');
        }
        
        if (reels.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No reels yet'),
                Text('Share your first reel!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isSmallScreen = maxHeight < 600;
            
            return Container(
              height: maxHeight,
              child: ListView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12), // Reduce padding
                itemCount: reels.length,
                itemBuilder: (context, index) {
                  final reel = reels[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8), // Reduce margin
                    child: PostWidget(
                      post: reel,
                      onLike: () async {
                        try {
                          await PostService.toggleLike(
                            postId: reel.id,
                            token: authProvider.authToken!,
                          );
                          // Refresh the reels tab
                          setState(() {});
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to like reel: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onComment: () {
                        // Handle comment
                      },
                      onShare: () {
                        // Handle share
                      },
                      onUserTap: () {
                        _navigateToUserProfile(reel);
                      },
                      onDelete: () {
                        // Remove the deleted reel from the list and refresh
                        setState(() {
                          reels.removeWhere((r) => r.id == reel.id);
                        });
                        print('Reel deleted: ${reel.id}');
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLikedTab() {
    return FutureBuilder<List<Post>>(
      future: Provider.of<AuthProvider>(context, listen: false).getLikedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading liked posts: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final posts = snapshot.data ?? [];
        
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No liked posts yet'),
                Text('Like some posts to see them here!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Fixed height
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostWidget(
                post: post,
                onLike: () async {
                  try {
                    await Provider.of<AuthProvider>(context, listen: false).likePost(post.id);
                    // Refresh the liked posts tab
                    setState(() {});
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to like post: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onComment: () {
                  // Handle comment
                },
                onShare: () {
                  // Handle share
                },
                onUserTap: () {
                  _navigateToUserProfile(post);
                },
                onDelete: () {
                  // Remove the deleted post from the list and refresh
                  setState(() {
                    posts.removeWhere((p) => p.id == post.id);
                  });
                  print('Post deleted: ${post.id}');
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<AuthProvider>(context, listen: false).getSavedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading saved posts: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final postsData = snapshot.data ?? [];
        
        if (postsData.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No saved posts yet'),
                Text('Save posts to view them later!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Fixed height
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: postsData.length,
            itemBuilder: (context, index) {
              final postData = postsData[index];
              final post = _createPostFromData(postData);
              return PostWidget(
                post: post,
                onLike: () async {
                  try {
                    await Provider.of<AuthProvider>(context, listen: false).likePost(post.id);
                    // Refresh the saved posts tab
                    setState(() {});
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to like post: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onComment: () {
                  // Handle comment
                },
                onShare: () {
                  // Handle share
                },
                onUserTap: () {
                  _navigateToUserProfile(post);
                },
                onDelete: () {
                  // Remove the deleted post from the list and refresh
                  setState(() {
                    postsData.removeWhere((p) => p['id'] == post.id || p['_id'] == post.id);
                  });
                  print('Post deleted: ${post.id}');
                },
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to create Post objects from API data
  Post _createPostFromData(Map<String, dynamic> postData) {
    return Post(
      id: postData['id'] ?? postData['_id'] ?? '',
      userId: postData['userId'] ?? postData['user_id'] ?? '',
      username: postData['username'] ?? '',
      userAvatar: postData['userAvatar'] ?? postData['user_avatar'] ?? '',
      caption: postData['caption'] ?? '',
      imageUrl: postData['imageUrl'] ?? postData['image_url'],
      videoUrl: postData['videoUrl'] ?? postData['video_url'],
      type: _parsePostType(postData['type'] ?? 'image'),
      likes: postData['likes'] ?? postData['likesCount'] ?? 0,
      comments: postData['comments'] ?? postData['commentsCount'] ?? 0,
      shares: postData['shares'] ?? postData['sharesCount'] ?? 0,
      createdAt: postData['createdAt'] != null 
          ? DateTime.parse(postData['createdAt']) 
          : DateTime.now(),
      hashtags: List<String>.from(postData['hashtags'] ?? []),
    );
  }

  // Helper method to parse post type
  PostType _parsePostType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'reel':
        return PostType.reel;
      default:
        return PostType.image;
    }
  }

  // Helper methods
  Color _getReligionColor(Religion? religion) {
    switch (religion) {
      case Religion.hinduism:
        return Colors.orange;
      case Religion.islam:
        return Colors.green;
      case Religion.christianity:
        return Colors.blue;
      case Religion.buddhism:
        return Colors.purple;
      case Religion.sikhism:
        return Colors.amber;
      case Religion.judaism:
        return Colors.indigo;
      case Religion.other:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                // Close dialog first
                Navigator.of(context).pop();
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Logging out...'),
                        ],
                      ),
                    );
                  },
                );
                
                try {
                  // Call logout
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  
                  // Close loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  
                  // Navigate to signup screen (as requested by user)
                  if (mounted) {
                    // Show immediate feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logging out...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    
                    // Immediately redirect to signup page
                    Navigator.of(context).pushNamedAndRemoveUntil('/signup', (route) => false);
                    
                    // Logout in background (don't wait for it)
                    authProvider.logout().catchError((e) {
                      print('Background logout error: $e');
                    });
                  }
                } catch (e) {
                  // Close loading dialog
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                  
                  // Show error message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSettingsMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userProfile;
    
    final List<PopupMenuEntry<String>> menuItems = [
      const PopupMenuItem(
        value: 'edit_profile',
        child: Text('Edit Profile'),
      ),
      const PopupMenuItem(
        value: 'followers',
        child: Text('Followers'),
      ),
      const PopupMenuItem(
        value: 'following',
        child: Text('Following'),
      ),

      const PopupMenuDivider(), // Add separator
      // Privacy Toggle Menu Item
      if (user != null)
        PopupMenuItem(
          value: 'toggle_privacy',
          child: Row(
            children: [
              Icon(
                user.isPrivate ? Icons.lock : Icons.public,
                color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                user.isPrivate ? 'Make Public' : 'Make Private',
                style: TextStyle(
                  color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      const PopupMenuDivider(), // Add separator
      const PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFE53E3E)),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(color: Color(0xFFE53E3E))),
          ],
        ),
      ),
    ];

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 100,
        MediaQuery.of(context).size.height - 100,
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height,
      ),
      items: menuItems,
    ).then((value) {
      if (value == 'edit_profile') {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userProfile!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileEditScreen(user: user),
          ),
        );
      } else if (value == 'followers') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowersScreen(userId: Provider.of<AuthProvider>(context, listen: false).userProfile!.id),
          ),
        );
      } else if (value == 'following') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowingScreen(userId: Provider.of<AuthProvider>(context, listen: false).userProfile!.id),
          ),
        );
      } else if (value == 'toggle_privacy') {
        _handlePrivacyToggle(context);
      } else if (value == 'logout') {
        _showLogoutDialog(context);
      }
    });
  }

  void _navigateToUserProfile(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: post.userId,
          username: post.username,
          fullName: post.username, // Use username as fallback for fullName
          avatar: post.userAvatar,
          bio: '', // Default empty bio
          followersCount: 0, // Default value
          followingCount: 0, // Default value
          postsCount: 0, // Default value
          isPrivate: false, // Default to public, will be updated when user profile is loaded
        ),
      ),
    );
  }

  void _handlePrivacyToggle(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userProfile;
    
    if (user == null) return;
    
    try {
      final success = await authProvider.toggleAccountPrivacy();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account is now ${user.isPrivate ? 'public' : 'private'}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'Failed to toggle privacy',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPrivacyToggleButton(UserModel user) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Privacy Status Icon
              Icon(
                user.isPrivate ? Icons.lock : Icons.public,
                size: 20,
                color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              
              // Privacy Status Text
              Text(
                user.isPrivate ? 'Private Account' : 'Public Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: user.isPrivate ? const Color(0xFFE53E3E) : const Color(0xFF10B981),
                  fontFamily: 'Poppins',
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Toggle Button
              GestureDetector(
                onTap: authProvider.isLoading ? null : () async {
                  try {
                    final success = await authProvider.toggleAccountPrivacy();
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Account is now ${user.isPrivate ? 'public' : 'private'}',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authProvider.error ?? 'Failed to toggle privacy',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: const Color(0xFFE53E3E),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          backgroundColor: const Color(0xFFE53E3E),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: user.isPrivate ? const Color(0xFF10B981) : const Color(0xFFE53E3E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: user.isPrivate ? const Color(0xFF10B981) : const Color(0xFFE53E3E),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (authProvider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          user.isPrivate ? Icons.public : Icons.lock,
                          size: 16,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        authProvider.isLoading 
                          ? 'Updating...' 
                          : (user.isPrivate ? 'Make Public' : 'Make Private'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
      },
    );
  }
} 