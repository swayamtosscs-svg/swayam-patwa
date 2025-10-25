import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/story_model.dart';
// Removed media model import since it's no longer needed
// Removed local story service import to prevent showing old local stories
import 'custom_http_client.dart';
import 'api_service.dart';
import 'dp_service.dart';

class StoryService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';

  /// Upload a story with media file directly to story API
  static Future<StoryUploadResponse> uploadStory({
    required File file,
    required String userId,
    required String caption,
    String? token,
  }) async {
    try {
      print('StoryService: Uploading story to $_baseUrl/story/upload');
      print('StoryService: File path: ${file.path}');
      print('StoryService: User ID: $userId');
      print('StoryService: Caption: $caption');

      // Create multipart request for story upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/story/upload'),
      );

      // Add the file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      // Add form fields
      request.fields['userId'] = userId;
      request.fields['caption'] = caption;

      print('StoryService: Sending multipart request with file, userId, and caption');

      // Use custom HTTP client for better SSL handling
      final response = await CustomHttpClient.client.send(request);
      final responseData = await response.stream.bytesToString();
      
      print('StoryService: Story upload response status: ${response.statusCode}');
      print('StoryService: Story upload response body: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseData);
        print('StoryService: Success response (${response.statusCode}): $jsonResponse');
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Parse the story data from the response
          final storyData = jsonResponse['data'];
          final story = Story(
            id: storyData['storyId'] ?? storyData['id'] ?? '',
            authorId: storyData['author']?['id'] ?? userId,
            authorName: storyData['author']?['fullName'] ?? storyData['author']?['username'] ?? '',
            authorUsername: storyData['author']?['username'] ?? '',
            authorAvatar: storyData['author']?['avatar'] ?? '',
            media: _constructFullUrl(storyData['secureUrl'] ?? storyData['media'] ?? ''),
            mediaId: storyData['storyId'] ?? storyData['id'] ?? '',
            type: storyData['mediaType'] ?? storyData['type'] ?? 'image',
            caption: storyData['caption'] ?? caption, // Include caption from upload
            mentions: List<String>.from(storyData['mentions'] ?? []),
            hashtags: List<String>.from(storyData['hashtags'] ?? []),
            isActive: storyData['isActive'] ?? true,
            views: List<String>.from(storyData['views'] ?? []),
            viewsCount: storyData['viewsCount'] ?? 0,
            expiresAt: DateTime.tryParse(storyData['expiresAt'] ?? '') ?? DateTime.now().add(const Duration(hours: 24)),
            createdAt: DateTime.tryParse(storyData['createdAt'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(storyData['updatedAt'] ?? '') ?? DateTime.now(),
          );
          
          return StoryUploadResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Story uploaded successfully',
            story: story,
          );
        } else {
          return StoryUploadResponse(
            success: false,
            message: jsonResponse['message'] ?? 'Failed to upload story',
          );
        }
      } else {
        print('StoryService: Error response (${response.statusCode}): $responseData');
        
        // Try to get error message from response
        try {
          final errorResponse = jsonDecode(responseData);
          final errorMessage = errorResponse['message'] ?? 'Failed to upload story. Status: ${response.statusCode}';
          print('StoryService: Error message: $errorMessage');
          
          return StoryUploadResponse(
            success: false,
            message: errorMessage,
          );
        } catch (e) {
          print('StoryService: Failed to parse error response: $e');
          
          // Provide specific error messages for common status codes
          String userMessage;
          switch (response.statusCode) {
            case 405:
              userMessage = 'Story upload method not allowed. Please try again.';
              break;
            case 401:
              userMessage = 'Unauthorized. Please check your authentication.';
              break;
            case 400:
              userMessage = 'Bad request. Please check your story data.';
              break;
            default:
              userMessage = 'Failed to upload story. Status: ${response.statusCode}';
          }
          
          return StoryUploadResponse(
            success: false,
            message: userMessage,
          );
        }
      }
    } catch (e) {
      print('StoryService: Network error: $e');
      return StoryUploadResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Upload story from file (image/video) - Updated to use story API directly
  static Future<StoryUploadResponse> uploadStoryFromFile({
    required File file,
    required String userId,
    required String caption,
    String? token,
  }) async {
    try {
      print('StoryService: Starting story upload for ${file.path}');
      
      // Upload story directly to story API
      final result = await uploadStory(
        file: file,
        userId: userId,
        caption: caption,
        token: token,
      );
      
      if (result.success) {
        print('StoryService: Story uploaded successfully via story API');
        return result;
      } else {
        print('StoryService: Story upload failed, returning error');
        return StoryUploadResponse(
          success: false,
          message: 'Failed to upload story to server',
        );
      }
    } catch (e) {
      print('StoryService: Error uploading story from file: $e');
      return StoryUploadResponse(
        success: false,
        message: 'Error uploading story: $e',
      );
    }
  }

  /// Get stories for a specific user using the story retrieve API
  static Future<List<Story>> getUserStories(String userId, {String? token, int page = 1, int limit = 10}) async {
    try {
      print('StoryService: Fetching stories for user $userId from $_baseUrl/stories');
      print('StoryService: Token provided: ${token != null ? "Yes (${token.length} chars)" : "No"}');
      
      // Try the correct API endpoint first
      final response = await http.get(
        Uri.parse('$_baseUrl/stories?userId=$userId&page=$page&limit=$limit'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      print('StoryService: User stories response status: ${response.statusCode}');
      print('StoryService: User stories response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('StoryService: JSON response success: ${jsonResponse['success']}');
        print('StoryService: JSON response data: ${jsonResponse['data']}');
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final userData = jsonResponse['data']['user'];
          final List<dynamic> storiesJson = jsonResponse['data']['stories'] ?? [];
          print('StoryService: Found ${storiesJson.length} stories for user $userId');
          print('StoryService: User data: $userData');
          
          List<Story> stories = [];
          for (var storyJson in storiesJson) {
            try {
              print('StoryService: Parsing story: ${storyJson['id']}');
              
              // Extract story ID with better handling
              final storyId = storyJson['id'] ?? storyJson['_id'] ?? '';
              if (storyId.isEmpty) {
                print('StoryService: WARNING - Story has no ID, skipping: $storyJson');
                continue;
              }
              
              // Map the API response to Story model
              final story = Story(
                id: storyId,
                authorId: storyJson['author']?['_id'] ?? storyJson['author']?['id'] ?? userId,
                authorName: storyJson['author']?['fullName'] ?? storyJson['author']?['username'] ?? '',
                authorUsername: storyJson['author']?['username'] ?? '',
                authorAvatar: storyJson['author']?['avatar'] ?? '',
                media: _constructFullUrl(storyJson['media'] ?? ''),
                mediaId: storyId,
                type: storyJson['type'] ?? 'image',
                caption: storyJson['caption'] ?? storyJson['description'], // Include caption field
                mentions: List<String>.from(storyJson['mentions'] ?? []),
                hashtags: List<String>.from(storyJson['hashtags'] ?? []),
                isActive: storyJson['isActive'] ?? true,
                views: List<String>.from(storyJson['views'] ?? []),
                viewsCount: storyJson['viewsCount'] ?? 0,
                expiresAt: DateTime.tryParse(storyJson['expiresAt'] ?? '') ?? DateTime.now().add(const Duration(hours: 24)),
                createdAt: DateTime.tryParse(storyJson['createdAt'] ?? '') ?? DateTime.now(),
                updatedAt: DateTime.tryParse(storyJson['updatedAt'] ?? '') ?? DateTime.now(),
              );
              
              // Debug: Log author avatar information
              print('StoryService: Story ${storyId} - Author: ${story.authorName}');
              print('StoryService: Author Avatar URL: ${story.authorAvatar}');
              if (story.authorAvatar == null || story.authorAvatar!.isEmpty) {
                print('StoryService: WARNING - No avatar URL for story ${storyId}');
              }
              stories.add(story);
              print('StoryService: Successfully parsed story: ${story.id}');
            } catch (e) {
              print('StoryService: Error parsing story: $e');
              print('StoryService: Story JSON: $storyJson');
            }
          }
          print('StoryService: Returning ${stories.length} stories');
          
          // Additional verification: Ensure all stories belong to the requested user
          final filteredStories = stories.where((story) => story.authorId == userId).toList();
          if (filteredStories.length != stories.length) {
            print('StoryService: WARNING - API returned ${stories.length} stories but only ${filteredStories.length} belong to user $userId');
            print('StoryService: Filtering out stories from other users');
          }
          
          return filteredStories;
        } else {
          print('StoryService: API response indicates failure or no data');
          print('StoryService: Success: ${jsonResponse['success']}');
          print('StoryService: Message: ${jsonResponse['message']}');
        }
      } else {
        print('StoryService: HTTP error ${response.statusCode}: ${response.body}');
        
        // Try fallback endpoint if the main one fails
        if (response.statusCode == 404) {
          print('StoryService: Trying fallback endpoint /story/retrieve');
          return await _getUserStoriesFallback(userId, token: token, page: page, limit: limit);
        }
      }
      return [];
    } catch (e) {
      print('StoryService: Error getting user stories: $e');
      return [];
    }
  }

  /// Fallback method to get user stories using the old endpoint
  static Future<List<Story>> _getUserStoriesFallback(String userId, {String? token, int page = 1, int limit = 10}) async {
    try {
      print('StoryService: Fallback - Fetching stories for user $userId from $_baseUrl/story/retrieve');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/story/retrieve?userId=$userId&page=$page&limit=$limit'),
        headers: token != null ? {'Authorization': token} : {},
      );

      print('StoryService: Fallback response status: ${response.statusCode}');
      print('StoryService: Fallback response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final userData = jsonResponse['data']['user'];
          final List<dynamic> storiesJson = jsonResponse['data']['stories'] ?? [];
          print('StoryService: Fallback found ${storiesJson.length} stories for user $userId');
          
          List<Story> stories = [];
          for (var storyJson in storiesJson) {
            try {
              // Extract story ID with better handling
              final storyId = storyJson['id'] ?? storyJson['_id'] ?? '';
              if (storyId.isEmpty) {
                print('StoryService: Fallback WARNING - Story has no ID, skipping: $storyJson');
                continue;
              }
              
              final story = Story(
                id: storyId,
                authorId: storyJson['author']?['_id'] ?? storyJson['author']?['id'] ?? userId,
                authorName: storyJson['author']?['fullName'] ?? storyJson['author']?['username'] ?? '',
                authorUsername: storyJson['author']?['username'] ?? '',
                authorAvatar: storyJson['author']?['avatar'] ?? '',
                media: _constructFullUrl(storyJson['media'] ?? ''),
                mediaId: storyId,
                type: storyJson['type'] ?? 'image',
                caption: storyJson['caption'] ?? storyJson['description'],
                mentions: List<String>.from(storyJson['mentions'] ?? []),
                hashtags: List<String>.from(storyJson['hashtags'] ?? []),
                isActive: storyJson['isActive'] ?? true,
                views: List<String>.from(storyJson['views'] ?? []),
                viewsCount: storyJson['viewsCount'] ?? 0,
                expiresAt: DateTime.tryParse(storyJson['expiresAt'] ?? '') ?? DateTime.now().add(const Duration(hours: 24)),
                createdAt: DateTime.tryParse(storyJson['createdAt'] ?? '') ?? DateTime.now(),
                updatedAt: DateTime.tryParse(storyJson['updatedAt'] ?? '') ?? DateTime.now(),
              );
              stories.add(story);
            } catch (e) {
              print('StoryService: Fallback error parsing story: $e');
            }
          }
          
          // Additional verification: Ensure all stories belong to the requested user
          final filteredStories = stories.where((story) => story.authorId == userId).toList();
          if (filteredStories.length != stories.length) {
            print('StoryService: Fallback WARNING - API returned ${stories.length} stories but only ${filteredStories.length} belong to user $userId');
            print('StoryService: Fallback filtering out stories from other users');
          }
          
          return filteredStories;
        }
      }
      return [];
    } catch (e) {
      print('StoryService: Fallback error getting user stories: $e');
      return [];
    }
  }

  /// Get stories for a specific user by username
  static Future<List<Story>> getUserStoriesByUsername(String username, {String? token, int page = 1, int limit = 10}) async {
    try {
      print('StoryService: Fetching stories for username $username');
      
      // For now, we'll use a mapping of known usernames to user IDs
      // In a real app, you'd have an API to get user ID by username
      Map<String, String> usernameToId = {
        'swayam2': '68ac303e6f3bb238435477a4',
        // Add more username mappings here
      };
      
      String? userId = usernameToId[username];
      if (userId != null) {
        return await getUserStories(userId, token: token, page: page, limit: limit);
      } else {
        print('StoryService: Username $username not found in mapping');
        return [];
      }
    } catch (e) {
      print('StoryService: Error getting user stories by username: $e');
      return [];
    }
  }

  /// Get stories feed for followed users only - Updated to respect follow status
  static Future<List<Story>> getStoriesFeed(String token) async {
    try {
      print('StoryService: Fetching stories feed from story API (followed users only)');
      
      List<Story> allStories = [];
      Set<String> seenStoryIds = <String>{}; // Track unique story IDs to prevent duplicates
      
      // Note: This method should only be called with a list of followed users
      // For now, return empty list to prevent showing unfollowed users' stories
      print('StoryService: getStoriesFeed() should not be used directly - use getFollowedUsersStories() instead');
      print('StoryService: Returning empty list to prevent showing unfollowed users stories');
      
      return allStories;
    } catch (e) {
      print('StoryService: Error getting stories feed: $e');
      return [];
    }
  }

  /// Group stories by user to create story sections with deduplication
  static Map<String, List<Story>> groupStoriesByUser(List<Story> stories) {
    Map<String, List<Story>> groupedStories = {};
    Set<String> processedStoryIds = <String>{}; // Track processed stories to prevent duplicates
    
    for (Story story in stories) {
      // Skip if we've already processed this story
      if (processedStoryIds.contains(story.id)) {
        print('StoryService: Skipping duplicate story in grouping: ${story.id}');
        continue;
      }
      
      String userId = story.authorId;
      if (!groupedStories.containsKey(userId)) {
        groupedStories[userId] = [];
      }
      groupedStories[userId]!.add(story);
      processedStoryIds.add(story.id);
    }
    
    // Sort stories within each user group by creation date (newest first)
    groupedStories.forEach((userId, userStories) {
      userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    
    return groupedStories;
  }

  /// Ensure stories have valid author avatars by fetching missing DPs
  static Future<List<Story>> ensureStoriesHaveDPs(List<Story> stories, String token) async {
    final List<Story> updatedStories = [];
    
    for (final story in stories) {
      // If story already has a valid avatar, keep it as is
      if (story.authorAvatar != null && 
          story.authorAvatar!.isNotEmpty && 
          story.authorAvatar != 'null') {
        updatedStories.add(story);
        continue;
      }
      
      // Try to fetch DP for this user
      try {
        print('StoryService: Fetching DP for user ${story.authorId} (${story.authorName})');
        final dpResponse = await DPService.retrieveDP(
          userId: story.authorId,
          token: token,
        );
        
        String? dpUrl;
        if (dpResponse['success'] == true && dpResponse['data'] != null) {
          dpUrl = dpResponse['data']['dpUrl'] as String?;
          print('StoryService: DP found for ${story.authorName}: $dpUrl');
        } else {
          print('StoryService: No DP found for ${story.authorName}: ${dpResponse['message']}');
        }
        
        // Create updated story with DP
        final updatedStory = story.copyWith(authorAvatar: dpUrl);
        updatedStories.add(updatedStory);
        
      } catch (e) {
        print('StoryService: Error fetching DP for ${story.authorName}: $e');
        // Keep original story without DP
        updatedStories.add(story);
      }
    }
    
    return updatedStories;
  }

  /// Delete a story
  static Future<Map<String, dynamic>> deleteStory(String storyId, String userId, String token) async {
    try {
      print('StoryService: Deleting story $storyId for user $userId');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/story/delete?storyId=$storyId&userId=$userId'),
        headers: {
          'Authorization': token,
        },
      );

      print('StoryService: Delete story response status: ${response.statusCode}');
      print('StoryService: Delete story response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          print('StoryService: Story deleted successfully');
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Story deleted successfully',
            'data': jsonResponse['data'],
          };
        } else {
          print('StoryService: Story deletion failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to delete story',
          };
        }
      } else {
        print('StoryService: Story deletion failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to delete story. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('StoryService: Error deleting story: $e');
      return {
        'success': false,
        'message': 'Error deleting story: $e',
      };
    }
  }

  /// Get story views
  static Future<List<String>> getStoryViews(String storyId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/story/$storyId/views'),
        headers: {
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> viewsJson = jsonResponse['data']['views'] ?? [];
          return viewsJson.map((json) => json.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting story views: $e');
      return [];
    }
  }

  /// Mark story as viewed
  static Future<bool> markStoryAsViewed(String storyId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/story/$storyId/view'),
        headers: {
          'Authorization': token,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking story as viewed: $e');
      return false;
    }
  }

  // Helper method to construct full URL from relative path
  static String _constructFullUrl(String url) {
    if (url.isEmpty) return url;
    
    // If it's already a full URL, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's a relative path starting with /uploads, construct full URL
    if (url.startsWith('/uploads/')) {
      return 'http://103.14.120.163:8081$url';
    }
    
    // If it's a relative path without leading slash, add it
    if (url.startsWith('uploads/')) {
      return 'http://103.14.120.163:8081/$url';
    }
    
    return url;
  }

  // Removed retrieveMedia method since it's no longer needed for stories
  
  /// Utility method to remove duplicate stories from a list
  static List<Story> removeDuplicateStories(List<Story> stories) {
    Set<String> seenIds = <String>{};
    List<Story> uniqueStories = [];
    
    for (Story story in stories) {
      if (!seenIds.contains(story.id) && story.id.isNotEmpty) {
        seenIds.add(story.id);
        uniqueStories.add(story);
      }
    }
    
    return uniqueStories;
  }
  
  /// Utility method to check if a story list contains duplicates
  static bool hasDuplicateStories(List<Story> stories) {
    Set<String> ids = <String>{};
    for (Story story in stories) {
      if (ids.contains(story.id)) {
        return true;
      }
      ids.add(story.id);
    }
    return false;
  }
}

