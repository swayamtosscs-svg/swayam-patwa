import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/baba_page_post_model.dart';

class BabaPagePostService {
  static const String baseUrl = 'http://103.14.120.163:8081/api';

  /// Create a post for a Baba Ji page (only creator can create posts)
  static Future<BabaPagePostResponse> createBabaPagePost({
    required String babaPageId,
    required String content,
    required List<File> mediaFiles,
    required String token,
  }) async {
    try {
      print('BabaPagePostService: Creating post for Baba Ji page: $babaPageId');
      
      // First, verify that the user is the creator of the page
      final creatorCheck = await _verifyPageCreator(babaPageId, token);
      if (!creatorCheck['success']) {
        return BabaPagePostResponse(
          success: false,
          message: creatorCheck['message'] ?? 'Access denied',
        );
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/baba-pages/$babaPageId/posts'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add content
      request.fields['content'] = content;

      // Add media files
      for (int i = 0; i < mediaFiles.length; i++) {
        var file = mediaFiles[i];
        var multipartFile = await http.MultipartFile.fromPath(
          'media',
          file.path,
          filename: 'post_${DateTime.now().millisecondsSinceEpoch}_$i.${file.path.split('.').last}',
        );
        request.files.add(multipartFile);
      }

      print('BabaPagePostService: Sending request with ${mediaFiles.length} media files');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('BabaPagePostService: Response status: ${response.statusCode}');
      print('BabaPagePostService: Response body: ${response.body}');
      print('BabaPagePostService: Response headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return BabaPagePostResponse.fromJson(jsonResponse);
      } else {
        final jsonResponse = jsonDecode(response.body);
        return BabaPagePostResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to create post',
        );
      }
    } catch (e) {
      print('BabaPagePostService: Error creating post: $e');
      return BabaPagePostResponse(
        success: false,
        message: 'Error creating post: $e',
      );
    }
  }

  /// Get posts for a Baba Ji page
  static Future<BabaPagePostListResponse> getBabaPagePosts({
    required String babaPageId,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('BabaPagePostService: Fetching posts for Baba Ji page: $babaPageId');
      print('BabaPagePostService: Using token: ${token.substring(0, 20)}...');
      print('BabaPagePostService: Request URL: $baseUrl/baba-pages/$babaPageId/posts?page=$page&limit=$limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/baba-pages/$babaPageId/posts?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaPagePostService: Response status: ${response.statusCode}');
      print('BabaPagePostService: Response headers: ${response.headers}');
      print('BabaPagePostService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('BabaPagePostService: Parsed JSON response: $jsonResponse');
          
          final result = BabaPagePostListResponse.fromJson(jsonResponse);
          print('BabaPagePostService: Parsed result - Success: ${result.success}, Posts count: ${result.posts.length}');
          
          return result;
        } catch (e) {
          print('BabaPagePostService: Error parsing JSON response: $e');
          print('BabaPagePostService: Response body: ${response.body}');
          return BabaPagePostListResponse(
            success: false,
            message: 'Error parsing response: $e',
            posts: [],
          );
        }
      } else {
        print('BabaPagePostService: HTTP Error ${response.statusCode}');
        try {
          final jsonResponse = jsonDecode(response.body);
          print('BabaPagePostService: Error response: $jsonResponse');
          return BabaPagePostListResponse(
            success: false,
            message: jsonResponse['message'] ?? 'Failed to fetch posts',
            posts: [],
          );
        } catch (e) {
          print('BabaPagePostService: Error parsing error response: $e');
          return BabaPagePostListResponse(
            success: false,
            message: 'Failed to fetch posts: HTTP ${response.statusCode}',
            posts: [],
          );
        }
      }
    } catch (e) {
      print('BabaPagePostService: Error fetching posts: $e');
      print('BabaPagePostService: Stack trace: ${StackTrace.current}');
      return BabaPagePostListResponse(
        success: false,
        message: 'Error fetching posts: $e',
        posts: [],
      );
    }
  }


  /// Delete a Baba Ji page post (only creator can delete)
  static Future<BabaPagePostResponse> deleteBabaPagePost({
    required String babaPageId,
    required String postId,
    required String token,
  }) async {
    try {
      print('BabaPagePostService: Deleting post: $postId from page: $babaPageId');
      
      // First, verify that the user is the creator of the page
      final creatorCheck = await _verifyPageCreator(babaPageId, token);
      if (!creatorCheck['success']) {
        return BabaPagePostResponse(
          success: false,
          message: creatorCheck['message'] ?? 'Access denied',
        );
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/baba-pages/$babaPageId/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaPagePostService: Delete response status: ${response.statusCode}');
      print('BabaPagePostService: Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return BabaPagePostResponse.fromJson(jsonResponse);
      } else {
        final jsonResponse = jsonDecode(response.body);
        return BabaPagePostResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to delete post',
        );
      }
    } catch (e) {
      print('BabaPagePostService: Error deleting post: $e');
      return BabaPagePostResponse(
        success: false,
        message: 'Error deleting post: $e',
      );
    }
  }

  /// Verify that the current user is the creator of the page
  static Future<Map<String, dynamic>> _verifyPageCreator(String babaPageId, String token) async {
    try {
      // Get the page details
      final response = await http.get(
        Uri.parse('$baseUrl/baba-pages/$babaPageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Page not found or access denied',
        };
      }

      final jsonResponse = jsonDecode(response.body);
      if (!jsonResponse['success'] || jsonResponse['data'] == null) {
        return {
          'success': false,
          'message': 'Page not found',
        };
      }

      final pageData = jsonResponse['data'];
      final pageCreatorId = pageData['creatorId'] ?? pageData['creator'] ?? pageData['createdBy'];

      // Extract user ID from JWT token
      final userId = _extractUserIdFromToken(token);
      if (userId == null) {
        return {
          'success': false,
          'message': 'Invalid authentication token',
        };
      }

      // Check if current user is the creator
      if (pageCreatorId != userId) {
        return {
          'success': false,
          'message': 'Only the page creator can perform this action',
        };
      }

      return {'success': true};
    } catch (e) {
      print('BabaPagePostService: Error verifying page creator: $e');
      return {
        'success': false,
        'message': 'Error verifying permissions',
      };
    }
  }

  /// Extract user ID from JWT token
  static String? _extractUserIdFromToken(String token) {
    try {
      // JWT tokens have 3 parts separated by dots
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed
      final paddedPayload = payload + '=' * (4 - payload.length % 4);
      final decoded = utf8.decode(base64Url.decode(paddedPayload));
      final payloadJson = jsonDecode(decoded);
      
      return payloadJson['userId'] as String?;
    } catch (e) {
      print('BabaPagePostService: Error extracting user ID from token: $e');
      return null;
    }
  }
}
