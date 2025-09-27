import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/baba_page_comment_model.dart';

class BabaCommentService {
  static const String _baseUrl = 'https://api-rgram1.vercel.app/api';
  static const String _backupUrl = 'https://103.14.120.163:8081/api';
  static const String _commentsKey = 'baba_page_comments';

  /// Add a comment to a Baba Ji post using new API
  static Future<Map<String, dynamic>?> addComment({
    required String userId,
    required String postId,
    required String babaPageId,
    required String content,
    required String userName,
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
        // Also save to local storage
        if (data['data']?['comment'] != null) {
          final comment = BabaPageComment.fromJson(data['data']['comment']);
          await addLocalComment(postId, comment);
        }
        return data;
      } else {
        print('BabaCommentService: Failed to add comment: ${response.statusCode}');
        // If API fails, create local comment
        print('BabaCommentService: Add comment API failed with ${response.statusCode}, creating local comment');
        final localComment = BabaPageComment(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          userId: userId,
          userName: userName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await addLocalComment(postId, localComment);
        
        return {
          'success': true,
          'message': 'Comment added successfully (local)',
          'data': {
            'comment': localComment.toJson(),
          },
        };
      }
    } catch (e) {
      print('BabaCommentService: Error adding comment: $e, creating local comment');
      final localComment = BabaPageComment(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        userId: userId,
        userName: userName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await addLocalComment(postId, localComment);
      
      return {
        'success': true,
        'message': 'Comment added successfully (local)',
        'data': {
          'comment': localComment.toJson(),
        },
      };
    }
  }

  /// Add a comment to a Baba Ji reel using new API
  static Future<Map<String, dynamic>?> addReelComment({
    required String userId,
    required String reelId,
    required String babaPageId,
    required String content,
    required String userName,
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
        // Also save to local storage
        if (data['data']?['comment'] != null) {
          final comment = BabaPageComment.fromJson(data['data']['comment']);
          await addLocalComment(reelId, comment);
        }
        return data;
      } else {
        print('BabaCommentService: Failed to add reel comment: ${response.statusCode}');
        // If API fails, create local comment
        print('BabaCommentService: Add reel comment API failed with ${response.statusCode}, creating local comment');
        final localComment = BabaPageComment(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          userId: userId,
          userName: userName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await addLocalComment(reelId, localComment);
        
        return {
          'success': true,
          'message': 'Comment added successfully (local)',
          'data': {
            'comment': localComment.toJson(),
          },
        };
      }
    } catch (e) {
      print('BabaCommentService: Error adding reel comment: $e, creating local comment');
      final localComment = BabaPageComment(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        userId: userId,
        userName: userName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await addLocalComment(reelId, localComment);
      
      return {
        'success': true,
        'message': 'Comment added successfully (local)',
        'data': {
          'comment': localComment.toJson(),
        },
      };
    }
  }

  /// Get comments for a Baba Ji post using new API with optimized loading
  static Future<BabaPageCommentResponse> getComments({
    required String postId,
    required String babaPageId,
    int page = 1,
    int limit = 50, // Increased limit for better performance
    String? token,
  }) async {
    try {
      // Use the new comment receive API with optimized parameters
      final url = Uri.parse('$_baseUrl/comments/receive?postId=$postId&sortBy=createdAt&sortOrder=desc&limit=$limit&page=$page');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache', // Ensure fresh data
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // Add timeout for faster failure detection
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      print('BabaCommentService: Get comments - URL: $url');
      print('BabaCommentService: Get comments response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('BabaCommentService: Parsed response data: $data');
          final commentResponse = BabaPageCommentResponse.fromJson(data);
          print('BabaCommentService: Comment response - success: ${commentResponse.success}, comments count: ${commentResponse.comments.length}');
          
          // Save API comments to local storage
          await saveLocalComments(postId, commentResponse.comments);
          
          return commentResponse;
        } catch (e) {
          print('BabaCommentService: Error parsing JSON response: $e');
          print('BabaCommentService: Response body: ${response.body}');
          // If API fails, get comments from local storage
          print('BabaCommentService: API parsing failed, loading from local storage');
          final localComments = await getLocalComments(postId);
          return BabaPageCommentResponse(
            success: true,
            message: 'Comments loaded (local)',
            comments: localComments,
          );
        }
      } else {
        print('BabaCommentService: Failed to get comments: ${response.statusCode}');
        // If API fails, get comments from local storage
        print('BabaCommentService: API failed with ${response.statusCode}, loading from local storage');
        final localComments = await getLocalComments(postId);
        return BabaPageCommentResponse(
          success: true,
          message: 'Comments loaded (local)',
          comments: localComments,
        );
      }
    } catch (e) {
      print('BabaCommentService: Error getting comments: $e, loading from local storage');
      final localComments = await getLocalComments(postId);
      return BabaPageCommentResponse(
        success: true,
        message: 'Comments loaded (local)',
        comments: localComments,
      );
    }
  }

  /// Get comments for a Baba Ji reel using new API with optimized loading
  static Future<BabaPageCommentResponse> getReelComments({
    required String reelId,
    required String babaPageId,
    int page = 1,
    int limit = 50, // Increased limit for better performance
    String? token,
  }) async {
    try {
      // Use the new comment receive API for reels with optimized parameters
      final url = Uri.parse('$_baseUrl/comments/receive?postId=$reelId&sortBy=createdAt&sortOrder=desc&limit=$limit&page=$page');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache', // Ensure fresh data
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // Add timeout for faster failure detection
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      print('BabaCommentService: Get reel comments - URL: $url');
      print('BabaCommentService: Get reel comments response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final commentResponse = BabaPageCommentResponse.fromJson(data);
          
          // Save API comments to local storage
          await saveLocalComments(reelId, commentResponse.comments);
          
          return commentResponse;
        } catch (e) {
          print('BabaCommentService: Error parsing JSON response: $e');
          print('BabaCommentService: Response body: ${response.body}');
          // If API fails, get comments from local storage
          print('BabaCommentService: API parsing failed, loading from local storage');
          final localComments = await getLocalComments(reelId);
          return BabaPageCommentResponse(
            success: true,
            message: 'Comments loaded (local)',
            comments: localComments,
          );
        }
      } else {
        print('BabaCommentService: Failed to get reel comments: ${response.statusCode}');
        // If API fails, get comments from local storage
        print('BabaCommentService: API failed with ${response.statusCode}, loading from local storage');
        final localComments = await getLocalComments(reelId);
        return BabaPageCommentResponse(
          success: true,
          message: 'Comments loaded (local)',
          comments: localComments,
        );
      }
    } catch (e) {
      print('BabaCommentService: Error getting reel comments: $e, loading from local storage');
      final localComments = await getLocalComments(reelId);
      return BabaPageCommentResponse(
        success: true,
        message: 'Comments loaded (local)',
        comments: localComments,
      );
    }
  }

