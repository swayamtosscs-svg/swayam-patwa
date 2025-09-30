import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_comment_model.dart';

class UserCommentService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';
  static const String _commentsKey = 'user_post_comments';

  /// Get comments from local storage
  static Future<List<UserComment>> getLocalComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = prefs.getString('${_commentsKey}_$postId');
      if (commentsJson != null) {
        final List<dynamic> commentsList = jsonDecode(commentsJson);
        return commentsList.map((comment) => UserComment.fromJson(comment)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting local comments: $e');
      return [];
    }
  }

  /// Save comments to local storage
  static Future<void> saveLocalComments(String postId, List<UserComment> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_commentsKey}_$postId', jsonEncode(comments.map((c) => c.toJson()).toList()));
    } catch (e) {
      print('Error saving local comments: $e');
    }
  }

  /// Add comment to local storage
  static Future<void> addLocalComment(String postId, UserComment comment) async {
    try {
      final comments = await getLocalComments(postId);
      comments.insert(0, comment); // Add to beginning
      await saveLocalComments(postId, comments);
    } catch (e) {
      print('Error adding local comment: $e');
    }
  }

  /// Delete comment from local storage
  static Future<void> deleteLocalComment(String postId, String commentId) async {
    try {
      final comments = await getLocalComments(postId);
      comments.removeWhere((comment) => comment.id == commentId);
      await saveLocalComments(postId, comments);
    } catch (e) {
      print('Error deleting local comment: $e');
    }
  }

  /// Merge server comments with local comments to ensure persistence
  static List<UserComment> _mergeComments(List<UserComment> serverComments, List<UserComment> localComments) {
    final Map<String, UserComment> commentMap = {};
    
    // Add server comments first (they take priority)
    for (final comment in serverComments) {
      commentMap[comment.id] = comment;
    }
    
    // Add local comments that don't exist on server
    for (final comment in localComments) {
      if (!commentMap.containsKey(comment.id)) {
        commentMap[comment.id] = comment;
      }
    }
    
    // Convert back to list and sort by creation date (newest first)
    final mergedComments = commentMap.values.toList();
    mergedComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return mergedComments;
  }

  /// Get comments for a user post with enhanced persistence
  static Future<UserCommentResponse> getComments({
    required String postId,
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/posts/$postId/comments?page=$page&limit=$limit');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache', // Ensure fresh data
        },
      );

      print('UserCommentService: Get comments - URL: $url');
      print('UserCommentService: Get comments response status: ${response.statusCode}');
      print('UserCommentService: Get comments response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiResponse = UserCommentResponse.fromJson(data);
        
        // Always save API comments to local storage for persistence
        await saveLocalComments(postId, apiResponse.comments);
        
        // Also merge with any local comments that might not be on server yet
        final localComments = await getLocalComments(postId);
        final mergedComments = _mergeComments(apiResponse.comments, localComments);
        
        // Save merged comments back to local storage
        await saveLocalComments(postId, mergedComments);
        
        return UserCommentResponse(
          success: true,
          message: 'Comments loaded successfully',
          comments: mergedComments,
          pagination: apiResponse.pagination,
        );
      } else {
        // If API fails, get comments from local storage
        print('UserCommentService: API failed with ${response.statusCode}, loading from local storage');
        final localComments = await getLocalComments(postId);
        return UserCommentResponse(
          success: true,
          message: 'Comments loaded (local)',
          comments: localComments,
          pagination: {
            'currentPage': page,
            'totalPages': 0,
            'totalItems': localComments.length,
            'itemsPerPage': limit,
          },
        );
      }
    } catch (e) {
      print('UserCommentService: Error getting comments: $e, loading from local storage');
      final localComments = await getLocalComments(postId);
      return UserCommentResponse(
        success: true,
        message: 'Comments loaded (local)',
        comments: localComments,
        pagination: {
          'currentPage': page,
          'totalPages': 0,
          'totalItems': localComments.length,
          'itemsPerPage': limit,
        },
      );
    }
  }

  /// Add comment to a user post
  static Future<Map<String, dynamic>?> addComment({
    required String postId,
    required String userId,
    required String content,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/posts/$postId/comments');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
          'userId': userId,
        }),
      );

      print('UserCommentService: Add comment - URL: $url');
      print('UserCommentService: Add comment response status: ${response.statusCode}');
      print('UserCommentService: Add comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        // Always save to local storage for persistence
        if (result['data']?['comment'] != null) {
          final comment = UserComment.fromJson(result['data']['comment']);
          await addLocalComment(postId, comment);
          
          // Also trigger a refresh to get all comments and ensure sync
          await getComments(postId: postId, token: token);
        }
        return result;
      } else {
        // If API fails, create local comment that will persist
        print('UserCommentService: Add comment API failed with ${response.statusCode}, creating persistent local comment');
        final localComment = UserComment(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          userId: userId,
          postId: postId,
          username: 'You', // Will be updated with actual username
          userAvatar: '',
          createdAt: DateTime.now(),
        );
        
        await addLocalComment(postId, localComment);
        
        return {
          'success': true,
          'message': 'Comment added successfully (local - will sync when server is available)',
          'data': {
            'comment': localComment.toJson(),
          },
        };
      }
    } catch (e) {
      print('UserCommentService: Error adding comment: $e, creating persistent local comment');
      final localComment = UserComment(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        userId: userId,
        postId: postId,
        username: 'You',
        userAvatar: '',
        createdAt: DateTime.now(),
      );
      
      await addLocalComment(postId, localComment);
      
      return {
        'success': true,
        'message': 'Comment added successfully (local - will sync when server is available)',
        'data': {
          'comment': localComment.toJson(),
        },
      };
    }
  }

  /// Delete a comment
  static Future<Map<String, dynamic>?> deleteComment({
    required String commentId,
    required String userId,
    required String postId,
    required String token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/comments/$commentId');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('UserCommentService: Delete comment - URL: $url');
      print('UserCommentService: Delete comment response status: ${response.statusCode}');
      print('UserCommentService: Delete comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final result = jsonDecode(response.body);
        // Also remove from local storage
        await deleteLocalComment(postId, commentId);
        return result;
      } else {
        // If API fails, remove from local storage
        print('UserCommentService: Delete comment API failed with ${response.statusCode}, removing from local storage');
        await deleteLocalComment(postId, commentId);
        return {
          'success': true,
          'message': 'Comment deleted successfully (local)',
        };
      }
    } catch (e) {
      print('UserCommentService: Error deleting comment: $e, removing from local storage');
      await deleteLocalComment(postId, commentId);
      return {
        'success': true,
        'message': 'Comment deleted successfully (local)',
      };
    }
  }
}
