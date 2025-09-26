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

  // Start playing a video (pause others)
  void playVideo(String videoId) {
    if (_currentPlayingVideoId != videoId) {
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
      // Pause current video when scrolling starts
      pauseCurrentVideo();
    }
    
    // Reset scroll timer
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 500), () {
      _isScrolling = false;
    });
  }

  // Check if currently scrolling
  bool get isScrolling => _isScrolling;

  // Reset manager
  void reset() {
    _currentPlayingVideoId = null;
    _onVideoStateChanged = null;
    _scrollController?.removeListener(_onScroll);
    _scrollController = null;
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _isScrolling = false;
  }
}
