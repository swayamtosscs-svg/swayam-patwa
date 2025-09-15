import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/baba_page_post_model.dart';

class BabaPagePostService {
  static const String baseUrl = 'http://103.14.120.163:8081/api';

  /// Create a post for a Baba Ji page
  static Future<BabaPagePostResponse> createBabaPagePost({
    required String babaPageId,
    required String content,
    required List<File> mediaFiles,
    required String token,
  }) async {
    try {
      print('BabaPagePostService: Creating post for Baba Ji page: $babaPageId');
      
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/baba-pages/$babaPageId/posts?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('BabaPagePostService: Response status: ${response.statusCode}');
      print('BabaPagePostService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return BabaPagePostListResponse.fromJson(jsonResponse);
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
        try {
          final jsonResponse = jsonDecode(response.body);
          return BabaPagePostListResponse(
            success: false,
            message: jsonResponse['message'] ?? 'Failed to fetch posts',
            posts: [],
          );
        } catch (e) {
          return BabaPagePostListResponse(
            success: false,
            message: 'Failed to fetch posts: HTTP ${response.statusCode}',
            posts: [],
          );
        }
      }
    } catch (e) {
      print('BabaPagePostService: Error fetching posts: $e');
      return BabaPagePostListResponse(
        success: false,
        message: 'Error fetching posts: $e',
        posts: [],
      );
    }
  }


  /// Delete a Baba Ji page post
  static Future<BabaPagePostResponse> deleteBabaPagePost({
    required String babaPageId,
    required String postId,
    required String token,
  }) async {
    try {
      print('BabaPagePostService: Deleting post: $postId from page: $babaPageId');
      
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
}
