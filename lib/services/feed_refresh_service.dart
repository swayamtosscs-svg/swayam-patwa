import 'package:flutter/material.dart';

/// Service to handle feed refresh when follow status changes
class FeedRefreshService {
  static final FeedRefreshService _instance = FeedRefreshService._internal();
  factory FeedRefreshService() => _instance;
  FeedRefreshService._internal();

  // Callback function to refresh the home feed
  VoidCallback? _onFeedRefresh;

  /// Register the refresh callback from HomeScreen
  void registerRefreshCallback(VoidCallback callback) {
    _onFeedRefresh = callback;
    print('FeedRefreshService: Refresh callback registered');
  }

  /// Unregister the refresh callback
  void unregisterRefreshCallback() {
    _onFeedRefresh = null;
    print('FeedRefreshService: Refresh callback unregistered');
  }

  /// Trigger feed refresh (called when follow status changes)
  void refreshFeed() {
    if (_onFeedRefresh != null) {
      print('FeedRefreshService: Triggering feed refresh...');
      _onFeedRefresh!();
    } else {
      print('FeedRefreshService: No refresh callback registered');
    }
  }

  /// Check if refresh callback is registered
  bool get isCallbackRegistered => _onFeedRefresh != null;
}
