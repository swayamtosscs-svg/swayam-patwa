import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';

class FeedCacheService {
  static const String _cachedPostsKey = 'feed_cached_posts';
  static const String _cachedStoriesKey = 'feed_cached_stories';
  static const String _cachedPostsTimeKey = 'feed_cached_posts_time';
  static const String _cachedStoriesTimeKey = 'feed_cached_stories_time';
  static const String _cachedUserIdKey = 'feed_cached_user_id';
  static const Duration _cacheExpiryDuration = Duration(hours: 24); // Cache for 24 hours

  /// Save posts to persistent cache with user ID
  static Future<void> cachePosts(List<Post> posts, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = posts.map((post) => post.toJson()).toList();
      
      await prefs.setString(_cachedPostsKey, jsonEncode(postsJson));
      await prefs.setString(_cachedPostsTimeKey, DateTime.now().toIso8601String());
      
      // Store user ID if provided
      if (userId != null) {
        await prefs.setString(_cachedUserIdKey, userId);
      }
      
      print('FeedCacheService: Cached ${posts.length} posts for user: $userId');
    } catch (e) {
      print('FeedCacheService: Error caching posts: $e');
    }
  }

  /// Save stories to persistent cache with user ID
  static Future<void> cacheStories(Map<String, List<Story>> groupedStories, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert Map<String, List<Story>> to JSON-serializable format
      final Map<String, dynamic> storiesJson = {};
      groupedStories.forEach((key, stories) {
        storiesJson[key] = stories.map((story) => story.toJson()).toList();
      });
      
      await prefs.setString(_cachedStoriesKey, jsonEncode(storiesJson));
      await prefs.setString(_cachedStoriesTimeKey, DateTime.now().toIso8601String());
      
      // Store user ID if provided
      if (userId != null) {
        await prefs.setString(_cachedUserIdKey, userId);
      }
      
      print('FeedCacheService: Cached ${groupedStories.length} story groups for user: $userId');
    } catch (e) {
      print('FeedCacheService: Error caching stories: $e');
    }
  }

  /// Get cached posts if not expired and matches current user
  static Future<List<Post>?> getCachedPosts({String? currentUserId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString(_cachedPostsKey);
      final cacheTimeStr = prefs.getString(_cachedPostsTimeKey);
      final cachedUserId = prefs.getString(_cachedUserIdKey);
      
      if (postsJson == null || cacheTimeStr == null) {
        print('FeedCacheService: No cached posts found');
        return null;
      }
      
      // Check if user ID matches
      if (currentUserId != null && cachedUserId != null && cachedUserId != currentUserId) {
        print('FeedCacheService: User ID mismatch. Cached: $cachedUserId, Current: $currentUserId. Clearing cache.');
        await clearCachedPosts();
        return null;
      }
      
      // Check if cache is expired
      final cacheTime = DateTime.parse(cacheTimeStr);
      if (DateTime.now().difference(cacheTime) > _cacheExpiryDuration) {
        print('FeedCacheService: Cached posts expired');
        await clearCachedPosts();
        return null;
      }
      
      final List<dynamic> postsList = jsonDecode(postsJson);
      final posts = postsList.map((postJson) => Post.fromJson(postJson)).toList();
      
      print('FeedCacheService: Retrieved ${posts.length} cached posts for user: $currentUserId');
      return posts;
    } catch (e) {
      print('FeedCacheService: Error getting cached posts: $e');
      return null;
    }
  }

  /// Get cached stories if not expired and matches current user
  static Future<Map<String, List<Story>>?> getCachedStories({String? currentUserId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = prefs.getString(_cachedStoriesKey);
      final cacheTimeStr = prefs.getString(_cachedStoriesTimeKey);
      final cachedUserId = prefs.getString(_cachedUserIdKey);
      
      if (storiesJson == null || cacheTimeStr == null) {
        print('FeedCacheService: No cached stories found');
        return null;
      }
      
      // Check if user ID matches
      if (currentUserId != null && cachedUserId != null && cachedUserId != currentUserId) {
        print('FeedCacheService: User ID mismatch for stories. Cached: $cachedUserId, Current: $currentUserId. Clearing cache.');
        await clearCachedStories();
        return null;
      }
      
      // Check if cache is expired
      final cacheTime = DateTime.parse(cacheTimeStr);
      if (DateTime.now().difference(cacheTime) > _cacheExpiryDuration) {
        print('FeedCacheService: Cached stories expired');
        await clearCachedStories();
        return null;
      }
      
      final Map<String, dynamic> storiesMap = jsonDecode(storiesJson);
      final Map<String, List<Story>> groupedStories = {};
      
      storiesMap.forEach((key, storiesList) {
        groupedStories[key] = (storiesList as List)
            .map((storyJson) => Story.fromJson(storyJson))
            .toList();
      });
      
      print('FeedCacheService: Retrieved ${groupedStories.length} cached story groups for user: $currentUserId');
      return groupedStories;
    } catch (e) {
      print('FeedCacheService: Error getting cached stories: $e');
      return null;
    }
  }

  /// Clear cached posts
  static Future<void> clearCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedPostsKey);
      await prefs.remove(_cachedPostsTimeKey);
      print('FeedCacheService: Cleared cached posts');
    } catch (e) {
      print('FeedCacheService: Error clearing cached posts: $e');
    }
  }

  /// Clear cached stories
  static Future<void> clearCachedStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedStoriesKey);
      await prefs.remove(_cachedStoriesTimeKey);
      print('FeedCacheService: Cleared cached stories');
    } catch (e) {
      print('FeedCacheService: Error clearing cached stories: $e');
    }
  }

  /// Clear user ID from cache
  static Future<void> clearUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUserIdKey);
      print('FeedCacheService: Cleared cached user ID');
    } catch (e) {
      print('FeedCacheService: Error clearing cached user ID: $e');
    }
  }

  /// Clear all cached feed data
  static Future<void> clearAllCache() async {
    await clearCachedPosts();
    await clearCachedStories();
    await clearUserId();
  }

  /// Check if posts cache is valid
  static Future<bool> hasCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeStr = prefs.getString(_cachedPostsTimeKey);
      
      if (cacheTimeStr == null) return false;
      
      final cacheTime = DateTime.parse(cacheTimeStr);
      return DateTime.now().difference(cacheTime) <= _cacheExpiryDuration;
    } catch (e) {
      return false;
    }
  }

  /// Check if stories cache is valid
  static Future<bool> hasCachedStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeStr = prefs.getString(_cachedStoriesTimeKey);
      
      if (cacheTimeStr == null) return false;
      
      final cacheTime = DateTime.parse(cacheTimeStr);
      return DateTime.now().difference(cacheTime) <= _cacheExpiryDuration;
    } catch (e) {
      return false;
    }
  }
}

