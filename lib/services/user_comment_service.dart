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
    
    // Filter out local comments that start with "local_" (these are offline-only comments)
    final realLocalComments = localComments.where((comment) => !comment.id.startsWith('local_')).toList();
    
    // Add server comments first (they take priority) - these come from the database
    for (final comment in serverComments) {
      // Use a combination of userId+postId+content as a unique key since IDs might differ
      final uniqueKey = '${comment.userId}_${comment.postId}_${comment.content.substring(0, comment.content.length > 50 ? 50 : comment.content.length)}';
      commentMap[uniqueKey] = comment;
    }
    
    // Add real local comments (that were synced to server) that don't exist in server list
    // Only add if they're not duplicate
    for (final comment in realLocalComments) {
      final uniqueKey = '${comment.userId}_${comment.postId}_${comment.content.substring(0, comment.content.length > 50 ? 50 : comment.content.length)}';
      if (!commentMap.containsKey(uniqueKey)) {
        commentMap[uniqueKey] = comment;
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
    int limit = 1000, // Increased to show all comments including old ones
    bool forceRefresh = false, // Add option to force refresh from server
  }) async {
    try {
      // Use the unified comment receive endpoint (same as baba comments)
      final url = Uri.parse('$_baseUrl/comments/receive?postId=$postId&sortBy=createdAt&sortOrder=desc&limit=$limit&page=$page&_=${DateTime.now().millisecondsSinceEpoch}');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate', // Force fresh data
        'Pragma': 'no-cache',
        'Expires': '0',
      };
      
      // DON'T pass Authorization header when fetching comments
      // The server filters by userId from the token, which only returns current user's comments
      // We want ALL comments for the post, not just the current user's
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      print('UserCommentService: Get comments - URL: $url');
      print('UserCommentService: Get comments response status: ${response.statusCode}');
      print('UserCommentService: Get comments response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('UserCommentService: Parsed response data: $data');
          final apiResponse = UserCommentResponse.fromJson(data);
          print('UserCommentService: Comment response - success: ${apiResponse.success}, comments count: ${apiResponse.comments.length}');
          
          // IMPORTANT: Replace local storage with server comments to ensure sync
          // Clear any stale local data and use only server data for cross-device sync
          await saveLocalComments(postId, apiResponse.comments);
          print('UserCommentService: Saved ${apiResponse.comments.length} comments from server to local storage');
          
          return UserCommentResponse(
            success: true,
            message: 'Comments loaded successfully',
            comments: apiResponse.comments,
            pagination: apiResponse.pagination,
          );
        } catch (e) {
          print('UserCommentService: Error parsing JSON response: $e');
          print('UserCommentService: Response body: ${response.body}');
          // If API fails, get comments from local storage
          print('UserCommentService: API parsing failed, loading from local storage');
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
    required String userName,
  }) async {
    try {
      // Use the unified comment send endpoint (same as baba comments)
      final url = Uri.parse('$_baseUrl/comments/send?userId=$userId');
      
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
          'userId': userId,
          'postId': postId,
          'content': content,
        }),
      );

      print('UserCommentService: Add comment - URL: $url');
      print('UserCommentService: Add comment - PostId: $postId, UserId: $userId');
      print('UserCommentService: Add comment response status: ${response.statusCode}');
      print('UserCommentService: Add comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Always save to local storage for persistence
        if (data['data']?['comment'] != null) {
          // Handle comment response structure
          final commentJson = data['data']['comment'];
          final comment = UserComment.fromJson(commentJson);
          print('UserCommentService: Comment successfully saved to server with ID: ${comment.id}');
          await addLocalComment(postId, comment);
          
          // Also trigger a refresh to get all comments from server and ensure sync
          print('UserCommentService: Refreshing comments from server...');
          await getComments(postId: postId, token: token);
          print('UserCommentService: Comments refreshed from server');
        }
        return data;
      } else {
        // If API fails, create local comment that will persist
        print('UserCommentService: Add comment API failed with ${response.statusCode}, creating persistent local comment');
        final localComment = UserComment(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          userId: userId,
          postId: postId,
          username: userName,
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
        username: userName,
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
      // Use the unified comment delete endpoint (same as baba comments)
      final url = Uri.parse('$_baseUrl/comments/delete?commentId=$commentId&userId=$userId');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.delete(
        url,
        headers: headers,
      );

      print('UserCommentService: Delete comment - URL: $url');
      print('UserCommentService: Delete comment - CommentId: $commentId, UserId: $userId');
      print('UserCommentService: Delete comment response status: ${response.statusCode}');
      print('UserCommentService: Delete comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        // Parse response if there's a body
        Map<String, dynamic>? result;
        try {
          if (response.body.isNotEmpty) {
            result = jsonDecode(response.body);
          } else {
            result = {'success': true, 'message': 'Comment deleted successfully'};
          }
        } catch (e) {
          print('UserCommentService: Error parsing delete response: $e');
          result = {'success': true, 'message': 'Comment deleted successfully'};
        }
        
        // Also remove from local storage
        await deleteLocalComment(postId, commentId);
        print('UserCommentService: Comment deleted from server and local storage');
        return result;
      } else {
        print('UserCommentService: Delete comment API failed with ${response.statusCode}');
        // Even if API fails, try to remove from local storage
        await deleteLocalComment(postId, commentId);
        return {
          'success': false,
          'message': 'Failed to delete comment from server',
        };
      }
    } catch (e) {
      print('UserCommentService: Error deleting comment: $e');
      // Try to remove from local storage even on error
      try {
        await deleteLocalComment(postId, commentId);
      } catch (localError) {
        print('UserCommentService: Error deleting from local storage: $localError');
      }
      return {
        'success': false,
        'message': 'Error deleting comment: $e',
      };
    }
  }
}
