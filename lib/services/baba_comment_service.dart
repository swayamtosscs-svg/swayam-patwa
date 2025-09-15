import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/baba_page_comment_model.dart';

class BabaCommentService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';

  /// Add a comment to a Baba Ji post
  static Future<Map<String, dynamic>?> addComment({
    required String userId,
    required String postId,
    required String babaPageId,
    required String content,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/comments');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': postId,
          'contentType': 'post',
          'userId': userId,
          'content': content,
        }),
      );

      print('BabaCommentService: Add comment - URL: $url');
      print('BabaCommentService: Add comment - PostId: $postId, BabaPageId: $babaPageId, UserId: $userId');
      print('BabaCommentService: Add comment response status: ${response.statusCode}');
      print('BabaCommentService: Add comment response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaCommentService: Failed to add comment: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaCommentService: Error adding comment: $e');
      return null;
    }
  }

  /// Add a comment to a Baba Ji reel
  static Future<Map<String, dynamic>?> addReelComment({
    required String userId,
    required String reelId,
    required String babaPageId,
    required String content,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/comments');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': reelId,
          'contentType': 'reel',
          'userId': userId,
          'content': content,
        }),
      );

      print('BabaCommentService: Add reel comment - URL: $url');
      print('BabaCommentService: Add reel comment - ReelId: $reelId, BabaPageId: $babaPageId, UserId: $userId');
      print('BabaCommentService: Add reel comment response status: ${response.statusCode}');
      print('BabaCommentService: Add reel comment response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaCommentService: Failed to add reel comment: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaCommentService: Error adding reel comment: $e');
      return null;
    }
  }

  /// Get comments for a Baba Ji post
  static Future<BabaPageCommentResponse> getComments({
    required String postId,
    required String babaPageId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/comments?contentId=$postId&contentType=post&page=$page&limit=$limit');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('BabaCommentService: Get comments - URL: $url');
      print('BabaCommentService: Get comments response status: ${response.statusCode}');
      print('BabaCommentService: Get comments response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return BabaPageCommentResponse.fromJson(data);
        } catch (e) {
          print('BabaCommentService: Error parsing JSON response: $e');
          print('BabaCommentService: Response body: ${response.body}');
          return BabaPageCommentResponse(
            success: false,
            message: 'Error parsing response: $e',
            comments: [],
          );
        }
      } else {
        print('BabaCommentService: Failed to get comments: ${response.statusCode}');
        try {
          final data = jsonDecode(response.body);
          return BabaPageCommentResponse(
            success: false,
            message: data['message'] ?? 'Failed to load comments: ${response.statusCode}',
            comments: [],
          );
        } catch (e) {
          return BabaPageCommentResponse(
            success: false,
            message: 'Failed to load comments: HTTP ${response.statusCode}',
            comments: [],
          );
        }
      }
    } catch (e) {
      print('BabaCommentService: Error getting comments: $e');
      return BabaPageCommentResponse(
        success: false,
        message: 'Error loading comments: $e',
        comments: [],
      );
    }
  }

  /// Get comments for a Baba Ji reel
  static Future<BabaPageCommentResponse> getReelComments({
    required String reelId,
    required String babaPageId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/comments?contentId=$reelId&contentType=reel&page=$page&limit=$limit');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('BabaCommentService: Get reel comments - URL: $url');
      print('BabaCommentService: Get reel comments response status: ${response.statusCode}');
      print('BabaCommentService: Get reel comments response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return BabaPageCommentResponse.fromJson(data);
        } catch (e) {
          print('BabaCommentService: Error parsing JSON response: $e');
          print('BabaCommentService: Response body: ${response.body}');
          return BabaPageCommentResponse(
            success: false,
            message: 'Error parsing response: $e',
            comments: [],
          );
        }
      } else {
        print('BabaCommentService: Failed to get reel comments: ${response.statusCode}');
        try {
          final data = jsonDecode(response.body);
          return BabaPageCommentResponse(
            success: false,
            message: data['message'] ?? 'Failed to load reel comments: ${response.statusCode}',
            comments: [],
          );
        } catch (e) {
          return BabaPageCommentResponse(
            success: false,
            message: 'Failed to load reel comments: HTTP ${response.statusCode}',
            comments: [],
          );
        }
      }
    } catch (e) {
      print('BabaCommentService: Error getting reel comments: $e');
      return BabaPageCommentResponse(
        success: false,
        message: 'Error loading reel comments: $e',
        comments: [],
      );
    }
  }
}
