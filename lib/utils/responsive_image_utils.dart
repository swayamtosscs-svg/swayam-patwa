import 'package:flutter/material.dart';

class ResponsiveImageUtils {
  /// Calculate optimal image height based on screen size and image count
  static double calculateOptimalImageHeight({
    required double screenWidth,
    required int imageCount,
    required double maxHeight,
    required double minHeight,
  }) {
    double optimalHeight;
    
    // Get screen size category
    final screenSize = _getScreenSize(screenWidth);
    
    switch (imageCount) {
      case 1:
        // Single image - use different ratios based on screen size
        switch (screenSize) {
          case ScreenSize.small:
            optimalHeight = screenWidth * 0.8; // 5:4 ratio for small screens
            break;
          case ScreenSize.medium:
            optimalHeight = screenWidth * 0.75; // 4:3 ratio for medium screens
            break;
          case ScreenSize.large:
            optimalHeight = screenWidth * 0.7; // 10:7 ratio for large screens
            break;
        }
        break;
      case 2:
        // Two images - use square ratio
        optimalHeight = screenWidth;
        break;
      case 3:
        // Three images - use 3:2 ratio
        optimalHeight = screenWidth * 0.67;
        break;
      default:
        // Multiple images - use 16:9 ratio
        optimalHeight = screenWidth * 0.5625;
        break;
    }
    
    // Ensure height is within bounds
    return optimalHeight.clamp(minHeight, maxHeight);
  }
  
  /// Get screen size category based on width
  static ScreenSize _getScreenSize(double width) {
    if (width < 400) {
      return ScreenSize.small;
    } else if (width < 800) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }
  
  /// Calculate optimal cache dimensions based on screen size
  static Map<String, int> getOptimalCacheDimensions(double screenWidth) {
    final screenSize = _getScreenSize(screenWidth);
    
    switch (screenSize) {
      case ScreenSize.small:
        return {
          'memCacheWidth': 800,
          'memCacheHeight': 600,
          'maxWidthDiskCache': 800,
          'maxHeightDiskCache': 600,
        };
      case ScreenSize.medium:
        return {
          'memCacheWidth': 1200,
          'memCacheHeight': 800,
          'maxWidthDiskCache': 1200,
          'maxHeightDiskCache': 800,
        };
      case ScreenSize.large:
        return {
          'memCacheWidth': 1600,
          'memCacheHeight': 1000,
          'maxWidthDiskCache': 1600,
          'maxHeightDiskCache': 1000,
        };
    }
  }
  
  /// Get optimal fade durations based on screen size
  static Map<String, Duration> getOptimalFadeDurations(double screenWidth) {
    final screenSize = _getScreenSize(screenWidth);
    
    switch (screenSize) {
      case ScreenSize.small:
        return {
          'fadeInDuration': const Duration(milliseconds: 150),
          'fadeOutDuration': const Duration(milliseconds: 100),
        };
      case ScreenSize.medium:
        return {
          'fadeInDuration': const Duration(milliseconds: 200),
          'fadeOutDuration': const Duration(milliseconds: 150),
        };
      case ScreenSize.large:
        return {
          'fadeInDuration': const Duration(milliseconds: 250),
          'fadeOutDuration': const Duration(milliseconds: 200),
        };
    }
  }
}

enum ScreenSize {
  small,
  medium,
  large,
}