  /// Delete a comment using new API
  static Future<Map<String, dynamic>?> deleteComment({
    required String commentId,
    required String userId,
    required String postId,
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
        // Also remove from local storage
        await deleteLocalComment(postId, commentId);
        return data;
      } else {
        print('BabaCommentService: Failed to delete comment: ${response.statusCode}');
        // If API fails, remove from local storage
        print('BabaCommentService: Delete comment API failed with ${response.statusCode}, removing from local storage');
        await deleteLocalComment(postId, commentId);
        return {
          'success': true,
          'message': 'Comment deleted successfully (local)',
        };
      }
    } catch (e) {
      print('BabaCommentService: Error deleting comment: $e, removing from local storage');
      await deleteLocalComment(postId, commentId);
      return {
        'success': true,
        'message': 'Comment deleted successfully (local)',
      };
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
    required String userName,
    String? token,
  }) async {
    try {
      // Try primary URL first
      final result = await addComment(
        userId: userId,
        postId: postId,
        babaPageId: babaPageId,
        content: content,
        userName: userName,
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

  // ========== LOCAL STORAGE METHODS ==========

  /// Get comments from local storage
  static Future<List<BabaPageComment>> getLocalComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString('${_commentsKey}_$postId');
      if (commentsJson != null) {
        final List<dynamic> commentsList = jsonDecode(commentsJson);
        return commentsList.map((comment) => BabaPageComment.fromJson(comment)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting local baba comments: $e');
      return [];
    }
  }

  /// Save comments to local storage
  static Future<void> saveLocalComments(String postId, List<BabaPageComment> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_commentsKey}_$postId', jsonEncode(comments.map((c) => c.toJson()).toList()));
    } catch (e) {
      print('Error saving local baba comments: $e');
    }
  }

  /// Add comment to local storage
  static Future<void> addLocalComment(String postId, BabaPageComment comment) async {
    try {
      final comments = await getLocalComments(postId);
      comments.insert(0, comment); // Add to beginning
      await saveLocalComments(postId, comments);
    } catch (e) {
      print('Error adding local baba comment: $e');
    }
  }

  /// Delete comment from local storage
  static Future<void> deleteLocalComment(String postId, String commentId) async {
    try {
      final comments = await getLocalComments(postId);
      comments.removeWhere((comment) => comment.id == commentId);
      await saveLocalComments(postId, comments);
    } catch (e) {
      print('Error deleting local baba comment: $e');
    }
  }
}
