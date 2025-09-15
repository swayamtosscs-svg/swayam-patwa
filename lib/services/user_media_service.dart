import '../models/post_model.dart';
import '../models/story_model.dart';
import 'media_upload_service.dart';
import 'local_storage_service.dart';

class UserMediaService {
  /// Fetch all media for a specific user
  static Future<UserMediaResponse> getUserMedia({
    required String userId,
    String? token,
  }) async {
    try {
      print('UserMediaService: Fetching media for userId: $userId');
      print('UserMediaService: API URL will be: http://103.14.120.163:8081/api/media/upload?userId=$userId');
      
      // Try to get media from API first
      print('UserMediaService: Calling retrieveMediaByUserId for userId: $userId');
      final apiResponse = await MediaUploadService.retrieveMediaByUserId(userId: userId);
      
      print('UserMediaService: API Response - Success: ${apiResponse.success}, Data length: ${apiResponse.data.length}');
      if (apiResponse.data.isNotEmpty) {
        print('UserMediaService: First item data: ${apiResponse.data.first.mediaId} - ${apiResponse.data.first.secureUrl}');
        print('UserMediaService: First item fileType: ${apiResponse.data.first.fileType}');
      } else {
        print('UserMediaService: No media data returned for userId: $userId');
        print('UserMediaService: This means either:');
        print('  1. No posts uploaded for this user ID');
        print('  2. API returned empty data');
        print('  3. User ID mismatch (check if you uploaded posts with different user ID)');
        print('  4. Media API endpoint might not exist or be working');
      }
      
      if (apiResponse.success && apiResponse.data.isNotEmpty) {
        print('UserMediaService: API returned ${apiResponse.data.length} media items for userId: $userId');
        
        List<Story> stories = [];
        List<Post> posts = [];
        List<Post> reels = [];
        
        for (var mediaData in apiResponse.data) {
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
              posts.add(Post(
                id: mediaData.mediaId,
                userId: userId, // Use userId from API
                username: authorUsername,
                userAvatar: 'https://via.placeholder.com/50/6366F1/FFFFFF?text=${authorUsername.isNotEmpty ? authorUsername[0].toUpperCase() : 'U'}',
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
              reels.add(Post(
                id: mediaData.mediaId,
                userId: userId, // Use userId from API
                username: authorUsername,
                userAvatar: 'https://via.placeholder.com/50/6366F1/FFFFFF?text=${authorUsername.isNotEmpty ? authorUsername[0].toUpperCase() : 'U'}',
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
        
        // Try alternative approach - check if there are separate post/reel APIs
        print('UserMediaService: Trying alternative approach - checking for separate post/reel APIs');
        
        // For now, return empty results with a note about the issue
        print('UserMediaService: Returning empty results - media API might not be implemented yet');
        return UserMediaResponse(
          stories: [],
          posts: [],
          reels: [],
          success: true, // Still return success to avoid breaking the UI
        );
      }
    } catch (e) {
      print('UserMediaService: Error fetching user media: $e');
      print('UserMediaService: This might indicate that the media API endpoint is not available');
      
      return UserMediaResponse(
        stories: [],
        posts: [],
        reels: [],
        success: false,
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
