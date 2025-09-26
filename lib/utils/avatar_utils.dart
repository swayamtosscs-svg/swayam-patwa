import 'package:flutter/material.dart';

class AvatarUtils {
  static const String baseUrl = 'http://103.14.120.163:8081';
  
  /// Convert relative avatar URL to absolute URL
  static String getAbsoluteAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return '';
    }
    
    // If it's already an absolute URL, return as is
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return avatarUrl;
    }
    
    // If it's a relative path, prepend the base URL
    if (avatarUrl.startsWith('/')) {
      return '$baseUrl$avatarUrl';
    }
    
    // If it doesn't start with /, add it
    return '$baseUrl/$avatarUrl';
  }
  
  /// Check if avatar URL is valid
  static bool isValidAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return false;
    }
    
    final absoluteUrl = getAbsoluteAvatarUrl(avatarUrl);
    return absoluteUrl.startsWith('http://') || absoluteUrl.startsWith('https://');
  }
  
  /// Get default avatar URL
  static String? getDefaultAvatarUrl() {
    return null; // Return null instead of default girl picture
  }
  
  /// Generate initials from name
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return 'U'; // Default to 'U' for User
    }
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[words.length - 1].substring(0, 1)).toUpperCase();
    }
  }
  
  /// Generate avatar color based on name
  static Color getAvatarColor(String? name) {
    if (name == null || name.isEmpty) {
      return const Color(0xFF6366F1); // Default color
    }
    
    // Generate consistent color based on name hash
    final hash = name.hashCode;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5A2B), // Brown
      const Color(0xFF6B7280), // Gray
    ];
    
    return colors[hash.abs() % colors.length];
  }
  
  /// Build a default avatar widget with initials
  static Widget buildDefaultAvatar({
    required String? name,
    required double size,
    Color? borderColor,
    double borderWidth = 2,
  }) {
    final initials = getInitials(name);
    final avatarColor = getAvatarColor(name);
    final effectiveBorderColor = borderColor ?? avatarColor;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveBorderColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
  
  /// Build a gradient default avatar widget
  static Widget buildGradientDefaultAvatar({
    required String? name,
    required double size,
    Color? borderColor,
    double borderWidth = 2,
  }) {
    final avatarColor = getAvatarColor(name);
    final effectiveBorderColor = borderColor ?? avatarColor;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            avatarColor.withOpacity(0.1),
            avatarColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveBorderColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: avatarColor,
      ),
    );
  }
}
