import 'package:flutter/material.dart';
import 'dart:async';

class VideoManager {
  static final VideoManager _instance = VideoManager._internal();
  factory VideoManager() => _instance;
  VideoManager._internal();

  // Track the currently playing video
  String? _currentPlayingVideoId;
  
  // Callback to notify when video state changes
  Function(String? videoId)? _onVideoStateChanged;
  
  // Track visibility of videos
  final Map<String, bool> _videoVisibility = {};
  
  // Track video positions for PageView
  final Map<String, int> _videoPositions = {};
  
  // Current PageView index
  int? _currentPageIndex;
  
  // Scroll controller for detecting scroll events
  ScrollController? _scrollController;
  
  // Track if currently scrolling
  bool _isScrolling = false;
  
  // Timer for scroll detection
  Timer? _scrollTimer;

  // Register callback for video state changes
  void setOnVideoStateChanged(Function(String? videoId) callback) {
    _onVideoStateChanged = callback;
  }

  // Update video visibility
  void updateVideoVisibility(String videoId, bool isVisible) {
    _videoVisibility[videoId] = isVisible;
    
    print('VideoManager: Video $videoId visibility changed to $isVisible');
    
    // If this video becomes visible and no other video is playing, play it
    if (isVisible && _currentPlayingVideoId == null) {
      print('VideoManager: Playing video $videoId (no other video playing)');
      playVideo(videoId);
    }
    // If this video becomes invisible and it's currently playing, pause it
    else if (!isVisible && _currentPlayingVideoId == videoId) {
      print('VideoManager: Pausing video $videoId (became invisible)');
      pauseCurrentVideo();
    }
    // If this video becomes visible and another video is playing, play this one instead
    else if (isVisible && _currentPlayingVideoId != null && _currentPlayingVideoId != videoId) {
      print('VideoManager: Switching from ${_currentPlayingVideoId} to $videoId');
      playVideo(videoId);
    }
  }

  // Update PageView index
  void updatePageIndex(int index) {
    _currentPageIndex = index;
    print('VideoManager: PageView index changed to $index');
    
    // Find the video at this position and play it
    String? videoAtPosition;
    for (final entry in _videoPositions.entries) {
      if (entry.value == index) {
        videoAtPosition = entry.key;
        break;
      }
    }
    
    if (videoAtPosition != null && _videoVisibility[videoAtPosition] == true) {
      print('VideoManager: Playing video $videoAtPosition at position $index');
      playVideo(videoAtPosition);
    }
  }

  // Register video position in PageView
  void registerVideoPosition(String videoId, int position) {
    _videoPositions[videoId] = position;
    print('VideoManager: Registered video $videoId at position $position');
  }

  // Check if a video is visible
  bool isVideoVisible(String videoId) {
    return _videoVisibility[videoId] ?? false;
  }

  // Start playing a video (pause others)
  void playVideo(String videoId) {
    if (_currentPlayingVideoId != videoId) {
      print('VideoManager: Switching to video $videoId');
      
      // Pause previous video if any
      if (_currentPlayingVideoId != null) {
        _onVideoStateChanged?.call(_currentPlayingVideoId);
      }
      
      // Set new current video
      _currentPlayingVideoId = videoId;
      
      // Notify that this video should play
      _onVideoStateChanged?.call(videoId);
    }
  }

  // Pause current video
  void pauseCurrentVideo() {
    if (_currentPlayingVideoId != null) {
      print('VideoManager: Pausing current video $_currentPlayingVideoId');
      _onVideoStateChanged?.call(_currentPlayingVideoId);
      _currentPlayingVideoId = null;
    }
  }

  // Check if a video is currently playing
  bool isVideoPlaying(String videoId) {
    return _currentPlayingVideoId == videoId;
  }

  // Get currently playing video ID
  String? get currentPlayingVideoId => _currentPlayingVideoId;

  // Set scroll controller for scroll detection
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
    _scrollController?.addListener(_onScroll);
  }

  // Handle scroll events
  void _onScroll() {
    if (!_isScrolling) {
      _isScrolling = true;
      print('VideoManager: Scroll started, pausing current video');
      // Pause current video when scrolling starts
      pauseCurrentVideo();
    }
    
    // Reset scroll timer
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      _isScrolling = false;
      print('VideoManager: Scroll ended');
    });
  }

  // Check if currently scrolling
  bool get isScrolling => _isScrolling;

  // Reset manager
  void reset() {
    _currentPlayingVideoId = null;
    _onVideoStateChanged = null;
    _videoVisibility.clear();
    _videoPositions.clear();
    _currentPageIndex = null;
    _scrollController?.removeListener(_onScroll);
    _scrollController = null;
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _isScrolling = false;
  }
}
