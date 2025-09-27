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

  /// Like a user post
  static Future<Map<String, dynamic>> likeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    // Try multiple possible endpoints for liking posts
    final endpoints = [
      'http://103.14.120.163:8081/api/posts/$postId/like',
      'http://103.14.120.163:8081/api/feed/like/$postId',
      'http://103.14.120.163:8081/api/user/posts/$postId/like',
      'https://api-rgram1.vercel.app/api/posts/$postId/like',
    ];

    for (final endpoint in endpoints) {
      try {
        print('➡️ Trying like endpoint: $endpoint');
        
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contentId': postId,
            'contentType': 'post',
            'userId': userId,
            'action': 'like',
          }),
        );

        print('➡️ Like Post API - URL: $endpoint');
        print('➡️ Like Post API - PostId: $postId, UserId: $userId');
        print('➡️ Response status: ${response.statusCode}');
        print('➡️ Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final likedPosts = await getLikedPosts();
          likedPosts.add(postId);
          await saveLikedPosts(likedPosts);
          print('➡️ Like Post API succeeded with endpoint: $endpoint');
          return _safeDecode(response.body);
        } else if (response.statusCode == 404) {
          print('➡️ Like Post API: Endpoint $endpoint not found (404), trying next...');
          continue; // Try next endpoint
        } else {
          print('➡️ Like Post API: Endpoint $endpoint failed with ${response.statusCode}, trying next...');
          continue; // Try next endpoint
        }
      } catch (e) {
        print('➡️ Like Post API: Error with endpoint $endpoint: $e, trying next...');
        continue; // Try next endpoint
      }
    }

    // If all endpoints fail, use local fallback
    print('➡️ Like Post API: All endpoints failed, using local fallback');
    final likedPosts = await getLikedPosts();
    likedPosts.add(postId);
    await saveLikedPosts(likedPosts);
    return _fallbackLike(postId);
  }

  /// Unlike a user post
  static Future<Map<String, dynamic>> unlikeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    // Try multiple possible endpoints for unliking posts
    final endpoints = [
      'http://103.14.120.163:8081/api/posts/$postId/like',
      'http://103.14.120.163:8081/api/feed/like/$postId',
      'http://103.14.120.163:8081/api/user/posts/$postId/like',
      'https://api-rgram1.vercel.app/api/posts/$postId/like',
    ];

    for (final endpoint in endpoints) {
      try {
        print('➡️ Trying unlike endpoint: $endpoint');
        
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contentId': postId,
            'contentType': 'post',
            'userId': userId,
            'action': 'unlike',
          }),
        );

        print('➡️ Unlike Post API - URL: $endpoint');
        print('➡️ Unlike Post API - PostId: $postId, UserId: $userId');
        print('➡️ Response status: ${response.statusCode}');
        print('➡️ Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final likedPosts = await getLikedPosts();
          likedPosts.remove(postId);
          await saveLikedPosts(likedPosts);
          print('➡️ Unlike Post API succeeded with endpoint: $endpoint');
          return _safeDecode(response.body);
        } else if (response.statusCode == 404) {
          print('➡️ Unlike Post API: Endpoint $endpoint not found (404), trying next...');
          continue; // Try next endpoint
        } else {
          print('➡️ Unlike Post API: Endpoint $endpoint failed with ${response.statusCode}, trying next...');
          continue; // Try next endpoint
        }
      } catch (e) {
        print('➡️ Unlike Post API: Error with endpoint $endpoint: $e, trying next...');
        continue; // Try next endpoint
      }
    }

    // If all endpoints fail, use local fallback
    print('➡️ Unlike Post API: All endpoints failed, using local fallback');
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

  /// Local fallback like
  static Map<String, dynamic> _fallbackLike(String postId) {
    return {
      'success': true,
      'message': 'Post liked locally (API fallback)',
      'data': {'likesCount': 1},
    };
  }

  /// Local fallback unlike
  static Map<String, dynamic> _fallbackUnlike(String postId) {
    return {
      'success': true,
      'message': 'Post unliked locally (API fallback)',
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
