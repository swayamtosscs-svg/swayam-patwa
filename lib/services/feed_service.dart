import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/baba_page_post_model.dart';
import '../models/baba_page_reel_model.dart';
import 'baba_page_post_service.dart';
import 'baba_page_reel_service.dart';

class FeedService {
  static const String _baseUrl = 'https://api-rgram1.vercel.app/api';

  /// Get feed posts from followed users using the working Home Feed API
  static Future<List<Post>> getFeedPosts({
    required String token,
    required String currentUserId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('FeedService: Fetching home feed posts for user: $currentUserId');
      
      // Try the Home Feed API first
      final response = await http.get(
        Uri.parse('https://api-rgram1.vercel.app/api/feed/home?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Token with Bearer prefix
        },
      );

      print('FeedService: API Response Status: ${response.statusCode}');
      print('FeedService: API Response Headers: ${response.headers}');
      print('FeedService: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> postsData = jsonResponse['data']['posts'] ?? [];
          final List<Post> posts = [];

          for (final postData in postsData) {
            try {
              final username = postData['author']?['username'] ?? 'Unknown User';
              
              // Filter out demo posts
              if (username == 'dfg' || username == 'demo' || username == 'test') {
                print('FeedService: Skipping demo post from user: $username');
                continue;
              }
              
              final post = Post(
                id: postData['_id'] ?? '',
                userId: postData['author']?['_id'] ?? '',
                username: username,
                userAvatar: postData['author']?['avatar'] ?? '',
                caption: postData['content'] ?? '',
                imageUrl: postData['images']?.isNotEmpty == true ? postData['images'][0] : null,
                videoUrl: null, // This API doesn't seem to have video support yet
                type: PostType.image, // Default to image for now
                likes: postData['likesCount'] ?? 0,
                comments: postData['commentsCount'] ?? 0,
                shares: postData['sharesCount'] ?? 0,
                isLiked: (postData['likes'] as List?)?.contains(currentUserId) ?? false,
                createdAt: postData['createdAt'] != null 
                    ? DateTime.parse(postData['createdAt']) 
                    : DateTime.now(),
                hashtags: [], // This API doesn't seem to have hashtags
                thumbnailUrl: null,
              );
              posts.add(post);
              print('FeedService: Created post: ${post.id} by ${post.username}');
            } catch (e) {
              print('FeedService: Error creating post from data: $e');
              print('FeedService: Post data: $postData');
            }
          }

          if (posts.isNotEmpty) {
            print('FeedService: Successfully created ${posts.length} posts from home feed');
            return posts;
          }
        }
      }
      
      // If Home Feed API fails or returns no posts, try fallback
      print('FeedService: Home Feed API failed or returned no posts, trying fallback approach');
      final fallbackPosts = await _getFeedPostsFromFollowedUsers(token, currentUserId, page, limit);
      
      // Return empty list if no posts found instead of dummy data
      return fallbackPosts;
      
    } catch (e) {
      print('FeedService: Error getting home feed: $e');
      // Fallback to getting posts from followed users
      print('FeedService: Trying fallback approach due to error');
      final fallbackPosts = await _getFeedPostsFromFollowedUsers(token, currentUserId, page, limit);
      
      // Return empty list if no posts found instead of dummy data
      return fallbackPosts;
    }
  }

  /// Fallback method to get posts from followed users using existing working APIs
  static Future<List<Post>> _getFeedPostsFromFollowedUsers(
    String token, 
    String currentUserId, 
    int page, 
    int limit
  ) async {
    try {
      print('FeedService: Fallback: Getting posts from followed users');
      
      // First, get the list of users that the current user is following
      final followingResponse = await http.get(
        Uri.parse('https://api-rgram1.vercel.app/api/following/$currentUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('FeedService: Following API Response Status: ${followingResponse.statusCode}');
      print('FeedService: Following API Response Body: ${followingResponse.body}');

      if (followingResponse.statusCode != 200) {
        print('FeedService: Fallback: Failed to get following list: HTTP ${followingResponse.statusCode}');
        // Return empty list if we can't get following list
        return [];
      }

      final followingJson = jsonDecode(followingResponse.body);
      if (followingJson['success'] != true) {
        print('FeedService: Fallback: Failed to get following list: ${followingJson['message']}');
        // Return empty list if we can't get following list
        return [];
      }

      final List<dynamic> followingUsers = followingJson['data']?['following'] ?? [];
      print('FeedService: Fallback: Found ${followingUsers.length} following users');

      if (followingUsers.isEmpty) {
        print('FeedService: Fallback: No following users found, returning empty list');
        return [];
      }

      // Get posts from each followed user
      final List<Post> allPosts = [];
      
      for (final user in followingUsers) {
        final userId = user['_id'] ?? user['id'];
        if (userId != null) {
          try {
            // Get posts from this followed user using the working user media API
            final userPosts = await _getUserPostsFromMediaAPI(userId, token);
            allPosts.addAll(userPosts);
            print('FeedService: Fallback: Got ${userPosts.length} posts from user $userId');
          } catch (e) {
            print('FeedService: Fallback: Error getting posts from user $userId: $e');
          }
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
      
      print('FeedService: Fallback: Successfully created feed with ${paginatedPosts.length} posts');
      return paginatedPosts;
    } catch (e) {
      print('FeedService: Fallback: Error creating feed: $e');
      // Return empty list on error - only show posts from followed users
      return [];
    }
  }

  /// Get posts from a specific user using the working media API
  static Future<List<Post>> _getUserPostsFromMediaAPI(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://api-rgram1.vercel.app/api/media/upload?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> mediaData = jsonResponse['data']['media'] ?? [];
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
                  imageUrl: media['resourceType'] == 'video' ? null : (media['secureUrl'] ?? media['imageUrl']),
                  videoUrl: media['resourceType'] == 'video' ? (media['secureUrl'] ?? media['videoUrl']) : null,
                  type: _parsePostType(media['resourceType'] ?? 'image'),
                  likes: media['likes'] ?? 0,
                  comments: media['comments'] ?? 0,
                  shares: media['shares'] ?? 0,
                  isLiked: media['isLiked'] ?? false,
                  createdAt: media['createdAt'] != null 
                      ? DateTime.parse(media['createdAt']) 
                      : DateTime.now(),
                  hashtags: List<String>.from(media['tags'] ?? []),
                  thumbnailUrl: media['resourceType'] == 'video' ? (media['thumbnailUrl'] ?? media['secureUrl']) : null,
                );
                posts.add(post);
              } catch (e) {
                print('FeedService: Fallback: Error creating post from media: $e');
              }
            }
          }

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
        Uri.parse('https://api-rgram1.vercel.app/api/baba-pages?page=1&limit=50'),
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
              limit: 10,
            );

            if (postsResponse.success) {
              for (final babaPost in postsResponse.posts) {
                // Convert Baba Ji post to regular Post for feed
                final post = Post(
                  id: 'baba_${babaPost.id}',
                  userId: babaPost.babaPageId,
                  username: babaPage['name'] ?? 'Baba Ji',
                  userAvatar: babaPage['avatar'] ?? '',
                  caption: babaPost.content,
                  imageUrl: babaPost.media.isNotEmpty ? babaPost.media.first.url : null,
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
              limit: 10,
            );

            if (reelsResponse['success'] == true) {
              final reelsData = reelsResponse['data']['videos'] as List<dynamic>;
              for (final reelData in reelsData) {
                final reel = BabaPageReel.fromJson(reelData);
                // Convert Baba Ji reel to regular Post for feed
                final post = Post(
                  id: 'baba_reel_${reel.id}',
                  userId: reel.babaPageId,
                  username: babaPage['name'] ?? 'Baba Ji',
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
                  isBabaJiPost: true, // Mark as Baba Ji post
                  isReel: true, // Mark as reel
                  babaPageId: reel.babaPageId,
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

  /// Get mixed feed content (posts and reels) from followed users
  static Future<List<Post>> getMixedFeed({
    required String token,
    required String currentUserId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('FeedService: Fetching mixed feed content for user: $currentUserId');
      
      // Get posts from followed users using the home feed API
      final userPosts = await getFeedPosts(
        token: token,
        currentUserId: currentUserId,
        page: page,
        limit: limit ~/ 2, // Half for user posts
      );

      // Get Baba Ji posts
      final babaJiPosts = await getBabaJiPosts(
        token: token,
        page: page,
        limit: limit ~/ 2, // Half for Baba Ji posts
      );

      // Combine and sort all posts
      final List<Post> allPosts = [...userPosts, ...babaJiPosts];
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply final pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedPosts = allPosts.sublist(
        startIndex < allPosts.length ? startIndex : 0,
        endIndex < allPosts.length ? endIndex : allPosts.length,
      );

      print('FeedService: Mixed feed created with ${paginatedPosts.length} items (${userPosts.length} user posts, ${babaJiPosts.length} Baba Ji posts)');
      return paginatedPosts;
    } catch (e) {
      print('FeedService: Error creating mixed feed: $e');
      return [];
    }
  }
}
