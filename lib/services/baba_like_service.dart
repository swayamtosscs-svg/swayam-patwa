import 'dart:convert';
import 'package:http/http.dart' as http;

class BabaLikeService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';

  /// Like a Baba Ji post
  static Future<Map<String, dynamic>?> likeBabaPost({
    required String userId,
    required String postId,
    required String babaPageId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/like');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': postId, // Use the actual post ID, not babaPageId
          'contentType': 'post',
          'userId': userId,
          'action': 'like',
        }),
      );

      print('BabaLikeService: Like Baba Ji post - URL: $url');
      print('BabaLikeService: Like Baba Ji post - PostId: $postId, BabaPageId: $babaPageId, UserId: $userId');
      print('BabaLikeService: Like Baba Ji post response status: ${response.statusCode}');
      print('BabaLikeService: Like Baba Ji post response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaLikeService: Failed to like Baba Ji post: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaLikeService: Error liking Baba Ji post: $e');
      return null;
    }
  }

  /// Unlike a Baba Ji post
  static Future<Map<String, dynamic>?> unlikeBabaPost({
    required String userId,
    required String postId,
    required String babaPageId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/like');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': postId, // Use the actual post ID, not babaPageId
          'contentType': 'post',
          'userId': userId,
          'action': 'unlike',
        }),
      );

      print('BabaLikeService: Unlike Baba Ji post - URL: $url');
      print('BabaLikeService: Unlike Baba Ji post - PostId: $postId, BabaPageId: $babaPageId, UserId: $userId');
      print('BabaLikeService: Unlike Baba Ji post response status: ${response.statusCode}');
      print('BabaLikeService: Unlike Baba Ji post response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaLikeService: Failed to unlike Baba Ji post: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaLikeService: Error unliking Baba Ji post: $e');
      return null;
    }
  }

  /// Get like status for a Baba Ji post
  static Future<Map<String, dynamic>?> getBabaPostLikeStatus({
    required String userId,
    required String postId,
    required String babaPageId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/like?contentId=$postId&contentType=post&userId=$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('BabaLikeService: Get like status - URL: $url');
      print('BabaLikeService: Get like status response status: ${response.statusCode}');
      print('BabaLikeService: Get like status response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaLikeService: Failed to get like status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaLikeService: Error getting like status: $e');
      return null;
    }
  }

  /// Like a Baba Ji reel
  static Future<Map<String, dynamic>?> likeBabaReel({
    required String userId,
    required String reelId,
    required String babaPageId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/like');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': reelId, // Use the actual reel ID, not babaPageId
          'contentType': 'reel',
          'userId': userId,
          'action': 'like',
        }),
      );

      print('BabaLikeService: Like Baba Ji reel - URL: $url');
      print('BabaLikeService: Like Baba Ji reel - ReelId: $reelId, BabaPageId: $babaPageId, UserId: $userId');
      print('BabaLikeService: Like Baba Ji reel response status: ${response.statusCode}');
      print('BabaLikeService: Like Baba Ji reel response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaLikeService: Failed to like Baba Ji reel: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaLikeService: Error liking Baba Ji reel: $e');
      return null;
    }
  }

  /// Unlike a Baba Ji reel
  static Future<Map<String, dynamic>?> unlikeBabaReel({
    required String userId,
    required String reelId,
    required String babaPageId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/like');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': reelId, // Use the actual reel ID, not babaPageId
          'contentType': 'reel',
          'userId': userId,
          'action': 'unlike',
        }),
      );

      print('BabaLikeService: Unlike Baba Ji reel - URL: $url');
      print('BabaLikeService: Unlike Baba Ji reel - ReelId: $reelId, BabaPageId: $babaPageId, UserId: $userId');
      print('BabaLikeService: Unlike Baba Ji reel response status: ${response.statusCode}');
      print('BabaLikeService: Unlike Baba Ji reel response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaLikeService: Failed to unlike Baba Ji reel: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaLikeService: Error unliking Baba Ji reel: $e');
      return null;
    }
  }

  /// Get like status for a Baba Ji reel
  static Future<Map<String, dynamic>?> getBabaReelLikeStatus({
    required String userId,
    required String reelId,
    required String babaPageId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/baba-pages/$babaPageId/like?contentId=$reelId&contentType=reel&userId=$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('BabaLikeService: Get reel like status - URL: $url');
      print('BabaLikeService: Get reel like status response status: ${response.statusCode}');
      print('BabaLikeService: Get reel like status response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('BabaLikeService: Failed to get reel like status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('BabaLikeService: Error getting reel like status: $e');
      return null;
    }
  }
}
