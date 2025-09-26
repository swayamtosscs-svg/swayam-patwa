import 'package:shared_preferences/shared_preferences.dart';
import '../models/baba_page_model.dart';

/// Service to manage follow states for Baba pages across the app
/// This ensures consistency and persistence of follow states
class FollowStateService {
  static const String _followStatePrefix = 'follow_';
  
  /// Get the follow state for a specific Baba page
  /// Returns the saved state if available, otherwise returns the server state
  static Future<bool> getFollowState({
    required String userId,
    required String pageId,
    bool serverState = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followKey = '$_followStatePrefix${userId}_$pageId';
      final savedState = prefs.getBool(followKey);
      
      // Return saved state if available, otherwise return server state
      return savedState ?? serverState;
    } catch (e) {
      print('FollowStateService: Error getting follow state: $e');
      return serverState;
    }
  }
  
  /// Save the follow state for a specific Baba page
  static Future<void> saveFollowState({
    required String userId,
    required String pageId,
    required bool isFollowing,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followKey = '$_followStatePrefix${userId}_$pageId';
      await prefs.setBool(followKey, isFollowing);
      print('FollowStateService: Saved follow state for page $pageId: $isFollowing');
    } catch (e) {
      print('FollowStateService: Error saving follow state: $e');
    }
  }
  
  /// Update BabaPage objects with correct follow states from SharedPreferences
  static Future<List<BabaPage>> updatePagesWithFollowStates({
    required List<BabaPage> pages,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedPages = <BabaPage>[];
      
      for (final page in pages) {
        final followKey = '$_followStatePrefix${userId}_${page.id}';
        final savedFollowState = prefs.getBool(followKey);
        
        // Use saved state if available, otherwise use server state
        final isFollowing = savedFollowState ?? page.isFollowing;
        
        updatedPages.add(page.copyWith(isFollowing: isFollowing));
      }
      
      return updatedPages;
    } catch (e) {
      print('FollowStateService: Error updating pages with follow states: $e');
      return pages; // Return original pages on error
    }
  }
  
  /// Clear all follow states for a specific user
  /// This is useful when user logs out
  static Future<void> clearUserFollowStates(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('$_followStatePrefix${userId}_')) {
          await prefs.remove(key);
        }
      }
      
      print('FollowStateService: Cleared all follow states for user $userId');
    } catch (e) {
      print('FollowStateService: Error clearing user follow states: $e');
    }
  }
  
  /// Get all followed page IDs for a specific user
  static Future<List<String>> getFollowedPageIds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final followedPageIds = <String>[];
      
      for (final key in keys) {
        if (key.startsWith('$_followStatePrefix${userId}_')) {
          final isFollowing = prefs.getBool(key);
          if (isFollowing == true) {
            // Extract page ID from key
            final pageId = key.substring('$_followStatePrefix${userId}_'.length);
            followedPageIds.add(pageId);
          }
        }
      }
      
      return followedPageIds;
    } catch (e) {
      print('FollowStateService: Error getting followed page IDs: $e');
      return [];
    }
  }
  
  /// Sync follow states with server data
  /// This method can be called periodically to ensure consistency
  static Future<List<BabaPage>> syncWithServerData({
    required List<BabaPage> serverPages,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedPages = <BabaPage>[];
      
      for (final page in serverPages) {
        final followKey = '$_followStatePrefix${userId}_${page.id}';
        final savedFollowState = prefs.getBool(followKey);
        
        // If we have a saved state, use it; otherwise use server state
        final isFollowing = savedFollowState ?? page.isFollowing;
        
        updatedPages.add(page.copyWith(isFollowing: isFollowing));
      }
      
      return updatedPages;
    } catch (e) {
      print('FollowStateService: Error syncing with server data: $e');
      return serverPages; // Return original pages on error
    }
  }
}
