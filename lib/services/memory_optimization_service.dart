import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_http_client.dart';
// Removed Cloudinary dependency

class MemoryOptimizationService {
  static const int _maxImageCacheSize = 50;
  static const Duration _cacheCleanupInterval = Duration(minutes: 5);
  
  static DateTime? _lastCleanup;
  static bool _isLowMemoryMode = false;
  
  /// Initialize memory optimization service
  static void initialize() {
    // Set Flutter image cache limits
    PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
    
    // Set up periodic cleanup
    _schedulePeriodicCleanup();
    
    print('MemoryOptimizationService: Initialized with cache size: $_maxImageCacheSize images, 50MB');
  }
  
  /// Enable low memory mode for better performance on low-end devices
  static void enableLowMemoryMode() {
    _isLowMemoryMode = true;
    
    // Reduce cache sizes further
    PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheSize ~/ 2;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 25 << 20; // 25 MB
    
    // Clear existing caches
    clearAllCaches();
    
    print('MemoryOptimizationService: Low memory mode enabled');
  }
  
  /// Disable low memory mode
  static void disableLowMemoryMode() {
    _isLowMemoryMode = false;
    
    // Restore normal cache sizes
    PaintingBinding.instance.imageCache.maximumSize = _maxImageCacheSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
    
    print('MemoryOptimizationService: Low memory mode disabled');
  }
  
  /// Clear all memory caches
  static void clearAllCaches() {
    // Clear Flutter image caches
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // Clear custom image caches
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
    } catch (e) {
      print('MemoryOptimizationService: Could not clear Cloudinary cache: $e');
    }
    
    // Clear HTTP client cache
    CustomHttpClient.clearCache();
    
    // Force garbage collection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will trigger garbage collection on the next frame
    });
    
    _lastCleanup = DateTime.now();
    print('MemoryOptimizationService: All caches cleared');
  }
  
  /// Perform memory cleanup based on current memory pressure
  static void performCleanup() {
    final now = DateTime.now();
    
    // Don't cleanup too frequently
    if (_lastCleanup != null && 
        now.difference(_lastCleanup!) < _cacheCleanupInterval) {
      return;
    }
    
    // Clear old caches
    _clearOldCaches();
    
    // Check if we need to enable low memory mode
    _checkMemoryPressure();
    
    _lastCleanup = now;
  }
  
  /// Clear old caches to free memory
  static void _clearOldCaches() {
    // Clear Flutter image cache if it's getting large
    if (PaintingBinding.instance.imageCache.currentSize > _maxImageCacheSize * 0.8) {
      PaintingBinding.instance.imageCache.clear();
      print('MemoryOptimizationService: Flutter image cache cleared due to size');
    }
    
    // Clear custom image cache if it's getting large
    try {
      if (PaintingBinding.instance.imageCache.currentSize > _maxImageCacheSize * 0.8) {
        // Clear image cache
        PaintingBinding.instance.imageCache.clear();
        print('MemoryOptimizationService: Custom image cache cleared due to size');
      }
    } catch (e) {
      print('MemoryOptimizationService: Could not check/clear image cache: $e');
    }
  }
  
  /// Check memory pressure and adjust accordingly
  static void _checkMemoryPressure() {
    // This is a simplified check - in a real app you might use platform channels
    // to get actual memory usage from the OS
    
    // For now, we'll use a heuristic based on cache sizes
    final totalCacheSize = PaintingBinding.instance.imageCache.currentSize;
    
    if (totalCacheSize > _maxImageCacheSize * 1.5) {
      if (!_isLowMemoryMode) {
        enableLowMemoryMode();
      }
    } else if (totalCacheSize < _maxImageCacheSize * 0.5) {
      if (_isLowMemoryMode) {
        disableLowMemoryMode();
      }
    }
  }
  
  /// Get current memory usage statistics
  static Map<String, dynamic> getMemoryStats() {
    return {
      'flutterImageCacheSize': PaintingBinding.instance.imageCache.currentSize,
      'flutterImageCacheMaxSize': PaintingBinding.instance.imageCache.maximumSize,
      'imageCacheSize': PaintingBinding.instance.imageCache.currentSize,
      'customImageCacheMaxSize': _maxImageCacheSize,
      'isLowMemoryMode': _isLowMemoryMode,
      'lastCleanup': _lastCleanup?.toIso8601String(),
    };
  }
  
  /// Schedule periodic cleanup
  static void _schedulePeriodicCleanup() {
    Timer.periodic(_cacheCleanupInterval, (timer) {
      performCleanup();
    });
  }
  
  /// Get image cache size safely
  static int _getImageCacheSize() {
    try {
      return PaintingBinding.instance.imageCache.currentSize;
    } catch (e) {
      print('MemoryOptimizationService: Could not get image cache size: $e');
      return 0;
    }
  }

  /// Dispose the service and clean up resources
  static void dispose() {
    clearAllCaches();
    print('MemoryOptimizationService: Disposed');
  }
}
