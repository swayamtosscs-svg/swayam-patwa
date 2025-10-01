import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../services/baba_page_service.dart';
import '../services/follow_state_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/baba_page_reel_model.dart';
import '../widgets/story_widget.dart';
import '../widgets/enhanced_post_widget.dart';
import '../widgets/in_app_video_widget.dart';
import '../widgets/single_video_widget.dart';
import '../widgets/app_loader.dart';
import '../widgets/image_slider_widget.dart';
import '../widgets/dp_widget.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/notification_bell_widget.dart';
import '../utils/app_theme.dart';
import '../utils/font_theme.dart';
import '../screens/story_upload_screen.dart';
import '../screens/story_viewer_screen.dart';
import '../screens/post_full_view_screen.dart';
import '../screens/post_slider_screen.dart';
import '../screens/live_stream_screen.dart';
import '../services/story_service.dart';
// Removed local story service import to prevent showing old local stories
import '../services/feed_service.dart';
import '../services/chat_service.dart';
import '../models/chat_thread_model.dart';
import '../screens/profile_screen.dart'; // Added import for ProfileScreen
import '../screens/baba_pages_screen.dart'; // Added import for BabaPagesScreen
import '../profile_ui.dart';
import '../screens/search_screen.dart'; // Added import for SearchScreen
import '../screens/instagram_search_screen.dart'; // Added import for InstagramSearchScreen
import '../screens/add_options_screen.dart'; // Added import for AddOptionsScreen
import '../screens/user_profile_screen.dart'; // Added import for UserProfileScreen
import '../screens/chat_list_screen.dart'; // Added import for ChatListScreen
import '../screens/chat_screen.dart'; // Added import for ChatScreen
import '../services/post_service.dart'; // Added import for PostService
import '../services/baba_page_story_service.dart'; // Added import for BabaPageStoryService
import '../screens/discover_users_screen.dart'; // Added import for DiscoverUsersScreen
import '../screens/notifications_screen.dart'; // Added import for NotificationsScreen
import '../utils/performance_test.dart';

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
  bool _isRefreshing = false; // Single loading state for refresh operations
  final ScrollController _scrollController = ScrollController();
  int _currentPostIndex = 0;
  static const int _postsPerPage = 6; // Reduced for faster initial loading
  static const int _maxPostsInMemory = 20; // Reduced memory usage
  
  // Search overlay state
  bool _isSearchOverlayVisible = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchLoading = false;
  bool _hasSearched = false;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _clearLocalStories(); // Clear any old local stories first
    _loadInitialData(); // Load stories and posts in parallel
    _scrollController.addListener(_onScroll);
    
    // Force load Babaji stories on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureBabajiStoriesVisible();
    });
  }
  
  // Ensure Babaji stories are visible
  Future<void> _ensureBabajiStoriesVisible() async {
    print('=== ENSURING BABAJI STORIES VISIBLE ===');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken != null) {
        // Check if we already have Babaji stories
        final hasBabajiStories = _stories.any((story) => 
          story.authorName.toLowerCase().contains('baba') || 
          story.authorUsername.toLowerCase().contains('babaji')
        );
        
        if (!hasBabajiStories) {
          print('No Babaji stories found, loading them...');
          final babajiStories = await BabaPageStoryService.getAllBabajiStoriesAsStories(
            token: authProvider.authToken,
            page: 1,
            limit: 10,
          );
          
          if (babajiStories.isNotEmpty) {
            setState(() {
              _stories.addAll(babajiStories);
              _groupedStories = StoryService.groupStoriesByUser(_stories);
            });
            print('Added ${babajiStories.length} Babaji stories to ensure visibility');
          } else {
            print('Still no real Babaji stories found from API');
            print('Dhani Baba needs to upload stories to see them here');
          }
        } else {
          print('Babaji stories already present');
        }
      }
    } catch (e) {
      print('Error ensuring Babaji stories visible: $e');
    }
    print('=== END ENSURING BABAJI STORIES VISIBLE ===');
  }
  
  // Manual method to force load Babaji stories
  Future<void> _forceLoadBabajiStories() async {
    print('=== MANUAL FORCE LOAD BABAJI STORIES ===');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken != null) {
        print('Manually loading Babaji stories...');
        final babajiStories = await BabaPageStoryService.getAllBabajiStoriesAsStories(
          token: authProvider.authToken,
          page: 1,
          limit: 10,
        );
        
        if (babajiStories.isNotEmpty) {
          setState(() {
            _stories.addAll(babajiStories);
            _groupedStories = StoryService.groupStoriesByUser(_stories);
          });
          print('Manual load: Added ${babajiStories.length} Babaji stories');
        } else {
          print('Manual load: No real stories from API');
          print('Dhani Baba needs to upload stories first');
        }
      } else {
        print('Manual load: No auth token available');
      }
    } catch (e) {
      print('Manual load error: $e');
    }
    print('=== END MANUAL FORCE LOAD ===');
  }

  // Load initial data in parallel for faster startup
  Future<void> _loadInitialData() async {
    try {
      // Load stories and posts in parallel for faster initial loading
      await Future.wait([
        _loadStories(),
        _loadInitialPosts(),
      ]);
    } catch (e) {
      print('HomeScreen: Error loading initial data: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Only load more posts if we're not already loading and have posts to load
      if (!_isLoadingPosts && _posts.isNotEmpty) {
        _loadMorePosts();
      }
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
            // Remove duplicates based on post ID
            final uniquePosts = <String, Post>{};
            for (final post in posts) {
              uniquePosts[post.id] = post;
            }
            _posts = uniquePosts.values.take(_maxPostsInMemory).toList();
            _isLoadingPosts = false; // Always clear loading state
          });
        print('HomeScreen: Loaded ${posts.length} posts from followed users');
        if (posts.isNotEmpty) {
          print('HomeScreen: Posts data: ${posts.map((p) => '${p.username}: ${p.caption}').toList()}');
          
          // Debug: Check for Baba Ji reels
          final babjiReels = posts.where((p) => p.isBabaJiPost && p.isReel).toList();
          print('HomeScreen: Found ${babjiReels.length} Baba Ji reels in feed');
          for (final reel in babjiReels) {
            print('  - Baba Ji Reel: ${reel.id} by ${reel.username}');
            print('    Video URL: ${reel.videoUrl}');
            print('    Thumbnail: ${reel.thumbnailUrl}');
          }
        } else {
          print('HomeScreen: No posts available - showing empty state');
        }
        }
      } else {
        print('HomeScreen: No user profile found');
        if (mounted) {
          setState(() {
            _isLoadingPosts = false; // Always clear loading state
          });
        }
      }
    } catch (e) {
      print('HomeScreen: Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false; // Always clear loading state
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

  // Ultra-optimized posts loading for refresh
  Future<void> _loadInitialPostsOptimized() async {
    if (_isLoadingPosts) return;
    
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.userProfile != null) {
        // Use smaller limit for faster loading during refresh
        final posts = await FeedService.getMixedFeed(
          token: authProvider.authToken!,
          currentUserId: authProvider.userProfile!.id,
          page: 1,
          limit: 3, // Reduced from _postsPerPage for faster refresh
        );
        
        if (mounted) {
          setState(() {
            // Only add new posts, don't replace existing ones
            final existingIds = _posts.map((p) => p.id).toSet();
            final newPosts = posts.where((post) => !existingIds.contains(post.id)).toList();
            _posts = [..._posts, ...newPosts].take(_maxPostsInMemory).toList();
            _isLoadingPosts = false; // Always clear loading state
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingPosts = false; // Always clear loading state
          });
        }
      }
    } catch (e) {
      print('HomeScreen: Error loading posts (optimized): $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false; // Always clear loading state
        });
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

        if (mounted) {
          setState(() {
            if (newPosts.isNotEmpty) {
              // Add new posts but maintain memory limit and remove duplicates
              final existingIds = _posts.map((p) => p.id).toSet();
              final uniqueNewPosts = newPosts.where((post) => !existingIds.contains(post.id)).toList();
              final totalPosts = [..._posts, ...uniqueNewPosts];
              _posts = totalPosts.take(_maxPostsInMemory).toList();
            }
            _isLoadingPosts = false; // Always clear loading state
          });
          if (newPosts.isNotEmpty) {
            print('HomeScreen: Loaded ${newPosts.length} more posts from followed users');
          } else {
            print('HomeScreen: No more posts available');
          }
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
        // Get real unread notification count from the API
        return await NotificationService.getUnreadCount(
          token: authProvider.authToken!,
        );
      }
    } catch (e) {
      print('HomeScreen: Error getting unread notification count: $e');
    }
    return 0;
  }

  // Ultra-optimized stories loading for refresh
  Future<void> _loadStoriesOptimized() async {
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
          // Get current user's stories first (limit to 5 for speed)
          if (authProvider.userProfile != null) {
            final userStories = await StoryService.getUserStories(
              authProvider.userProfile!.id,
              token: authProvider.authToken,
              page: 1,
              limit: 5, // Reduced limit for faster loading
            );
            if (userStories.isNotEmpty) {
              allStories.addAll(userStories);
            }
          }
          
          // Get stories from followed users (limit to 3 users for speed)
          try {
            final followedUsers = await _getFollowedUsers(authProvider.authToken!);
            
            if (followedUsers.isNotEmpty) {
              // Limit to first 3 followed users for faster loading
              final limitedUsers = followedUsers.take(3).toList();
              
              // Load stories from each followed user in parallel
              final storyFutures = limitedUsers.map((followedUserId) async {
                try {
                  final followedUserStories = await StoryService.getUserStories(
                    followedUserId,
                    token: authProvider.authToken,
                    page: 1,
                    limit: 3, // Reduced limit for faster loading
                  );
                  return followedUserStories;
                } catch (e) {
                  print('Error loading stories from followed user $followedUserId: $e');
                  return <Story>[];
                }
              });
              
              // Wait for all story loading to complete in parallel
              final storyResults = await Future.wait(storyFutures);
              
              // Add all stories
              for (final stories in storyResults) {
                allStories.addAll(stories);
              }
            }
          } catch (e) {
            print('Error getting followed users: $e');
          }
          
          // Load Babaji stories for home page - only if user is following Baba Ji (optimized)
          try {
            final isFollowingBabaJi = await _isUserFollowingBabaJi(authProvider.authToken!, authProvider.userProfile?.id);
            print('Optimized loading - User is following Baba Ji: $isFollowingBabaJi');
            if (isFollowingBabaJi) {
              print('Loading Babaji stories for home page (optimized)...');
              final babajiStories = await BabaPageStoryService.getAllBabajiStoriesAsStories(
                token: authProvider.authToken,
                page: 1,
                limit: 5, // Reduced limit for faster loading
              );
              print('Optimized loading - Loaded ${babajiStories.length} Babaji stories');
              if (babajiStories.isNotEmpty) {
                allStories.addAll(babajiStories);
                print('Added ${babajiStories.length} Babaji stories to home page (optimized)');
              }
            } else {
              print('Optimized loading - User is not following Baba Ji, skipping Babaji stories');
            }
          } catch (e) {
            print('Error loading Babaji stories (optimized): $e');
          }
        } catch (e) {
          print('Error loading stories from story API: $e');
        }
      }
      
      // Sort stories by creation date (newest first) - only if we have stories
      if (allStories.isNotEmpty) {
        allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Group stories by user
        _groupedStories = StoryService.groupStoriesByUser(allStories);
      } else {
        _groupedStories = {};
      }
      
      if (mounted) {
        setState(() {
          _stories = allStories;
          _isLoadingStories = false;
        });
      }
    } catch (e) {
      print('Error loading stories (optimized): $e');
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
          _groupedStories = {};
        });
      }
    }
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
          
          // Load Babaji stories for home page - only if user is following Baba Ji
          try {
            print('Checking if user is following Baba Ji...');
            final isFollowingBabaJi = await _isUserFollowingBabaJi(authProvider.authToken!, authProvider.userProfile?.id);
            print('User is following Baba Ji: $isFollowingBabaJi');
            
            // Always load Baba Ji stories for home page display
            print('=== LOADING BABA JI STORIES ===');
            print('Token available: ${authProvider.authToken != null}');
            if (authProvider.authToken != null) {
              print('Token preview: ${authProvider.authToken!.substring(0, authProvider.authToken!.length > 20 ? 20 : authProvider.authToken!.length)}...');
            }
            
            final babajiStories = await BabaPageStoryService.getAllBabajiStoriesAsStories(
              token: authProvider.authToken,
              page: 1,
              limit: 10,
            );
            print('=== BABA JI STORIES RESULT ===');
            print('Loaded ${babajiStories.length} Baba Ji stories');
            
            if (babajiStories.isNotEmpty) {
              allStories.addAll(babajiStories);
              print('Added ${babajiStories.length} Baba Ji stories to allStories');
              print('Total stories now: ${allStories.length}');
              
              // Debug: Print details of each Baba Ji story
              print('=== BABA JI STORY DETAILS ===');
              for (int i = 0; i < babajiStories.length; i++) {
                final story = babajiStories[i];
                print('Story $i:');
                print('  - ID: ${story.id}');
                print('  - Author ID: ${story.authorId}');
                print('  - Author Name: ${story.authorName}');
                print('  - Author Username: ${story.authorUsername}');
                print('  - Media: ${story.media}');
                print('  - Type: ${story.type}');
                print('  - Created: ${story.createdAt}');
                print('  - Is Active: ${story.isActive}');
                print('  - Expires At: ${story.expiresAt}');
              }
            } else {
              print('=== NO REAL BABA JI STORIES FOUND ===');
              print('This means:');
              print('1. Dhani Baba has not uploaded any stories yet');
              print('2. API connection issue');
              print('3. Wrong Baba page ID');
              print('4. Stories expired or inactive');
              print('5. Need to check if stories are uploaded to correct Baba page');
              print('No fake stories will be shown - only real uploaded stories');
            }
          } catch (e) {
            print('Error loading Babaji stories: $e');
            // Continue without Babaji stories if there's an error
          }
          
        } catch (e) {
          print('Error loading stories from story API: $e');
        }
      }
      
      // Remove local stories fallback - only show real stories from server
      // This prevents showing old/stale local stories when user has no real stories
      
      // If no stories were loaded, try to load at least Babaji stories as fallback
      if (allStories.isEmpty) {
        print('No stories loaded, trying Babaji stories as fallback...');
        try {
          final babajiStories = await BabaPageStoryService.getAllBabajiStoriesAsStories(
            token: authProvider.authToken,
            page: 1,
            limit: 10,
          );
          if (babajiStories.isNotEmpty) {
            allStories.addAll(babajiStories);
            print('Added ${babajiStories.length} Babaji stories as fallback');
          } else {
            print('No real Babaji stories available as fallback');
            print('Dhani Baba needs to upload stories first');
          }
        } catch (e) {
          print('Error loading Babaji stories as fallback: $e');
          print('No fake stories will be created - only real uploaded stories');
        }
      }
      
      // Sort stories by creation date (newest first) - only if we have stories
      if (allStories.isNotEmpty) {
        print('=== SORTING AND GROUPING STORIES ===');
        print('Total stories before sorting: ${allStories.length}');
        
        allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('HomeScreen: Total stories loaded: ${allStories.length}');
        
        // Debug: Print all stories before grouping
        print('=== ALL STORIES BEFORE GROUPING ===');
        for (int i = 0; i < allStories.length; i++) {
          final story = allStories[i];
          print('Story $i:');
          print('  - ID: ${story.id}');
          print('  - Author ID: ${story.authorId}');
          print('  - Author Name: ${story.authorName}');
          print('  - Author Username: ${story.authorUsername}');
          print('  - Media: ${story.media}');
          print('  - Type: ${story.type}');
          print('  - Is Active: ${story.isActive}');
        }
        
        // Group stories by user
        _groupedStories = StoryService.groupStoriesByUser(allStories);
        print('HomeScreen: Grouped stories into ${_groupedStories.length} user sections');
        
        // Debug: Print details of each user's story section
        print('=== GROUPED STORIES ===');
        _groupedStories.forEach((userId, userStories) {
          final firstStory = userStories.first;
          print('User Section: ${firstStory.authorName} (${firstStory.authorUsername})');
          print('  - User ID: $userId');
          print('  - Author ID: ${firstStory.authorId}');
          print('  - Stories count: ${userStories.length}');
          userStories.forEach((story) {
            print('    - Story ${story.id}: ${story.type} - ${story.media}');
          });
        });
        
        // Special debug for Baba Ji stories
        final babajiStories = allStories.where((story) => 
          story.authorName.toLowerCase().contains('baba') || 
          story.authorUsername.toLowerCase().contains('babaji')
        ).toList();
        print('HomeScreen: Found ${babajiStories.length} Baba Ji stories in allStories');
        babajiStories.forEach((story) {
          print('  - Baba Ji Story: ${story.id} by ${story.authorName} (${story.authorUsername})');
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

  // Refresh the entire feed - Ultra-optimized for speed
  Future<void> _refreshFeed() async {
    print('HomeScreen: Refreshing feed...');
    setState(() {
      _isRefreshing = true; // Set single loading state for refresh
    });
    
    try {
      // Load stories and posts in parallel for maximum speed
      final futures = <Future>[];
      
      // Only reload stories if they're empty or very old (older than 5 minutes)
      final now = DateTime.now();
      final storiesAge = _stories.isEmpty ? Duration.zero : now.difference(_stories.first.createdAt);
      if (_stories.isEmpty || storiesAge.inMinutes > 5) {
        futures.add(_loadStoriesOptimized());
      }
      
      // Only refresh posts if we have very few posts (less than 3)
      if (_posts.length < 3) {
        futures.add(_loadInitialPostsOptimized());
      }
      
      // Wait for all operations to complete in parallel
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      
    } catch (e) {
      print('HomeScreen: Error during refresh: $e');
    }
    
    setState(() {
      _isRefreshing = false; // Clear loading state
    });
    
    print('HomeScreen: Feed refresh completed');
  }


  // Search methods
  void _showSearchOverlay() {
    setState(() {
      _isSearchOverlayVisible = true;
    });
  }

  void _hideSearchOverlay() {
    setState(() {
      _isSearchOverlayVisible = false;
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
      _lastSearchQuery = '';
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
      _lastSearchQuery = query.trim();
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await authProvider.searchUsers(query.trim());
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchSubmitted(String query) {
    _performSearch(query);
  }

  void _onSearchChanged(String query) {
    // Debounce search - only search after user stops typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _performSearch(query);
      }
    });
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

  // Helper method to check if user is following Baba Ji
  Future<bool> _isUserFollowingBabaJi(String token, String? userId) async {
    try {
      if (userId == null) {
        print('HomeScreen: No user ID available, cannot check Baba Ji follow status');
        return false;
      }

      print('HomeScreen: Checking if user $userId is following Baba Ji...');
      
      // Get Baba pages to check follow status
      final babaPagesResponse = await BabaPageService.getBabaPages(token: token, page: 1, limit: 50);
      
      if (babaPagesResponse.success && babaPagesResponse.pages.isNotEmpty) {
        // Find the main Baba Ji page (assuming it's the first one or has a specific identifier)
        // For now, we'll check if any Baba page is being followed
        for (final babaPage in babaPagesResponse.pages) {
          // Use FollowStateService to get the correct follow state
          final isFollowing = await FollowStateService.getFollowState(
            userId: userId,
            pageId: babaPage.id,
            serverState: babaPage.isFollowing,
          );
          
          if (isFollowing) {
            print('HomeScreen: User is following Baba Ji page: ${babaPage.name} (${babaPage.id})');
            return true;
          }
        }
        
        print('HomeScreen: User is not following any Baba Ji pages');
        return false;
      } else {
        print('HomeScreen: Failed to get Baba pages: ${babaPagesResponse.message}');
        return false;
      }
    } catch (e) {
      print('HomeScreen: Error checking Baba Ji follow status: $e');
      return false;
    }
  }






  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Spiritual symbols overlay
                _buildSpiritualSymbolsOverlay(),
                SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Show single loader for any loading state - Fixed to prevent infinite loading
            if (authProvider.userProfile == null || _isRefreshing) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 3, // Thinner for faster visual feedback
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    Text(
                      authProvider.userProfile == null 
                        ? 'Loading...' 
                        : 'Refreshing feed...',
                      style: const TextStyle(
                        fontSize: 14, // Smaller font for faster rendering
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refreshFeed,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // App Bar
                      SliverToBoxAdapter(
                        child: _buildAppBar(authProvider.userProfile!),
                      ),
                      
                      // Stories Section
                      _buildStoriesSection(),
                      
                      // Feed Content
                      _buildFeedContent(),
                    ],
                  ),
                ),
                
                // Search Overlay
                if (_isSearchOverlayVisible)
                  _buildSearchOverlay(),
              ],
            );
          },
        ),
                ),
              ],
            ),
          ),
      bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildAppBar(UserModel userProfile) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // RGram Logo Image (left aligned)
              Image.asset(
                'assets/icons/home_header_logo.png',
                height: 54,
                width: 80,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              // Search Icon
              IconButton(
                onPressed: () {
                  _showSearchOverlay();
                },
                icon: const Icon(Icons.search, color: Colors.black, size: 24),
                tooltip: 'Search Users',
              ),
              // Notification Bell Widget
              const NotificationBellWidget(
                size: 24,
                color: Colors.black,
              ),
              // Debug Button for Babaji Stories (temporary)
              IconButton(
                onPressed: () {
                  _forceLoadBabajiStories();
                },
                icon: const Icon(Icons.bug_report, color: Colors.red, size: 24),
                tooltip: 'Debug: Force Load Babaji Stories',
              ),
              // Message Icon with Badge
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 24),
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
          ),
        );
      },
    );
  }

  Widget _buildSearchOverlay() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Signup page bg.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Spiritual symbols overlay
          Positioned.fill(
            child: CustomPaint(
              painter: SpiritualSymbolsPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Search Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _hideSearchOverlay,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Search Users',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
            
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearchSubmitted,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'Search for users...',
                  hintStyle: const TextStyle(
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.black,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _hasSearched = false;
                            });
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.black54,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
            
                // Search Results
                Expanded(
                  child: _buildSearchResults(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        if (_isSearchLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: themeService.primaryColor,
            ),
          );
        }

        if (!_hasSearched) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.black.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Search for users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter a username or name to find other accounts',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (_searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.black.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No users found for "$_lastSearchQuery"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final userData = _searchResults[index];
            return _buildSearchUserCard(userData);
          },
        );
      },
    );
  }

  Widget _buildSearchUserCard(Map<String, dynamic> userData) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final username = userData['username'] ?? 'Unknown';
        final fullName = userData['fullName'] ?? 'No Name';
        final bio = userData['bio'] ?? '';
        final avatar = userData['avatar'] ?? '';
        final userId = userData['id'] ?? userData['_id'] ?? '';
        final followersCount = userData['followersCount'] ?? 0;
        final followingCount = userData['followingCount'] ?? 0;
        final postsCount = userData['postsCount'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading:             // Profile Picture using DPWidget
            DPWidget(
              currentImageUrl: avatar,
              userId: userData['_id'] ?? '',
              token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
              userName: fullName,
              onImageChanged: (String newImageUrl) {
                // Update the avatar if needed
                print('HomeScreen: Avatar changed to: $newImageUrl');
              },
              size: 50,
              borderColor: const Color(0xFF6366F1),
              showEditButton: false, // Don't show edit button for other users' profiles
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatItem('Posts', postsCount.toString()),
                    const SizedBox(width: 16),
                    FutureBuilder<Map<String, int>>(
                      future: userId.isNotEmpty ? Provider.of<AuthProvider>(context, listen: false).getUserCounts(userId) : Future.value({'followers': 0, 'following': 0}),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Row(
                            children: [
                              SkeletonStatItem(width: 50, height: 20),
                              const SizedBox(width: 16),
                              SkeletonStatItem(width: 50, height: 20),
                            ],
                          );
                        }
                        
                        int realFollowersCount = followersCount;
                        int realFollowingCount = followingCount;
                        if (snapshot.hasData && userId.isNotEmpty) {
                          realFollowersCount = snapshot.data!['followers'] ?? followersCount;
                          realFollowingCount = snapshot.data!['following'] ?? followingCount;
                        }
                        return Row(
                          children: [
                            _buildStatItem('Followers', realFollowersCount.toString()),
                            const SizedBox(width: 16),
                            _buildStatItem('Following', realFollowingCount.toString()),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                
                // Action Buttons
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Message Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Add conversation to local storage
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          if (authProvider.userProfile != null) {
                            await ChatService.addConversation(
                              currentUserId: authProvider.userProfile!.id,
                              otherUserId: userData['_id'] ?? '',
                              otherUsername: username,
                              otherFullName: fullName,
                              otherAvatar: avatar,
                            );
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                recipientUserId: userData['_id'] ?? '',
                                recipientUsername: username,
                                recipientFullName: fullName,
                                recipientAvatar: avatar,
                                threadId: null, // New conversation
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // Navigate to user profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: userData['_id'] ?? '',
                    username: username,
                    fullName: fullName,
                    avatar: avatar,
                    bio: bio,
                    followersCount: followersCount,
                    followingCount: followingCount,
                    postsCount: postsCount,
                    isPrivate: userData['isPrivate'] ?? false,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Icon(
          Icons.person,
          size: 30,
          color: Colors.black,
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  // Spiritual symbols overlay (same as Messages screen)
  Widget _buildSpiritualSymbolsOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SpiritualSymbolsPainter(),
      ),
    );
  }

  // Theme switcher helper methods
  String _getNextReligion(String currentReligion) {
    const religions = ['hinduism', 'islam', 'christianity', 'jainism', 'buddhism', 'default'];
    final currentIndex = religions.indexOf(currentReligion);
    return religions[(currentIndex + 1) % religions.length];
  }

  IconData _getThemeIcon(String religion) {
    switch (religion) {
      case 'hinduism':
      case 'hindu':
        return Icons.auto_awesome;
      case 'islam':
      case 'muslim':
        return Icons.star;
      case 'christianity':
      case 'christian':
        return Icons.add;
      case 'jainism':
      case 'jain':
        return Icons.eco;
      case 'buddhism':
      case 'buddhist':
        return Icons.self_improvement;
      default:
        return Icons.palette;
    }
  }

  Color _getThemeColor(String religion) {
    switch (religion) {
      case 'hinduism':
      case 'hindu':
        return ThemeService.hinduSaffronOrange;
      case 'islam':
      case 'muslim':
        return ThemeService.islamDarkGreen;
      case 'christianity':
      case 'christian':
        return ThemeService.christianDeepBlue;
      case 'jainism':
      case 'jain':
        return ThemeService.jainDeepRed;
      case 'buddhism':
      case 'buddhist':
        return ThemeService.buddhistMonkOrange;
      default:
        return ThemeService.defaultPrimary;
    }
  }

  String _getReligionDisplayName(String religion) {
    switch (religion) {
      case 'hinduism':
      case 'hindu':
        return 'Hindu';
      case 'islam':
      case 'muslim':
        return 'Islamic';
      case 'christianity':
      case 'christian':
        return 'Christian';
      case 'jainism':
      case 'jain':
        return 'Jain';
      case 'buddhism':
      case 'buddhist':
        return 'Buddhist';
      default:
        return 'Default';
    }
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
        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show loading indicator if stories are loading
            if (_isLoadingStories && _groupedStories.isEmpty)
              Container(
                height: 80,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading stories...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Always show stories list with add story button
              Container(
                height: 80,
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
                    storyType: firstStory.type, // Pass story type for video indicator
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

  Widget _buildInstagramStyleAddStoryButton() {
    return Container(
      width: 70,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Your Story Circle (Instagram style)
          GestureDetector(
            onTap: () {
              _navigateToStoryUpload();
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300], // Light gray background like Instagram
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Your Story Text
          Text(
            'Your story',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                    AppTheme.accentColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(screenWidth < 600 ? 2 : 3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Icon(
                  Icons.add,
                  color: AppTheme.primaryColor,
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
                color: AppTheme.textPrimary,
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
    // Find the index of the current post in the posts list
    final postIndex = _posts.indexWhere((p) => p.id == post.id);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostSliderScreen(
          posts: _posts,
          initialIndex: postIndex >= 0 ? postIndex : 0,
        ),
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
          isPrivate: post.isPrivate ?? false, // Use the actual privacy status from post
        ),
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_posts.isEmpty && !_isRefreshing && !_isLoadingPosts) {
      // Show message when no posts are available
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
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
            // Show loading indicator at the bottom (only when not refreshing) - Optimized
            if (_isLoadingPosts && _currentPostIndex < _maxPostsInMemory && !_isRefreshing) {
              return Container(
                padding: const EdgeInsets.all(12), // Reduced padding
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2, // Thinner for faster rendering
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final post = _posts[index];
          
          // Check if this is a reel and use video widget
          if (post.isReel && post.videoUrl != null && post.videoUrl!.isNotEmpty) {
            // Convert Post to BabaPageReel for video widget
            final reel = BabaPageReel(
              id: post.id,
              babaPageId: post.userId,
              title: (post.caption ?? '').split('\n').first, // First line as title
              description: post.caption ?? '',
              video: ReelVideo(
                url: post.videoUrl!,
                filename: '',
                size: 0,
                duration: 0,
                mimeType: 'video/mp4',
                publicId: '',
              ),
              thumbnail: ReelThumbnail(
                url: post.thumbnailUrl ?? post.imageUrl ?? '',
                filename: '',
                size: 0,
                mimeType: 'image/jpeg',
                publicId: '',
              ),
              category: 'reel',
              viewsCount: 0, // Post model doesn't have views property
              likesCount: post.likes,
              commentsCount: post.comments,
              sharesCount: post.shares,
              isActive: true,
              createdAt: post.createdAt,
              updatedAt: post.createdAt,
            );
            
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: _getResponsiveHorizontalPadding() * 0.5,
                vertical: _getResponsiveVerticalPadding(),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: SingleVideoWidget(
                reel: reel,
                autoplay: true, // Auto-play videos on home screen
                showFullDetails: true,
                onTap: () {
                  _openPostInFullView(post);
                },
              ),
            );
          }
          
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: _getResponsiveHorizontalPadding() * 0.5,
              vertical: _getResponsiveVerticalPadding(),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: EnhancedPostWidget(
              post: post,
              onLike: post.isBabaJiPost ? () {
                print('Liked Baba Ji post: ${post.id}');
              } : null,
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
        childCount: _posts.length + (_isLoadingPosts && _currentPostIndex < _maxPostsInMemory && !_isRefreshing ? 1 : 0),
      ),
    );
  }

  // Method to refresh feed when returning from discover users
  Future<void> _refreshFeedOnReturn() async {
    // Clear cache to ensure fresh data
    FeedService.clearCache();
    await _loadInitialPosts();
  }

  // Performance monitoring method (for debugging)
  Future<void> _testFeedPerformance() async {
    if (kDebugMode) {
      print('Testing feed refresh performance...');
      
      final results = await PerformanceTest.runFeedPerformanceTests(
        optimizedRefresh: _refreshFeed,
        standardRefresh: () async {
          // Simulate old refresh method
          await Future.wait([
            _loadStories(),
            _loadInitialPosts(),
          ]);
        },
      );
      
      PerformanceTest.printPerformanceReport(results);
    }
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          decoration: BoxDecoration(
            color: themeService.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.1),
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
                      builder: (context) => const ProfileUI(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? themeService.primaryColor : themeService.onSurfaceColor.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? themeService.primaryColor : themeService.onSurfaceColor.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      },
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
                
                // Immediately redirect to login page
                Navigator.pushReplacementNamed(context, '/login');
                
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
      ..color = AppTheme.primaryColor
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
      ..color = AppTheme.secondaryColor
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
      ..color = AppTheme.accentColor
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
      ..color = AppTheme.goldColor
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
      ..color = AppTheme.maroonColor
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
      ..color = AppTheme.crimsonColor
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
      ..color = AppTheme.primaryColor
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
      ..color = AppTheme.successColor
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
      ..color = AppTheme.goldColor
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

// Spiritual symbols painter for background overlay
class SpiritualSymbolsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw various spiritual symbols across the background
    _drawOm(canvas, size, paint);
    _drawCross(canvas, size, paint);
    _drawStarOfDavid(canvas, size, paint);
    _drawCrescent(canvas, size, paint);
    _drawLotus(canvas, size, paint);
    _drawPeaceSymbol(canvas, size, paint);
  }

  void _drawOm(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final center = Offset(size.width * 0.2, size.height * 0.3);
    final radius = 20.0;
    
    // Simplified Om symbol
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, paint);
  }

  void _drawCross(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.8, size.height * 0.2);
    final length = 30.0;
    
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - length),
      Offset(center.dx, center.dy + length),
      paint,
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - length, center.dy),
      Offset(center.dx + length, center.dy),
      paint,
    );
  }

  void _drawStarOfDavid(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.7, size.height * 0.6);
    final radius = 25.0;
    
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (3.14159 / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCrescent(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.3, size.height * 0.7);
    final radius = 20.0;
    
    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      0.5 * 3.14159,
      3.14159,
    );
    canvas.drawPath(path, paint);
  }

  void _drawLotus(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.5, size.height * 0.8);
    final radius = 15.0;
    
    // Draw lotus petals
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45.0) * (3.14159 / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      final petalPath = Path();
      petalPath.addOval(Rect.fromCircle(center: Offset(x, y), radius: 8));
      canvas.drawPath(petalPath, paint);
    }
  }

  void _drawPeaceSymbol(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.1, size.height * 0.5);
    final radius = 25.0;
    
    // Draw circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw peace symbol lines
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}