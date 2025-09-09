import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_model.dart';
import '../models/media_model.dart';

class LocalStoryService {
  static const String _storiesKey = 'local_stories';
  
  /// Store a story locally
  static Future<bool> storeStoryLocally(Story story) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStoriesJson = prefs.getStringList(_storiesKey) ?? [];
      
      // Add new story
      existingStoriesJson.add(jsonEncode(story.toJson()));
      
      // Store back to preferences
      await prefs.setStringList(_storiesKey, existingStoriesJson);
      
      print('LocalStoryService: Story stored locally: ${story.id}');
      return true;
    } catch (e) {
      print('LocalStoryService: Error storing story locally: $e');
      return false;
    }
  }
  
  /// Get all locally stored stories
  static Future<List<Story>> getLocalStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = prefs.getStringList(_storiesKey) ?? [];
      
      List<Story> stories = [];
      for (final storyJson in storiesJson) {
        try {
          final storyData = jsonDecode(storyJson);
          stories.add(Story.fromJson(storyData));
        } catch (e) {
          print('LocalStoryService: Error parsing local story: $e');
        }
      }
      
      print('LocalStoryService: Retrieved ${stories.length} local stories');
      return stories;
    } catch (e) {
      print('LocalStoryService: Error getting local stories: $e');
      return [];
    }
  }
  
  /// Create a story from media data
  static Story createStoryFromMedia({
    required MediaData mediaData,
    required String authorId,
    required String authorName,
    required String authorUsername,
    String? authorAvatar,
  }) {
    return Story(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      media: mediaData.secureUrl,
      mediaId: mediaData.id,
      type: mediaData.resourceType,
      mentions: [],
      hashtags: [],
      isActive: true,
      views: [],
      viewsCount: 0,
      expiresAt: DateTime.now().add(const Duration(hours: 24)), // Stories expire in 24 hours
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a story from media data with user profile
  static Story createStoryFromMediaWithUser({
    required MediaData mediaData,
    required String token,
  }) {
    // For now, return a story with placeholder user data
    // In a real app, you'd get this from the auth provider
    return Story(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'local_user_${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'Your Story',
      authorUsername: 'you',
      authorAvatar: null,
      media: mediaData.secureUrl,
      mediaId: mediaData.id,
      type: mediaData.resourceType,
      mentions: [],
      hashtags: [],
      isActive: true,
      views: [],
      viewsCount: 0,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Clear all local stories
  static Future<bool> clearLocalStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storiesKey);
      print('LocalStoryService: All local stories cleared');
      return true;
    } catch (e) {
      print('LocalStoryService: Error clearing local stories: $e');
      return false;
    }
  }
}
