import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';
import '../screens/followers_screen.dart';
import '../screens/following_screen.dart';
import '../services/user_media_service.dart';
import '../screens/chat_screen.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String fullName;
  final String avatar;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isPrivate;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatar,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.isPrivate = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _userPosts = [];
  List<Post> _userReels = [];
  bool _isLoadingPosts = false;
  bool _isLoadingReels = false;
  bool _isFollowing = false;
  bool _isLoadingFollowRequest = false;

  String get _targetUserId => widget.userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserMedia();
    _checkFollowingStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Check if the current user is following the target user
  Future<void> _checkFollowingStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isFollowing = await authProvider.isFollowingUser(widget.userId);
      
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print('Error checking following status: $e');
    }
  }



  Future<void> _loadUserMedia() async {
    setState(() {
      _isLoadingPosts = true;
      _isLoadingReels = true;
    });

    try {
      print('Loading media for user: ${widget.username}');
      
      // Use UserMediaService to get posts and reels from API
      final userMedia = await UserMediaService.getUserMedia(userId: widget.userId);
      
      if (mounted) {
        setState(() {
          _userPosts = userMedia.posts; // Use posts from UserMediaService
          _userReels = userMedia.reels; // Use reels from UserMediaService
          _isLoadingPosts = false;
          _isLoadingReels = false;
        });
        
        print('Loaded ${_userPosts.length} posts and ${_userReels.length} reels for user ${widget.username}');
      }
    } catch (e) {
      print('Error loading user media: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
          _isLoadingReels = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get total media count (posts + reels)
  int get _totalMediaCount {
    return _userPosts.length + _userReels.length;
  }

  // Get posts count (only images)
  int get _postsCount {
    return _userPosts.length;
  }

  // Get reels count (only videos/reels)
  int get _reelsCount {
    return _userReels.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(widget.fullName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              // Refresh following status and posts
              await _checkFollowingStatus();
              await _loadUserMedia();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile refreshed'),
                    backgroundColor: Color(0xFF6366F1),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
          ),
          
          // Message Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    recipientUserId: widget.userId,
                    recipientUsername: widget.username,
                    recipientFullName: widget.fullName,
                    recipientAvatar: widget.avatar,
                    threadId: null, // New conversation
                  ),
                ),
              );
            },
            icon: const Icon(Icons.message, color: Color(0xFF6366F1)),
            tooltip: 'Send Message',
          ),
          // Debug button to show raw data
          if (kDebugMode)
            IconButton(
              onPressed: () => _showDebugInfo(),
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug Info',
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: const Color(0xFF666666),
                indicatorColor: const Color(0xFF6366F1),
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Reels'),
                  Tab(text: 'Tagged'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadUserMedia,
                  child: _buildPostsTab(),
                ),
                RefreshIndicator(
                  onRefresh: _loadUserMedia,
                  child: _buildReelsTab(),
                ),
                RefreshIndicator(
                  onRefresh: _loadUserMedia,
                  child: _buildTaggedTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            child: widget.avatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.avatar,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          
          const SizedBox(height: 16),
          
          // User Name
          Text(
            widget.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Username
          Text(
            '@${widget.username}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontFamily: 'Poppins',
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bio
          if (widget.bio.isNotEmpty)
            Text(
              widget.bio,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Posts', _isLoadingPosts ? '...' : _postsCount.toString()),
              _buildStatItem('Reels', _isLoadingReels ? '...' : _reelsCount.toString()),
              GestureDetector(
                onTap: () {
                  // Navigate to followers list for this user
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersScreen(userId: widget.userId),
                    ),
                  );
                },
                child: _buildStatItem('Followers', widget.followersCount.toString()),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to following list for this user
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowingScreen(userId: widget.userId),
                    ),
                  );
                },
                child: _buildStatItem('Following', widget.followingCount.toString()),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Follow/Unfollow Button
          _buildFollowButton(),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 40,
      color: Color(0xFF6366F1),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    // Don't show follow button if user is viewing their own profile
    if (_targetUserId == Provider.of<AuthProvider>(context, listen: false).userProfile?.id) {
      return const SizedBox.shrink();
    }

    // Show different button states based on account privacy and follow status
    if (widget.isPrivate && !_isFollowing) {
      // Show "Follow" button for private account
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoadingFollowRequest ? null : () async {
            await _followUser();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: _isLoadingFollowRequest
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Follow',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      );
    } else {
      // Show normal follow/unfollow button for public accounts or already followed users
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            bool success;
            
            if (_isFollowing) {
              // Unfollow the user
              success = await authProvider.unfollowUser(_targetUserId);
            } else {
              // Follow the user
              success = await authProvider.followUser(_targetUserId);
            }

            if (success) {
              if (mounted) {
                setState(() {
                  _isFollowing = !_isFollowing;
                });
                
                // Refresh the following status to ensure consistency
                await _checkFollowingStatus();
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFollowing ? 'Following ${widget.username}' : 'Unfollowed ${widget.username}'),
                  backgroundColor: const Color(0xFF6366F1),
                ),
              );
            } else {
              final errorMessage = Provider.of<AuthProvider>(context, listen: false).error ?? 'Action failed';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFollowing ? Colors.grey[200] : const Color(0xFF6366F1),
            foregroundColor: _isFollowing ? const Color(0xFF666666) : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            _isFollowing ? 'Following' : 'Follow',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }
  }

  /// Follow a user directly
  Future<void> _followUser() async {
    try {
      setState(() {
        _isLoadingFollowRequest = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.followUser(_targetUserId);
      
      if (success) {
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _isLoadingFollowRequest = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully followed ${widget.username}'),
              backgroundColor: const Color(0xFF6366F1),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingFollowRequest = false;
          });
          
          final errorMessage = authProvider.error ?? 'Failed to follow user';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFollowRequest = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When ${widget.username} shares photos and videos, they\'ll appear here',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'Note: Posts display is currently limited due to API implementation. This feature will be fully functional once the media retrieval API is complete.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return _buildPostGridItem(post);
      },
    );
  }

  Widget _buildPostGridItem(Post post) {
    return GestureDetector(
      onTap: () {
        // Navigate to post full view
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing post by ${post.username}'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (post.imageUrl?.isNotEmpty == true)
              ? Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPostPlaceholder(),
                )
              : _buildPostPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPostPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        color: Color(0xFF999999),
        size: 32,
      ),
    );
  }

  Widget _buildReelsTab() {
    if (_isLoadingReels) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    if (_userReels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No reels yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When ${widget.username} creates reels, they\'ll appear here',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'Note: Reels display is currently limited due to API implementation. This feature will be fully functional once the media retrieval API is complete.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _userReels.length,
      itemBuilder: (context, index) {
        final reel = _userReels[index];
        return _buildReelGridItem(reel);
      },
    );
  }

  Widget _buildReelGridItem(Post reel) {
    return GestureDetector(
      onTap: () {
        // Navigate to reel full view
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing reel by ${reel.username}'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Show video thumbnail or placeholder
              (reel.videoUrl?.isNotEmpty == true)
                  ? Container(
                      color: Colors.black,
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                  : _buildReelPlaceholder(),
              // Play button overlay
              const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReelPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.video_library,
        color: Color(0xFF999999),
        size: 32,
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User ID: ${widget.userId}'),
              Text('Username: ${widget.username}'),
              Text('Posts Count: ${_userPosts.length}'),
              Text('Reels Count: ${_userReels.length}'),
              const SizedBox(height: 16),
              const Text('Posts:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._userPosts.map((post) => Text('  - ${post.id}: ${post.type}')),
              const SizedBox(height: 16),
              const Text('Reels:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._userReels.map((reel) => Text('  - ${reel.id}: ${reel.type}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaggedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No tagged photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos of ${widget.username} will appear here when they\'re tagged',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
