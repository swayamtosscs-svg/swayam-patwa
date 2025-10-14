import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';
import '../screens/followers_screen.dart';
import '../screens/following_screen.dart';
import '../services/user_media_service.dart';
import '../services/chat_service.dart';
import '../screens/chat_screen.dart';
import '../screens/post_full_view_screen.dart';
import '../utils/avatar_utils.dart';
import '../widgets/follow_button.dart';
import '../widgets/dp_widget.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../models/highlight_model.dart';
import '../services/highlight_service.dart';
import '../screens/highlights_screen.dart';
import '../screens/highlight_viewer_screen.dart';
import '../test_follow_status_debug.dart';

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
  int _realFollowersCount = 0;
  int _realFollowingCount = 0;
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;

  String get _targetUserId => widget.userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserMedia();
    _checkFollowingStatus();
    _loadRealCounts();
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

  /// Load real followers and following counts from API
  Future<void> _loadRealCounts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      setState(() {
        _isLoadingFollowers = true;
        _isLoadingFollowing = true;
      });

      // Load both counts in a single optimized call
      final counts = await authProvider.getUserCounts(widget.userId);
      
      if (mounted) {
        setState(() {
          _realFollowersCount = counts['followers'] ?? 0;
          _realFollowingCount = counts['following'] ?? 0;
          _isLoadingFollowers = false;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      print('Error loading real counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingFollowers = false;
          _isLoadingFollowing = false;
        });
      }
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
      backgroundColor: const Color(0xFFF0EBE1), // Same as own profile page background
      appBar: _buildInstagramStyleAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkFollowingStatus();
          await _loadUserMedia();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Instagram-style Profile Header
              _buildInstagramStyleProfileHeader(),
              
              SizedBox(height: MediaQuery.of(context).size.width < 600 ? 8 : 12),
              
              // Instagram-style Tab Bar
              _buildInstagramStyleTabBar(),
              
              // Tab Content
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildInstagramStyleAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF0EBE1), // Same as own profile page background
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      title: Text(
        widget.username,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
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
          icon: const Icon(Icons.refresh, color: Colors.black),
        ),
        
        // Message Button
        IconButton(
          onPressed: () async {
            // Add conversation to local storage
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.userProfile != null) {
              await ChatService.addConversation(
                currentUserId: authProvider.userProfile!.id,
                otherUserId: widget.userId,
                otherUsername: widget.username,
                otherFullName: widget.fullName,
                otherAvatar: widget.avatar,
              );
            }
            
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
          icon: const Icon(Icons.message, color: Colors.black),
          tooltip: 'Send Message',
        ),
        
        // Debug button (only in debug mode)
        if (kDebugMode)
          IconButton(
            onPressed: () {
              showFollowStatusDebug(context, widget.userId, widget.username);
            },
            icon: const Icon(Icons.bug_report, color: Colors.black),
            tooltip: 'Debug Follow Status',
          ),
        
        // More options
        IconButton(
          onPressed: () {
            // Show more options
          },
          icon: const Icon(Icons.more_vert, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildInstagramStyleProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Picture and Stats Row
          Row(
            children: [
              // Profile Picture using DPWidget
              DPWidget(
                currentImageUrl: widget.avatar,
                userId: widget.userId,
                token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
                userName: widget.fullName,
                onImageChanged: (String newImageUrl) {
                  // Update the avatar if needed
                  print('UserProfileScreen: Avatar changed to: $newImageUrl');
                },
                size: 120,
                borderColor: const Color(0xFF4A2C2A),
                showEditButton: false, // Don't show edit button for other users' profiles
              ),
              
              const SizedBox(width: 20),
              
              // Stats Column
              Expanded(
                child: Column(
                  children: [
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildStatColumn(_postsCount.toString(), 'posts')),
                        Expanded(child: _buildStatColumn(_reelsCount.toString(), 'reels')),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowersScreen(userId: widget.userId),
                                ),
                              );
                            },
                            child: _buildStatColumn(
                              _isLoadingFollowers ? '...' : _realFollowersCount.toString(), 
                              'followers'
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowingScreen(userId: widget.userId),
                                ),
                              );
                            },
                            child: _buildStatColumn(
                              _isLoadingFollowing ? '...' : _realFollowingCount.toString(), 
                              'following'
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User Name and Bio
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fullName,
                style: const TextStyle(
                  color: Color(0xFF4A2C2A), // Deep Brown
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              if (widget.bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.bio,
                  style: const TextStyle(
                    color: Color(0xFF4A2C2A), // Deep Brown
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Follow Button
          _buildFollowButton(),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Color(0xFF4A2C2A), // Deep Brown
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4A2C2A), // Deep Brown
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstagramStyleTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4A2C2A), // Deep Brown
        unselectedLabelColor: const Color(0xFF999999),
        indicatorColor: const Color(0xFF4A2C2A), // Deep Brown
        tabs: const [
          Tab(icon: Icon(Icons.grid_on)),
          Tab(icon: Icon(Icons.play_circle_outline)),
          Tab(icon: Icon(Icons.bookmark_border)),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Calculate available height more intelligently for mobile
    double availableHeight;
    if (isMobile) {
      // For mobile: Use remaining space after header, tabs, and bottom navigation
      availableHeight = screenHeight * 0.45; // Reduced from 0.6 to 0.45
    } else {
      // For desktop: Use original calculation
      availableHeight = screenHeight * 0.6;
    }
    
    return Container(
      height: availableHeight,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildReelsTab(),
          _buildTaggedTab(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final mobilePadding = isMobile ? 12.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.all(mobilePadding),
      child: Column(
        children: [
          // Profile Image using DPWidget
          DPWidget(
            currentImageUrl: widget.avatar,
            userId: widget.userId,
            token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
            userName: widget.fullName,
            onImageChanged: (String newImageUrl) {
              // Update the avatar if needed
              print('UserProfileScreen: Avatar changed to: $newImageUrl');
            },
            size: isMobile ? 80 : 100,
            borderColor: const Color(0xFF6366F1),
            showEditButton: false, // Don't show edit button for other users' profiles
          ),
          
          SizedBox(height: isMobile ? 12 : 16),
          
          // User Name
          Text(
            widget.fullName,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          
          SizedBox(height: isMobile ? 2 : 4),
          
          // Username
          Text(
            '@${widget.username}',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: const Color(0xFF666666),
              fontFamily: 'Poppins',
            ),
          ),
          
          SizedBox(height: isMobile ? 8 : 12),
          
          // Bio
          if (widget.bio.isNotEmpty)
            Text(
              widget.bio,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: const Color(0xFF666666),
                fontFamily: 'Poppins',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: isMobile ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          
          SizedBox(height: isMobile ? 12 : 16),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildStatItem('Posts', _isLoadingPosts ? '...' : _postsCount.toString())),
              Expanded(child: _buildStatItem('Reels', _isLoadingReels ? '...' : _reelsCount.toString())),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to followers list for this user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: _buildStatItem('Followers', _isLoadingFollowers ? '...' : _realFollowersCount.toString()),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to following list for this user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowingScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: _buildStatItem('Following', _isLoadingFollowing ? '...' : _realFollowingCount.toString()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Follow/Unfollow Button
          _buildFollowButton(),
          
          const SizedBox(height: 20),
          
          // Highlights Section
          _buildHighlightsSection(),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return AvatarUtils.buildDefaultAvatar(
      name: widget.fullName,
      size: 100,
      borderColor: const Color(0xFF6366F1),
      borderWidth: 2,
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
            color: Colors.black,
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

    // Use the FollowButton widget that handles friend requests
    return FollowButton(
      targetUserId: _targetUserId,
      targetUserName: widget.username,
      isPrivate: widget.isPrivate, // Use the actual privacy status from widget
      isFollowing: _isFollowing,
      onFollowChanged: () {
        // Refresh the following status when follow state changes
        _checkFollowingStatus();
        _loadRealCounts();
      },
    );
  }

  /// Follow a user directly
  Future<void> _followUser() async {
    try {
      setState(() {
        _isLoadingFollowRequest = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.followUser(_targetUserId, followerName: widget.username);
      
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

    // Check if account is private and user is not following
    if (widget.isPrivate && !_isFollowing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'This account is private',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow ${widget.username} to see their posts',
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Text(
                'Send a follow request to see their posts and stories',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostFullViewScreen(
              post: post,
            ),
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

    // Check if account is private and user is not following
    if (widget.isPrivate && !_isFollowing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'This account is private',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow ${widget.username} to see their reels',
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Text(
                'Send a follow request to see their reels and stories',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostFullViewScreen(post: reel),
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

  Widget _buildHighlightsSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return FutureBuilder<HighlightsListResponse>(
      future: HighlightService.getHighlights(
        token: authProvider.authToken ?? '',
        page: 1,
        limit: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.success) {
          print('UserProfileScreen: Highlights error - ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final highlights = snapshot.data!.highlights;
        print('UserProfileScreen: Found ${highlights.length} highlights');
        
        if (highlights.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Highlights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A2C2A),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: highlights.length,
                  itemBuilder: (context, index) {
                    final highlight = highlights[index];
                    return _buildHighlightItem(highlight);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightItem(Highlight highlight) {
    return GestureDetector(
      onTap: () {
        // Navigate to highlight viewer to show stories
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HighlightViewerScreen(highlight: highlight),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: highlight.stories.isNotEmpty && highlight.stories.first.media.isNotEmpty
                    ? Image.network(
                        highlight.stories.first.media,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.star,
                              color: Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.star,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              highlight.name,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A2C2A),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
