import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

class LocalStorageService {
  static const String _postsKey = 'user_posts';
  static const String _reelsKey = 'user_reels';

  /// Save a post locally
  static Future<void> savePost(Post post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPosts = await getUserPosts();
      
      // Add the new post to the beginning of the list
      existingPosts.insert(0, post);
      
      // Keep only the last 50 posts to avoid storage issues
      if (existingPosts.length > 50) {
        existingPosts.removeRange(50, existingPosts.length);
      }
      
      final postsJson = existingPosts.map((post) => post.toJson()).toList();
      await prefs.setString(_postsKey, jsonEncode(postsJson));
    } catch (e) {
      print('Error saving post locally: $e');
    }
  }

  /// Save a reel locally
  static Future<void> saveReel(Post reel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingReels = await getUserReels();
      
      // Add the new reel to the beginning of the list
      existingReels.insert(0, reel);
      
      // Keep only the last 50 reels to avoid storage issues
      if (existingReels.length > 50) {
        existingReels.removeRange(50, existingReels.length);
      }
      
      final reelsJson = existingReels.map((reel) => reel.toJson()).toList();
      await prefs.setString(_reelsKey, jsonEncode(reelsJson));
    } catch (e) {
      print('Error saving reel locally: $e');
    }
  }

  /// Get user's posts from local storage
  static Future<List<Post>> getUserPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      if (postsString == null) return [];
      
      final postsJson = jsonDecode(postsString) as List<dynamic>;
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('Error loading posts from local storage: $e');
      return [];
    }
  }

  /// Get user's reels from local storage
  static Future<List<Post>> getUserReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reelsString = prefs.getString(_reelsKey);
      
      if (reelsString == null) return [];
      
      final reelsJson = jsonDecode(reelsString) as List<dynamic>;
      return reelsJson.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('Error loading reels from local storage: $e');
      return [];
    }
  }

  /// Get all user's content (posts + reels)
  static Future<List<Post>> getAllUserContent() async {
    try {
      final posts = await getUserPosts();
      final reels = await getUserReels();
      
      final allContent = [...posts, ...reels];
      
      // Sort by creation date (newest first)
      allContent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allContent;
    } catch (e) {
      print('Error loading all user content: $e');
      return [];
    }
  }

  /// Clear all local data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_postsKey);
      await prefs.remove(_reelsKey);
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }
}
