import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/baba_page_model.dart';
import '../models/baba_page_post_model.dart';
import '../models/baba_page_reel_model.dart';
import '../models/privacy_model.dart';
import 'baba_page_post_service.dart';
import 'baba_page_reel_service.dart';
import 'privacy_service.dart';
import 'custom_http_client.dart';

class FeedService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';
  
  // Enhanced cache for feed data with better performance
  static List<Post> _cachedFeedPosts = [];
  static DateTime? _lastFeedCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 10); // Increased cache duration
  
  // Cache for Baba Ji posts
  static List<Post> _cachedBabaJiPosts = [];
  static DateTime? _lastBabaJiCacheTime;
  
  // Request deduplication to prevent multiple identical requests
  static final Map<String, Future<List<Post>>> _activeRequests = {};
  
  // Following users cache to reduce API calls
  static List<String> _cachedFollowingUsers = [];
  static DateTime? _lastFollowingCacheTime;
  static const Duration _followingCacheExpiry = Duration(minutes: 15);

  /// Get social feed with privacy enforcement
  static Future<List<Post>> getSocialFeedWithPrivacy({
    required String token,
    required String currentUserId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('FeedService: Fetching social feed with privacy enforcement for user: $currentUserId');
      
      final response = await PrivacyService.getSocialFeedWithPrivacy(
        page: page,
        limit: limit,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> postsData = response['data']['posts'] ?? [];
        final List<Post> posts = [];

        for (final postData in postsData) {
          try {
            final post = Post.fromJson(postData);
            posts.add(post);
          } catch (e) {
            print('FeedService: Error parsing post: $e');
            continue;
          }
        }

        print('FeedService: Successfully fetched ${posts.length} social feed posts');
        return posts;
      } else {
        print('FeedService: Failed to fetch social feed: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('FeedService: Error fetching social feed: $e');
      return [];
    }
  }

  /// Get assets feed with privacy enforcement
  static Future<List<Post>> getAssetsFeedWithPrivacy({
    required String token,
    required String currentUserId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('FeedService: Fetching assets feed with privacy enforcement for user: $currentUserId');
      
      final response = await PrivacyService.getAssetsFeedWithPrivacy(
        page: page,
        limit: limit,
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> postsData = response['data']['posts'] ?? [];
        final List<Post> posts = [];

        for (final postData in postsData) {
          try {
            final post = Post.fromJson(postData);
            posts.add(post);
          } catch (e) {
            print('FeedService: Error parsing post: $e');
            continue;
          }
        }

        print('FeedService: Successfully fetched ${posts.length} assets feed posts');
        return posts;
      } else {
        print('FeedService: Failed to fetch assets feed: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('FeedService: Error fetching assets feed: $e');
      return [];
    }
  }

  /// Get feed posts ONLY from followed users (no random posts)
  static Future<List<Post>> getFeedPostsFromFollowedUsersOnly({
    required String token,
    required String currentUserId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('FeedService: Fetching posts ONLY from followed users for user: $currentUserId');
      
      // Always use the fallback method to ensure we only get posts from followed users
      final followedUserPosts = await _getFeedPostsFromFollowedUsers(token, currentUserId, page, limit);
      
      // STRICT FINAL VALIDATION: Double-check that all posts are from followed users only
      final followingUserIds = await _getCachedFollowingUsers(token, currentUserId);
      final strictlyFilteredPosts = followedUserPosts.where((post) {
        final isFromFollowedUser = followingUserIds.contains(post.userId);
        if (!isFromFollowedUser) {
          print('FeedService: STRICT FILTER - Removing post from unfollowed user: ${post.username} (${post.userId})');
        }
        return isFromFollowedUser;
      }).toList();
      
      print('FeedService: STRICT FILTER - Original posts: ${followedUserPosts.length}, After strict filtering: ${strictlyFilteredPosts.length}');
      print('FeedService: Following user IDs: $followingUserIds');
      
      return strictlyFilteredPosts;
      
    } catch (e) {
      print('FeedService: Error getting posts from followed users only: $e');
      return [];
    }
  }

  /// Get feed posts from followed users using the working Home Feed API
  static Future<List<Post>> getFeedPosts({
    required String token,
    required String currentUserId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('FeedService: Fetching home feed posts for user: $currentUserId (following only)');
      
      // Always use the fallback method to ensure we only get posts from followed users
      // This ensures we don't show random posts from users the current user doesn't follow
      final followedUserPosts = await _getFeedPostsFromFollowedUsers(token, currentUserId, page, limit);
      
      print('FeedService: Successfully fetched ${followedUserPosts.length} posts from followed users');
      return followedUserPosts;
      
    } catch (e) {
      print('FeedService: Error getting home feed: $e');
      // Return empty list if no posts found instead of dummy data
      return [];
    }
  }

  /// Optimized method to get posts from followed users with caching and parallel processing
  static Future<List<Post>> _getFeedPostsFromFollowedUsers(
    String token, 
    String currentUserId, 
    int page, 
    int limit
  ) async {
    try {
      print('FeedService: Optimized: Getting posts from followed users');
      
      // Get cached following users first
      List<String> followingUserIds = await _getCachedFollowingUsers(token, currentUserId);
      
      if (followingUserIds.isEmpty) {
        print('FeedService: Optimized: No following users found, returning empty list');
        return [];
      }
      
      // STRICT VALIDATION: Ensure we only process users that are actually followed
      print('FeedService: Strict validation - Processing posts from ${followingUserIds.length} followed users only');
      print('FeedService: Following user IDs: $followingUserIds');

      // Process posts from followed users in parallel batches for better performance
      final List<Post> allPosts = [];
      const int batchSize = 5; // Process 5 users at a time
      
      for (int i = 0; i < followingUserIds.length; i += batchSize) {
        final batch = followingUserIds.skip(i).take(batchSize).toList();
        
        // Process batch in parallel
        final batchFutures = batch.map((userId) => 
          _getUserPostsFromMediaAPI(userId, token)
        ).toList();
        
        try {
          final batchResults = await Future.wait(batchFutures);
          for (int j = 0; j < batchResults.length; j++) {
            final userPosts = batchResults[j];
            final userId = batch[j];
            
            // STRICT VALIDATION: Only add posts from users in our following list
            final validatedPosts = userPosts.where((post) => 
              post.userId == userId && // Ensure post belongs to the expected user
              followingUserIds.contains(post.userId) // Double-check user is in following list
            ).toList();
            
            print('FeedService: Validation for user $userId:');
            print('  - Total posts fetched: ${userPosts.length}');
            print('  - Posts after validation: ${validatedPosts.length}');
            print('  - Filtered out: ${userPosts.length - validatedPosts.length}');
            
            if (userPosts.isNotEmpty && validatedPosts.isEmpty) {
              print('FeedService: WARNING - All posts filtered out for user $userId!');
              print('FeedService: Sample post userId: ${userPosts.first.userId}');
              print('FeedService: Expected userId: $userId');
              print('FeedService: Following list contains userId: ${followingUserIds.contains(userId)}');
            }
            
            allPosts.addAll(validatedPosts);
            print('FeedService: Strict validation - Added ${validatedPosts.length} posts from user $userId');
          }
          print('FeedService: Optimized: Processed batch ${(i ~/ batchSize) + 1}, got ${batchResults.fold(0, (sum, posts) => sum + posts.length)} posts');
        } catch (e) {
          print('FeedService: Optimized: Error processing batch: $e');
          // Continue with next batch even if one fails
        }
      }

      // Sort all posts by creation date (newest first)
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedPosts = allPosts.sublist(
        startIndex < allPosts.length ? startIndex : 0,
        endIndex < allPosts.length ? endIndex : allPosts.length,
      );
      
      print('FeedService: Optimized: Successfully created feed with ${paginatedPosts.length} posts from ${followingUserIds.length} users');
      return paginatedPosts;
    } catch (e) {
      print('FeedService: Optimized: Error creating feed: $e');
      return [];
    }
  }
  
  /// Get following count for a user
  static Future<int> _getFollowingCount(String token, String currentUserId) async {
    try {
      final followingUserIds = await _getCachedFollowingUsers(token, currentUserId);
      return followingUserIds.length;
    } catch (e) {
      print('FeedService: Error getting following count: $e');
      return 0;
    }
  }

  /// Check if user is following Babji
  static Future<bool> _isUserFollowingBabji(String token, String currentUserId) async {
    try {
      print('FeedService: Checking if user $currentUserId is following Babji...');
      
      // Get Baba pages to check follow status
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/baba-pages?page=1&limit=50'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> babaPages = jsonResponse['data']['pages'] ?? [];
          
          // Check if user is following any Baba page
          for (final babaPage in babaPages) {
            final babaPageId = babaPage['_id'] ?? babaPage['id'];
            if (babaPageId != null) {
              // Check follow status for this Baba page
              final followResponse = await http.get(
                Uri.parse('http://103.14.120.163:8081/api/baba-pages/$babaPageId/follow-status/$currentUserId'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              );
              
              if (followResponse.statusCode == 200) {
                final followJson = jsonDecode(followResponse.body);
                if (followJson['success'] == true && followJson['data'] != null) {
                  final isFollowing = followJson['data']['isFollowing'] ?? false;
                  if (isFollowing) {
                    print('FeedService: User is following Babji page: ${babaPage['name'] ?? 'Baba Ji'} ($babaPageId)');
                    return true;
                  }
                }
              }
            }
          }
          
          print('FeedService: User is not following any Babji pages');
          return false;
        } else {
          print('FeedService: Failed to get Baba pages: ${jsonResponse['message']}');
          return false;
        }
      } else {
        print('FeedService: Failed to get Baba pages: HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('FeedService: Error checking Babji follow status: $e');
      return false;
    }
  }

  /// Get cached following users with fallback to API
  static Future<List<String>> _getCachedFollowingUsers(String token, String currentUserId) async {
    // Check cache first
    if (_isCacheValid(_lastFollowingCacheTime) && _cachedFollowingUsers.isNotEmpty) {
      print('FeedService: Using cached following users');
      return _cachedFollowingUsers;
    }
    
    try {
      // Fetch from API using optimized client
      final followingResponse = await CustomHttpClient.get(
        Uri.parse('http://103.14.120.163:8081/api/following/$currentUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (followingResponse.statusCode != 200) {
        print('FeedService: Failed to get following list: HTTP ${followingResponse.statusCode}');
        return [];
      }

      final followingJson = jsonDecode(followingResponse.body);
      if (followingJson['success'] != true) {
        print('FeedService: Failed to get following list: ${followingJson['message']}');
        return [];
      }

      final List<dynamic> followingUsers = followingJson['data']?['following'] ?? [];
      final List<String> userIds = followingUsers.map((user) => user['_id'] ?? user['id']).where((id) => id != null).cast<String>().toList();
      
      // Cache the result
      _cachedFollowingUsers = userIds;
      _lastFollowingCacheTime = DateTime.now();
      
      print('FeedService: Cached ${userIds.length} following users');
      return userIds;
    } catch (e) {
      print('FeedService: Error getting following users: $e');
      return [];
    }
  }

  /// Get posts from a specific user using the working media API
  static Future<List<Post>> _getUserPostsFromMediaAPI(String userId, String token) async {
    try {
      print('FeedService: Fetching posts for user: $userId');
      final response = await CustomHttpClient.get(
        Uri.parse('http://103.14.120.163:8081/api/media/upload?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('FeedService: Media API response for user $userId: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> mediaData = jsonResponse['data']['media'] ?? [];
          print('FeedService: Found ${mediaData.length} media items for user $userId');
          final List<Post> posts = [];

          for (final media in mediaData) {
            // Only include posts (not stories)
            if (media['title']?.toLowerCase().contains('story') != true) {
              try {
                final post = Post(
                  id: media['_id'] ?? media['id'] ?? '',
                  userId: media['uploadedBy']?['_id'] ?? media['userId'] ?? userId,
                  username: media['uploadedBy']?['username'] ?? media['username'] ?? 'Unknown User',
                  userAvatar: media['uploadedBy']?['avatar'] ?? media['userAvatar'] ?? '',
                  caption: media['title'] ?? media['caption'] ?? 'A post by ${media['uploadedBy']?['username'] ?? 'Unknown User'}',
                  imageUrl: media['resourceType'] == 'video' ? null : (media['secureUrl'] ?? media['imageUrl'] ?? (media['publicUrl'] != null ? 'http://103.14.120.163:8081${media['publicUrl']}' : null)),
                  videoUrl: media['resourceType'] == 'video' ? (media['secureUrl'] ?? media['videoUrl'] ?? (media['publicUrl'] != null ? 'http://103.14.120.163:8081${media['publicUrl']}' : null)) : null,
                  type: _parsePostType(media['resourceType'] ?? 'image'),
                  likes: media['likes'] ?? 0,
                  comments: media['comments'] ?? 0,
                  shares: media['shares'] ?? 0,
                  isLiked: media['isLiked'] ?? false,
                  createdAt: media['createdAt'] != null 
                      ? DateTime.parse(media['createdAt']) 
                      : DateTime.now(),
                  hashtags: List<String>.from(media['tags'] ?? []),
                  thumbnailUrl: media['resourceType'] == 'video' ? (media['thumbnailUrl'] ?? media['secureUrl'] ?? (media['publicUrl'] != null ? 'http://103.14.120.163:8081${media['publicUrl']}' : null)) : null,
                );
                posts.add(post);
                print('FeedService: Created media post: ${post.id} by ${post.username} (${post.userId})');
                print('FeedService: Media data: ${media['_id']} - ${media['title']}');
                print('FeedService: Post type: ${post.type}, isReel: ${post.isReel}, videoUrl: ${post.videoUrl}');
              } catch (e) {
                print('FeedService: Fallback: Error creating post from media: $e');
              }
            }
          }

          print('FeedService: Successfully fetched ${posts.length} posts for user $userId');
          print('FeedService: Posts for user $userId: ${posts.map((p) => '${p.id}(${p.type})').join(', ')}');
          return posts;
        }
      }
      
      return [];
    } catch (e) {
      print('FeedService: Fallback: Error getting posts from user $userId: $e');
      return [];
    }
  }

  /// Parse post type from API response
  static PostType _parsePostType(String type) {
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

  /// Get Baba Ji posts for the feed
  static Future<List<Post>> getBabaJiPosts({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('FeedService: Fetching Baba Ji posts for feed');
      
      // Get all Baba Ji pages first
      final babaPagesResponse = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/baba-pages?page=1&limit=50'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (babaPagesResponse.statusCode != 200) {
        print('FeedService: Failed to get Baba Ji pages: ${babaPagesResponse.statusCode}');
        return [];
      }

      final babaPagesJson = jsonDecode(babaPagesResponse.body);
      if (babaPagesJson['success'] != true) {
        print('FeedService: Failed to get Baba Ji pages: ${babaPagesJson['message']}');
        return [];
      }

      final List<dynamic> babaPages = babaPagesJson['data']['pages'] ?? [];
      print('FeedService: Found ${babaPages.length} Baba Ji pages');

      final List<Post> allBabaPosts = [];

      // Get posts from each Baba Ji page
      for (final babaPage in babaPages) {
        final babaPageId = babaPage['_id'] ?? babaPage['id'];
        if (babaPageId != null) {
          try {
            final postsResponse = await BabaPagePostService.getBabaPagePosts(
              babaPageId: babaPageId,
              token: token,
              page: 1,
              limit: 50, // Increased limit to fetch more posts
            );

            if (postsResponse.success) {
              for (final babaPost in postsResponse.posts) {
                // Convert Baba Ji post to regular Post for feed
                final imageUrls = babaPost.media.map((media) => media.url).toList();
                
                // Debug: Log Baba Ji avatar data
                final babaAvatarUrl = babaPage['avatar'] ?? '';
                print('FeedService: Baba Ji avatar for ${babaPage['name'] ?? 'Baba Ji'}: $babaAvatarUrl');
                print('FeedService: Full Baba Ji page data: $babaPage');
                
                final post = Post(
                  id: 'baba_${babaPost.id}',
                  userId: babaPost.babaPageId,
                  username: babaPage['name'] ?? 'Baba Ji',
                  userAvatar: babaAvatarUrl,
                  caption: babaPost.content,
                  imageUrl: babaPost.media.isNotEmpty ? babaPost.media.first.url : null,
                  imageUrls: imageUrls, // Pass all image URLs
                  videoUrl: null,
                  type: PostType.image,
                  likes: babaPost.likesCount,
                  comments: babaPost.commentsCount,
                  shares: babaPost.sharesCount,
                  isLiked: false,
                  createdAt: babaPost.createdAt,
                  hashtags: [],
                  thumbnailUrl: null,
                  isBabaJiPost: true, // Mark as Baba Ji post
                  babaPageId: babaPost.babaPageId,
                );
                allBabaPosts.add(post);
              }
            }
          } catch (e) {
            print('FeedService: Error getting posts from Baba Ji page $babaPageId: $e');
          }
        }
      }

      // Get reels from each Baba Ji page
      final List<Post> allBabaReels = [];
      
      for (final babaPage in babaPages) {
        final babaPageId = babaPage['_id'] ?? babaPage['id'];
        if (babaPageId != null) {
          try {
            final reelsResponse = await BabaPageReelService.getBabaPageReels(
              babaPageId: babaPageId,
              token: token,
              page: 1,
              limit: 50, // Increased limit to fetch more reels
            );

            if (reelsResponse['success'] == true) {
              final reelsData = reelsResponse['data']['videos'] as List<dynamic>;
              for (final reelData in reelsData) {
                final reel = BabaPageReel.fromJson(reelData);
                // Convert Baba Ji reel to regular Post for feed
                final babaPageObj = BabaPage.fromJson(babaPage);
                
                // Debug: Log Baba Ji reel avatar data
                final babaReelAvatarUrl = babaPage['avatar'] ?? '';
                print('FeedService: Baba Ji reel avatar for ${babaPage['name'] ?? 'Baba Ji'}: $babaReelAvatarUrl');
                
                final post = Post(
                  id: 'baba_reel_${reel.id}',
                  userId: reel.babaPageId,
                  username: '${babaPage['name'] ?? 'Baba Ji'} (ID: ${reel.babaPageId})',
                  userAvatar: babaReelAvatarUrl,
                  caption: '${reel.title}\n\n${reel.description}',
                  imageUrl: reel.thumbnail.url,
                  videoUrl: reel.video.url,
                  type: PostType.video,
                  likes: reel.likesCount,
                  comments: reel.commentsCount,
                  shares: reel.sharesCount,
                  isLiked: false,
                  createdAt: reel.createdAt,
                  hashtags: [],
                  thumbnailUrl: reel.thumbnail.url,
                  isBabaJiPost: true, // Mark as Baba Ji post
                  isReel: true, // Mark as reel
                  babaPageId: reel.babaPageId,
                  babaPageData: babaPageObj, // Store complete Baba Ji page data
                );
                allBabaReels.add(post);
              }
            }
          } catch (e) {
            print('FeedService: Error getting reels from Baba Ji page $babaPageId: $e');
          }
        }
      }

      // Combine posts and reels
      final List<Post> allBabaContent = [...allBabaPosts, ...allBabaReels];
      
      // Sort by creation date (newest first)
      allBabaContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('FeedService: Found ${allBabaPosts.length} Baba Ji posts and ${allBabaReels.length} Baba Ji reels');
      return allBabaContent;
    } catch (e) {
      print('FeedService: Error getting Baba Ji posts: $e');
      return [];
    }
  }

  /// Get mixed feed content (posts and reels) from followed users and Baba Ji only - Ultra-optimized with caching
  /// STRICT FILTERING: Only shows posts from users you follow + Baba Ji posts (only if following Babji). No random posts allowed.
  static Future<List<Post>> getMixedFeed({
    required String token,
    required String currentUserId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('FeedService: Fetching mixed feed content for user: $currentUserId (following + Baba Ji only if following)');
      
      // Create request key for deduplication
      final requestKey = 'mixed_feed_${currentUserId}_${page}_${limit}';
      
      // Check if same request is already in progress
      if (_activeRequests.containsKey(requestKey)) {
        print('FeedService: Request already in progress, waiting for result');
        return await _activeRequests[requestKey]!;
      }
      
      // Check cache first for faster loading
      if (_isCacheValid(_lastFeedCacheTime)) {
        print('FeedService: Using cached feed data');
        return _getCachedFeedPosts(page, limit);
      }
      
      // Create future for this request
      final future = _loadMixedFeedData(token, currentUserId, page, limit);
      _activeRequests[requestKey] = future;
      
      try {
        final result = await future;
        _activeRequests.remove(requestKey);
        return result;
      } catch (e) {
        _activeRequests.remove(requestKey);
        rethrow;
      }
    } catch (e) {
      print('FeedService: Error creating mixed feed: $e');
      // Return cached data if available, even if expired
      if (_cachedFeedPosts.isNotEmpty) {
        print('FeedService: Returning cached data due to error');
        return _getCachedFeedPosts(page, limit);
      }
      return [];
    }
  }
  
  /// Internal method to load mixed feed data with optimized parallel processing
  static Future<List<Post>> _loadMixedFeedData(
    String token,
    String currentUserId,
    int page,
    int limit,
  ) async {
    // First check if user follows anyone
    final followingCount = await _getFollowingCount(token, currentUserId);
    
    // If user doesn't follow anyone, return empty feed
    if (followingCount == 0) {
      print('FeedService: User follows no one, returning empty feed - new users should follow people to see content');
      clearCache();
      return [];
    }
    
    print('FeedService: User follows $followingCount users, loading feed content');
    
    // Check if user is following Babji before loading Babji posts
    final isFollowingBabji = await _isUserFollowingBabji(token, currentUserId);
    print('FeedService: User is following Babji: $isFollowingBabji');
    
    // Prepare futures list
    final futures = <Future<List<Post>>>[];
    
    // Always load posts from followed users
    futures.add(getFeedPostsFromFollowedUsersOnly(
      token: token,
      currentUserId: currentUserId,
      page: page,
      limit: isFollowingBabji ? limit ~/ 2 : limit, // Adjust limit based on Babji follow status
    ));
    
    // Only load Babji posts if user is following Babji
    if (isFollowingBabji) {
      futures.add(getBabaJiPostsOptimized(
        token: token,
        page: page,
        limit: limit ~/ 2, // Half for Baba Ji posts
      ));
    } else {
      print('FeedService: User is not following Babji, skipping Babji posts');
      futures.add(Future.value(<Post>[])); // Empty list for Babji posts
    }
    
    // Wait for all futures to complete
    final results = await Future.wait(futures);
    final followedUserPosts = results[0] as List<Post>;
    final babaJiPosts = results.length > 1 ? results[1] as List<Post> : <Post>[];

    // STRICT FILTERING: Only include posts from followed users (but not videos)
    // Double-check that these are NOT Baba Ji posts and are from followed users only
    final filteredFollowedUserPosts = followedUserPosts.where((post) => 
      post.type != PostType.video && 
      post.isReel != true && 
      post.videoUrl == null &&
      !post.isBabaJiPost && // Ensure these are not Baba Ji posts
      post.userId != null && // Ensure user ID exists
      post.userId!.isNotEmpty // Ensure user ID is not empty
    ).toList();
    
    // Include both image posts and reels from Babji (but not videos)
    final filteredBabaJiPosts = babaJiPosts.where((post) => 
      post.type != PostType.video && 
      post.isReel != true && 
      post.videoUrl == null &&
      post.isBabaJiPost == true // Ensure these are Baba Ji posts
    ).toList();

    // STRICT FINAL VALIDATION: Combine and sort all posts (prioritize Babji posts, then followed users)
    final List<Post> allPosts = [...filteredBabaJiPosts, ...filteredFollowedUserPosts];
    
    // Final validation to ensure no unauthorized posts slip through
    final validatedPosts = allPosts.where((post) {
      if (post.isBabaJiPost == true) {
        // Baba Ji posts are always allowed
        return true;
      } else {
        // For user posts, ensure they are from followed users only
        return !post.isBabaJiPost && post.userId != null && post.userId!.isNotEmpty;
      }
    }).toList();
    
    validatedPosts.sort((a, b) {
      // Prioritize Babji posts first, then sort by creation date
      if (a.isBabaJiPost && !b.isBabaJiPost) return -1;
      if (!a.isBabaJiPost && b.isBabaJiPost) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    // Cache the results
    _cachedFeedPosts = validatedPosts;
    _lastFeedCacheTime = DateTime.now();

    // Apply final pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    final paginatedPosts = validatedPosts.sublist(
      startIndex < validatedPosts.length ? startIndex : 0,
      endIndex < validatedPosts.length ? endIndex : validatedPosts.length,
    );

    print('FeedService: STRICT FILTERING - Mixed feed created with ${paginatedPosts.length} items (${filteredBabaJiPosts.length} Babji posts ${isFollowingBabji ? 'shown (user follows Babji)' : 'hidden (user not following Babji)'}, ${filteredFollowedUserPosts.length} followed user posts - videos filtered out)');
    
    // Debug: Log details of Babji posts
    if (filteredBabaJiPosts.isNotEmpty) {
      print('FeedService: Babji posts in feed:');
      for (final post in filteredBabaJiPosts) {
        print('  - Babji Post: ${post.id} by ${post.username}');
        print('    Caption: ${post.caption}');
        print('    Created: ${post.createdAt}');
      }
    } else {
      if (isFollowingBabji) {
        print('FeedService: WARNING - No Babji posts found in feed despite following Babji!');
      } else {
        print('FeedService: No Babji posts shown - user is not following Babji');
      }
    }
    
    return paginatedPosts;
  }

  /// Check if cache is still valid
  static bool _isCacheValid(DateTime? cacheTime) {
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }

  /// Get cached feed posts with pagination
  static List<Post> _getCachedFeedPosts(int page, int limit) {
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    return _cachedFeedPosts.sublist(
      startIndex < _cachedFeedPosts.length ? startIndex : 0,
      endIndex < _cachedFeedPosts.length ? endIndex : _cachedFeedPosts.length,
    );
  }

  /// Clear cache (call when user posts new content)
  static void clearCache() {
    _cachedFeedPosts.clear();
    _cachedBabaJiPosts.clear();
    _cachedFollowingUsers.clear();
    _lastFeedCacheTime = null;
    _lastBabaJiCacheTime = null;
    _lastFollowingCacheTime = null;
    _activeRequests.clear(); // Clear active requests
    print('FeedService: All caches cleared');
  }

  /// Clear only following users cache (useful for debugging following issues)
  static void clearFollowingCache() {
    _cachedFollowingUsers.clear();
    _lastFollowingCacheTime = null;
    print('FeedService: Following users cache cleared');
  }

  /// Force refresh following users list (useful when follow status changes)
  static Future<List<String>> forceRefreshFollowingUsers(String token, String currentUserId) async {
    print('FeedService: Force refreshing following users list...');
    clearFollowingCache();
    return await _getCachedFollowingUsers(token, currentUserId);
  }

  /// Ultra-optimized Baba Ji posts loading with enhanced caching and parallel processing
  static Future<List<Post>> getBabaJiPostsOptimized({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('FeedService: Fetching Baba Ji posts (ultra-optimized)');
      
      // Check cache first
      if (_isCacheValid(_lastBabaJiCacheTime) && _cachedBabaJiPosts.isNotEmpty) {
        print('FeedService: Using cached Baba Ji posts');
        return _getCachedBabaJiPosts(page, limit);
      }
      
      // Get limited Baba Ji pages for faster loading using optimized client
      final babaPagesResponse = await CustomHttpClient.get(
        Uri.parse('http://103.14.120.163:8081/api/baba-pages?page=1&limit=3'), // Further reduced for speed
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (babaPagesResponse.statusCode != 200) {
        print('FeedService: Failed to get Baba Ji pages: ${babaPagesResponse.statusCode}');
        return [];
      }

      final babaPagesJson = jsonDecode(babaPagesResponse.body);
      if (babaPagesJson['success'] != true) {
        print('FeedService: Failed to get Baba Ji pages: ${babaPagesJson['message']}');
        return [];
      }

      final List<dynamic> babaPages = babaPagesJson['data']['pages'] ?? [];
      print('FeedService: Found ${babaPages.length} Baba Ji pages');

      // Process posts and reels in parallel for maximum speed
      final futures = await Future.wait([
        _loadBabaJiPosts(babaPages, token),
        _loadBabaJiReels(babaPages, token),
      ]);

      final allBabaPosts = futures[0] as List<Post>;
      final allBabaReels = futures[1] as List<Post>;

      // Combine posts and reels
      final List<Post> allBabaContent = [...allBabaPosts, ...allBabaReels];

      // Sort by creation date (newest first)
      allBabaContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Cache the results
      _cachedBabaJiPosts = allBabaContent;
      _lastBabaJiCacheTime = DateTime.now();

      print('FeedService: Found ${allBabaPosts.length} Baba Ji posts and ${allBabaReels.length} Baba Ji reels (ultra-optimized)');
      
      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedPosts = allBabaContent.sublist(
        startIndex < allBabaContent.length ? startIndex : 0,
        endIndex < allBabaContent.length ? endIndex : allBabaContent.length,
      );
      
      return paginatedPosts;
    } catch (e) {
      print('FeedService: Error getting Baba Ji posts (ultra-optimized): $e');
      // Return cached data if available
      if (_cachedBabaJiPosts.isNotEmpty) {
        print('FeedService: Returning cached Baba Ji data due to error');
        return _getCachedBabaJiPosts(page, limit);
      }
      return [];
    }
  }
  
  /// Load Baba Ji posts in parallel
  static Future<List<Post>> _loadBabaJiPosts(List<dynamic> babaPages, String token) async {
    final postFutures = babaPages.map((babaPage) async {
      final babaPageId = babaPage['_id'] ?? babaPage['id'];
      if (babaPageId != null) {
        try {
          final postsResponse = await BabaPagePostService.getBabaPagePosts(
            babaPageId: babaPageId,
            token: token,
            page: 1,
            limit: 2, // Further reduced for speed
          );

          if (postsResponse.success) {
            final List<Post> posts = [];
            for (final babaPost in postsResponse.posts) {
              final imageUrls = babaPost.media.map((media) => media.url).toList();
              final post = Post(
                id: 'baba_${babaPost.id}',
                userId: babaPost.babaPageId,
                username: babaPage['name'] ?? 'Baba Ji',
                userAvatar: babaPage['avatar'] ?? '',
                caption: babaPost.content,
                imageUrl: babaPost.media.isNotEmpty ? babaPost.media.first.url : null,
                imageUrls: imageUrls,
                videoUrl: null,
                type: PostType.image,
                likes: babaPost.likesCount,
                comments: babaPost.commentsCount,
                shares: babaPost.sharesCount,
                isLiked: false,
                createdAt: babaPost.createdAt,
                hashtags: [],
                thumbnailUrl: null,
                isBabaJiPost: true,
                babaPageId: babaPost.babaPageId,
              );
              posts.add(post);
            }
            return posts;
          }
        } catch (e) {
          print('FeedService: Error getting posts from Baba Ji page $babaPageId: $e');
        }
      }
      return <Post>[];
    });

    final postResults = await Future.wait(postFutures);
    final List<Post> allPosts = [];
    for (final posts in postResults) {
      allPosts.addAll(posts);
    }
    return allPosts;
  }
  
  /// Load Baba Ji reels in parallel
  static Future<List<Post>> _loadBabaJiReels(List<dynamic> babaPages, String token) async {
    final reelFutures = babaPages.map((babaPage) async {
      final babaPageId = babaPage['_id'] ?? babaPage['id'];
      if (babaPageId != null) {
        try {
          final reelsResponse = await BabaPageReelService.getBabaPageReels(
            babaPageId: babaPageId,
            token: token,
            page: 1,
            limit: 2, // Further reduced for speed
          );

          if (reelsResponse['success'] == true) {
            final List<Post> reels = [];
            final reelsData = reelsResponse['data']['videos'] as List<dynamic>;
            for (final reelData in reelsData) {
              final reel = BabaPageReel.fromJson(reelData);
              final babaPageObj = BabaPage.fromJson(babaPage);
              final post = Post(
                id: 'baba_reel_${reel.id}',
                userId: reel.babaPageId,
                username: '${babaPage['name'] ?? 'Baba Ji'} (ID: ${reel.babaPageId})',
                userAvatar: babaPage['avatar'] ?? '',
                caption: '${reel.title}\n\n${reel.description}',
                imageUrl: reel.thumbnail.url,
                videoUrl: reel.video.url,
                type: PostType.video,
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
                babaPageData: babaPageObj,
              );
              reels.add(post);
            }
            return reels;
          }
        } catch (e) {
          print('FeedService: Error getting reels from Baba Ji page $babaPageId: $e');
        }
      }
      return <Post>[];
    });

    final reelResults = await Future.wait(reelFutures);
    final List<Post> allReels = [];
    for (final reels in reelResults) {
      allReels.addAll(reels);
    }
    return allReels;
  }
  
  /// Get cached Baba Ji posts with pagination
  static List<Post> _getCachedBabaJiPosts(int page, int limit) {
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    return _cachedBabaJiPosts.sublist(
      startIndex < _cachedBabaJiPosts.length ? startIndex : 0,
      endIndex < _cachedBabaJiPosts.length ? endIndex : _cachedBabaJiPosts.length,
    );
  }

  /// Debug helper to specifically check Swayam's posts
  static Future<void> debugSwayamPosts(String token, String currentUserId) async {
    try {
      print('FeedService.debugSwayamPosts: Starting Swayam-specific debugging');
      
      // 1. Check if Swayam is in following list
      final followingUserIds = await _getCachedFollowingUsers(token, currentUserId);
      print('FeedService.debugSwayamPosts: Following users: $followingUserIds');
      
      // Look for Swayam's user ID (could be different formats)
      final swayamIds = followingUserIds.where((id) => 
        id.toLowerCase().contains('swayam') || 
        id.contains('swayam')
      ).toList();
      
      if (swayamIds.isNotEmpty) {
        print('FeedService.debugSwayamPosts: Found Swayam IDs: $swayamIds');
        
        // 2. Try to fetch Swayam's posts directly
        for (final swayamId in swayamIds) {
          print('FeedService.debugSwayamPosts: Fetching posts for Swayam ID: $swayamId');
          final swayamPosts = await _getUserPostsFromMediaAPI(swayamId, token);
          print('FeedService.debugSwayamPosts: Swayam posts count: ${swayamPosts.length}');
          
          for (final post in swayamPosts) {
            print('FeedService.debugSwayamPosts: Swayam post: ${post.id} - ${post.caption}');
            print('FeedService.debugSwayamPosts: Post type: ${post.type}, isReel: ${post.isReel}, videoUrl: ${post.videoUrl}');
          }
        }
      } else {
        print('FeedService.debugSwayamPosts: WARNING - No Swayam user ID found in following list!');
        print('FeedService.debugSwayamPosts: This might be why Swayam posts are not showing');
      }
      
      print('FeedService.debugSwayamPosts: Swayam debugging complete');
    } catch (e) {
      print('FeedService.debugSwayamPosts: Error: $e');
    }
  }

  /// Debug helper to check following status and filter posts
  static Future<void> debugFollowingAndPosts(String token, String currentUserId) async {
    try {
      print('FeedService.debugFollowingAndPosts: Starting diagnostics for user: $currentUserId');
      
      // 1) Get following list
      final followingUserIds = await _getCachedFollowingUsers(token, currentUserId);
      print('FeedService.debugFollowingAndPosts: Following ${followingUserIds.length} users: $followingUserIds');
      
      // 2) Get all posts from followed users
      final allPosts = await _getFeedPostsFromFollowedUsers(token, currentUserId, 1, 50);
      print('FeedService.debugFollowingAndPosts: Found ${allPosts.length} total posts from followed users');
      
      // 3) Check each post's user ID
      for (final post in allPosts) {
        final isFromFollowedUser = followingUserIds.contains(post.userId);
        print('FeedService.debugFollowingAndPosts: Post by ${post.username} (${post.userId}) - From followed user: $isFromFollowedUser');
        if (!isFromFollowedUser) {
          print('FeedService.debugFollowingAndPosts: WARNING - Post from unfollowed user detected!');
        }
      }
      
      // 4) Apply strict filtering
      final filteredPosts = allPosts.where((post) => followingUserIds.contains(post.userId)).toList();
      print('FeedService.debugFollowingAndPosts: After strict filtering: ${filteredPosts.length} posts');
      
      print('FeedService.debugFollowingAndPosts: Diagnostics complete');
    } catch (e) {
      print('FeedService.debugFollowingAndPosts: Error: $e');
    }
  }

  /// Debug helper to investigate why the feed might be empty
  /// Does not alter app state; only logs details to the console
  static Future<void> debugFeedLoading(String token, String currentUserId) async {
    try {
      print('FeedService.debugFeedLoading: starting diagnostics for user: ' + currentUserId);

      // 1) Check following list size (prerequisite for feed)
      try {
        final followingResponse = await http.get(
          Uri.parse('http://103.14.120.163:8081/api/following/' + currentUserId),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token,
          },
        );
        print('FeedService.debugFeedLoading: following status: ' + followingResponse.statusCode.toString());
        if (followingResponse.body.isNotEmpty) {
          print('FeedService.debugFeedLoading: following body (truncated 500): ' + followingResponse.body.substring(0, followingResponse.body.length > 500 ? 500 : followingResponse.body.length));
        }
      } catch (e) {
        print('FeedService.debugFeedLoading: error fetching following: ' + e.toString());
      }

      // 2) Attempt to get posts from followed users only
      try {
        final followedPosts = await getFeedPostsFromFollowedUsersOnly(
          token: token,
          currentUserId: currentUserId,
          page: 1,
          limit: 10,
        );
        print('FeedService.debugFeedLoading: followed user posts count: ' + followedPosts.length.toString());
        for (final p in followedPosts.take(5)) {
          print('  - Followed Post: ' + p.id + ' by ' + p.username + ' at ' + p.createdAt.toIso8601String());
        }
      } catch (e) {
        print('FeedService.debugFeedLoading: error loading followed posts: ' + e.toString());
      }

      // 3) Attempt to get optimized Baba Ji posts
      try {
        final babaPosts = await getBabaJiPostsOptimized(
          token: token,
          page: 1,
          limit: 10,
        );
        print('FeedService.debugFeedLoading: Baba Ji items count (posts + reels): ' + babaPosts.length.toString());
        for (final p in babaPosts.take(5)) {
          print('  - Baba Item: ' + p.id + ' by ' + p.username + (p.isReel == true ? ' [REEL]' : ''));
        }
      } catch (e) {
        print('FeedService.debugFeedLoading: error loading Baba Ji posts: ' + e.toString());
      }

      // 4) Try mixed feed path for completeness (uses cache logic)
      try {
        final mixed = await getMixedFeed(
          token: token,
          currentUserId: currentUserId,
          page: 1,
          limit: 10,
        );
        print('FeedService.debugFeedLoading: mixed feed count: ' + mixed.length.toString());
      } catch (e) {
        print('FeedService.debugFeedLoading: error loading mixed feed: ' + e.toString());
      }

      // 5) Specific Swayam debugging
      await debugSwayamPosts(token, currentUserId);

      print('FeedService.debugFeedLoading: diagnostics complete');
    } catch (e) {
      print('FeedService.debugFeedLoading: unexpected error: ' + e.toString());
    }
  }
}