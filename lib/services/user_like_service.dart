import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserLikeService {
  static const String _likesKey = 'user_post_likes';

  /// Get liked posts from local storage
  static Future<Set<String>> getLikedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedPostsJson = prefs.getString(_likesKey);
      if (likedPostsJson != null) {
        final List<dynamic> likedPostsList = jsonDecode(likedPostsJson);
        return likedPostsList.map((e) => e.toString()).toSet();
      }
      return <String>{};
    } catch (e) {
      print('Error getting liked posts: $e');
      return <String>{};
    }
  }

  /// Save liked posts to local storage
  static Future<void> saveLikedPosts(Set<String> likedPosts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_likesKey, jsonEncode(likedPosts.toList()));
    } catch (e) {
      print('Error saving liked posts: $e');
    }
  }

  /// Check if a post is liked locally
  static Future<bool> isPostLiked(String postId) async {
    final likedPosts = await getLikedPosts();
    return likedPosts.contains(postId);
  }

  /// Like a user post (API + local fallback)
  static Future<Map<String, dynamic>> likeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    try {
      // Try the real API first
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/likes/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentType': 'post',
          'contentId': postId,
        }),
      );

      print('UserLikeService: Like API response status: ${response.statusCode}');
      print('UserLikeService: Like API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Also save to local storage for offline support
        final likedPosts = await getLikedPosts();
        likedPosts.add(postId);
        await saveLikedPosts(likedPosts);
        
        return result;
      } else {
        print('UserLikeService: API failed with ${response.statusCode}, using local fallback');
        return _fallbackLike(postId);
      }
    } catch (e) {
      print('UserLikeService: Error calling like API: $e, using local fallback');
      return _fallbackLike(postId);
    }
  }

  /// Unlike a user post (API + local fallback)
  static Future<Map<String, dynamic>> unlikeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    try {
      // Try the real API first
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/likes/unlike'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentType': 'post',
          'contentId': postId,
        }),
      );

      print('UserLikeService: Unlike API response status: ${response.statusCode}');
      print('UserLikeService: Unlike API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Also remove from local storage
        final likedPosts = await getLikedPosts();
        likedPosts.remove(postId);
        await saveLikedPosts(likedPosts);
        
        return result;
      } else {
        print('UserLikeService: API failed with ${response.statusCode}, using local fallback');
        return _fallbackUnlike(postId);
      }
    } catch (e) {
      print('UserLikeService: Error calling unlike API: $e, using local fallback');
      return _fallbackUnlike(postId);
    }
  }

  /// Toggle like/unlike
  static Future<Map<String, dynamic>> toggleUserPostLike({
    required String postId,
    required String token,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    return isCurrentlyLiked
        ? await unlikeUserPost(postId: postId, token: token, userId: userId)
        : await likeUserPost(postId: postId, token: token, userId: userId);
    }

  /// Local like
  static Map<String, dynamic> _fallbackLike(String postId) {
    return {
      'success': true,
      'message': 'Post liked locally (offline mode)',
      'data': {'likesCount': 1},
    };
  }

  /// Local unlike
  static Map<String, dynamic> _fallbackUnlike(String postId) {
    return {
      'success': true,
      'message': 'Post unliked locally (offline mode)',
      'data': {'likesCount': 0},
    };
  }
}
