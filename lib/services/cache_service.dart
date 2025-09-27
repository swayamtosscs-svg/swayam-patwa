import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String _cachePrefix = 'rgram_cache_';
  static const Duration _defaultExpiry = Duration(hours: 1);
  static const int _maxCacheSize = 100; // Maximum number of cached items
  
  /// Cache data with expiry
  static Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final expiryTime = DateTime.now().add(expiry ?? _defaultExpiry);
      
      final cacheData = {
        'data': data,
        'expiry': expiryTime.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      
      // Clean up old cache entries if needed
      await _cleanupOldCache();
      
      if (kDebugMode) {
        print('CacheService: Cached data for key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Error caching data: $e');
      }
    }
  }
  
  /// Get cached data if not expired
  static Future<T?> getCachedData<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final cachedString = prefs.getString(cacheKey);
      
      if (cachedString == null) return null;
      
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiryTime = DateTime.parse(cacheData['expiry']);
      
      // Check if cache is expired
      if (DateTime.now().isAfter(expiryTime)) {
        await prefs.remove(cacheKey);
        return null;
      }
      
      if (kDebugMode) {
        print('CacheService: Retrieved cached data for key: $key');
      }
      
      return cacheData['data'] as T?;
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Error retrieving cached data: $e');
      }
      return null;
    }
  }
  
  /// Check if data exists in cache and is not expired
  static Future<bool> hasCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final cachedString = prefs.getString(cacheKey);
      
      if (cachedString == null) return false;
      
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiryTime = DateTime.parse(cacheData['expiry']);
      
      return !DateTime.now().isAfter(expiryTime);
    } catch (e) {
      return false;
    }
  }
  
  /// Remove specific cached data
  static Future<void> removeCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      await prefs.remove(cacheKey);
      
      if (kDebugMode) {
        print('CacheService: Removed cached data for key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Error removing cached data: $e');
      }
    }
  }
  
  /// Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      if (kDebugMode) {
        print('CacheService: Cleared all cached data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Error clearing cache: $e');
      }
    }
  }
  
  /// Clean up old cache entries
  static Future<void> _cleanupOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      if (keys.length <= _maxCacheSize) return;
      
      final cacheEntries = <MapEntry<String, DateTime>>[];
      
      for (final key in keys) {
        final cachedString = prefs.getString(key);
        if (cachedString != null) {
          try {
            final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
            final timestamp = DateTime.parse(cacheData['timestamp']);
            cacheEntries.add(MapEntry(key, timestamp));
          } catch (e) {
            // Remove invalid cache entries
            await prefs.remove(key);
          }
        }
      }
      
      // Sort by timestamp and remove oldest entries
      cacheEntries.sort((a, b) => a.value.compareTo(b.value));
      final entriesToRemove = cacheEntries.length - _maxCacheSize;
      
      for (int i = 0; i < entriesToRemove; i++) {
        await prefs.remove(cacheEntries[i].key);
      }
      
      if (kDebugMode) {
        print('CacheService: Cleaned up ${entriesToRemove} old cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CacheService: Error cleaning up cache: $e');
      }
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      int totalEntries = 0;
      int expiredEntries = 0;
      int validEntries = 0;
      
      for (final key in keys) {
        final cachedString = prefs.getString(key);
        if (cachedString != null) {
          try {
            final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
            final expiryTime = DateTime.parse(cacheData['expiry']);
            
            totalEntries++;
            if (DateTime.now().isAfter(expiryTime)) {
              expiredEntries++;
            } else {
              validEntries++;
            }
          } catch (e) {
            totalEntries++;
            expiredEntries++;
          }
        }
      }
      
      return {
        'totalEntries': totalEntries,
        'validEntries': validEntries,
        'expiredEntries': expiredEntries,
        'maxCacheSize': _maxCacheSize,
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'validEntries': 0,
        'expiredEntries': 0,
        'maxCacheSize': _maxCacheSize,
        'error': e.toString(),
      };
    }
  }
}
