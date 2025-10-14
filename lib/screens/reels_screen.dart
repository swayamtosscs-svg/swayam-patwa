import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/baba_page_model.dart';
import '../models/baba_page_reel_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/baba_page_service.dart';
import '../services/baba_page_reel_service.dart';
import '../services/local_storage_service.dart';
import '../services/dp_service.dart';
import '../services/user_media_service.dart';
import '../widgets/user_comment_dialog.dart';
import '../widgets/video_player_widget.dart';
import '../screens/user_profile_screen.dart';
import '../utils/video_manager.dart';
import '../test_follow_status_debug.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final VideoManager _videoManager = VideoManager();
  
  List<Post> _reels = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Map<String, bool> _followStates = {}; // Track follow state for each user
  Map<String, bool> _likeStates = {}; // Track like state for each post
  Map<String, int> _likeCounts = {}; // Track like counts for each post
  bool _isCheckingFollowStatus = false; // Track if follow status check is in progress

  @override
  void initState() {
    super.initState();
    _setupVideoManager();
    _loadReels();
  }

  @override
  void dispose() {
    _videoManager.reset();
    _pageController.dispose();
    super.dispose();
  }

  void _setupVideoManager() {
    // Set up the video manager to handle PageView changes
    _videoManager.setScrollController(_pageController);
  }

  Future<void> _loadReels() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final List<Post> allReels = [];
      List<Post> userReels = [];
      List<Post> additionalReels = [];
      List<String> followedUserIds = [];
      List<dynamic> babaPages = [];
      List<Post> localReels = [];

      // 1. Fetch reels from regular feed (user reels)
      try {
        final feedResponse = await ApiService.getRGramFeed(token: token);
        if (feedResponse['success'] == true && feedResponse['data'] != null) {
          final postsData = feedResponse['data']['posts'] as List<dynamic>? ?? [];
          final posts = postsData.map((json) => Post.fromJson(json)).toList();
          userReels = posts.where((post) {
            // Check if it's a video/reel content
            final isVideoContent = post.isReel || 
                                  post.type == PostType.reel || 
                                  post.type == PostType.video ||
                                  (post.videoUrl != null && post.videoUrl!.isNotEmpty);
            
            // Additional check for posts that might have video URLs but not marked as video type
            final hasVideoUrl = post.videoUrl != null && post.videoUrl!.isNotEmpty;
            
            return isVideoContent && hasVideoUrl;
          }).toList();
          allReels.addAll(userReels);
          print('ReelsScreen: Found ${userReels.length} user reels from feed');
          
          // Debug: Print details of found reels
          for (final reel in userReels) {
            print('ReelsScreen: User reel - ID: ${reel.id}, Type: ${reel.type}, isReel: ${reel.isReel}, VideoURL: ${reel.videoUrl?.isNotEmpty == true ? "Present" : "Missing"}');
          }
        }
      } catch (e) {
        print('ReelsScreen: Error fetching user reels: $e');
      }

      // 1.5. Fetch additional user reels from UserMediaService
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.userProfile?.id;
        
        if (currentUserId != null) {
          final userMediaResponse = await UserMediaService.getUserMedia(userId: currentUserId);
          if (userMediaResponse.success) {
            additionalReels = userMediaResponse.reels.where((reel) =>  
              reel.videoUrl != null && reel.videoUrl!.isNotEmpty
            ).toList();
            
            // Check for duplicates before adding
            for (final reel in additionalReels) {
              final alreadyExists = allReels.any((existingReel) => 
                existingReel.id == reel.id || existingReel.videoUrl == reel.videoUrl
              );
              if (!alreadyExists) {
                allReels.add(reel);
              }
            }
            
            print('ReelsScreen: Found ${additionalReels.length} additional user reels from UserMediaService');
          }
        }
      } catch (e) {
        print('ReelsScreen: Error fetching additional user reels: $e');
      }

      // 1.6. Fetch reels from followed users
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.userProfile?.id;
        
        if (currentUserId != null) {
          // Get list of followed users (people the current user follows)
          final followingResponse = await ApiService.getRGramFollowing(
            userId: currentUserId,
            token: token,
          );
          
          if (followingResponse['success'] == true && followingResponse['data'] != null) {
            final followingData = followingResponse['data']['following'] as List<dynamic>? ?? [];
            
            // Fetch reels from each followed user (limit to first 10 to avoid too many API calls)
            followedUserIds = followingData.take(10).map((following) => following['_id'] ?? following['id']).where((id) => id != null).cast<String>().toList();
            
            // Fetch reels from all following users in parallel for better performance
            final futures = followedUserIds.map((followedUserId) async {
              try {
                final userMediaResponse = await UserMediaService.getUserMedia(userId: followedUserId);
                if (userMediaResponse.success) {
                  return userMediaResponse.reels.where((reel) => 
                    reel.videoUrl != null && reel.videoUrl!.isNotEmpty
                  ).toList();
                }
                return <Post>[];
              } catch (e) {
                print('ReelsScreen: Error fetching reels from followed user $followedUserId: $e');
                return <Post>[];
              }
            });
            
            // Wait for all API calls to complete
            final results = await Future.wait(futures);
            
            // Process all results and add to allReels
            for (final followedUserReels in results) {
              // Check for duplicates before adding
              for (final reel in followedUserReels) {
                final alreadyExists = allReels.any((existingReel) => 
                  existingReel.id == reel.id || existingReel.videoUrl == reel.videoUrl
                );
                if (!alreadyExists) {
                  allReels.add(reel);
                }
              }
            }
            
            final totalFollowingReels = results.fold<int>(0, (sum, reels) => sum + reels.length);
            print('ReelsScreen: Fetched $totalFollowingReels reels from ${followedUserIds.length} following users');
          }
        }
      } catch (e) {
        print('ReelsScreen: Error fetching reels from following users: $e');
      }

      // 2. Fetch Baba Ji page reels
      try {
        final babaPagesResponse = await BabaPageService.getBabaPages(token: token);
        if (babaPagesResponse.success && babaPagesResponse.pages.isNotEmpty) {
          babaPages = babaPagesResponse.pages;
          
          for (final babaPage in babaPages) {
            final babaPageId = babaPage.id;
            if (babaPageId.isNotEmpty) {
              try {
                final reelsResponse = await BabaPageReelService.getBabaPageReels(
                  babaPageId: babaPageId,
                  token: token,
                  page: 1,
                  limit: 20,
                );

                if (reelsResponse['success'] == true) {
                  final reelsData = reelsResponse['data']['videos'] as List<dynamic>;
                  for (final reelData in reelsData) {
                    final reel = BabaPageReel.fromJson(reelData);
                    // Convert Baba Ji reel to regular Post for reels screen
                    final babaPageObj = BabaPage.fromJson(babaPage.toJson());
                    final post = Post(
                      id: 'baba_reel_${reel.id}',
                      userId: reel.babaPageId,
                      username: '${babaPage.name} (ID: ${reel.babaPageId})',
                      userAvatar: babaPage.avatar,
                      caption: '${reel.title}\n\n${reel.description}',
                      imageUrl: reel.thumbnail.url,
                      videoUrl: reel.video.url,
                      type: PostType.reel,
                      likes: reel.likesCount,
                      comments: reel.commentsCount,
                      shares: reel.sharesCount,
                      isLiked: false,
                      createdAt: reel.createdAt,
                      hashtags: [],
                      thumbnailUrl: reel.thumbnail.url,
                      isBabaJiPost: true,
                      isReel: true,
                      babaPageId: reel.babaPageId,
                      babaPageData: babaPageObj, // Store complete Baba Ji page data
                    );
                    allReels.add(post);
                  }
                }
              } catch (e) {
                print('ReelsScreen: Error getting reels from Baba Ji page $babaPageId: $e');
              }
            }
          }
          print('ReelsScreen: Found Baba Ji reels');
        }
      } catch (e) {
        print('ReelsScreen: Error fetching Baba Ji reels: $e');
      }

      // 3. Fetch local storage reels
      try {
        localReels = await LocalStorageService.getUserReels();
        allReels.addAll(localReels);
        print('ReelsScreen: Found ${localReels.length} local reels');
      } catch (e) {
        print('ReelsScreen: Error fetching local reels: $e');
      }

      // Remove duplicates based on video URL
      final uniqueReels = <String, Post>{};
      for (final reel in allReels) {
        if (reel.videoUrl != null && reel.videoUrl!.isNotEmpty) {
          uniqueReels[reel.videoUrl!] = reel;
        }
      }

      // Sort by creation date (latest first)
      final sortedReels = uniqueReels.values.toList();
      sortedReels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('ReelsScreen: Total unique reels found: ${sortedReels.length}');
      print('ReelsScreen: Sources - Feed: ${userReels.length}, UserMedia: ${additionalReels.length}, Following: ${followedUserIds.length} users, Baba Ji: ${babaPages.length} pages, Local: ${localReels.length}');
      
      // Initialize like and follow states
      for (final reel in sortedReels) {
        _likeStates[reel.id] = reel.isLiked;
        _likeCounts[reel.id] = reel.likes;
        _followStates[reel.userId] = false; // Will be updated by checking follow status
      }
      
      setState(() {
        _reels = sortedReels;
        _isLoading = false;
      });
      
      // Check follow status for all users
      _checkFollowStatuses();
    } catch (e) {
      print('Error loading reels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : _reels.isEmpty
                ? RefreshIndicator(
                    onRefresh: _loadReels,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: _buildEmptyState(),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReels,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        // Update video manager with new page index
                        _videoManager.updatePageIndex(index);
                      },
                      itemCount: _reels.length,
                      itemBuilder: (context, index) {
                        final reel = _reels[index];
                        return _buildReelCard(reel, index);
                      },
                    ),
                  ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 20),
          Text(
            'No Reels Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Be the first to create a reel!\nPull down to refresh and check for new content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/reel-upload');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Reel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelCard(Post reel, int index) {
    // Register video position with video manager
    _videoManager.registerVideoPosition(reel.id, index);
    
    return Stack(
      children: [
        // Video Player
        Positioned.fill(
          child: VideoPlayerWidget(
            videoUrl: reel.videoUrl!,
            videoId: reel.id, // Pass video ID for tracking
            autoPlay: index == _currentIndex,
            showControls: false,
          ),
        ),
        
        // Gradient overlay for better text visibility
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
        ),
        
        // Content overlay
        Positioned.fill(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(reel),
              
              // Bottom content
              Expanded(
                child: Row(
                  children: [
                    // Left side - User info and description
                    Expanded(
                      child: _buildLeftContent(reel),
                    ),
                    
                    // Right side - Action buttons
                    _buildRightActions(reel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(Post reel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Reels',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${_reels.length})',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          // Debug button (only in debug mode)
          if (kDebugMode)
            IconButton(
              onPressed: () {
                if (_reels.isNotEmpty) {
                  final currentReel = _reels[_currentIndex];
                  showFollowStatusDebug(context, currentReel.userId, currentReel.username);
                }
              },
              icon: const Icon(
                Icons.bug_report,
                color: Colors.white,
              ),
              tooltip: 'Debug Follow Status',
            ),
          // Refresh follow status button
          IconButton(
            onPressed: () {
              _checkFollowStatuses();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing follow statuses...'),
                  backgroundColor: Color(0xFF6366F1),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: 'Refresh Follow Status',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/reel-upload');
            },
            icon: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftContent(Post reel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // User info
          Row(
            children: [
                InkWell(
                onTap: () {
                  print('Avatar tapped for user: ${reel.userId}');
                  _navigateToUserProfile(reel.userId, reel.username, reel.isBabaJiPost, babaPageData: reel.babaPageData);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: _buildUserAvatar(
                    userId: reel.userId,
                    username: reel.username,
                    currentAvatar: reel.userAvatar,
                    token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              print('Username tapped for user: ${reel.userId}');
                              _navigateToUserProfile(reel.userId, reel.username, reel.isBabaJiPost, babaPageData: reel.babaPageData);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Text(
                                reel.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        if (reel.isBabaJiPost) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'BABA JI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        print('Handle tapped for user: ${reel.userId}');
                        _navigateToUserProfile(reel.userId, reel.username, reel.isBabaJiPost, babaPageData: reel.babaPageData);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text(
                          reel.isBabaJiPost ? '@${reel.userId}' : '@${reel.username.toLowerCase().replaceAll(' ', '')}',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleFollow(reel),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_followStates[reel.userId] ?? false) ? Colors.grey[600] : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isCheckingFollowStatus
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        (_followStates[reel.userId] ?? false) ? 'Following' : 'Follow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Caption
          if (reel.caption?.isNotEmpty == true)
            Text(
              reel.caption!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          
          const SizedBox(height: 8),
          
          // Music info
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: Colors.grey[300],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                reel.isBabaJiPost ? 'Baba Ji Audio' : 'Original Audio',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightActions(Post reel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Like button
          _buildActionButton(
            icon: (_likeStates[reel.id] ?? false) ? Icons.favorite : Icons.favorite_border,
            count: _likeCounts[reel.id] ?? reel.likes,
            onTap: () => _toggleLike(reel),
            isLiked: _likeStates[reel.id] ?? false,
          ),
          
          const SizedBox(height: 20),
          
          // Comment button
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            count: reel.comments,
            onTap: () => _openComments(reel),
          ),
          
          const SizedBox(height: 20),
          
          // Share button
          _buildActionButton(
            icon: Icons.share,
            count: reel.shares,
            onTap: () => _shareReel(reel),
          ),
          
          const SizedBox(height: 20),
          
          // More options
          IconButton(
            onPressed: () => _showMoreOptions(reel),
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    bool isLiked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: isLiked ? Colors.red : Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: false,
                onTap: () {
                  print('Home tab tapped');
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              _buildNavItem(
                icon: Icons.live_tv,
                label: 'Live Darshan',
                isSelected: false,
                onTap: () {
                  print('Live Darshan tab tapped');
                  Navigator.pushNamed(context, '/live-stream');
                },
              ),
              _buildNavItem(
                icon: Icons.add,
                label: 'Add',
                isSelected: false,
                onTap: () {
                  print('Add tab tapped');
                  Navigator.pushNamed(context, '/add-options');
                },
              ),
              _buildNavItem(
                icon: Icons.video_library,
                label: 'Reels',
                isSelected: true,
                onTap: () {
                  print('Reels tab tapped');
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              _buildNavItem(
                icon: Icons.self_improvement,
                label: 'Baba Ji',
                isSelected: false,
                onTap: () {
                  print('Baba Ji tab tapped');
                  Navigator.pushNamed(context, '/baba-pages');
                },
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Account',
                isSelected: false,
                onTap: () {
                  print('Account tab tapped');
                  Navigator.pushNamed(context, '/profile');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.red : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.red : Colors.grey[600],
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkFollowStatuses() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUserId = authProvider.userProfile?.id;
      
      if (token == null || currentUserId == null) {
        print('ReelsScreen: Cannot check follow statuses - missing token or user ID');
        return;
      }
      
      setState(() {
        _isCheckingFollowStatus = true;
      });
      
      print('ReelsScreen: Checking follow statuses for ${_reels.length} reels');
      
      // Check follow status for each unique user
      final uniqueUserIds = _reels.map((reel) => reel.userId).toSet();
      print('ReelsScreen: Unique user IDs to check: ${uniqueUserIds.toList()}');
      
      for (final userId in uniqueUserIds) {
        if (userId != currentUserId) {
          try {
            print('ReelsScreen: Checking follow status for user: $userId');
            final followStatus = await ApiService.checkRGramFollowStatus(
              targetUserId: userId,
              token: token,
            );
            
            print('ReelsScreen: Follow status response for $userId: $followStatus');
            
            if (followStatus['success'] == true && followStatus['data'] != null && mounted) {
              final isFollowing = followStatus['data']['isFollowing'] ?? false;
              print('ReelsScreen: User $userId follow status: $isFollowing');
              
              setState(() {
                _followStates[userId] = isFollowing;
              });
            } else {
              print('ReelsScreen: Follow status check failed for $userId: ${followStatus['message']}');
              // Fallback: use AuthProvider method
              try {
                final authFollowStatus = await authProvider.isFollowingUser(userId);
                print('ReelsScreen: AuthProvider fallback for $userId: $authFollowStatus');
                if (mounted) {
                  setState(() {
                    _followStates[userId] = authFollowStatus;
                  });
                }
              } catch (fallbackError) {
                print('ReelsScreen: AuthProvider fallback also failed for $userId: $fallbackError');
              }
            }
          } catch (e) {
            print('ReelsScreen: Error checking follow status for user $userId: $e');
            // Try fallback method
            try {
              final authFollowStatus = await authProvider.isFollowingUser(userId);
              print('ReelsScreen: AuthProvider fallback for $userId after error: $authFollowStatus');
              if (mounted) {
                setState(() {
                  _followStates[userId] = authFollowStatus;
                });
              }
            } catch (fallbackError) {
              print('ReelsScreen: AuthProvider fallback also failed for $userId after error: $fallbackError');
            }
          }
        } else {
          print('ReelsScreen: Skipping follow status check for current user: $userId');
        }
      }
      
      print('ReelsScreen: Final follow states: $_followStates');
      
      if (mounted) {
        setState(() {
          _isCheckingFollowStatus = false;
        });
      }
    } catch (e) {
      print('ReelsScreen: Error checking follow statuses: $e');
      if (mounted) {
        setState(() {
          _isCheckingFollowStatus = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(Post reel) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUserId = authProvider.userProfile?.id;
      
      if (token == null || currentUserId == null) {
        print('ReelsScreen: Cannot follow - missing token or user ID');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to follow users'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final isCurrentlyFollowing = _followStates[reel.userId] ?? false;
      print('ReelsScreen: Toggling follow for user ${reel.username} (${reel.userId}) - Currently following: $isCurrentlyFollowing');
      
      // Optimistically update UI
      setState(() {
        _followStates[reel.userId] = !isCurrentlyFollowing;
      });
      
      Map<String, dynamic> result;
      if (isCurrentlyFollowing) {
        print('ReelsScreen: Unfollowing user ${reel.username}');
        result = await ApiService.unfollowRGramUser(
          targetUserId: reel.userId,
          token: token,
        );
      } else {
        print('ReelsScreen: Following user ${reel.username}');
        result = await ApiService.followRGramUser(
          targetUserId: reel.userId,
          token: token,
        );
      }
      
      print('ReelsScreen: Follow API result: $result');
      
      if (result['success'] != true && mounted) {
        // Revert on failure
        setState(() {
          _followStates[reel.userId] = isCurrentlyFollowing;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update follow status'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFollowing ? 'Unfollowed ${reel.username}' : 'Following ${reel.username}'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }
    } catch (e) {
      print('ReelsScreen: Error toggling follow: $e');
      // Revert on error
      setState(() {
        _followStates[reel.userId] = !(_followStates[reel.userId] ?? false);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(Post reel) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUserId = authProvider.userProfile?.id;
      
      if (token == null || currentUserId == null) return;
      
      final isCurrentlyLiked = _likeStates[reel.id] ?? false;
      final currentLikeCount = _likeCounts[reel.id] ?? reel.likes;
      
      // Optimistically update UI
      setState(() {
        _likeStates[reel.id] = !isCurrentlyLiked;
        _likeCounts[reel.id] = isCurrentlyLiked ? currentLikeCount - 1 : currentLikeCount + 1;
      });
      
      Map<String, dynamic> result;
      if (isCurrentlyLiked) {
        result = await ApiService.unlikePost(
          postId: reel.id,
          token: token,
          userId: currentUserId,
        );
      } else {
        result = await ApiService.likePost(
          postId: reel.id,
          token: token,
          userId: currentUserId,
        );
      }
      
      if (result['success'] != true && mounted) {
        // Revert on failure
        setState(() {
          _likeStates[reel.id] = isCurrentlyLiked;
          _likeCounts[reel.id] = currentLikeCount;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update like status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Revert on error
      setState(() {
        _likeStates[reel.id] = !(_likeStates[reel.id] ?? false);
        _likeCounts[reel.id] = (_likeCounts[reel.id] ?? reel.likes);
      });
    }
  }

  void _openComments(Post reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserCommentDialog(
        postId: reel.id,
        onCommentAdded: () {
          // Update comment count if needed
          setState(() {
            // You can increment comment count here if you track it
          });
        },
      ),
    );
  }

  void _shareReel(Post reel) {
    // TODO: Implement share functionality
  }

  void _showMoreOptions(Post reel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text('Block User', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUserProfile(String userId, String username, bool isBabaJiPost, {BabaPage? babaPageData}) async {
    print('Navigating to profile for user: $userId, username: $username, isBabaJiPost: $isBabaJiPost');
    
    try {
      if (isBabaJiPost && babaPageData != null) {
        print('Baba Ji profile detected with complete data, navigating to Baba Ji page screen');
        // Navigate to Baba Ji page detail screen with complete data
        Navigator.pushNamed(
          context,
          '/baba-page-detail',
          arguments: {
            'babaPageId': babaPageData.id,
            'babaPageName': babaPageData.name,
            'description': babaPageData.description,
            'avatar': babaPageData.avatar,
            'coverImage': babaPageData.coverImage,
            'location': babaPageData.location,
            'religion': babaPageData.religion,
            'website': babaPageData.website,
            'creatorId': babaPageData.creatorId,
            'followersCount': babaPageData.followersCount,
            'postsCount': babaPageData.postsCount,
            'videosCount': babaPageData.videosCount,
            'storiesCount': babaPageData.storiesCount,
            'isActive': babaPageData.isActive,
            'isFollowing': babaPageData.isFollowing,
            'createdAt': babaPageData.createdAt.toIso8601String(),
            'updatedAt': babaPageData.updatedAt.toIso8601String(),
          },
        );
      } else if (isBabaJiPost) {
        print('Baba Ji profile detected without complete data, fetching full data first');
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          // Fetch complete Baba Ji page data
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final token = authProvider.authToken;
          
          if (token == null) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to view Baba Ji profiles'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          final response = await BabaPageService.getBabaPageById(
            pageId: userId,
            token: token,
          );
          
          Navigator.of(context).pop(); // Close loading dialog
          
          if (response.success && response.data != null) {
            print('Baba Ji page data fetched successfully, navigating with complete data');
            // Navigate with complete data
            Navigator.pushNamed(
              context,
              '/baba-page-detail',
              arguments: {
                'babaPageId': response.data!.id,
                'babaPageName': response.data!.name,
                'description': response.data!.description,
                'avatar': response.data!.avatar,
                'coverImage': response.data!.coverImage,
                'location': response.data!.location,
                'religion': response.data!.religion,
                'website': response.data!.website,
                'creatorId': response.data!.creatorId,
                'followersCount': response.data!.followersCount,
                'postsCount': response.data!.postsCount,
                'videosCount': response.data!.videosCount,
                'storiesCount': response.data!.storiesCount,
                'isActive': response.data!.isActive,
                'isFollowing': response.data!.isFollowing,
                'createdAt': response.data!.createdAt.toIso8601String(),
                'updatedAt': response.data!.updatedAt.toIso8601String(),
              },
            );
          } else {
            print('Failed to fetch Baba Ji page data: ${response.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load Baba Ji profile: ${response.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
              userId: userId,
              username: username,
              fullName: username,
              avatar: '',
              bio: '',
              followersCount: 0,
              followingCount: 0,
              postsCount: 0,
              isPrivate: false,
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

  Widget _buildUserAvatar({
    required String userId,
    required String username,
    required String currentAvatar,
    required String token,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: DPService.retrieveDP(userId: userId, token: token),
      builder: (context, snapshot) {
        // If we have a successful response with DP URL, show the real DP
        if (snapshot.hasData && 
            snapshot.data!['success'] == true && 
            snapshot.data!['data'] != null &&
            snapshot.data!['data']['dpUrl'] != null) {
          
          final dpUrl = snapshot.data!['data']['dpUrl'] as String;
          print('ReelsScreen: Found DP for user $username: $dpUrl');
          
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                dpUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[400]!, Colors.pink[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('ReelsScreen: Error loading DP image for user $username: $error');
                  // Fallback to gradient avatar if image fails to load
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[400]!, Colors.pink[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
        
        // Log the reason for fallback
        if (snapshot.hasData) {
          print('ReelsScreen: DP API failed for user $username: ${snapshot.data!['message']}');
        } else if (snapshot.hasError) {
          print('ReelsScreen: DP API error for user $username: ${snapshot.error}');
        } else {
          print('ReelsScreen: DP API loading for user $username');
        }
        
        // Fallback to gradient avatar if no DP is found or API fails
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[400]!, Colors.pink[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      },
    );
  }
}
