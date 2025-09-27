import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/baba_page_story_model.dart';
import '../models/story_model.dart';
import 'custom_http_client.dart';

class BabaPageStoryService {
  static const String _baseUrl = 'https://103.14.120.163:8081/api';
  static const String _fallbackUrl = 'http://103.14.120.163:8081/api';

  /// Upload a story for a Baba page
  static Future<BabaPageStoryUploadResponse> uploadBabaPageStory({
    required File mediaFile,
    required String babaPageId,
    required String content,
    String? token,
  }) async {
    try {
      print('BabaPageStoryService: Uploading story for Baba page $babaPageId');
      print('BabaPageStoryService: File path: ${mediaFile.path}');
      print('BabaPageStoryService: Content: $content');

      // Try HTTPS first
      return await _uploadStoryWithUrl(
        mediaFile: mediaFile,
        babaPageId: babaPageId,
        content: content,
        token: token,
        url: _baseUrl,
      );
    } catch (e) {
      print('BabaPageStoryService: HTTPS upload failed, trying HTTP fallback: $e');
      
      // Try HTTP fallback if HTTPS fails
      try {
        return await _uploadStoryWithUrl(
          mediaFile: mediaFile,
          babaPageId: babaPageId,
          content: content,
          token: token,
          url: _fallbackUrl,
        );
      } catch (fallbackError) {
        print('BabaPageStoryService: HTTP fallback also failed: $fallbackError');
        return BabaPageStoryUploadResponse(
          success: false,
          message: 'Network error: $e',
        );
      }
    }
  }

  /// Upload story with a specific URL (for fallback)
  static Future<BabaPageStoryUploadResponse> _uploadStoryWithUrl({
    required File mediaFile,
    required String babaPageId,
    required String content,
    String? token,
    required String url,
  }) async {
    try {
      print('BabaPageStoryService: Uploading story with URL: $url');
      
      // Create multipart request for story upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/baba-pages/$babaPageId/stories'),
      );

      // Add the media file
      request.files.add(await http.MultipartFile.fromPath('media', mediaFile.path));
      
      // Add form fields
      request.fields['content'] = content;

      print('BabaPageStoryService: Sending multipart request with media file and content');

      // Use custom HTTP client for better SSL handling
      final response = await CustomHttpClient.client.send(request);
      final responseData = await response.stream.bytesToString();
      
      print('BabaPageStoryService: Story upload response status: ${response.statusCode}');
      print('BabaPageStoryService: Story upload response body: $responseData');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(responseData);
        print('BabaPageStoryService: Parsed JSON response: $jsonResponse');
        
        return BabaPageStoryUploadResponse.fromJson(jsonResponse);
      } else {
        print('BabaPageStoryService: Upload failed with status: ${response.statusCode}');
        return BabaPageStoryUploadResponse(
          success: false,
          message: 'Upload failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('BabaPageStoryService: Error uploading story with URL $url: $e');
      rethrow;
    }
  }

