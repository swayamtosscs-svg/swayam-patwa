import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserLikeService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api/feed';
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

  /// Like a user post (local only)
  static Future<Map<String, dynamic>> likeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    // Use local fallback only
    final likedPosts = await getLikedPosts();
    likedPosts.add(postId);
    await saveLikedPosts(likedPosts);
    return _fallbackLike(postId);
  }

  /// Unlike a user post (local only)
  static Future<Map<String, dynamic>> unlikeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    // Use local fallback only
    final likedPosts = await getLikedPosts();
    likedPosts.remove(postId);
    await saveLikedPosts(likedPosts);
    return _fallbackUnlike(postId);
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
      'message': 'Post liked locally',
      'data': {'likesCount': 1},
    };
  }

  /// Local unlike
  static Map<String, dynamic> _fallbackUnlike(String postId) {
    return {
      'success': true,
      'message': 'Post unliked locally',
      'data': {'likesCount': 0},
    };
  }

  /// Safe decode
  static Map<String, dynamic> _safeDecode(String body) {
    try {
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
