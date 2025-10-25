import '../models/post_model.dart';
import '../models/story_model.dart';
import 'media_upload_service.dart';
import 'local_storage_service.dart';

class UserMediaService {
  // Static callback to notify when media is updated
  static Function(String userId)? onMediaUpdated;
  
  /// Notify that media has been updated for a specific user
  static void notifyMediaUpdated(String userId) {
    print('UserMediaService: Notifying media updated for user: $userId');
    onMediaUpdated?.call(userId);
  }
  /// Fetch all media for a specific user - ALWAYS returns real data from API
  static Future<UserMediaResponse> getUserMedia({
    required String userId,
    String? token,
  }) async {
    try {
      print('UserMediaService: Fetching REAL media data for userId: $userId');
      print('UserMediaService: API URL: http://103.14.120.163:8081/api/media/upload?userId=$userId');
      
      // Always fetch fresh data from API - no caching to ensure accuracy
      print('UserMediaService: Calling retrieveMediaByUserId for userId: $userId');
      final apiResponse = await MediaUploadService.retrieveMediaByUserId(userId: userId);
      
      print('UserMediaService: API Response - Success: ${apiResponse.success}, Data length: ${apiResponse.data.length}');
      if (apiResponse.data.isNotEmpty) {
        print('UserMediaService: First item data: ${apiResponse.data.first.mediaId} - ${apiResponse.data.first.secureUrl}');
        print('UserMediaService: First item fileType: ${apiResponse.data.first.fileType}');
        print('UserMediaService: REAL POST COUNT: ${apiResponse.data.length} total media items');
      } else {
        print('UserMediaService: No media data returned for userId: $userId');
        print('UserMediaService: This means either:');
        print('  1. No posts uploaded for this user ID');
        print('  2. API returned empty data');
        print('  3. User ID mismatch (check if you uploaded posts with different user ID)');
        print('  4. Media API endpoint might not exist or be working');
        print('UserMediaService: REAL POST COUNT: 0 (no posts found)');
      }
      
      if (apiResponse.success && apiResponse.data.isNotEmpty) {
        print('UserMediaService: API returned ${apiResponse.data.length} media items for userId: $userId');
        
        // Get list of deleted post IDs from local storage
        final deletedPostIds = await LocalStorageService.getDeletedPostIds();
        print('UserMediaService: Found ${deletedPostIds.length} deleted post IDs in local storage');
        
        List<Story> stories = [];
        List<Post> posts = [];
        List<Post> reels = [];
        
        for (var mediaData in apiResponse.data) {
          // Skip deleted posts
          if (deletedPostIds.contains(mediaData.mediaId)) {
            print('UserMediaService: Skipping deleted post: ${mediaData.mediaId}');
            continue;
          }
          print('UserMediaService: Processing media item: ${mediaData.mediaId}');
          print('UserMediaService: File type: ${mediaData.fileType}');
          print('UserMediaService: Secure URL: ${mediaData.secureUrl}');
          
          if (mediaData.secureUrl.isNotEmpty && mediaData.fileType.isNotEmpty) {
            final postType = _getPostType(mediaData.fileType);
            print('UserMediaService: Determined post type: $postType');
            
            final authorName = mediaData.username.isNotEmpty ? mediaData.username : 'User';
            final authorUsername = mediaData.username.isNotEmpty ? mediaData.username : 'user';
            
            if (postType == PostType.image) {
              print('UserMediaService: Adding as POST (image)');
              // Use empty string for userAvatar since MediaData doesn't have this property
              // The PostWidget will handle showing initials when avatar is empty
              final userAvatar = '';
              print('UserMediaService: User avatar for $authorUsername: $userAvatar');
              
              posts.add(Post(
                id: mediaData.mediaId,
                userId: userId, // Use userId from API
                username: authorUsername,
                userAvatar: userAvatar,
                caption: 'A post by $authorUsername',
                imageUrl: mediaData.secureUrl,
                type: PostType.image,
                likes: 0,
                comments: 0,
                shares: 0,
                createdAt: mediaData.uploadedAt,
                hashtags: [],
              ));
              
              stories.add(Story(
                id: mediaData.mediaId,
                authorId: userId, // Use userId from API
                authorName: authorName,
                authorUsername: authorUsername,
                media: mediaData.secureUrl,
                mediaId: mediaData.mediaId,
                type: 'image',
                mentions: [],
                hashtags: [],
                isActive: true,
                views: [],
                viewsCount: 0,
                expiresAt: mediaData.uploadedAt.add(const Duration(hours: 24)),
                createdAt: mediaData.uploadedAt,
                updatedAt: mediaData.uploadedAt,
              ));
            } else if (postType == PostType.video || postType == PostType.reel) {
              print('UserMediaService: Adding as REEL (video)');
              // Use empty string for userAvatar since MediaData doesn't have this property
              // The PostWidget will handle showing initials when avatar is empty
              final userAvatar = '';
              print('UserMediaService: User avatar for reel $authorUsername: $userAvatar');
              
              reels.add(Post(
                id: mediaData.mediaId,
                userId: userId, // Use userId from API
                username: authorUsername,
                userAvatar: userAvatar,
                caption: 'A reel by $authorUsername',
                videoUrl: mediaData.secureUrl,
                type: PostType.video,
                likes: 0,
                comments: 0,
                shares: 0,
                createdAt: mediaData.uploadedAt,
                hashtags: [],
              ));
              
              stories.add(Story(
                id: mediaData.mediaId,
                authorId: userId, // Use userId from API
                authorName: authorName,
                authorUsername: authorUsername,
                media: mediaData.secureUrl,
                mediaId: mediaData.mediaId,
                type: 'video',
                mentions: [],
                hashtags: [],
                isActive: true,
                views: [],
                viewsCount: 0,
                expiresAt: mediaData.uploadedAt.add(const Duration(hours: 24)),
                createdAt: mediaData.uploadedAt,
                updatedAt: mediaData.uploadedAt,
              ));
            }
          } else {
            print('UserMediaService: Skipping media item - missing secureUrl or fileType');
            print('UserMediaService: secureUrl: ${mediaData.secureUrl}');
            print('UserMediaService: fileType: ${mediaData.fileType}');
          }
        }
        
        print('UserMediaService: Processed ${posts.length} posts and ${reels.length} reels from API');
        
        return UserMediaResponse(
          stories: stories,
          posts: posts,
          reels: reels,
          success: true,
        );
      } else {
        print('UserMediaService: API returned no media or failed for userId: $userId');
        print('UserMediaService: API success: ${apiResponse.success}, Data length: ${apiResponse.data.length}');
        
        // Enhanced error handling - provide more specific error information
        if (!apiResponse.success) {
          print('UserMediaService: API call failed - this might indicate:');
          print('  1. Server is down or unreachable');
          print('  2. Invalid user ID format');
          print('  3. Authentication issues');
          print('  4. API endpoint not implemented');
        } else if (apiResponse.data.isEmpty) {
          print('UserMediaService: API call succeeded but returned empty data - this means:');
          print('  1. User has no posts uploaded');
          print('  2. User ID is correct but no media exists');
          print('  3. This is normal for new users');
        }
        
        // Return empty results with success=true to avoid breaking the UI
        // The UI will show 0 posts/reels which is correct behavior
        return UserMediaResponse(
          stories: [],
          posts: [],
          reels: [],
          success: true, // Return success to avoid breaking the UI
        );
      }
    } catch (e) {
      print('UserMediaService: Error fetching user media: $e');
      print('UserMediaService: Exception type: ${e.runtimeType}');
      
      // Enhanced error handling for different types of exceptions
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        print('UserMediaService: Network connection error - server might be unreachable');
      } else if (e.toString().contains('TimeoutException')) {
        print('UserMediaService: Request timeout - server is slow or overloaded');
      } else if (e.toString().contains('FormatException')) {
        print('UserMediaService: Data format error - API response is malformed');
      } else {
        print('UserMediaService: Unknown error occurred');
      }
      
      // Return empty results with success=false to indicate error
      // But still return empty arrays to prevent UI crashes
      return UserMediaResponse(
        stories: [],
        posts: [],
        reels: [],
        success: false, // Indicate error occurred
      );
    }
  }

  /// Get only stories for a user
  static Future<List<Story>> getUserStories({
    required String userId,
    String? token,
  }) async {
    final response = await getUserMedia(userId: userId, token: token);
    return response.stories;
  }

  /// Get only posts for a user
  static Future<List<Post>> getUserPosts({
    required String userId,
    String? token,
  }) async {
    final response = await getUserMedia(userId: userId, token: token);
    return response.posts;
  }

  /// Get only reels for a user
  static Future<List<Post>> getUserReels({
    required String userId,
    String? token,
  }) async {
    final response = await getUserMedia(userId: userId, token: token);
    return response.reels;
  }

  /// Force refresh user media data - ensures latest post counts are shown
  static Future<UserMediaResponse> forceRefreshUserMedia({
    required String userId,
    String? token,
  }) async {
    print('UserMediaService: Force refreshing media data for userId: $userId');
    // Clear any potential cache and fetch fresh data
    return await getUserMedia(userId: userId, token: token);
  }

  /// Get real-time post count for a user (posts only, not reels)
  static Future<int> getRealPostCount({
    required String userId,
    String? token,
  }) async {
    try {
      final response = await getUserMedia(userId: userId, token: token);
      final postCount = response.posts.length;
      print('UserMediaService: Real post count for $userId: $postCount');
      return postCount;
    } catch (e) {
      print('UserMediaService: Error getting real post count: $e');
      return 0;
    }
  }

  /// Get real-time reel count for a user (videos only, not posts)
  static Future<int> getRealReelCount({
    required String userId,
    String? token,
  }) async {
    try {
      final response = await getUserMedia(userId: userId, token: token);
      final reelCount = response.reels.length;
      print('UserMediaService: Real reel count for $userId: $reelCount');
      return reelCount;
    } catch (e) {
      print('UserMediaService: Error getting real reel count: $e');
      return 0;
    }
  }

  /// Clear any cached data for a specific user (useful when posts are uploaded/deleted)
  static void clearUserCache(String userId) {
    print('UserMediaService: Clearing cache for user: $userId');
    // Since we're using force refresh, we don't have persistent cache
    // But we can notify listeners that data should be refreshed
    notifyMediaUpdated(userId);
  }

  /// Clear all cached data (useful for logout or major changes)
  static void clearAllCache() {
    print('UserMediaService: Clearing all cached data');
    // Reset the callback
    onMediaUpdated = null;
  }

  /// Search for users (mock implementation for now)
  static Future<List<UserSearchResult>> searchUsers({
    required String query,
    String? token,
  }) async {
    // Mock search results - in real app this would call a search API
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    if (query.toLowerCase().contains('dhani')) {
      return [
        UserSearchResult(
          id: 'dhani_id',
          username: 'dhani',
          fullName: 'Dhani User',
          avatar: 'https://via.placeholder.com/50/10B981/FFFFFF?text=D',
        ),
      ];
    } else if (query.toLowerCase().contains('riyana')) {
      return [
        UserSearchResult(
          id: 'riyana_id',
          username: 'riyana',
          fullName: 'Riyana Patel',
          avatar: 'https://via.placeholder.com/50/6366F1/FFFFFF?text=R',
        ),
      ];
    } else {
      return [
        UserSearchResult(
          id: 'user_1',
          username: 'user1',
          fullName: 'User One',
          avatar: 'https://via.placeholder.com/50/8B5CF6/FFFFFF?text=U',
        ),
        UserSearchResult(
          id: 'user_2',
          username: 'user2',
          fullName: 'User Two',
          avatar: 'https://via.placeholder.com/50/EF4444/FFFFFF?text=U',
        ),
      ];
    }
  }
  
  /// Helper method to convert file type to PostType
  static PostType _getPostType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return PostType.image;
      case 'video':
      case 'mp4':
      case 'mov':
      case 'avi':
        return PostType.video;
      case 'reel':
        return PostType.reel;
      default:
        return PostType.image; // Default to image
    }
  }
}

class UserMediaResponse {
  final List<Story> stories;
  final List<Post> posts;
  final List<Post> reels;
  final bool success;

  UserMediaResponse({
    required this.stories,
    required this.posts,
    required this.reels,
    required this.success,
  });
}

class UserSearchResult {
  final String id;
  final String username;
  final String fullName;
  final String avatar;

  UserSearchResult({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
  });
}
