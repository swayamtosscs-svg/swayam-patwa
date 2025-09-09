import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../widgets/story_widget.dart';
import '../widgets/enhanced_post_widget.dart';
import '../widgets/app_loader.dart';
import '../utils/app_theme.dart';
import '../screens/story_upload_screen.dart';
import '../screens/story_viewer_screen.dart';
import '../screens/post_full_view_screen.dart';
import '../screens/live_stream_screen.dart';
import '../services/story_service.dart';
// Removed local story service import to prevent showing old local stories
import '../services/feed_service.dart';
import '../services/chat_service.dart';
import '../models/chat_thread_model.dart';
import '../screens/profile_screen.dart'; // Added import for ProfileScreen
import '../screens/search_screen.dart'; // Added import for SearchScreen
import '../screens/add_options_screen.dart'; // Added import for AddOptionsScreen
import '../screens/user_profile_screen.dart'; // Added import for UserProfileScreen
import '../screens/chat_list_screen.dart'; // Added import for ChatListScreen
import '../services/post_service.dart'; // Added import for PostService
import '../screens/discover_users_screen.dart'; // Added import for DiscoverUsersScreen
import '../screens/notifications_screen.dart'; // Added import for NotificationsScreen
import '../screens/baba_pages_screen.dart'; // Added import for BabaPagesScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Story> _stories = [];
  Map<String, List<Story>> _groupedStories = {}; // Grouped stories by user
  List<Post> _posts = []; // Cache posts to avoid regeneration
  bool _isLoadingStories = false;
  bool _isLoadingPosts = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPostIndex = 0;
  static const int _postsPerPage = 5; // Load fewer posts initially
  static const int _maxPostsInMemory = 50; // Maximum posts to keep in memory

  @override
  void initState() {
    super.initState();
    _clearLocalStories(); // Clear any old local stories first
    _loadStories();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialPosts() async {
    if (_isLoadingPosts) return;
    
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('HomeScreen: Auth provider - userProfile: ${authProvider.userProfile != null}, authToken: ${authProvider.authToken != null ? "exists" : "null"}');
      
      if (authProvider.userProfile != null) {
        print('HomeScreen: Current user ID: ${authProvider.userProfile!.id}');
        print('HomeScreen: Calling FeedService.getFeedPosts...');
        
        // Use FeedService to get mixed feed (user posts + Baba Ji posts)
        final posts = await FeedService.getMixedFeed(
          token: authProvider.authToken!,
          currentUserId: authProvider.userProfile!.id,
          page: 1,
          limit: _postsPerPage,
        );

        print('HomeScreen: FeedService returned ${posts.length} posts');
        
        if (mounted) {
          setState(() {
            _posts = posts.take(_maxPostsInMemory).toList(); // Limit posts in memory
            _isLoadingPosts = false;
          });
          print('HomeScreen: Loaded ${posts.length} posts from followed users');
          print('HomeScreen: Posts data: ${posts.map((p) => '${p.username}: ${p.caption}').toList()}');
        }
      } else {
        print('HomeScreen: No user profile found');
        setState(() {
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('HomeScreen: Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading posts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingPosts || _posts.length >= _maxPostsInMemory) return;
    
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userProfile != null) {
        final nextPage = (_posts.length ~/ _postsPerPage) + 1;
        final newPosts = await FeedService.getMixedFeed(
          token: authProvider.authToken!,
          currentUserId: authProvider.userProfile!.id,
          page: nextPage,
          limit: _postsPerPage,
        );

        if (mounted && newPosts.isNotEmpty) {
          setState(() {
            // Add new posts but maintain memory limit
            final totalPosts = [..._posts, ...newPosts];
            _posts = totalPosts.take(_maxPostsInMemory).toList();
            _isLoadingPosts = false;
          });
          print('HomeScreen: Loaded ${newPosts.length} more posts from followed users');
        } else {
          setState(() {
            _isLoadingPosts = false;
          });
        }
      } else {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  /// Get unread message count for the message badge
  Future<int> _getUnreadMessageCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken != null && authProvider.userProfile != null) {
        final threads = await ChatService.getChatThreads(
          token: authProvider.authToken!,
          currentUserId: authProvider.userProfile!.id,
        );
        
        int totalUnread = 0;
        for (final thread in threads) {
          totalUnread += thread.unreadCount;
        }
        return totalUnread;
      }
    } catch (e) {
      print('HomeScreen: Error getting unread message count: $e');
    }
    return 0;
  }

  /// Get unread notification count for the notification badge
  Future<int> _getUnreadNotificationCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken != null && authProvider.userProfile != null) {
        // Assuming a notification service exists or you'd fetch from a backend
        // For now, a placeholder that returns a dummy count
        return 5; // Example: return a dummy count
      }
    } catch (e) {
      print('HomeScreen: Error getting unread notification count: $e');
    }
    return 0;
  }

  Future<void> _loadStories() async {
    if (mounted) {
      setState(() {
        _isLoadingStories = true;
      });
    }

    try {
      List<Story> allStories = [];
      
      // Load stories from server first (only if we have auth token)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken != null) {
        try {
          // Get current user's stories first
          if (authProvider.userProfile != null) {
            final userStories = await StoryService.getUserStories(
              authProvider.userProfile!.id,
              token: authProvider.authToken,
              page: 1,
              limit: 10,
            );
            print('Loaded ${userStories.length} stories from current user');
            if (userStories.isNotEmpty) {
              allStories.addAll(userStories);
            }
          }
          
          // Get stories only from followed users, not from all users
          try {
            // Get followed users list
            final followedUsers = await _getFollowedUsers(authProvider.authToken!);
            print('Found ${followedUsers.length} followed users');
            
            // Only proceed if user is actually following someone
            if (followedUsers.isNotEmpty) {
              // Get stories from each followed user
              for (String followedUserId in followedUsers) {
                try {
                  final followedUserStories = await StoryService.getUserStories(
                    followedUserId,
                    token: authProvider.authToken,
                    page: 1,
                    limit: 10,
                  );
                  print('Loaded ${followedUserStories.length} stories from followed user $followedUserId');
                  
                  // Only add stories if the user actually has stories
                  if (followedUserStories.isNotEmpty) {
                    allStories.addAll(followedUserStories);
                    print('Added ${followedUserStories.length} stories from followed user $followedUserId');
                  } else {
                    print('Followed user $followedUserId has no stories, skipping');
                  }
                } catch (e) {
                  print('Error loading stories from followed user $followedUserId: $e');
                  // Continue with other users even if one fails
                }
              }
            } else {
              print('User is not following anyone, no stories to load from followed users');
            }
            
            print('Total stories after loading from followed users: ${allStories.length}');
          } catch (e) {
            print('Error getting followed users: $e');
            // Fallback: if we can't get followed users, just show current user's stories
          }
          
        } catch (e) {
          print('Error loading stories from story API: $e');
        }
      }
      
      // Remove local stories fallback - only show real stories from server
      // This prevents showing old/stale local stories when user has no real stories
      
      // Sort stories by creation date (newest first) - only if we have stories
      if (allStories.isNotEmpty) {
        allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('HomeScreen: Total stories loaded: ${allStories.length}');
        
        // Group stories by user
        _groupedStories = StoryService.groupStoriesByUser(allStories);
        print('HomeScreen: Grouped stories into ${_groupedStories.length} user sections');
        
        // Debug: Print details of each user's story section
        _groupedStories.forEach((userId, userStories) {
          final firstStory = userStories.first;
          print('HomeScreen: User ${firstStory.authorName} (${firstStory.authorUsername}) has ${userStories.length} stories');
          userStories.forEach((story) {
            print('  - Story ${story.id}: ${story.type} - ${story.media}');
          });
        });
        
        // Debug: Show current user info
        if (authProvider.userProfile != null) {
          print('HomeScreen: Current user ID: ${authProvider.userProfile!.id}');
          print('HomeScreen: Current user name: ${authProvider.userProfile!.fullName}');
        }
        
        // Summary of what stories are being shown
        print('=== STORIES SUMMARY ===');
        print('Total stories loaded: ${allStories.length}');
        print('Stories grouped by ${_groupedStories.length} users:');
        _groupedStories.forEach((userId, userStories) {
          final firstStory = userStories.first;
          final isCurrentUser = authProvider.userProfile != null && 
                              firstStory.authorId == authProvider.userProfile!.id;
          print('  - ${isCurrentUser ? "YOUR STORIES" : "FOLLOWED USER"}: ${firstStory.authorUsername} (${userStories.length} stories)');
        });
        print('=======================');
      } else {
        // No stories available
        print('HomeScreen: No stories available - user has no stories and follows no users with stories');
        _groupedStories = {};
      }
      
      if (mounted) {
        setState(() {
          _stories = allStories;
          _isLoadingStories = false;
        });
      }
    } catch (e) {
      print('Error loading stories: $e');
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
          _groupedStories = {};
        });
      }
    }
  }

  // Clear any old local stories from device storage
  Future<void> _clearLocalStories() async {
    try {
      // Clear local stories from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_stories');
      print('HomeScreen: Cleared old local stories from device storage');
    } catch (e) {
      print('HomeScreen: Error clearing local stories: $e');
    }
  }

  // Refresh the entire feed
  Future<void> _refreshFeed() async {
    print('HomeScreen: Refreshing feed...');
    setState(() {
      _posts = [];
      _stories = [];
      _groupedStories = {};
    });
    
    await Future.wait([
      _loadStories(),
      _loadInitialPosts(),
    ]);
    
    print('HomeScreen: Feed refresh completed');
  }

  // Helper method to get list of users that current user is following
  Future<List<String>> _getFollowedUsers(String token) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get the list of users that current user is following
      final followingUsers = await authProvider.getFollowingUsers();
      print('Found ${followingUsers.length} followed users');
      
      // Extract user IDs from the following users list
      List<String> followedUserIds = [];
      for (var userData in followingUsers) {
        final userId = userData['id'] ?? userData['_id'];
        if (userId != null && userId.toString().isNotEmpty) {
          followedUserIds.add(userId.toString());
          print('Following user: ${userData['username'] ?? 'Unknown'} (ID: $userId)');
        }
      }
      
      return followedUserIds;
      
    } catch (e) {
      print('Error getting followed users: $e');
      return [];
    }
  }







  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea( // Add SafeArea to prevent overflow on different screen sizes
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.userProfile == null) {
              return const AppLoader(message: 'Loading...');
            }

            return RefreshIndicator(
              onRefresh: _refreshFeed,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // App Bar
                  _buildAppBar(authProvider.userProfile!),
                  
                  // Stories Section
                  _buildStoriesSection(),
                  
                  // Feed Content
                  _buildFeedContent(),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar(UserModel userProfile) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            // App Logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/RGRAM logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 12),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        // Refresh Button
        IconButton(
          onPressed: () {
            _refreshFeed();
          },
          icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
          tooltip: 'Refresh Feed',
        ),
        // Notification Icon with Badge
        Stack(
          children: [
            IconButton(
              onPressed: () {
                // Navigate to notifications screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications, color: Color(0xFF6366F1)),
              tooltip: 'Notifications',
            ),
            // Unread notification badge
            Positioned(
              right: 8,
              top: 8,
              child: FutureBuilder<int>(
                future: _getUnreadNotificationCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Message Icon with Badge
        Stack(
          children: [
            IconButton(
              onPressed: () {
                // Navigate to chat list screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.message, color: Color(0xFF6366F1)),
              tooltip: 'Messages',
            ),
            // Unread message badge
            Positioned(
              right: 8,
              top: 8,
              child: FutureBuilder<int>(
                future: _getUnreadMessageCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Responsive helper methods
  double _getResponsiveHorizontalPadding() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 8; // Small screens - reduced from 16
    if (screenWidth < 1200) return 12; // Medium screens - reduced from 20
    return 16; // Large screens - reduced from 24
  }

  double _getResponsiveVerticalPadding() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 4; // Small screens - reduced from 8
    if (screenWidth < 1200) return 6; // Medium screens - reduced from 10
    return 8; // Large screens - reduced from 12
  }

  Widget _buildStoriesSection() {
    return SliverToBoxAdapter(
      child: Container(
        // Remove fixed height to prevent overflow
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            // Stories Header with Refresh Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  IconButton(
                    onPressed: () => _refreshFeed(),
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.grey[600],
                    ),
                    tooltip: 'Refresh Stories',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Show stories or no stories message
            if (_isLoadingStories)
              const AppLoader(message: 'Loading stories...')
            else if (_groupedStories.isEmpty)
              // No stories available message
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_stories,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No stories yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your first story or follow users to see their stories here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _navigateToStoryUpload,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Story'),
                          style: AppTheme.primaryButtonStyle.copyWith(
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/search');
                          },
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Find Users'),
                          style: AppTheme.secondaryButtonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.all(AppTheme.cardColor),
                            foregroundColor: MaterialStateProperty.all(AppTheme.textSecondary),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              // Stories List - Use SizedBox with flexible height
              SizedBox(
                height: 90, // Reduced height to prevent overflow
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 16,
                  ),
                  itemCount: _groupedStories.length + 1, // User story sections + add story button
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Add Story Button
                      return _buildAddStoryButton();
                    }
                    
                    // Get user story section
                    final userId = _groupedStories.keys.elementAt(index - 1);
                    final userStories = _groupedStories[userId]!;
                    final firstStory = userStories.first; // Use first story for user info
                    
                    print('HomeScreen: Building story section for user ${firstStory.authorName}');
                    print('HomeScreen: User has ${userStories.length} stories');
                    
                    // Check if this is the current user's story
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final isCurrentUser = authProvider.userProfile != null && 
                                        firstStory.authorId == authProvider.userProfile!.id;
                    
                    // Determine display name - prioritize username for followed accounts
                    String displayName;
                    if (isCurrentUser) {
                      displayName = 'Your Story';
                    } else {
                      // Show username for followed accounts to make it clear whose story it is
                      displayName = firstStory.authorUsername.isNotEmpty ? 
                                   firstStory.authorUsername : 
                                   firstStory.authorName.isNotEmpty ? 
                                   firstStory.authorName : 'Unknown User';
                    }
                    
                    // Ensure we have a valid media URL from the first story
                    String mediaUrl = firstStory.media;
                    if (mediaUrl.isEmpty || mediaUrl == 'null') {
                      print('HomeScreen: Invalid media URL, using default');
                      mediaUrl = 'https://via.placeholder.com/70x70/6366F1/FFFFFF?text=Story';
                    }
                    
                                         return StoryWidget(
                       storyId: userId, // Use userId as storyId for the section
                       userId: firstStory.authorId,
                       userName: displayName, // Use the determined display name
                       userImage: firstStory.authorAvatar,
                       storyImage: mediaUrl,
                       isViewed: false, // Will be updated based on view status
                       currentUserId: authProvider.userProfile?.id, // Pass current user ID
                       onTap: () {
                         // Open story viewer with all stories from this user
                         print('Opening story section for user: ${firstStory.authorName}');
                         print('User has ${userStories.length} stories to view');
                         _openStoryViewerForUser(userId, userStories);
                       },
                       
                     );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStoryButton() {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing based on screen size
    double storySize = 70;
    double containerWidth = 80;
    double fontSize = 12;
    double spacing = 8;
    
    if (screenWidth < 600) { // Small screens
      storySize = 60;
      containerWidth = 70;
      fontSize = 11;
      spacing = 6;
    } else if (screenWidth < 1200) { // Medium screens
      storySize = 65;
      containerWidth = 75;
      fontSize = 12;
      spacing = 7;
    }
    
    return Container(
      width: containerWidth,
      margin: EdgeInsets.only(right: screenWidth < 600 ? 8 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          // Add Story Circle
          GestureDetector(
            onTap: () {
              _navigateToStoryUpload();
            },
            child: Container(
              width: storySize,
              height: storySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFEC4899),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(screenWidth < 600 ? 2 : 3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.add,
                  color: const Color(0xFF6366F1),
                  size: screenWidth < 600 ? 24 : 30,
                ),
              ),
            ),
          ),
          
          SizedBox(height: spacing),
          
          // Add Story Text - Use Flexible to prevent overflow
          Flexible(
            child: Text(
              'Add Story',
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Allow 2 lines to prevent overflow
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToStoryUpload() async {
    // Get the auth token from the provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.authToken;
    
    if (token != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryUploadScreen(token: token),
        ),
      );
      
      // Refresh stories if upload was successful
      if (result == true) {
        _refreshFeed();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to upload stories'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openStoryViewer(Story story) {
    // Find the index of the tapped story
    final storyIndex = _stories.indexOf(story);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          story: story,
          allStories: _stories,
          initialIndex: storyIndex,
        ),
      ),
    );
  }

  void _openStoryViewerForUser(String userId, List<Story> userStories) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          story: userStories.first, // Pass the first story as required parameter
          allStories: userStories,
          initialIndex: 0, // Start from the first story in the section
        ),
      ),
    );
  }
  
  /// Delete a story and refresh the stories list
  Future<void> _deleteStory(String userId, List<Story> userStories) async {
    try {
      // Get auth token and current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUser = authProvider.userProfile;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to delete stories'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check if current user is the owner of the story
      final firstStory = userStories.first;
      if (currentUser == null || currentUser.id != firstStory.authorId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only delete your own stories'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting story...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Delete the story (only if user is the owner)
      final result = await StoryService.deleteStory(
        firstStory.id,
        firstStory.authorId,
        token,
      );
      
      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Story deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh stories to remove the deleted story
        await _refreshFeed();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete story'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting story: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openPostInFullView(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostFullViewScreen(post: post),
      ),
    );
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

  Widget _buildFeedContent() {
    if (_posts.isEmpty && !_isLoadingPosts) {
      // Show message when no posts are available
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.feed_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No posts from followed users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Follow some users to see their posts and reels in your feed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/search');
                    },
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search Users'),
                    style: AppTheme.primaryButtonStyle.copyWith(
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/explore');
                    },
                    icon: const Icon(Icons.explore, size: 18),
                    label: const Text('Explore Posts'),
                    style: AppTheme.secondaryButtonStyle.copyWith(
                      backgroundColor: MaterialStateProperty.all(AppTheme.cardColor),
                      foregroundColor: MaterialStateProperty.all(AppTheme.textSecondary),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiscoverUsersScreen(),
                      ),
                    );
                    // Refresh feed when returning from discover users
                    _refreshFeedOnReturn();
                  },
                  icon: const Icon(Icons.people, size: 18),
                  label: const Text('Discover Users with Posts'),
                  style: AppTheme.accentButtonStyle.copyWith(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _posts.length) {
            // Show loading indicator at the bottom
            if (_isLoadingPosts && _currentPostIndex < _maxPostsInMemory) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final post = _posts[index];
          
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: _getResponsiveHorizontalPadding() * 0.5,
              vertical: _getResponsiveVerticalPadding(),
            ),
            child: EnhancedPostWidget(
              post: post,
              onLike: () {
                print('Liked post: ${post.id}');
              },
              onComment: () {
                print('Comment on post: ${post.id}');
              },
              onShare: () {
                print('Share post: ${post.id}');
              },
              onUserTap: () {
                _navigateToUserProfile(post);
              },
              onPostTap: () {
                _openPostInFullView(post);
              },
              onDelete: () {
                // Remove the deleted post from the list and refresh
                setState(() {
                  _posts.removeWhere((p) => p.id == post.id);
                });
                print('Post deleted: ${post.id}');
                
                // Refresh the feed to get more content if needed
                if (_posts.length < _maxPostsInMemory) {
                  _loadMorePosts();
                }
              },
            ),
          );
        },
        childCount: _posts.length + (_isLoadingPosts && _currentPostIndex < _maxPostsInMemory ? 1 : 0),
      ),
    );
  }

  // Method to refresh feed when returning from discover users
  Future<void> _refreshFeedOnReturn() async {
    await _loadInitialPosts();
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: true,
                onTap: () {
                  // Already on home
                },
              ),
              
              // Search
              _buildNavItem(
                icon: Icons.search,
                label: 'Search',
                isSelected: false,
                onTap: () {
                  // Navigate to search screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
              ),
              
              // Add Button (Simple)
              _buildNavItem(
                icon: Icons.add,
                label: 'Add',
                isSelected: false,
                onTap: () {
                  // Navigate to add options screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddOptionsScreen(),
                    ),
                  );
                },
              ),
              
              // Baba Ji Pages
              _buildNavItem(
                icon: Icons.self_improvement,
                label: 'Baba Ji',
                isSelected: false,
                onTap: () {
                  // Navigate to Baba Ji pages screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BabaPagesScreen(),
                    ),
                  );
                },
              ),
              
              // Live Darshan
              _buildNavItem(
                icon: Icons.live_tv,
                label: 'Live Darshan',
                isSelected: false,
                onTap: () {
                  // Navigate to live darshan
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiveStreamScreen(),
                    ),
                  );
                },
              ),
              
              // Account
              _buildNavItem(
                icon: Icons.person,
                label: 'Account',
                isSelected: false,
                onTap: () {
                  // Navigate to account/profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  void _showInterestChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Interest'),
          content: const Text('Select your spiritual interest to personalize your feed'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to interest selection screen
                Navigator.pushNamed(context, '/interests');
              },
              child: Text(
                'Change',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show immediate loading feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logging out...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Immediately redirect to signup page
                Navigator.pushReplacementNamed(context, '/signup');
                
                // Logout in background (don't wait for it)
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout().catchError((e) {
                  print('Background logout error: $e');
                });
              },
              child: Text(
                'Logout',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom Painter for Religious Diversity Symbol
class ReligiousDiversityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw the Earth (center circle)
    final earthPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.3, earthPaint);
    
    // Draw religious symbols around the Earth
    _drawReligiousSymbols(canvas, center, radius);
  }
  
  void _drawReligiousSymbols(Canvas canvas, Offset center, double radius) {
    // Om symbol (Hinduism) - Top left
    _drawOmSymbol(canvas, Offset(center.dx - radius * 0.6, center.dy - radius * 0.6), radius * 0.15);
    
    // Cross (Christianity) - Top middle
    _drawCross(canvas, Offset(center.dx, center.dy - radius * 0.6), radius * 0.15);
    
    // Crescent and Star (Islam) - Top right
    _drawCrescent(canvas, Offset(center.dx + radius * 0.6, center.dy - radius * 0.6), radius * 0.15);
    
    // Dharma Wheel (Buddhism) - Middle right
    _drawDharmaWheel(canvas, Offset(center.dx + radius * 0.6, center.dy), radius * 0.15);
    
    // Star of David (Judaism) - Bottom right
    _drawStarOfDavid(canvas, Offset(center.dx + radius * 0.6, center.dy + radius * 0.6), radius * 0.15);
    
    // Ahimsa Hand (Jainism) - Bottom middle
    _drawAhimsaHand(canvas, Offset(center.dx, center.dy + radius * 0.6), radius * 0.15);
    
    // Khanda (Sikhism) - Bottom left
    _drawKhanda(canvas, Offset(center.dx - radius * 0.6, center.dy + radius * 0.6), radius * 0.15);
    
    // Bahá'í Star - Middle left
    _drawBahaiStar(canvas, Offset(center.dx - radius * 0.6, center.dy), radius * 0.15);
  }
  
  void _drawOmSymbol(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    
    // Simplified Om symbol representation
    final path = Path();
    path.moveTo(center.dx - size * 0.3, center.dy + size * 0.2);
    path.quadraticBezierTo(center.dx, center.dy - size * 0.3, center.dx + size * 0.3, center.dy + size * 0.2);
    path.moveTo(center.dx, center.dy - size * 0.2);
    path.lineTo(center.dx, center.dy + size * 0.3);
    canvas.drawPath(path, paint);
  }
  
  void _drawCross(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.15;
    
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.4),
      Offset(center.dx, center.dy + size * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size * 0.25, center.dy),
      Offset(center.dx + size * 0.25, center.dy),
      paint,
    );
  }
  
  void _drawCrescent(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    
    // Crescent moon
    final path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: size * 0.4), 0, 3.14);
    path.addArc(Rect.fromCircle(center: Offset(center.dx + size * 0.1, center.dy), radius: size * 0.3), 0, 3.14);
    canvas.drawPath(path, paint);
    
    // Star
    _drawStar(canvas, Offset(center.dx + size * 0.2, center.dy - size * 0.2), size * 0.15);
  }
  
  void _drawDharmaWheel(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFFEAB308)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08;
    
    // Outer circle
    canvas.drawCircle(center, size * 0.4, paint);
    
    // Inner spokes
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14159 / 4;
      final start = Offset(
        center.dx + (size * 0.1) * cos(angle),
        center.dy + (size * 0.1) * sin(angle),
      );
      final end = Offset(
        center.dx + (size * 0.35) * cos(angle),
        center.dy + (size * 0.35) * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }
  
  void _drawStarOfDavid(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    
    // Draw two overlapping triangles
    final path1 = Path();
    path1.moveTo(center.dx, center.dy - size * 0.4);
    path1.lineTo(center.dx - size * 0.35, center.dy + size * 0.2);
    path1.lineTo(center.dx + size * 0.35, center.dy + size * 0.2);
    path1.close();
    
    final path2 = Path();
    path2.moveTo(center.dx, center.dy + size * 0.4);
    path2.lineTo(center.dx - size * 0.35, center.dy - size * 0.2);
    path2.lineTo(center.dx + size * 0.35, center.dy - size * 0.2);
    path2.close();
    
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }
  
  void _drawAhimsaHand(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    
    // Simplified hand representation
    final path = Path();
    path.moveTo(center.dx - size * 0.3, center.dy - size * 0.2);
    path.quadraticBezierTo(center.dx, center.dy - size * 0.4, center.dx + size * 0.3, center.dy - size * 0.2);
    path.lineTo(center.dx + size * 0.2, center.dy + size * 0.1);
    path.quadraticBezierTo(center.dx, center.dy + size * 0.3, center.dx - size * 0.2, center.dy + size * 0.1);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawKhanda(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    
    // Central circle
    canvas.drawCircle(center, size * 0.15, paint);
    
    // Vertical sword
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.4),
      Offset(center.dx, center.dy + size * 0.4),
      paint,
    );
    
    // Horizontal swords
    canvas.drawLine(
      Offset(center.dx - size * 0.3, center.dy),
      Offset(center.dx + size * 0.3, center.dy),
      paint,
    );
  }
  
  void _drawBahaiStar(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    
    // 8-pointed star
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14159 / 4;
      final start = Offset(
        center.dx + (size * 0.1) * cos(angle),
        center.dy + (size * 0.1) * sin(angle),
      );
      final end = Offset(
        center.dx + (size * 0.4) * cos(angle),
        center.dy + (size * 0.4) * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }
  
  void _drawStar(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * 3.14159 / 5 - 3.14159 / 2;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

