import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import 'feed_service.dart';

class RealtimeFeedService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';
  
  // Timer for periodic refresh
  static Timer? _refreshTimer;
  static bool _isServiceActive = false;
  
  // Callbacks for UI updates
  static Function(List<Post>)? onNewPostsDetected;
  static Function()? onRefreshStarted;
  static Function()? onRefreshCompleted;
  
  // Last check timestamp
  static DateTime? _lastCheckTime;
  static String? _lastPostId;
  
  // Configuration - DISABLED to prevent constant feed refresh
  static const Duration _refreshInterval = Duration(minutes: 2); // DISABLED - was causing constant refresh
  static const Duration _backgroundRefreshInterval = Duration(minutes: 5); // Background check every 5 minutes
  
  /// Start the real-time feed service (periodic refresh DISABLED to prevent constant feed refresh)
  static void startRealtimeService({
    required String token,
    required String currentUserId,
    Function(List<Post>)? onNewPosts,
    Function()? onRefreshStart,
    Function()? onRefreshComplete,
  }) {
    if (_isServiceActive) {
      print('RealtimeFeedService: Service already active');
      return;
    }
    
    print('RealtimeFeedService: Starting real-time feed service (periodic refresh DISABLED)');
    
    // Set callbacks
    onNewPostsDetected = onNewPosts;
    onRefreshStarted = onRefreshStart;
    onRefreshCompleted = onRefreshComplete;
    
    _isServiceActive = true;
    _lastCheckTime = DateTime.now();
    
    // Start periodic refresh (DISABLED to prevent constant feed refresh)
    _startPeriodicRefresh(token, currentUserId);
    
    // Set up background refresh listener
    _setupBackgroundRefresh(token, currentUserId);
  }
  
  /// Stop the real-time feed service
  static void stopRealtimeService() {
    if (!_isServiceActive) {
      return;
    }
    
    print('RealtimeFeedService: Stopping real-time feed service');
    
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isServiceActive = false;
    
    // Clear callbacks
    onNewPostsDetected = null;
    onRefreshStarted = null;
    onRefreshCompleted = null;
  }
  
  /// Start periodic refresh timer - DISABLED to prevent constant refresh
  static void _startPeriodicRefresh(String token, String currentUserId) {
    // DISABLED: Periodic refresh was causing constant feed refresh
    // Only refresh manually when user pulls to refresh or app resumes
    print('RealtimeFeedService: Periodic refresh DISABLED to prevent constant feed refresh');
    
    // Uncomment below lines if you want to re-enable periodic refresh
    // _refreshTimer = Timer.periodic(_refreshInterval, (timer) async {
    //   if (!_isServiceActive) {
    //     timer.cancel();
    //     return;
    //   }
    //   
    //   print('RealtimeFeedService: Periodic refresh triggered');
    //   await _checkForNewPosts(token, currentUserId);
    // });
  }
  
  /// Setup background refresh when app comes to foreground
  static void _setupBackgroundRefresh(String token, String currentUserId) {
    // This will be called when app lifecycle changes
    // Implementation depends on app lifecycle management
  }
  
  /// Check for new posts and notify if found
  static Future<void> _checkForNewPosts(String token, String currentUserId) async {
    try {
      print('RealtimeFeedService: Checking for new posts...');
      
      // Get latest posts (only first page to check for new content) - includes followed users + Baba Ji
      final latestPosts = await FeedService.getMixedFeedPosts(
        token: token,
        currentUserId: currentUserId,
        page: 1,
        limit: 5, // Only check first 5 posts for new content
      );
      
      if (latestPosts.isNotEmpty) {
        // Check if we have new posts by comparing with last known post
        final latestPost = latestPosts.first;
        final hasNewPosts = _lastPostId == null || latestPost.id != _lastPostId;
        
        if (hasNewPosts) {
          print('RealtimeFeedService: New posts detected!');
          
          // Update last known post ID
          _lastPostId = latestPost.id;
          _lastCheckTime = DateTime.now();
          
          // Notify UI about new posts
          if (onNewPostsDetected != null) {
            onNewPostsDetected!(latestPosts);
          }
        } else {
          print('RealtimeFeedService: No new posts found');
        }
      }
      
    } catch (e) {
      print('RealtimeFeedService: Error checking for new posts: $e');
    }
  }
  
  /// Force refresh the feed (called on pull-to-refresh)
  static Future<List<Post>> forceRefreshFeed({
    required String token,
    required String currentUserId,
  }) async {
    try {
      print('RealtimeFeedService: Force refreshing feed...');
      
      if (onRefreshStarted != null) {
        onRefreshStarted!();
      }
      
      // Clear cache and get fresh data
      await _clearFeedCache();
      
      // Get fresh posts - includes followed users + Baba Ji
      final freshPosts = await FeedService.getMixedFeedPosts(
        token: token,
        currentUserId: currentUserId,
        page: 1,
        limit: 10,
      );
      
      // Update last known post
      if (freshPosts.isNotEmpty) {
        _lastPostId = freshPosts.first.id;
        _lastCheckTime = DateTime.now();
      }
      
      if (onRefreshCompleted != null) {
        onRefreshCompleted!();
      }
      
      print('RealtimeFeedService: Force refresh completed with ${freshPosts.length} posts');
      return freshPosts;
      
    } catch (e) {
      print('RealtimeFeedService: Error during force refresh: $e');
      if (onRefreshCompleted != null) {
        onRefreshCompleted!();
      }
      return [];
    }
  }
  
  /// Clear feed cache to force fresh data
  static Future<void> _clearFeedCache() async {
    try {
      // Clear FeedService cache
      FeedService.clearCache();
      print('RealtimeFeedService: Cleared feed cache');
    } catch (e) {
      print('RealtimeFeedService: Error clearing cache: $e');
    }
  }
  
  /// Check if service is active
  static bool get isActive => _isServiceActive;
  
  /// Get last check time
  static DateTime? get lastCheckTime => _lastCheckTime;
  
  /// Get refresh interval
  static Duration get refreshInterval => _refreshInterval;
  
  /// Manual trigger for checking new posts (useful for testing)
  static Future<void> manualCheck({
    required String token,
    required String currentUserId,
  }) async {
    await _checkForNewPosts(token, currentUserId);
  }
  
  /// Get new posts count since last check
  static Future<int> getNewPostsCount({
    required String token,
    required String currentUserId,
  }) async {
    try {
      final latestPosts = await FeedService.getMixedFeed(
        token: token,
        currentUserId: currentUserId,
        page: 1,
        limit: 20,
      );
      
      if (_lastPostId == null) {
        return latestPosts.length;
      }
      
      // Count posts newer than last known post
      int newCount = 0;
      for (final post in latestPosts) {
        if (post.id == _lastPostId) {
          break;
        }
        newCount++;
      }
      
      return newCount;
    } catch (e) {
      print('RealtimeFeedService: Error getting new posts count: $e');
      return 0;
    }
  }
}
