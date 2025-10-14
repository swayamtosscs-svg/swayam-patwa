import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/video_player_widget.dart';
import '../models/post_model.dart';
import '../services/feed_service.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../providers/auth_provider.dart';

class InstagramFeedScreen extends StatefulWidget {
  const InstagramFeedScreen({super.key});

  @override
  State<InstagramFeedScreen> createState() => _InstagramFeedScreenState();
}

class _InstagramFeedScreenState extends State<InstagramFeedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _reelsPageController = PageController();
  int _currentReelIndex = 0;
  
  List<Post> posts = [];
  List<Post> reels = [];
  
  // Error handling variables
  String? _errorMessage;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isLoading = false;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMorePosts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeedData();
  }

  Future<void> _loadFeedData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        posts.clear();
        reels.clear();
        _hasMorePosts = true;
        _errorMessage = null;
      });
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUserId = authProvider.userProfile?.id;

      if (token == null || currentUserId == null) {
        setState(() {
          _errorMessage = 'Please login to view feed';
          _isLoading = false;
        });
        return;
      }

      // Load mixed feed (posts and reels from followed users + Baba Ji content)
      final feedPosts = await FeedService.getMixedFeed(
        token: token,
        currentUserId: currentUserId,
        page: _currentPage,
        limit: 20,
      );

      setState(() {
        if (refresh) {
          posts = feedPosts.where((post) => post.type != PostType.video).toList();
          reels = feedPosts.where((post) => post.type == PostType.video || post.isReel == true).toList();
        } else {
          posts.addAll(feedPosts.where((post) => post.type != PostType.video));
          reels.addAll(feedPosts.where((post) => post.type == PostType.video || post.isReel == true));
        }
        
        _isLoading = false;
        _isInitialized = true;
        
        // Check if we have more posts to load
        if (feedPosts.length < 20) {
          _hasMorePosts = false;
        }
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading feed: $e';
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _reelsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized && _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError && _errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Feed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadFeedData(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          'assets/images/Rgram_Text_Logo.png',
          height: 32,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'R-Gram',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _loadFeedData(refresh: true),
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.grid_on),
              text: 'Posts',
            ),
            Tab(
              icon: Icon(Icons.video_library),
              text: 'Reels',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildReelsTab(),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (posts.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Posts Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow some users to see their posts here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadFeedData(refresh: true),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFeedData(refresh: true),
      child: ListView.builder(
        itemCount: posts.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return _buildPostCard(posts[index]);
        },
      ),
    );
  }

  Widget _buildReelsTab() {
    if (reels.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Reels Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow some users to see their reels here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadFeedData(refresh: true),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _reelsPageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        setState(() {
          _currentReelIndex = index;
        });
      },
      itemCount: reels.length,
      itemBuilder: (context, index) {
        return _buildReelCard(reels[index], index);
      },
    );
  }

  Widget _buildAddStoryItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 2),
              color: Colors.grey[200],
            ),
            child: const Icon(Icons.add, color: Colors.grey, size: 30),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(int index) {
    final avatars = ['➕', '😊', '🕉️', '🙏', '🌊', '🕉️', '⛪'];
    final usernames = ['Add', 'TejasviSen', 'TempleDevotee', 'DivineConnect', 'GangaBhakti', 'Reel 1', 'Temple'];
    
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: index == 0 ? Colors.grey : Colors.purple,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Container(
                color: index == 0 ? Colors.grey[200] : Colors.purple[100],
                child: Center(
                  child: Text(
                    avatars[index % avatars.length],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            usernames[index % usernames.length],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    post.userAvatar,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (post.location != null)
                        Text(
                          post.location!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(post);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Post media
          if (post.type == PostType.image && post.imageUrl != null)
            Image.network(
              post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 400,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 50),
                );
              },
            ),
          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${post.likes} likes',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Caption
          if (post.caption != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: post.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(text: post.caption!),
                  ],
                ),
              ),
            ),
          // Comments preview
          if (post.comments > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                'View all ${post.comments} comments',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          // Time ago
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              _formatTimeAgo(post.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelCard(Post reel, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Show image instead of video for now
        if (reel.imageUrl != null)
          Image.network(
            reel.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildVideoPlaceholder(reel),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildVideoPlaceholder(reel);
            },
          )
        else
          _buildVideoPlaceholder(reel),
        
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black54,
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        
        // Content overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          reel.userAvatar,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${reel.username}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Uploaded by ${reel.username}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (reel.caption != null)
                            Text(
                              reel.caption!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Hashtags
                if (reel.hashtags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: reel.hashtags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 12),
                
                // Music info
                if (reel.music != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reel.music!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        // Action buttons
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              _buildReelActionButton(
                icon: Icons.favorite,
                label: '${reel.likes}',
                onTap: () {
                  // Handle like
                },
              ),
              const SizedBox(height: 20),
              _buildReelActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${reel.comments}',
                onTap: () {
                  // Handle comment
                },
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              _buildReelActionButton(
                icon: Icons.bookmark_border,
                label: 'Save',
                onTap: () {
                  // Handle save
                },
              ),
              const SizedBox(height: 20),
              _buildReelActionButton(
                icon: Icons.person_add_outlined,
                label: 'Follow',
                onTap: () {
                  // Handle follow
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder(Post reel) {
    return Container(
      color: _getReelColor(reel.id),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getReelColor(reel.id),
                  _getReelColor(reel.id).withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large play button
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Video title
                Text(
                  reel.caption ?? 'Video Content',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Username
                Text(
                  '@${reel.username}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Uploader info
                Text(
                  'Uploaded by ${reel.username}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Video info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tap to play video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getReelColor(String reelId) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
    ];
    
    final index = reelId.hashCode % colors.length;
    return colors[index.abs()];
  }

  Widget _buildReelActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton({
    required bool isFollowing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFollowing ? Colors.grey[600] : Colors.red,
        ),
        child: Icon(
          isFollowing ? Icons.check : Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.search, 'Search', false),
          _buildNavItem(Icons.add_box_outlined, 'Post', false),
          _buildNavItem(Icons.favorite_border, 'Activity', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
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

  void _showDeleteConfirmation(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(post);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
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
          duration: Duration(seconds: 2),
        ),
      );

      print('InstagramFeedScreen: Starting deletion for post ID: ${post.id}');

      // Call delete API
      final response = await ApiService.deleteMedia(
        mediaId: post.id,
        token: token,
      );

      print('InstagramFeedScreen: Delete response: $response');

      if (response['success'] == true) {
        // Remove from local list immediately
        setState(() {
          posts.removeWhere((p) => p.id == post.id);
          reels.removeWhere((p) => p.id == post.id);
        });
        
        // Clear from local storage
        await LocalStorageService.deletePost(post.id);
        await LocalStorageService.deleteReel(post.id);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message with more details
        final errorMessage = response['message'] ?? 'Failed to delete post';
        print('InstagramFeedScreen: Delete failed: $errorMessage');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $errorMessage'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('InstagramFeedScreen: Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final String? thumbnailUrl;

  const ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
    this.thumbnailUrl,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  bool _isMuted = true;
  
  // Error handling variables
  String? _errorMessage;
  bool _isInitialized = true;
  bool _hasError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video player
        Positioned.fill(
          child: VideoPlayerWidget(
            videoUrl: widget.videoUrl,
            autoPlay: widget.isActive,
            looping: true,
            muted: _isMuted,
          ),
        ),
        // Tap to play/pause
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              // Play/pause is handled by VideoPlayerWidget
              setState(() {});
            },
            child: AnimatedOpacity(
              opacity: 0.0, // Always transparent since VideoPlayerWidget handles play/pause
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 80),
                ),
              ),
            ),
          ),
        ),
        // Mute toggle
        Positioned(
          right: 16,
          top: 16,
          child: GestureDetector(
            onTap: () {
              _isMuted = !_isMuted;
              setState(() {});
            },
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Show thumbnail if available
        if (widget.thumbnailUrl != null)
          Image.network(
            widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackBackground(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildFallbackBackground();
            },
          )
        else
          _buildFallbackBackground(),
        
        // Loading indicator
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Show thumbnail if available
        if (widget.thumbnailUrl != null)
          Image.network(
            widget.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackBackground(),
          )
        else
          _buildFallbackBackground(),
        
        // Error overlay
        Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Video unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isInitialized = false;
                        _hasError = false;
                        _isLoading = true;
                      });
                      // Retry logic can be implemented here
                      setState(() {
                        _isInitialized = true;
                        _hasError = false;
                        _isLoading = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.video_library,
          color: Colors.white54,
          size: 80,
        ),
      ),
    );
  }

}