  /// Get stories for a specific Baba page
  static Future<List<BabaPageStory>> getBabaPageStories({
    required String babaPageId,
    String? token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('BabaPageStoryService: Fetching stories for Baba page $babaPageId');
      
      // Try HTTPS first
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/baba-pages/$babaPageId/stories?page=$page&limit=$limit'),
          headers: token != null ? {'Authorization': token} : {},
        );

        print('BabaPageStoryService: Stories response status: ${response.statusCode}');
        print('BabaPageStoryService: Stories response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            // Handle the API response format: data is directly an array of stories
            final storiesData = jsonResponse['data'] as List<dynamic>? ?? [];
            print('BabaPageStoryService: Retrieved ${storiesData.length} stories from API');
            return storiesData.map((storyJson) => BabaPageStory.fromJson(storyJson)).toList();
          } else {
            print('BabaPageStoryService: API returned error: ${jsonResponse['message']}');
            return [];
          }
        } else {
          print('BabaPageStoryService: Failed to fetch stories with status: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        print('BabaPageStoryService: HTTPS fetch failed, trying HTTP fallback: $e');
        
        // Try HTTP fallback
        try {
          final response = await http.get(
            Uri.parse('$_fallbackUrl/baba-pages/$babaPageId/stories?page=$page&limit=$limit'),
            headers: token != null ? {'Authorization': token} : {},
          );

          print('BabaPageStoryService: HTTP Stories response status: ${response.statusCode}');
          print('BabaPageStoryService: HTTP Stories response body: ${response.body}');

          if (response.statusCode == 200) {
            final jsonResponse = json.decode(response.body);
            
            if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
              // Handle the API response format: data is directly an array of stories
              final storiesData = jsonResponse['data'] as List<dynamic>? ?? [];
              print('BabaPageStoryService: Retrieved ${storiesData.length} stories from HTTP API');
              return storiesData.map((storyJson) => BabaPageStory.fromJson(storyJson)).toList();
            } else {
              print('BabaPageStoryService: HTTP API returned error: ${jsonResponse['message']}');
              return [];
            }
          } else {
            print('BabaPageStoryService: Failed to fetch stories with HTTP status: ${response.statusCode}');
            return [];
          }
        } catch (fallbackError) {
          print('BabaPageStoryService: HTTP fallback also failed: $fallbackError');
          return [];
        }
      }
    } catch (e) {
      print('BabaPageStoryService: Error fetching stories: $e');
      return [];
    }
  }

  /// Delete a Baba page story
  static Future<bool> deleteBabaPageStory({
    required String storyId,
    required String babaPageId,
    String? token,
  }) async {
    try {
      print('BabaPageStoryService: Deleting story $storyId for Baba page $babaPageId');
      
      // Try HTTPS first
      try {
        final response = await http.delete(
          Uri.parse('$_baseUrl/baba-pages/$babaPageId/stories/$storyId'),
          headers: token != null ? {'Authorization': token} : {},
        );

        print('BabaPageStoryService: Delete response status: ${response.statusCode}');
        print('BabaPageStoryService: Delete response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          final jsonResponse = json.decode(response.body);
          return jsonResponse['success'] == true;
        } else {
          print('BabaPageStoryService: Failed to delete story with status: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        print('BabaPageStoryService: HTTPS delete failed, trying HTTP fallback: $e');
        
        // Try HTTP fallback
        try {
          final response = await http.delete(
            Uri.parse('$_fallbackUrl/baba-pages/$babaPageId/stories/$storyId'),
            headers: token != null ? {'Authorization': token} : {},
          );

          print('BabaPageStoryService: HTTP Delete response status: ${response.statusCode}');
          print('BabaPageStoryService: HTTP Delete response body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 204) {
            final jsonResponse = json.decode(response.body);
            return jsonResponse['success'] == true;
          } else {
            print('BabaPageStoryService: Failed to delete story with HTTP status: ${response.statusCode}');
            return false;
          }
        } catch (fallbackError) {
          print('BabaPageStoryService: HTTP fallback delete also failed: $fallbackError');
          return false;
        }
      }
    } catch (e) {
      print('BabaPageStoryService: Error deleting story: $e');
      return false;
    }
  }

  /// Get all Babaji stories as regular Story objects for home page display
  static Future<List<Story>> getAllBabajiStoriesAsStories({
    String? token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('BabaPageStoryService: Fetching all Babaji stories for home page');
      print('BabaPageStoryService: Token available: ${token != null}');
      
      List<Story> allStories = [];
      
      // Get all Baba pages first
      // For now, we'll use the specific Baba page ID from your example
      // Updated to use the actual Baba page ID from the logs
      const String babaPageId = '68d3bdc685cf1a0feab6f6c6';
      
      print('BabaPageStoryService: Using Baba page ID: $babaPageId');
      
      // Get stories from this Baba page
      final babaPageStories = await getBabaPageStories(
        babaPageId: babaPageId,
        token: token,
        page: page,
        limit: limit,
      );
      
      print('BabaPageStoryService: Retrieved ${babaPageStories.length} stories from Baba page $babaPageId');
      
      // Convert Baba page stories to regular Story objects
      for (final babaStory in babaPageStories) {
        print('BabaPageStoryService: Converting story ${babaStory.id} with media: ${babaStory.media.url}');
        
        final story = Story(
          id: babaStory.id,
          authorId: babaStory.babaPageId,
          authorName: 'Baba Ji', // Default name for Baba page stories
          authorUsername: 'babaji', // Default username
          authorAvatar: null, // Will be handled by the UI
          media: babaStory.media.url,
          mediaId: babaStory.id,
          type: babaStory.media.type,
          mentions: [],
          hashtags: [],
          isActive: babaStory.isActive,
          views: [],
          viewsCount: babaStory.viewsCount,
          expiresAt: babaStory.expiresAt,
          createdAt: babaStory.createdAt,
          updatedAt: babaStory.updatedAt,
        );
        allStories.add(story);
        print('BabaPageStoryService: Added story ${story.id} with author ${story.authorName}');
      }
      
      print('BabaPageStoryService: Converted ${allStories.length} Baba page stories to regular Story objects');
      return allStories;
      
    } catch (e) {
      print('BabaPageStoryService: Error fetching all Babaji stories: $e');
      print('BabaPageStoryService: Stack trace: ${StackTrace.current}');
      return [];
    }
  }
}
