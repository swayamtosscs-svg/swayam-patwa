import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/baba_page_story_model.dart';
import '../models/story_model.dart';
import 'custom_http_client.dart';
import 'baba_page_service.dart';

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
      print('BabaPageStoryService: Token provided: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        print('BabaPageStoryService: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      
      // Create multipart request for story upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/baba-pages/$babaPageId/stories'),
      );

      // Add authentication header if token is provided
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        print('BabaPageStoryService: Added Authorization header with token');
      } else {
        print('BabaPageStoryService: No token provided for authentication');
      }

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
        
        // Parse error response for better error message
        String errorMessage = 'Upload failed with status: ${response.statusCode}';
        try {
          final errorResponse = json.decode(responseData);
          if (errorResponse['message'] != null) {
            errorMessage = errorResponse['message'];
          }
        } catch (e) {
          print('BabaPageStoryService: Could not parse error response: $e');
        }
        
        return BabaPageStoryUploadResponse(
          success: false,
          message: errorMessage,
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
      print('=== GET BABA PAGE STORIES DEBUG ===');
      print('BabaPageStoryService: Fetching stories for Baba page $babaPageId');
      print('BabaPageStoryService: Page: $page, Limit: $limit');
      print('BabaPageStoryService: Token provided: ${token != null}');
      if (token != null) {
        print('BabaPageStoryService: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      
      // Try HTTPS first
      try {
        final url = '$_baseUrl/baba-pages/$babaPageId/stories?page=$page&limit=$limit';
        print('BabaPageStoryService: Making HTTPS request to: $url');
        
        final response = await http.get(
          Uri.parse(url),
          headers: token != null ? {'Authorization': token} : {},
        );

        print('BabaPageStoryService: HTTPS Stories response status: ${response.statusCode}');
        print('BabaPageStoryService: HTTPS Stories response body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print('BabaPageStoryService: Parsed JSON response: $jsonResponse');
          
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            // Handle the API response format: data is directly an array of stories
            final storiesData = jsonResponse['data'] as List<dynamic>? ?? [];
            print('BabaPageStoryService: Retrieved ${storiesData.length} stories from HTTPS API');
            if (storiesData.isNotEmpty) {
              print('BabaPageStoryService: First story data: ${storiesData.first}');
            }
            return storiesData.map((storyJson) => BabaPageStory.fromJson(storyJson)).toList();
          } else {
            print('BabaPageStoryService: HTTPS API returned error: ${jsonResponse['message']}');
            return [];
          }
        } else {
          print('BabaPageStoryService: Failed to fetch stories with HTTPS status: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        print('BabaPageStoryService: HTTPS fetch failed, trying HTTP fallback: $e');
        
        // Try HTTP fallback
        try {
          final fallbackUrl = '$_fallbackUrl/baba-pages/$babaPageId/stories?page=$page&limit=$limit';
          print('BabaPageStoryService: Making HTTP fallback request to: $fallbackUrl');
          
          final response = await http.get(
            Uri.parse(fallbackUrl),
            headers: token != null ? {'Authorization': token} : {},
          );

          print('BabaPageStoryService: HTTP Stories response status: ${response.statusCode}');
          print('BabaPageStoryService: HTTP Stories response body: ${response.body}');

          if (response.statusCode == 200) {
            final jsonResponse = json.decode(response.body);
            print('BabaPageStoryService: HTTP Parsed JSON response: $jsonResponse');
            
            if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
              // Handle the API response format: data is directly an array of stories
              final storiesData = jsonResponse['data'] as List<dynamic>? ?? [];
              print('BabaPageStoryService: Retrieved ${storiesData.length} stories from HTTP API');
              if (storiesData.isNotEmpty) {
                print('BabaPageStoryService: HTTP First story data: ${storiesData.first}');
              }
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
      print('BabaPageStoryService: Stack trace: ${StackTrace.current}');
      print('=== END GET BABA PAGE STORIES DEBUG ===');
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
      print('=== BABA PAGE STORY SERVICE DEBUG ===');
      print('BabaPageStoryService: Fetching all Babaji stories for home page');
      print('BabaPageStoryService: Token available: ${token != null}');
      if (token != null) {
        print('BabaPageStoryService: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      print('BabaPageStoryService: Page: $page, Limit: $limit');
      
      List<Story> allStories = [];
      
      // Try to get all Baba pages first to find the one with stories
      print('BabaPageStoryService: Getting all Baba pages to find stories...');
      try {
        // Import BabaPageService to get all pages
        final babaPagesResponse = await BabaPageService.getBabaPages(token: token ?? '', page: 1, limit: 50);
        
        if (babaPagesResponse.success && babaPagesResponse.pages.isNotEmpty) {
          print('BabaPageStoryService: Found ${babaPagesResponse.pages.length} Baba pages');
          
          // Try each Baba page to find stories
          for (final babaPage in babaPagesResponse.pages) {
            print('BabaPageStoryService: Checking Baba page: ${babaPage.name} (${babaPage.id})');
            
            final babaPageStories = await getBabaPageStories(
              babaPageId: babaPage.id,
              token: token,
              page: 1,
              limit: 10,
            );
            
            if (babaPageStories.isNotEmpty) {
              print('BabaPageStoryService: Found ${babaPageStories.length} stories in ${babaPage.name}');
              
              // Convert stories for this page
              for (final babaStory in babaPageStories) {
                final story = Story(
                  id: babaStory.id,
                  authorId: babaStory.babaPageId,
                  authorName: babaPage.name, // Use actual Baba page name
                  authorUsername: babaPage.name.toLowerCase().replaceAll(' ', ''), // Create username from name
                  authorAvatar: babaPage.avatar,
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
                print('BabaPageStoryService: Added story ${story.id} from ${story.authorName}');
              }
            } else {
              print('BabaPageStoryService: No stories found in ${babaPage.name}');
            }
          }
        } else {
          print('BabaPageStoryService: No Baba pages found or API error');
        }
      } catch (e) {
        print('BabaPageStoryService: Error getting Baba pages: $e');
      }
      
      // Fallback: Try the hardcoded Baba page ID if no stories found
      if (allStories.isEmpty) {
        print('BabaPageStoryService: No stories found in any Baba page, trying hardcoded ID...');
        const String babaPageId = '68d3bdc685cf1a0feab6f6c6';
        
        final babaPageStories = await getBabaPageStories(
          babaPageId: babaPageId,
          token: token,
          page: page,
          limit: limit,
        );
        
        print('BabaPageStoryService: Retrieved ${babaPageStories.length} stories from hardcoded Baba page $babaPageId');
        
        if (babaPageStories.isNotEmpty) {
          // Convert stories for hardcoded page
          for (final babaStory in babaPageStories) {
            final story = Story(
              id: babaStory.id,
              authorId: babaStory.babaPageId,
              authorName: 'Dhani Baba', // Use Dhani Baba name
              authorUsername: 'dhanibaba', // Use Dhani Baba username
              authorAvatar: null,
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
            print('BabaPageStoryService: Added story ${story.id} from ${story.authorName}');
          }
        } else {
          print('BabaPageStoryService: No stories found in hardcoded Baba page either');
          print('Dhani Baba needs to upload stories to see them here');
        }
      }
      
      print('BabaPageStoryService: Total stories found: ${allStories.length}');
      print('=== END BABA PAGE STORY SERVICE DEBUG ===');
      return allStories;
      
    } catch (e) {
      print('BabaPageStoryService: Error fetching all Babaji stories: $e');
      print('BabaPageStoryService: Stack trace: ${StackTrace.current}');
      return [];
    }
  }
}
