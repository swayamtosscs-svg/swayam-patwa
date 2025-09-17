import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_model.dart';

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
  
  late List<Post> posts;
  late List<Post> reels;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  void _initializeData() {
    // Initialize posts (horizontal scrollable feed)
    posts = [
      Post(
        id: '1',
        userId: 'user1',
        username: 'spiritual_guide',
        userAvatar: '🙏',
        caption: 'Morning meditation brings peace to the soul #meditation #peace #spiritual',
        imageUrl: 'https://picsum.photos/400/400?random=1',
        type: PostType.image,
        likes: 1247,
        comments: 89,
        shares: 23,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        hashtags: ['meditation', 'peace', 'spiritual'],
      ),
      Post(
        id: '2',
        userId: 'user2',
        username: 'divine_connect',
        userAvatar: '🕉️',
        caption: 'Beautiful temple architecture #temple #architecture #divine',
        imageUrl: 'https://picsum.photos/400/400?random=2',
        type: PostType.image,
        likes: 892,
        comments: 45,
        shares: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        hashtags: ['temple', 'architecture', 'divine'],
      ),
      Post(
        id: '3',
        userId: 'user3',
        username: 'peaceful_soul',
        userAvatar: '🧘',
        caption: 'Sunset prayer time #prayer #sunset #peaceful',
        imageUrl: 'https://picsum.photos/400/400?random=3',
        type: PostType.image,
        likes: 1567,
        comments: 123,
        shares: 67,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        hashtags: ['prayer', 'sunset', 'peaceful'],
      ),
      Post(
        id: '4',
        userId: 'user4',
        username: 'gospel_singer',
        userAvatar: '🎵',
        caption: 'Sunday service highlights #gospel #church #worship',
        imageUrl: 'https://picsum.photos/400/400?random=4',
        type: PostType.image,
        likes: 2341,
        comments: 234,
        shares: 89,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        hashtags: ['gospel', 'church', 'worship'],
      ),
    ];

    // Initialize reels (vertical video feed) - using images as placeholders for now
    reels = [
      Post(
        id: 'reel1',
        userId: 'user1',
        username: 'TejasviSen',
        userAvatar: '😊',
        caption: 'What\'s my name?? 💃💃 The type of audience says it all ✅ #dance #trending',
        imageUrl: 'https://picsum.photos/400/600?random=100',
        type: PostType.reel,
        likes: 1200,
        comments: 89,
        shares: 23,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        hashtags: ['dance', 'trending', 'viral'],
        music: 'Chuttamalle · Shilpa Rao',
        thumbnailUrl: 'https://picsum.photos/400/600?random=100',
      ),
      Post(
        id: 'reel2',
        userId: 'user2',
        username: 'divine_connect',
        userAvatar: '🕉️',
        caption: 'Temple rituals and ceremonies #temple #rituals #ceremonies',
        imageUrl: 'https://picsum.photos/400/600?random=200',
        type: PostType.reel,
        likes: 1892,
        comments: 145,
        shares: 78,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        hashtags: ['temple', 'rituals', 'ceremonies'],
        music: 'Sacred Chants - Traditional',
        thumbnailUrl: 'https://picsum.photos/400/600?random=200',
      ),
      Post(
        id: 'reel3',
        userId: 'user3',
        username: 'peaceful_soul',
        userAvatar: '🧘',
        caption: 'Mindfulness breathing exercise #mindfulness #breathing #exercise',
        imageUrl: 'https://picsum.photos/400/600?random=300',
        type: PostType.reel,
        likes: 2567,
        comments: 223,
        shares: 167,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        hashtags: ['mindfulness', 'breathing', 'exercise'],
        music: 'Calm Nature Sounds - Original',
        thumbnailUrl: 'https://picsum.photos/400/600?random=300',
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reelsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Rgram',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Reels'),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPostsTab() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Stories row
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryItem();
                }
                return _buildStoryItem(index);
              },
            ),
          ),
          // Posts feed
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(posts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelsTab() {
    return Container(
      color: Colors.black,
      child: PageView.builder(
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
      ),
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
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
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
          // Post actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Toggle like
                    });
                  },
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Toggle save
                    });
                  },
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: post.isSaved ? Colors.black : Colors.black,
                  ),
                ),
              ],
            ),
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
              _getTimeAgo(post.createdAt),
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
              _buildReelActionButton(
                icon: Icons.share,
                label: '${reel.shares}',
                onTap: () {
                  // Handle share
                },
              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
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
  VideoPlayerController? _controller;
  bool _isMuted = true;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _init();
    }
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive && _isInitialized && !_hasError) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  Future<void> _init() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final controller = VideoPlayerController.network(
        widget.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      _controller = controller;
      
      // Set a timeout for video initialization
      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception('Video took too long to load. Please check your internet connection.');
        },
      );
      
      await controller.setLooping(true);
      if (_isMuted) {
        await controller.setVolume(0.0);
      }
      if (widget.isActive) {
        await controller.play();
      }
      
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      print('Video initialization error: $e');
      if (!mounted) return;
      
      String errorMsg = 'Failed to load video';
      if (e.toString().contains('timeout')) {
        errorMsg = 'Video loading timeout. Check your internet connection.';
      } else if (e.toString().contains('404')) {
        errorMsg = 'Video not found. The link may be broken.';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Network error. Please check your connection.';
      }
      
      setState(() {
        _isInitialized = true;
        _hasError = true;
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  void _disposeController() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_controller == null || !_isInitialized) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        // Video player
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
        // Tap to play/pause
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
              setState(() {});
            },
            child: AnimatedOpacity(
              opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
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
            onTap: () async {
              _isMuted = !_isMuted;
              await _controller!.setVolume(_isMuted ? 0.0 : 1.0);
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
                      _init();
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
