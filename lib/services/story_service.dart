import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/story_model.dart';
// Removed media model import since it's no longer needed
// Removed local story service import to prevent showing old local stories
import 'custom_http_client.dart';
import 'api_service.dart';

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
      print('StoryService: Fetching stories for user $userId from $_baseUrl/story/retrieve');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/story/retrieve?userId=$userId&page=$page&limit=$limit'),
        headers: token != null ? {'Authorization': token} : {},
      );

      print('StoryService: User stories response status: ${response.statusCode}');
      print('StoryService: User stories response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final userData = jsonResponse['data']['user'];
          final List<dynamic> storiesJson = jsonResponse['data']['stories'] ?? [];
          print('StoryService: Found ${storiesJson.length} stories for user $userId');
          
          List<Story> stories = [];
          for (var storyJson in storiesJson) {
            try {
              // Map the API response to Story model
              final story = Story(
                id: storyJson['id'] ?? '',
                authorId: storyJson['author']?['_id'] ?? storyJson['author']?['id'] ?? userId,
                authorName: storyJson['author']?['fullName'] ?? storyJson['author']?['username'] ?? '',
                authorUsername: storyJson['author']?['username'] ?? '',
                authorAvatar: storyJson['author']?['avatar'] ?? '',
                media: _constructFullUrl(storyJson['media'] ?? ''),
                mediaId: storyJson['id'] ?? '',
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
              stories.add(story);
            } catch (e) {
              print('StoryService: Error parsing story: $e');
            }
          }
          return stories;
        }
      }
      return [];
    } catch (e) {
      print('StoryService: Error getting user stories: $e');
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

  /// Get stories feed for all users - Updated to use story API
  static Future<List<Story>> getStoriesFeed(String token) async {
    try {
      print('StoryService: Fetching stories feed from story API');
      
      List<Story> allStories = [];
      
      // For now, let's fetch stories from some known users to demonstrate the functionality
      // In a real app, you would get this list from a following/friends API
      List<String> userIdsToFetch = [
        '68ac303e6f3bb238435477a4', // swayam2 user from your example
        // Add more user IDs here as needed
        // You can add more user IDs to test with multiple users
      ];
      
      // Fetch stories from each user
      for (String userId in userIdsToFetch) {
        try {
          final userStories = await getUserStories(userId, token: token, page: 1, limit: 10);
          print('StoryService: Fetched ${userStories.length} stories for user $userId');
          allStories.addAll(userStories);
        } catch (e) {
          print('StoryService: Error fetching stories for user $userId: $e');
        }
      }
      
      // Sort all stories by creation date (newest first)
      if (allStories.isNotEmpty) {
        allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('StoryService: Total stories in feed: ${allStories.length}');
      }
      
      return allStories;
    } catch (e) {
      print('StoryService: Error getting stories feed: $e');
      return [];
    }
  }

  /// Group stories by user to create story sections
  static Map<String, List<Story>> groupStoriesByUser(List<Story> stories) {
    Map<String, List<Story>> groupedStories = {};
    
    for (Story story in stories) {
      String userId = story.authorId;
      if (!groupedStories.containsKey(userId)) {
        groupedStories[userId] = [];
      }
      groupedStories[userId]!.add(story);
    }
    
    // Sort stories within each user group by creation date (newest first)
    groupedStories.forEach((userId, userStories) {
      userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    
    return groupedStories;
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
}

