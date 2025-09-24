import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/baba_page_comment_model.dart';

class BabaCommentService {
  static const String _baseUrl = 'https://api-rgram1.vercel.app/api';
  static const String _backupUrl = 'https://103.14.120.163:8081/api';

  /// Add a comment to a Baba Ji post using new API
  static Future<Map<String, dynamic>?> addComment({
    required String userId,
    required String postId,
    required String babaPageId,
    required String content,
    String? token,
  }) async {
    try {
      // Map current user to a working user ID in comment system
      // This is a temporary solution until user sync is implemented
      final effectiveUserId = _getEffectiveUserId(userId);
      final url = Uri.parse('$_baseUrl/comments/send?userId=$effectiveUserId');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'userId': effectiveUserId,
          'postId': postId,
          'content': content,
        }),
      );

      print('BabaCommentService: Add comment - URL: $url');
      print('BabaCommentService: Add comment - PostId: $postId, Original UserId: $userId, Effective UserId: $effectiveUserId');
      print('BabaCommentService: Add comment response status: ${response.statusCode}');
      print('BabaCommentService: Add comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
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

  /// Add a comment to a Baba Ji reel using new API
  static Future<Map<String, dynamic>?> addReelComment({
    required String userId,
    required String reelId,
    required String babaPageId,
    required String content,
    String? token,
  }) async {
    try {
      // Map current user to a working user ID in comment system
      final effectiveUserId = _getEffectiveUserId(userId);
      final url = Uri.parse('$_baseUrl/comments/send?userId=$effectiveUserId');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'userId': effectiveUserId,
          'postId': reelId, // Treating reel as post for API compatibility
          'content': content,
        }),
      );

      print('BabaCommentService: Add reel comment - URL: $url');
      print('BabaCommentService: Add reel comment - ReelId: $reelId, Original UserId: $userId, Effective UserId: $effectiveUserId');
      print('BabaCommentService: Add reel comment response status: ${response.statusCode}');
      print('BabaCommentService: Add reel comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
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

  /// Get comments for a Baba Ji post using new API
  static Future<BabaPageCommentResponse> getComments({
    required String postId,
    required String babaPageId,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Use the new comment receive API
      final url = Uri.parse('$_baseUrl/comments/receive?postId=$postId&sortBy=createdAt&sortOrder=asc&limit=$limit');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        url,
        headers: headers,
      );

      print('BabaCommentService: Get comments - URL: $url');
      print('BabaCommentService: Get comments response status: ${response.statusCode}');
      print('BabaCommentService: Get comments response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('BabaCommentService: Parsed response data: $data');
          final commentResponse = BabaPageCommentResponse.fromJson(data);
          print('BabaCommentService: Comment response - success: ${commentResponse.success}, comments count: ${commentResponse.comments.length}');
          return commentResponse;
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

  /// Get comments for a Baba Ji reel using new API
  static Future<BabaPageCommentResponse> getReelComments({
    required String reelId,
    required String babaPageId,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Use the new comment receive API for reels
      final url = Uri.parse('$_baseUrl/comments/receive?postId=$reelId&sortBy=createdAt&sortOrder=asc&limit=$limit');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(
        url,
        headers: headers,
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

  /// Delete a comment using new API
  static Future<Map<String, dynamic>?> deleteComment({
    required String commentId,
    required String userId,
    String? token,
  }) async {
    try {
      // Map current user to a working user ID in comment system
      final effectiveUserId = _getEffectiveUserId(userId);
      final url = Uri.parse('$_baseUrl/comments/delete?commentId=$commentId&userId=$effectiveUserId');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.delete(
        url,
        headers: headers,
      );

      print('BabaCommentService: Delete comment - URL: $url');
      print('BabaCommentService: Delete comment - CommentId: $commentId, Original UserId: $userId, Effective UserId: $effectiveUserId');
      print('BabaCommentService: Delete comment response status: ${response.statusCode}');
      print('BabaCommentService: Delete comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaCommentService: Failed to delete comment: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaCommentService: Error deleting comment: $e');
      return null;
    }
  }

  /// Debug method to test comment API endpoints
  static Future<void> debugCommentEndpoints({
    required String postId,
    required String babaPageId,
    String? token,
  }) async {
    print('BabaCommentService: Debug - Testing comment endpoints');
    print('BabaCommentService: Debug - PostId: $postId, BabaPageId: $babaPageId');
    
    try {
      // Test getting comments
      final commentsResponse = await getComments(
        postId: postId,
        babaPageId: babaPageId,
        token: token,
      );
      
      print('BabaCommentService: Debug - Comments response success: ${commentsResponse.success}');
      print('BabaCommentService: Debug - Comments count: ${commentsResponse.comments.length}');
      print('BabaCommentService: Debug - Comments message: ${commentsResponse.message}');
      
      if (commentsResponse.comments.isNotEmpty) {
        print('BabaCommentService: Debug - First comment: ${commentsResponse.comments.first.toJson()}');
      }
      
    } catch (e) {
      print('BabaCommentService: Debug - Error: $e');
    }
  }

  /// Fallback method to try backup URL if primary fails
  static Future<Map<String, dynamic>?> addCommentWithFallback({
    required String userId,
    required String postId,
    required String babaPageId,
    required String content,
    String? token,
  }) async {
    try {
      // Try primary URL first
      final result = await addComment(
        userId: userId,
        postId: postId,
        babaPageId: babaPageId,
        content: content,
        token: token,
      );
      
      if (result != null && result['success'] == true) {
        return result;
      }
      
      // If primary fails, try backup URL
      print('BabaCommentService: Primary URL failed, trying backup URL');
      final effectiveUserId = _getEffectiveUserId(userId);
      final backupUrl = Uri.parse('$_backupUrl/comments/send?userId=$effectiveUserId');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.post(
        backupUrl,
        headers: headers,
        body: jsonEncode({
          'userId': effectiveUserId,
          'postId': postId,
          'content': content,
        }),
      );

      print('BabaCommentService: Backup URL response status: ${response.statusCode}');
      print('BabaCommentService: Backup URL response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaCommentService: Backup URL also failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaCommentService: Error with fallback: $e');
      return null;
    }
  }

  /// Helper method to get effective user ID for comment system
  /// Maps current app users to working users in comment system
  static String _getEffectiveUserId(String originalUserId) {
    // Map current user to a working user ID in comment system
    // TODO: Implement proper user creation/sync in comment system
    if (originalUserId == '68c98967a921a001da9787b3') {
      return '68b53b03f09b98a6dcded481'; // Map dhani to working test user
    }
    return originalUserId; // Use original ID for other users
  }
}
